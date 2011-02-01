package com.iblsoft.flexiweather.widgets
{
	import com.iblsoft.flexiweather.ogc.BBox;
	import com.iblsoft.flexiweather.ogc.cache.TileAreaCache;
	import com.iblsoft.flexiweather.ogc.tiling.InteractiveLayerWMSWithQTT;
	import com.iblsoft.flexiweather.ogc.tiling.TileIndex;
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
	import flash.utils.Timer;
	
	import mx.core.Container;
	import mx.events.ResizeEvent;

	public class InteractiveWidget extends Container
	{
        private var ms_crs: String = "EPSG:4326";
        private var m_viewBBox: BBox = new BBox(-180, -90, 180, 90);
        private var m_extentBBox: BBox = new BBox(-180, -90, 180, 90);
        private var mb_orderingLayers: Boolean = false;

		private var mb_backgroundChessBoard: Boolean = false;

		private var m_resizeTimer: Timer;
		
		private var m_layerContainer: Container = new Container();

		private var m_labelLayout: AnticollisionLayout = new AnticollisionLayout();
		
		private var m_tileAreaCache: TileAreaCache = new TileAreaCache();

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
		}
		
		public override function addChild(child: DisplayObject): DisplayObject
		{
			if(child is InteractiveLayer) {
				// InteractiveLayer based child are added to m_layerContainer
				InteractiveLayer(child).container = this; // this also ensures that child is InteractiveLayer
				child.x = x;
				child.y = y;
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

		public function addLayer(l: InteractiveLayer, index: int = -1): void
		{
			if (index >= 0)
				addChildAt(l, index);
			else
				addChild(l);
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
							//trace('[InteractiveWidget.orderLayers] ... swapping ' + ilJ.name + ' with ' + ilI.name);
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
				trace("InteractiveWidget view BBOX is not changed");
				return;
			}
			
			m_tileAreaCache.clearCache();
			
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
        
        public function getQTLayer(name: String = ''): InteractiveLayerWMSWithQTT
        {
        	var layer: InteractiveLayerWMSWithQTT;
        	var total: int = layerContainer.numChildren;
        	for (var i: int = 0; i < total; i++)
        	{
        		var currLayer: InteractiveLayer = layerContainer.getChildAt(i) as InteractiveLayer;
        		if (currLayer is InteractiveLayerWMSWithQTT)
        		{
        			layer = currLayer as InteractiveLayerWMSWithQTT;
        			if (name == '' || name == layer.name)
        				break;
        		}
        	}
        	
        	if (layer)
			{
				return layer;
			}
			return null;
        }
        public function tilesScale(): Point
        {
        	var layer: InteractiveLayerWMSWithQTT = getQTLayer();
        	
        	if (layer)
			{
				return new Point(int(100*layer.tileLayer.tileScaleX)/100, int(100 * layer.tileLayer.tileScaleY)/100);
			}        	
        	return null;
        }
        
        public function pointToTileIndex(x: Number, y: Number): TileIndex
        {
        	var layer: InteractiveLayerWMSWithQTT = getQTLayer();
        	
        	if (layer)
			{
				var coord: Coord = pointToCoord(x,y);
				return layer.tileLayer.tilingUtils.getTileIndexForPosition(coord.x, coord.y, layer.tileLayer.layerZoom);
			}        	
        	return null;
        }
        
        public function pointToCoord(x: Number, y: Number): Coord
        {
        	return new Coord(
	        		ms_crs,
	        		x * m_viewBBox.width / (width - 1) + m_viewBBox.xMin,
	        		(height - 1 - y) * m_viewBBox.height / (height - 1) + m_viewBBox.yMin)
        }

        public function coordToPoint(c: Coord): Point
        {
        	if(Projection.equalCRSs(c.crs, ms_crs)) {
        		return new Point(
        				(c.x - m_viewBBox.xMin) * (width - 1) / m_viewBBox.width,
        				height - 1 - (c.y - m_viewBBox.yMin) * (height - 1) / m_viewBBox.height);
        	}
        	else
        		return null; // TODO: implement reprojection somehow
        	return new Coord(
        		x * m_viewBBox.width / (width - 1) + m_viewBBox.xMin,
        		(height - 1 - y) * m_viewBBox.height / (height - 1) + m_viewBBox.yMin)
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
        	setViewBBox(m_viewBBox, true); // set the view bbox to update the aspects 
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
	        	signalAreaChanged(b_finalChange);
	        	dispatchEvent(new Event("crsChanged"));
        	}
        }
        
        public function setViewBBoxRaw(xmin: Number, ymin: Number, xmax: Number, ymax: Number, b_finalChange: Boolean): void
        {
        	setViewBBox(new BBox(xmin, ymin, xmax, ymax), b_finalChange);
        }

        public function setViewBBox(bbox: BBox, b_finalChange: Boolean): void
        {
        	// aspect is the bigger the bbox is wider than higher
        	
        	// this is the aspect ratio we want to maintain
        	var f_extentAspect: Number = 1; //m_extentBBox.width / m_extentBBox.height;
        	
        	var f_bboxCenterX: Number = bbox.xMin + bbox.width / 2.0; 
        	var f_bboxCenterY: Number = bbox.yMin + bbox.height / 2.0;
        	
        	// this is the aspect ratio of currently requeste bbox
        	var f_bboxApect: Number = bbox.width / bbox.height;
        	var f_componentApect: Number = width / height;

        	var f_newBBoxWidth: Number;
        	var f_newBBoxHeight: Number;
        	
        	if(f_bboxApect < f_extentAspect) {
        		// extent looks wider 
        		f_newBBoxWidth = f_componentApect * f_extentAspect * bbox.height;
        		f_newBBoxHeight = bbox.height;
        	}
        	else {
        		// extent looks higher
        		f_newBBoxWidth =  bbox.width;
        		f_newBBoxHeight = bbox.width / f_extentAspect / f_componentApect;
        	}
        	
        	if(f_newBBoxHeight > m_extentBBox.height) {
        		f_newBBoxHeight = m_extentBBox.height;
        		f_newBBoxWidth = f_componentApect * f_extentAspect * f_newBBoxHeight;
        	}
        	if(f_newBBoxWidth > m_extentBBox.width) {
        		f_newBBoxWidth = m_extentBBox.width;
        		f_newBBoxHeight = f_newBBoxWidth / f_componentApect / f_extentAspect;
        	}
        	var viewBBox: Rectangle = new Rectangle(
	        		f_bboxCenterX - f_newBBoxWidth / 2.0,
	        		f_bboxCenterY - f_newBBoxHeight / 2.0,
	        		f_newBBoxWidth,
	        		f_newBBoxHeight);
	        if(viewBBox.x < m_extentBBox.xMin)
	        	viewBBox.offset(-viewBBox.x + m_extentBBox.xMin, 0);
	        if(viewBBox.y < m_extentBBox.yMin)
	        	viewBBox.offset(0, -viewBBox.y + m_extentBBox.yMin);
	        if(viewBBox.right > m_extentBBox.xMax)
	        	viewBBox.offset(-viewBBox.right + m_extentBBox.xMax, 0);
	        if(viewBBox.bottom > m_extentBBox.yMax)
	        	viewBBox.offset(0, -viewBBox.bottom + m_extentBBox.yMax);

	        var newBBox: BBox = BBox.fromRectangle(viewBBox);
//	        if(!m_viewBBox.equals(newBBox)) {
		        m_viewBBox = newBBox;
	        	signalAreaChanged(b_finalChange);
//	        }
        }

        public function setExtentBBOX(bbox: BBox): void
        {
        	m_extentBBox = bbox;
        	setViewBBox(m_extentBBox, true); // this calls signalAreaChanged()
        }

        public function setExtentBBOXRaw(xmin: Number, ymin: Number, xmax: Number, ymax: Number): void
        {
        	setExtentBBOX(new BBox(xmin, ymin, xmax, ymax));
        }
        
        public function setViewFullExtent(): void
        {
        	setViewBBox(m_extentBBox, true);
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
		
		public function get tileAreaCache(): TileAreaCache
		{
			return m_tileAreaCache;
		}
		
	}
}