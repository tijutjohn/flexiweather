package com.iblsoft.flexiweather.widgets
{
	import com.iblsoft.flexiweather.ogc.BBox;
	import com.iblsoft.flexiweather.proj.Coord;
	import com.iblsoft.flexiweather.proj.Projection;
	
	import flash.display.DisplayObject;
	import flash.display.GradientType;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import mx.core.Container;
	import mx.events.ResizeEvent;
	import mx.events.FlexEvent;

	public class InteractiveWidget extends Container
	{
        private var ms_crs: String = "EPSG:4326";
        private var m_viewBBox: BBox = new BBox(-180, -90, 180, 90);
        private var m_extentBBox: BBox = new BBox(-180, -90, 180, 90);
        private var mb_orderingLayers: Boolean = false;

		public function InteractiveWidget() {
			super();
			
			mouseEnabled = true;
			mouseFocusEnabled = true;
			doubleClickEnabled = true;
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
			InteractiveLayer(child).container = this;
			child.x = x;
			child.y = y;
			child.width = width;
			child.height = height;
			var o: DisplayObject = super.addChild(child);
			orderLayers();
			return o;
		}
		
		public override function addChildAt(child: DisplayObject, index: int): DisplayObject
		{
			var o: DisplayObject = super.addChildAt(child, index);
			orderLayers();
			return o;
		}

		public function addLayer(l: InteractiveLayer, index: int = -1): void
		{
			//trace("InteractiveWidget.addLayer(): pos: " + index);
			if (index >= 0)
				addChildAt(l, index);
			else
				addChild(l);
			orderLayers();
		}

		public function removeLayer(l: InteractiveLayer): void
		{
			if(contains(l))
				removeChild(l);
		}
		
		public function removeAllLayers(): void
		{
			removeAllChildren();
		}
		
		public function orderLayers(): void
		{
			if(mb_orderingLayers)
				return;
			mb_orderingLayers = true;
			try {
				// stable-sort interactive layers in ma_layers according to their zOrder property
				for(var i: int = 0; i < numChildren; ++i) {
					var ilI: InteractiveLayer = InteractiveLayer(getChildAt(i)); 
					for(var j: int = i + 1; j < numChildren; ++j) {
						var ilJ: InteractiveLayer = InteractiveLayer(getChildAt(j));
						if(ilJ.zOrder < ilI.zOrder) {
							// swap Ith and Jth layer, we know that J > I
							removeChildAt(j);
							removeChildAt(i);
							addChildAt(ilJ, i);
							addChildAt(ilI, j);
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
            /*for(var i: int = 0; i < _layers.length; ++i) {
            	var l: InteractiveLayer = InteractiveLayer(_layers[i]);
            	if(l.isDynamicPartInvalid())
            		l.draw(l.graphics); 
            }*/
            graphics.clear();
            var matrix: Matrix = new Matrix();
            matrix.rotate(90);
            graphics.beginGradientFill(GradientType.LINEAR, [0xAAAAAA, 0xFFFFFF], [1, 1], [0, 255], matrix);
            graphics.drawRect(0, 0, width, height);
            graphics.endFill();
            super.updateDisplayList(unscaledWidth, unscaledHeight);
            /*for(var i: int = 0; i < _layers.length; ++i) {
            	var l: InteractiveLayer = InteractiveLayer(_layers[i]);
            	if(!l.visible)
            		continue;
            	l.draw(graphics); 
            }*/
        }

		protected function signalAreaChanged(b_finalChange: Boolean): void
		{
			onAreaChanged(b_finalChange);
		}

        protected function onAreaChanged(b_finalChange: Boolean): void
        {
            for(var i: int = 0; i < numChildren; ++i) {
            	var l: InteractiveLayer = InteractiveLayer(getChildAt(i));
            	if(l.onAreaChanged(b_finalChange))
            		break;
            	if(!l.isDynamicPartInvalid())
            		l.invalidateDynamicPart();
            }
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
            for(var i: int = numChildren - 1; i >= 0; --i) {
            	var l: InteractiveLayer = InteractiveLayer(getChildAt(i));
            	if(!l.enabled)
            		continue;
            	if(l.onMouseDown(event))
            		break; 
            }
        }

        protected function onMouseUp(event: MouseEvent): void
        {
            for(var i: int = numChildren - 1; i >= 0; --i) {
            	var l: InteractiveLayer = InteractiveLayer(getChildAt(i));
            	if(!l.enabled)
            		continue;
            	if(l.onMouseUp(event))
            		break; 
            }
        }

        protected function onMouseMove(event: MouseEvent): void
        {
            for(var i: int = numChildren - 1; i >= 0; --i) {
            	var l: InteractiveLayer = InteractiveLayer(getChildAt(i));
            	if(!l.enabled)
            		continue;
            	if(l.onMouseMove(event))
            		break; 
            }
        }

        protected function onMouseWheel(event: MouseEvent): void
        {
            for(var i: int = numChildren - 1; i >= 0; --i) {
            	var l: InteractiveLayer = InteractiveLayer(getChildAt(i));
            	if(!l.enabled)
            		continue;
            	if(l.onMouseWheel(event))
            		break; 
            }
        }
        
        protected function onMouseClick(event: MouseEvent): void
        {
            for(var i: int = numChildren - 1; i >= 0; --i) {
            	var l: InteractiveLayer = InteractiveLayer(getChildAt(i));
            	if(!l.enabled)
            		continue;
            	if(l.onMouseClick(event))
            		break; 
            }
        }

        protected function onMouseDoubleClick(event: MouseEvent): void
        {
            for(var i: int = numChildren - 1; i >= 0; --i) {
            	var l: InteractiveLayer = InteractiveLayer(getChildAt(i));
            	if(!l.enabled)
            		continue;
            	if(l.onMouseDoubleClick(event))
            		break; 
            }
        }

        protected function onMouseRollOver(event: MouseEvent): void
        {
            for(var i: int = numChildren - 1; i >= 0; --i) {
            	var l: InteractiveLayer = InteractiveLayer(getChildAt(i));
            	if(!l.enabled)
            		continue;
            	if(l.onMouseRollOver(event))
            		break; 
            }
        }

        protected function onMouseRollOut(event: MouseEvent): void
        {
            for(var i: int = numChildren - 1; i >= 0; --i) {
            	var l: InteractiveLayer = InteractiveLayer(getChildAt(i));
            	if(!l.enabled)
            		continue;
            	if(l.onMouseRollOut(event))
            		break; 
            }
        }
        
        protected function onResized(Event: ResizeEvent): void
        {
        	setViewBBox(m_viewBBox, true); // set the view bbox to update the aspects 
            for(var i: int = 0; i < numChildren; ++i) {
            	var l: InteractiveLayer = InteractiveLayer(getChildAt(i));
            	l.width = width;
            	l.height = height;
            	l.onContainerSizeChanged();
            	if(!l.isDynamicPartInvalid())
            		l.invalidateDynamicPart();
            }
            scrollRect = new Rectangle(0, 0, width, height);
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
        
        // getters & setters

		[Bindable(event = "crsChanged")]
        public function get crs(): String
        { return getCRS(); }

		[Bindable(event = "crsChanged")]
        public function set srs(s_crs: String): void
        { return setCRS(s_crs, true); }
	}
}