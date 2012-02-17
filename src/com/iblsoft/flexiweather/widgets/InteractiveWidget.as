package com.iblsoft.flexiweather.widgets
{
	import com.iblsoft.flexiweather.events.InteractiveLayerEvent;
	import com.iblsoft.flexiweather.events.InteractiveWidgetEvent;
	import com.iblsoft.flexiweather.ogc.BBox;
	import com.iblsoft.flexiweather.proj.Coord;
	import com.iblsoft.flexiweather.proj.Projection;
	import com.iblsoft.flexiweather.utils.AnticollisionLayout;
	
	import flash.display.DisplayObject;
	import flash.display.GradientType;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.events.TimerEvent;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.system.Capabilities;
	import flash.utils.Timer;
	import flash.utils.clearTimeout;
	import flash.utils.getTimer;
	import flash.utils.setTimeout;
	
	import mx.core.Container;
	import mx.events.ResizeEvent;
	
	import spark.components.Group;

	[Event (name="viewBBoxChanged", type="flash.events.Event")]
	
	/**
	 * Dispatched, when all layers which were loaded at once are loaded. 
	 */	
	[Event (name="allDataLayersLoaded", type="com.iblsoft.flexiweather.events.InteractiveWidgetEvent")]
	[Event (name="dataLayerLoadingStarted", type="com.iblsoft.flexiweather.events.InteractiveWidgetEvent")]
	[Event (name="dataLayerLoadingFinished", type="com.iblsoft.flexiweather.events.InteractiveWidgetEvent")]
	
	public class InteractiveWidget extends Container
	{
		public static const VIEW_BBOX_CHANGED: String = 'viewBBoxChanged';
		
        private var ms_crs: String = Projection.CRS_EPSG_GEOGRAPHIC;
		private var m_crsProjection: Projection = Projection.getByCRS(ms_crs);
        private var m_viewBBox: BBox = new BBox(-180, -90, 180, 90);
        private var m_extentBBox: BBox = new BBox(-180, -90, 180, 90);
        private var mb_orderingLayers: Boolean = false;

		private var mb_autoLayout: Boolean = false;

		private var mb_backgroundChessBoard: Boolean = false;

		private var m_resizeTimer: Timer;
		
		private var m_layerContainer: Container = new Container();

		private var m_labelLayout: AnticollisionLayout = new AnticollisionLayout();
		
		private var m_lastResizeTime: Number;
		
		public function InteractiveWidget() {
			super();
			
			mouseEnabled = true;
			mouseFocusEnabled = true;
			doubleClickEnabled = true;

			addChild(m_layerContainer);
			m_layerContainer.x = m_layerContainer.y = 0;
			rawChildren.addChild(m_labelLayout);
			clipContent = true;

			addEventListener(MouseEvent.MOUSE_DOWN, onMouseDown);
			addEventListener(MouseEvent.MOUSE_UP, onMouseUp);
			addEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
			addEventListener(MouseEvent.MOUSE_WHEEL, onMouseWheel);
			addEventListener(MouseEvent.CLICK, onMouseClick);
			addEventListener(MouseEvent.DOUBLE_CLICK, onMouseDoubleClick);
			addEventListener(MouseEvent.ROLL_OVER, onMouseRollOver);
			addEventListener(MouseEvent.ROLL_OUT, onMouseRollOut);
			addEventListener(ResizeEvent.RESIZE, onResized);
			
			m_lastResizeTime = getTimer();
		}
		
		override protected function commitProperties():void
		{
			super.commitProperties();
			
			if (mb_autoLayoutChanged)
			{
				var widgetParent: Group = parent as Group;
				if (widgetParent)
				{
					if (mb_autoLayout)
					{
						widgetParent.addEventListener(ResizeEvent.RESIZE, onParentResize);
					} else {
						widgetParent.removeEventListener(ResizeEvent.RESIZE, onParentResize);
					}
				}
			}
		}
			
		private var _resizeInterval: Number;
		private function onParentResize(event: ResizeEvent): void
		{
			clearTimeout(_resizeInterval);
			
			//wait 1 second before resing (if there is another resize event)
			var resizeMinimumTime: Number = 1000; //1000ms
			
			var currTime: Number = getTimer();
			
			if ((currTime - m_lastResizeTime) >= resizeMinimumTime)
			{
				trace("go autolayout: time diff: "+(currTime - m_lastResizeTime) +" ms");
				m_lastResizeTime = currTime;
				autoLayoutViewBBox(m_viewBBox, true, true);
			} else {
				trace("on parent resize: wait at least "+(currTime - m_lastResizeTime) +" ms");
				//uto layout but do not load layers (finalUpdate = false)
				autoLayoutViewBBox(m_viewBBox, false, true);
				
				_resizeInterval = setTimeout(autoLayoutViewBBox, (currTime - m_lastResizeTime), m_viewBBox, true, true);
			}
		}
		
		public override function addChild(child: DisplayObject): DisplayObject
		{
			if(child is InteractiveLayer) {
				// InteractiveLayer based child are added to m_layerContainer
				InteractiveLayer(child).container = this; // this also ensures that child is InteractiveLayer
				child.width = width;
				child.height = height;
				var o: DisplayObject = m_layerContainer.addChild(child);
				orderLayers();
				return o;
			}
			else
				return super.addChild(child);
		}
		
		public override function addChildAt(child: DisplayObject, index: int): DisplayObject
		{
			if(child is InteractiveLayer) {
				// InteractiveLayer based child are added to m_layerContainer
				InteractiveLayer(child).container = this; // this also ensures that child is InteractiveLayer
				child.x = x;
				child.y = y;
				child.width = width;
				child.height = height;
				var o: DisplayObject = m_layerContainer.addChildAt(child, index);
				orderLayers();
				return o;
			}
			else
				return super.addChildAt(child, index);
		}

		private var m_layersLoading: int = 0;
		private function onLayerLoadingStart( event: InteractiveLayerEvent): void
		{
			m_layersLoading++;
			
			var ile: InteractiveWidgetEvent = new InteractiveWidgetEvent(InteractiveWidgetEvent.DATA_LAYER_LOADING_STARTED);
			ile.layersLoading = m_layersLoading;
			dispatchEvent(ile);
			
			trace("IW onLayerLoadingStart " + event.interactiveLayer.name + " m_layersLoading: " + m_layersLoading);
		}
		private function onLayerLoaded( event: InteractiveLayerEvent): void
		{
			m_layersLoading--;
			trace("IW onLayerLoaded " + event.interactiveLayer.name + " layers currently loading: " + m_layersLoading);
			
			var ile: InteractiveWidgetEvent = new InteractiveWidgetEvent(InteractiveWidgetEvent.DATA_LAYER_LOADING_FINISHED);
			ile.layersLoading = m_layersLoading;
			dispatchEvent(ile);
			
			if (m_layersLoading <= 0)
			{
				trace("\t IW ALL layers are loaded");
				var ile: InteractiveWidgetEvent = new InteractiveWidgetEvent(InteractiveWidgetEvent.ALL_DATA_LAYERS_LOADED);
				dispatchEvent(ile);
			}
		}
		
		public function addLayer(l: InteractiveLayer, index: int = -1): void
		{
			l.addEventListener(InteractiveDataLayer.LOADING_FINISHED, onLayerLoaded);
			l.addEventListener(InteractiveDataLayer.LOADING_STARTED, onLayerLoadingStart);
			
			if (index >= 0)
				addChildAt(l, index);
			else
				addChild(l);
			
			//when new layer is added to container, call onAreaChange to notify layer, that layer is already added to container, so it can render itself
			l.onAreaChanged(true);
			
			orderLayers();
		}
		
		public function removeLayer(l: InteractiveLayer, b_destroy: Boolean = false): void
		{
			if(l.parent == m_layerContainer) {
				l.destroy();
				m_layerContainer.removeChild(l);
			}
		}
		
		public function removeAllLayers(): void
		{
			while(m_layerContainer.numChildren) {
				var i: int = m_layerContainer.numChildren - 1;
				var l: InteractiveLayer = InteractiveLayer(m_layerContainer.getChildAt(i));
				l.destroy();
				m_layerContainer.removeChildAt(i);
			}
		}
		
		public function debugLayers(): void
		{
			var total: int = m_layerContainer.numChildren;
			for (var i: int = 0; i < total; i++)
			{
				var layer: InteractiveLayer = InteractiveLayer(m_layerContainer.getChildAt(i)); 
				trace("Widget debugLayers: " + i + ": " + layer.name);
			}
		}
		
		public function orderLayers(): void
		{
			if(mb_orderingLayers)
				return;
			mb_orderingLayers = true;
			try {
				// stable-sort interactive layers in ma_layers according to their zOrder property
				for(var i: int = 0; i < m_layerContainer.numChildren; ++i) {
					var ilI: InteractiveLayer = InteractiveLayer(m_layerContainer.getChildAt(i)); 
					for(var j: int = i + 1; j < m_layerContainer.numChildren; ++j) {
						var ilJ: InteractiveLayer = InteractiveLayer(m_layerContainer.getChildAt(j));
						if(ilJ.zOrder < ilI.zOrder) {
							// swap Ith and Jth layer, we know that J > I
//							trace('[InteractiveWidget.orderLayers] ... swapping ' + ilJ.name + ' with ' + ilI.name);
							m_layerContainer.swapChildren(ilJ, ilI);
						}
					}
				}
			}
			finally {
				mb_orderingLayers = false;
			}
		}

        override protected function updateDisplayList(
            	unscaledWidth: Number, unscaledHeight: Number): void
        {
            if (isNaN(unscaledWidth) || isNaN(unscaledHeight))
            {
            	//when user press Cancel on printing interactiveWidget, both sizes was NaN
            	return;
            }

			m_layerContainer.width = width;
			m_layerContainer.height = height;
			
			if(m_labelLayout.m_placementBitmap == null)
				m_labelLayout.setBoundary(new Rectangle(0, 0, width, height)); 
			if(m_labelLayout.needsUpdate())
				m_labelLayout.update();

			graphics.clear();

			if(mb_backgroundChessBoard) {
				var i_squareSize: uint = 10;
				var i_row: uint = 0;
				for(var y: uint = 0; y < height; y += i_squareSize, ++i_row) {
					var b_flag: Boolean = (i_row & 1) != 0;
					for(var x: uint = 0; x < width; x += i_squareSize) {
						graphics.beginFill(b_flag ? 0xc0c0c0 : 0x808080);
						graphics.drawRect(x, y, i_squareSize, i_squareSize);
						graphics.endFill();
						b_flag = !b_flag;
					}
				}
			}
			else {
				var matrix: Matrix = new Matrix();
				matrix.rotate(90);
				graphics.beginGradientFill(GradientType.LINEAR, [0xAAAAAA, 0xFFFFFF], [1, 1], [0, 255], matrix);
				graphics.drawRect(0, 0, width, height);
				graphics.endFill();
			}

			// DEBUG: display label layout placement bitmap
			//graphics.beginBitmapFill(m_labelLayout.m_placementBitmap);
			//graphics.drawRect(0, 0, m_labelLayout.m_placementBitmap.width, m_labelLayout.m_placementBitmap.height);
			//graphics.endFill();

            super.updateDisplayList(unscaledWidth, unscaledHeight);
        }

		protected function signalAreaChanged(b_finalChange: Boolean): void
		{
			onAreaChanged(b_finalChange);
		}

		private var _oldViewBBox: BBox = new BBox(0,0,0,0);
		
        protected function onAreaChanged(b_finalChange: Boolean): void
        {
        	if (_oldViewBBox.equals(m_viewBBox))
			{
				if (!b_finalChange)
				{
//					trace("IWidget onAreaChanged oldView equals to new one: b_finalChange: " + b_finalChange);
					return;
				}
			}
			
            for(var i: int = 0; i < m_layerContainer.numChildren; ++i) {
            	var l: InteractiveLayer = InteractiveLayer(m_layerContainer.getChildAt(i));
            	if(l.onAreaChanged(b_finalChange))
            		break;
            	if(!l.isDynamicPartInvalid())
            		l.invalidateDynamicPart();
            }
			m_labelLayout.setDirty();
			
			_oldViewBBox = m_viewBBox.clone();
        }
		
		internal function onLayerVisibilityChanged(layer: InteractiveLayer): void
		{
			m_labelLayout.setDirty();
		}
        
		/** Converts screen point (pixels) into Coord with current CRS. */ 
        public function pointToCoord(x: Number, y: Number): Coord
        {
        	return new Coord(
	        		ms_crs,
	        		x * m_viewBBox.width / (width - 1) + m_viewBBox.xMin,
	        		(height - 1 - y) * m_viewBBox.height / (height - 1) + m_viewBBox.yMin)
        }

		/** Converts screen point (pixels) into Coord with current CRS. */ 
        public function coordToPoint(c: Coord): Point
        {
			var ptInOurCRS: Point;
        	if(Projection.equalCRSs(c.crs, ms_crs)) {
				ptInOurCRS = c;
        	}
        	else {
				if(m_crsProjection == null) {
					trace("InteractiveWidget.coordToPoint(): Unknown IW projection for CRS=" + ms_crs);
					return null;
				}
				var sourceProjection: Projection = Projection.getByCRS(c.crs);
				if(sourceProjection == null) {
					trace("InteractiveWidget.coordToPoint(): Unknown projection for CRS=" + c.crs);
					return null;
				}
				ptInOurCRS = m_crsProjection.laLoPtToPrjPt(sourceProjection.prjXYToLaLoPt(c.x, c.y));
			}
			return new Point(
					(ptInOurCRS.x - m_viewBBox.xMin) * (width - 1) / m_viewBBox.width,
					height - 1 - (ptInOurCRS.y - m_viewBBox.yMin) * (height - 1) / m_viewBBox.height);
        }
		
		/**
		 * Splits coordinates of BBox (in the currently used CRS) into partial sub-BBoxes of the
		 * IW's View BBox, which are visible.
		 * When panning over the anti-meridian (assuming the IW's View BBox is bigger than
		 * Projection extent BBOx - the source BBox must be split into typically 2 sub-parts
		 * one to the left (east hemisphere) and on the righ (west hemisphere). If the view is zoomed
		 * out enough even multiple reflection of the part can be seen.
		 **/
		public function mapBBoxToProjectionExtentParts(bbox: BBox): Array
		{
			var a: Array = [];
			if(m_crsProjection.wrapsHorizontally) {
				var testExtentBBox: BBox = m_crsProjection.extentBBox;
				var f_crsExtentBBoxWidth: Number = m_crsProjection.extentBBox.width;
				for(var i: int = 0; i < 10; i++) {
					var i_delta: int = (i & 1 ? 1 : -1) * ((i + 1) >> 1); // generates sequence 0, 1, -1, 2, -2, ..., 5, -5
//					trace("\t mapBBoxToViewParts delta: " + i_delta);
					var reflectedBBox: BBox = bbox.translated(f_crsExtentBBoxWidth * i_delta, 0)
					var intersectionOfReflectedBBoxWithCRSExtentBBox: BBox =
							reflectedBBox.intersected(m_crsProjection.extentBBox);
					
//					trace("\t mapBBoxToViewParts ............reflectedBBox: " + reflectedBBox);
//					trace("\t mapBBoxToViewParts inters. of reflected BBox: " + intersectionOfReflectedBBoxWithCRSExtentBBox);
					if(intersectionOfReflectedBBoxWithCRSExtentBBox && intersectionOfReflectedBBoxWithCRSExtentBBox.width > 0 && intersectionOfReflectedBBoxWithCRSExtentBBox.height > 0) {
						var b_foundEnvelopingBBox: Boolean = false;
						for each(var otherBBox: BBox in a) {
							if(otherBBox.contains(intersectionOfReflectedBBoxWithCRSExtentBBox)) {
								b_foundEnvelopingBBox = true;
								break;
							}
						}
						if(!b_foundEnvelopingBBox) {
//							trace("InteractiveWidget.mapBBoxToViewParts(): reflected "
//								+ i_delta + " part " + intersectionOfReflectedBBoxWithCRSExtentBBox.toString());
							a.push(intersectionOfReflectedBBoxWithCRSExtentBBox);
						} 
					}
				}
			}
			if(a.length == 0) {
				var primaryPartBBox: BBox = bbox;
				primaryPartBBox = primaryPartBBox.intersected(m_crsProjection.extentBBox);
				if(primaryPartBBox == null) // no intersection!
					primaryPartBBox = bbox; // just keep the current view BBox and let's see what server returns
				a.push(primaryPartBBox);
//				trace("InteractiveWidget.mapBBoxToViewParts(): primary part only " + primaryPartBBox.toString());
			}
			return a;
		}

		/**
		 * Converts coordinates of BBox (in the currently used CRS) into its visual reflections
		 * if the IW's View BBox is bigger than extent BBox of the Projection.
		 * Then at certain zoom-out distance the same BBox may appear multiple times withing the View.
		 * Visualy this looks like multiple reflection of the same BBox in the View.   
		 **/
		public function mapBBoxToViewReflections(bbox: BBox, returnIntersectedBBox: Boolean = false): Array
		{
			var f_crsExtentBBoxWidth: Number = m_crsProjection.extentBBox.width;
			var intersectedBBox: BBox;
			
			if(!m_crsProjection.wrapsHorizontally) {
				//trace("InteractiveWidget.mapBBoxToViewReflections(): mapping to primary part "
				//		+ bbox.toString());
				if (!returnIntersectedBBox)
					return [bbox];
				else {
					intersectedBBox = bbox.intersected(m_viewBBox);
					if(intersectedBBox == null)
						return [];
					else
						return [intersectedBBox];
				}
			}
			else {
				var a: Array = [];
				for(var i: int = 0; i < 11; i++) {
					var i_delta: int = (i & 1 ? 1 : -1) * ((i + 1) >> 1); // generates sequence 0, 1, -1, 2, -2, ..., 5, -5
					var reflectedBBox: BBox = bbox.translated(f_crsExtentBBoxWidth * i_delta, 0)
						
					intersectedBBox = reflectedBBox.intersected(m_viewBBox); 
					if(intersectedBBox) {
//						trace("InteractiveWidget.mapBBoxToViewReflections(): mapping to reflection "
//							+ i_delta + " into " + reflectedBBox.toString());
						
						if (!returnIntersectedBBox)
							a.push(reflectedBBox);
						else
							a.push(intersectedBBox);
					}
				}
				return a;
			}
		}			

        // Mouse events handling

        protected function onMouseDown(event: MouseEvent): void
        {
            for(var i: int = m_layerContainer.numChildren - 1; i >= 0; --i) {
            	var l: InteractiveLayer = InteractiveLayer(m_layerContainer.getChildAt(i));
            	if(!l.enabled)
            		continue;
            	if(l.onMouseDown(event))
            		break; 
            }
			postUserActionUpdate();			
        }

        protected function onMouseUp(event: MouseEvent): void
        {
            for(var i: int = m_layerContainer.numChildren - 1; i >= 0; --i) {
            	var l: InteractiveLayer = InteractiveLayer(m_layerContainer.getChildAt(i));
            	if(!l.enabled)
            		continue;
            	if(l.onMouseUp(event))
            		break; 
            }
			postUserActionUpdate();			
        }

        protected function onMouseMove(event: MouseEvent): void
        {
            for(var i: int = m_layerContainer.numChildren - 1; i >= 0; --i) {
            	var l: InteractiveLayer = InteractiveLayer(m_layerContainer.getChildAt(i));
            	if(!l.enabled)
            		continue;
            	if(l.onMouseMove(event))
            		break; 
            }
			postUserActionUpdate();			
        }

        protected function onMouseWheel(event: MouseEvent): void
        {
            for(var i: int = m_layerContainer.numChildren - 1; i >= 0; --i) {
            	var l: InteractiveLayer = InteractiveLayer(m_layerContainer.getChildAt(i));
            	if(!l.enabled)
            		continue;
            	if(l.onMouseWheel(event))
            		break; 
            }
			postUserActionUpdate();			
        }
        
        protected function onMouseClick(event: MouseEvent): void
        {
            for(var i: int = m_layerContainer.numChildren - 1; i >= 0; --i) {
            	var l: InteractiveLayer = InteractiveLayer(m_layerContainer.getChildAt(i));
            	if(!l.enabled)
            		continue;
            	if(l.onMouseClick(event))
            		break; 
            }
			postUserActionUpdate();			
        }

        protected function onMouseDoubleClick(event: MouseEvent): void
        {
            for(var i: int = m_layerContainer.numChildren - 1; i >= 0; --i) {
            	var l: InteractiveLayer = InteractiveLayer(m_layerContainer.getChildAt(i));
            	if(!l.enabled)
            		continue;
            	if(l.onMouseDoubleClick(event))
            		break; 
            }
			postUserActionUpdate();			
        }

        protected function onMouseRollOver(event: MouseEvent): void
        {
            for(var i: int = m_layerContainer.numChildren - 1; i >= 0; --i) {
            	var l: InteractiveLayer = InteractiveLayer(m_layerContainer.getChildAt(i));
            	if(!l.enabled)
            		continue;
            	if(l.onMouseRollOver(event))
            		break; 
            }
			postUserActionUpdate();			
        }

        protected function onMouseRollOut(event: MouseEvent): void
        {
            for(var i: int = m_layerContainer.numChildren - 1; i >= 0; --i) {
            	var l: InteractiveLayer = InteractiveLayer(m_layerContainer.getChildAt(i));
            	if(!l.enabled)
            		continue;
            	if(l.onMouseRollOut(event))
            		break; 
            }
			postUserActionUpdate();			
        }
        
        protected function onResized(Event: ResizeEvent): void
        {
			m_labelLayout.setBoundary(new Rectangle(0, 0, width, height));
			if(!m_resizeTimer)
        	{
        		m_resizeTimer = new Timer(500, 1);
        		m_resizeTimer.addEventListener(TimerEvent.TIMER_COMPLETE, afterDelayedResize);
        	}
        	m_resizeTimer.stop();
        	m_resizeTimer.start();
        }
        
        private function afterDelayedResize(event: TimerEvent = null): void
        {
//        	setViewBBox(m_viewBBox, true); // set the view bbox to update the aspects 
        	setViewBBox(m_viewBBox, false); // set the view bbox to update the aspects 
            for(var i: int = 0; i < m_layerContainer.numChildren; ++i) {
            	var l: InteractiveLayer = InteractiveLayer(m_layerContainer.getChildAt(i));
            	l.width = width;
            	l.height = height;
            	l.onContainerSizeChanged();
            	if(!l.isDynamicPartInvalid())
            		l.invalidateDynamicPart();
            }
            scrollRect = new Rectangle(0, 0, width, height);
			postUserActionUpdate();
		}
		
		private function postUserActionUpdate(): void
		{
			for(var i: int = 0; i < m_layerContainer.numChildren; ++i) {
				var l: InteractiveLayer = InteractiveLayer(m_layerContainer.getChildAt(i));
				if(l.isDynamicPartInvalid())
					l.validateNow();
			}
			if(m_labelLayout.needsUpdate())
				m_labelLayout.update();
		}
		
		// Getters & setters

		public function getCRS(): String
		{ return ms_crs; }
		
		public function setCRS(s_crs: String, b_finalChange: Boolean = true): void
		{
			if(ms_crs != s_crs) {
				ms_crs = s_crs;
				m_crsProjection = Projection.getByCRS(s_crs);
				signalAreaChanged(b_finalChange);
				dispatchEvent(new Event("crsChanged"));
			}
		}
		
		public function getCRSProjection(): Projection
		{ return m_crsProjection; }
		
		public function setViewBBoxRaw(xmin: Number, ymin: Number, xmax: Number, ymax: Number, b_finalChange: Boolean): void
		{
			setViewBBox(new BBox(xmin, ymin, xmax, ymax), b_finalChange);
		}

		public function isCRSWrappingOverXAxis(): Boolean
		{
			m_crsProjection = Projection.getByCRS(ms_crs);
			return m_crsProjection.wrapsHorizontally; 
		}

		public function getMapScale(): Number
		{
			var w: int = width;
			var h: int = height;
			var bbox: BBox = m_viewBBox;
			var prj: Projection = m_crsProjection;
			
			var dpi: int = Capabilities.screenDPI;
			var maxDistanceOnEarthInKm: Number = bbox.getBBoxMaximumDistance(crs);
			var screenDistanceInPixels: Number = Math.sqrt(w * w + h * h);
			var screenDistanceInInches: Number = screenDistanceInPixels / dpi;
			
			var screenDistanceInKm: Number = screenDistanceInInches * 2.54 * 0.00001;
			
			var scale: Number = screenDistanceInKm / maxDistanceOnEarthInKm;
				
			trace("distanceInKm: " + screenDistanceInKm + " scale: " + scale);
			
			return scale
			
		}
		/**
		 * Set View bounding box for all layers
		 *  
		 * @param bbox - new bounding box to be changed to
		 * @param b_finalChange - false if it is change in some running action (like user has draging map or zooming in or out). If action is finished, set b_finalChange = true
		 * @param b_negotiateBBox - if bounding box needs to be negotiated (because some layers e.g. google can not set any bounding box (because of zoom)
		 * @param b_changeZoom - This is temporary argument, just for Google Maps fix of scaling maps on Map PAN
		 */		
        public function setViewBBox(bbox: BBox, b_finalChange: Boolean, b_negotiateBBox: Boolean = true): void
        {
			var b_changeZoom: Boolean = true;
			var oldBox: BBox = getViewBBox();
			
			var bboxWidthDiff: int = Math.abs(bbox.width - oldBox.width);
			var bboxHeightDiff: int = Math.abs(bbox.height - oldBox.height);
			
//			trace("InteractiveWidget.setViewBBox DIFF " + bboxWidthDiff + " , " + bboxHeightDiff);
			if (bboxHeightDiff == 0 && bboxWidthDiff == 0)
			{
				b_changeZoom = false;
			}
			
//			trace("InteractiveWidget.setViewBBox (bbox: " +  bbox+") final change: " + b_finalChange);
        	// aspect is the bigger the bbox is wider than higher
        	
        	// this is the aspect ratio we want to maintain
        	var f_extentAspect: Number = 1; //m_extentBBox.width / m_extentBBox.height;
        	
        	var f_bboxCenterX: Number = bbox.xMin + bbox.width / 2.0; 
        	var f_bboxCenterY: Number = bbox.yMin + bbox.height / 2.0;
        	
        	// this is the aspect ratio of currently requeste bbox
        	var f_bboxApect: Number = bbox.width / bbox.height;
        	var f_componentAspect: Number = width / height;
			if (isNaN(f_componentAspect))
				f_componentAspect = 1;
				

        	var f_newBBoxWidth: Number;
        	var f_newBBoxHeight: Number;
        	
			if (!mb_autoLayout)
			{
	        	
        	if(f_bboxApect < f_extentAspect) {
        		// extent looks wider 
        		f_newBBoxWidth = f_componentAspect * f_extentAspect * bbox.height;
        		f_newBBoxHeight = bbox.height;
        	}
        	else {
        		// extent looks higher
        		f_newBBoxWidth =  bbox.width;
        		f_newBBoxHeight = bbox.width / f_extentAspect / f_componentAspect;
        	}
        	
			// uncomment this if statement, if you want enable unzoom to see more reflections
//			if (!isCRSWrappingOverXAxis())
//			{
	        	if(f_newBBoxHeight > m_extentBBox.height) {
	        		f_newBBoxHeight = m_extentBBox.height;
	        		f_newBBoxWidth = f_componentAspect * f_extentAspect * f_newBBoxHeight;
	        	}
	        	if(f_newBBoxWidth > m_extentBBox.width) {
	        		f_newBBoxWidth = m_extentBBox.width;
	        		f_newBBoxHeight = f_newBBoxWidth / f_componentAspect / f_extentAspect;
	        	}
//			}
			if (isNaN(f_newBBoxHeight))
			{
				trace("stop f_newBBoxHeight is NaN");
			}
        	var viewBBox: Rectangle = new Rectangle(
	        		f_bboxCenterX - f_newBBoxWidth / 2.0,
	        		f_bboxCenterY - f_newBBoxHeight / 2.0,
	        		f_newBBoxWidth,
	        		f_newBBoxHeight);
			
			//check if view BBox is not outside extent BBox
	        if(viewBBox.y < m_extentBBox.yMin)
	        	viewBBox.offset(0, -viewBBox.y + m_extentBBox.yMin);
	        if(viewBBox.bottom > m_extentBBox.yMax)
	        	viewBBox.offset(0, -viewBBox.bottom + m_extentBBox.yMax);
			
			if (!isCRSWrappingOverXAxis())
			{
		        if(viewBBox.x < m_extentBBox.xMin)
		        	viewBBox.offset(-viewBBox.x + m_extentBBox.xMin, 0);
		        if(viewBBox.right > m_extentBBox.xMax)
		        	viewBBox.offset(-viewBBox.right + m_extentBBox.xMax, 0);
			}
			
	        var newBBox: BBox = BBox.fromRectangle(viewBBox);
			
			/*
//	        if(!m_viewBBox.equals(newBBox)) {
		        m_viewBBox = newBBox;
	        	signalAreaChanged(b_finalChange);
//	        }
			*/
			
			if (b_negotiateBBox)
				negotiateBBox(newBBox, b_finalChange, b_changeZoom);
			else
				setViewBBoxAfterNegotiation(newBBox, b_finalChange);

				
				
			} else {
				//auto layout in widget parent
				autoLayoutViewBBox(bbox, b_finalChange, true);
			}
			

        }
		
		private var _oldWidgetWidth: Number = 0;
		private var _oldWidgetHeight: Number = 0;
		
		private function autoLayoutViewBBox(bbox: BBox, b_finalChange:Boolean, b_setViewBBox: Boolean = false): void
		{
			trace("autoLayoutViewBBox: " + bbox.toBBOXString() + " b_finalChange: " + b_finalChange);
			//auto layout in widget parent
				var widgetParent: Group = parent as Group; 
				if (widgetParent)
				{
				var f_bboxApect: Number = bbox.width / bbox.height;
				
					var parentWidth: Number = widgetParent.width;
					var parentHeight: Number = widgetParent.height;
					var f_parentAspect: Number = parentWidth / parentHeight;
					
					var widgetXPosition: Number = 0;
					var widgetYPosition: Number = 0;
					var widgetWidth: Number = parentWidth;
					var widgetHeight: Number = parentHeight;
					
					if(f_bboxApect < f_parentAspect) {
						// extent looks wider 
						widgetWidth = widgetHeight * f_bboxApect;
						widgetXPosition = (parentWidth - widgetWidth) / 2;
					}
					else {
						// extent looks higher
						widgetHeight = widgetWidth / f_bboxApect;
						widgetYPosition = (parentHeight - widgetHeight) / 2;
					}
					
				//check if change in width and height is higher than 1px
				var widthDiff: Number = Math.abs(_oldWidgetWidth - widgetWidth);
				var heightDiff: Number = Math.abs(_oldWidgetHeight - widgetHeight);
				
				if (widgetWidth > 1 || widgetHeight > 1)
				{
					this.width = widgetWidth;
					this.height = widgetHeight;
					this.x = widgetXPosition;
					this.y = widgetYPosition;
					
					_oldWidgetWidth = widgetWidth;
					_oldWidgetHeight = widgetHeight;
					
					if (b_setViewBBox)
					setViewBBoxAfterNegotiation(bbox, b_finalChange);
				} else {
					trace("InteractiveWidget setViewBBox is too small: " + widthDiff + " , " + heightDiff);
				}
			}
        }
		
		
		private function negotiateBBox(newBBox: BBox, b_finalChange: Boolean, b_changeZoom: Boolean = true): void
		{
//			trace("\n *****************************************************************************");
//			trace("\t IWidget negotiateBBox newBBox at startup: :" + newBBox.toLaLoString(ms_crs));
//			trace("\t IWidget negotiateBBox newBBox at startup: :" + newBBox);
			var latestBBox: BBox;
			for(var i: int = 0; i < m_layerContainer.numChildren; ++i) {
				
				var l: InteractiveLayer = InteractiveLayer(m_layerContainer.getChildAt(i));
				
				latestBBox = l.negotiateBBox(newBBox, b_changeZoom);
				if (!latestBBox.equals(newBBox))
				{
					trace("WARNING: bbox changed by layer " + l.layerName);
				}
				newBBox = latestBBox;
//				if (newBBox) {
//					trace("\t\t IWidget negotiateBBox newBBox :" + newBBox.toLaLoString(ms_crs));
//					trace("\t\t IWidget negotiateBBox newBBox :" + newBBox);
//				} else 
//					trace("\t\t IWidget negotiateBBox newBBox IS NULL");
					
			}
//			trace("IWidget negotiateBBox newBBox at end: :" + newBBox.toLaLoString(ms_crs));
//			trace("IWidget negotiateBBox newBBox at end: :" + newBBox);
			
			setViewBBoxAfterNegotiation(newBBox, b_finalChange);
//			trace("*****************************************************************************\n");
		}
		
		
		private function setViewBBoxAfterNegotiation(newBBox: BBox, b_finalChange: Boolean): void
		{
			//dispath view bbox changed event to notify about change
			
			m_viewBBox = newBBox;
			
			dispatchEvent(new Event(VIEW_BBOX_CHANGED));
			
			signalAreaChanged(b_finalChange);
		}
		

	public function setExtentBBOX(bbox: BBox, b_finalChange: Boolean = true): void
	{
		m_extentBBox = bbox;
		setViewBBox(m_extentBBox, b_finalChange); // this calls signalAreaChanged()
	}
	
	public function setExtentBBOXRaw(xmin: Number, ymin: Number, xmax: Number, ymax: Number, b_finalChange: Boolean = true): void
	{
		setExtentBBOX(new BBox(xmin, ymin, xmax, ymax), b_finalChange);
	}
	
	public function setViewFullExtent(): void
	{
		setViewBBox(m_extentBBox, true);
	}
	
	public function getExtentBBox(): BBox
	{
		return m_extentBBox;
	}
	
	public function getViewBBox(): BBox
	{ return m_viewBBox; }
	
	public function invalidate(): void
	{
		signalAreaChanged(true);
	}

	// getters & setters
	
	[Bindable(event = "crsChanged")]
	public function get crs(): String
	{ return getCRS(); }
	
	[Bindable(event = "crsChanged")]
	public function set srs(s_crs: String): void
	{ return setCRS(s_crs, true); }
		
	public function set backgroundChessBoard(b: Boolean): void
	{
		mb_backgroundChessBoard = b;
		invalidateDisplayList();			
	}

	public function get layerContainer(): Container
	{
		return m_layerContainer;
	}
	
	public function get labelLayout(): AnticollisionLayout
	{ return m_labelLayout; }

	override public function toString(): String
	{
		return "InteractiveWidget ";
	}
	
	private var mb_autoLayoutChanged: Boolean;
	public function set autoLayoutInParent(value: Boolean): void
	{ 
		mb_autoLayout = value; 
		mb_autoLayoutChanged = true;
		invalidateProperties();
	}
	
	public function get autoLayoutInParent(): Boolean
	{ return mb_autoLayout; }
	}
}