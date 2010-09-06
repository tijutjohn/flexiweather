package com.iblsoft.flexiweather.widgets
{
	import com.iblsoft.flexiweather.events.InteractiveLayerEvent;
	import com.iblsoft.flexiweather.ogc.InteractiveLayerWMS;
	
	import flash.display.Graphics;
	import flash.geom.Rectangle;
	import flash.utils.Dictionary;
	
	import mx.collections.ArrayCollection;
	import mx.containers.Canvas;
	
	[Style(name="horizontalGap", type="Number", format="Length", inherit="no")]
	
	[Style(name="verticalGap", type="Number", format="Length", inherit="no")]
	
	[Style(name="labelAlign", type="String", enumeration="left,center,right", inherit="no")]
	
	[Style(name="horizontalAlign", type="String", enumeration="left,center,right", inherit="no")]
	
	[Style(name="horizontalDirection", type="String", enumeration="none,left,right", inherit="no")]
		
	[Style(name="verticalAlign", type="String", enumeration="bottom,middle,top", inherit="no")]
	
	[Style(name="verticalDirection", type="String", enumeration="none,down,up", inherit="no")]
	
	[Style(name="legendsBackgroundColor", type="uint", format="Color", inherit="no")]
	
	[Style(name="legendsBackgroundAlpha", type="Number", format="Length", inherit="no")]
	
	[Style(name="legendsBackgroundPadding", type="uint", format="Color", inherit="no")]
	
	/**
	 *  Number of pixels between the container's bottom border
	 *  and the bottom of its content area.
	 *  The default value is 0.
	 */
	[Style(name="paddingBottom", type="Number", format="Length", inherit="no")]
	
	/**
	 *  Number of pixels between the container's top border
	 *  and the top of its content area.
	 *  The default value is 0.
	 */
	[Style(name="paddingTop", type="Number", format="Length", inherit="no")]
	
	/**
	 *  Number of pixels between the container's left border
	 *  and the left of its content area.
	 *  The default value is 0.
	 */
	[Style(name="paddingLeft", type="Number", format="Length", inherit="no")]
	
	/**
	 *  Number of pixels between the container's right border
	 *  and the right of its content area.
	 *  The default value is 0.
	 */
	[Style(name="paddingRight", type="Number", format="Length", inherit="no")]

	
	public class InteractiveLayerLegends extends InteractiveLayer
	{
		
		internal var m_layers: ArrayCollection = new ArrayCollection();
		
		private var _legendsToBeRendered: int;
		public function get legendsToBeRendered(): int
		{
			return _legendsToBeRendered;
		}
		public function set legendsToBeRendered(value: int): void
		{
			_legendsToBeRendered = value;
			trace("_legendsToBeRendered = " + _legendsToBeRendered);
		}
		
		private var legendsBkgRectangle: Rectangle;
		private var _currentRectangle: Rectangle;
		
		public function InteractiveLayerLegends(container:InteractiveWidget = null)
		{
			super(container);
			
			mouseChildren = true;
			mouseEnabled = true;
		}
		
		public function addLayer(l: InteractiveLayer): void
		{
			m_layers.addItemAt(l, 0);
		}
		
		public function removeLayer(l: InteractiveLayer): void
		{
			var i : int = m_layers.getItemIndex(l);
			if(i >= 0) {
//				unbindSubLayer(l);
				m_layers.removeItemAt(i);
				l.removeLegend(getCanvasFromDictionary(l));
			}
		}
		
		override public function refresh(b_force:Boolean):void
		{
			super.refresh(b_force);
			
//			debug("Legends refresh");
		}
		override public function draw(graphics:Graphics):void
		{
			super.draw(graphics);
			
			//drawLegendsBackground(legendsBkgRectangle);
		}
		
		override public function onAreaChanged(b_finalChange:Boolean):void
		{
			super.onAreaChanged(b_finalChange);
			
//			debug("Legends onAreaChanged");
		}
		override public function onContainerSizeChanged():void
		{
			super.onContainerSizeChanged();
			
//			debug("Legends onContainerSizeChanged");
			
			renderLegendsStack();
		}
		
		public function removeAllLayers(): void
		{
//			for each(var l: InteractiveLayer in m_layers)
//				unbindSubLayer(l);
			m_layers.removeAll();
		}
		
		private function  repositionedLegends(): void
		{
			renderLegendsStack(true);
			debug("repositionedLegends: " + legendsBkgRectangle);	
			
			var ile: InteractiveLayerEvent = new InteractiveLayerEvent( InteractiveLayerEvent.LEGENDS_AREA_UPDATED);
			ile.area = legendsBkgRectangle;
			dispatchEvent(ile);
		}
		
		private var m_canvasDictionary: Dictionary = new Dictionary();
		private function addCanvasToDictionary(cnv: Canvas, layer: InteractiveLayer): void
		{
			if (!cnv)
			{
				trace("addCanvasToDictionary cnv IS NULL ");
			}
			trace("\t\t InteractiveLayerLegends addCanvasToDictionary ["+layer.name+"/"+layer+"]: " + cnv);
			m_canvasDictionary[layer] = cnv;
		}
		private function getCanvasFromDictionary(layer: InteractiveLayer): Canvas
		{
			var cnv: Canvas = m_canvasDictionary[layer];
			trace("\t\t InteractiveLayerLegends getCanvasFromDictionary ["+layer.name+"/"+layer+"]: " + cnv);
			return cnv;
		}
		public function clear(): void
		{
			graphics.clear();
		}
		/**
		 * Load legends and do not layout them 
		 * @return How many legends needs to be loaded
		 * 
		 */		
		private function loadLegends(): int
		{
			debug("loadLegends");
			legendsToBeRendered = 0;
			var l: InteractiveLayer;
			
			var canvas: Canvas;
			
			//find total count of layers for which legend should be rendered
			var _tempCanvases: Array = [];
			for each (l in m_layers)
			{
				
				if (l.hasLegend() && l.visible)
				{
					canvas = getCanvasFromDictionary(l);
							
					legendsToBeRendered++;
					if (canvas)
					{
						_tempCanvases.push(canvas);
					}
				}
			}
			
			if (_tempCanvases.length)
			{
				while (_tempCanvases.length > 0)
				{
					canvas = _tempCanvases.shift();
					onLegendRendered(canvas);
				}
			}
			
			if (legendsToBeRendered == 0)
				return legendsToBeRendered;
				
			for each (l in m_layers)
			{
				if (l.hasLegend() && l.visible)
				{
					canvas = getCanvasFromDictionary(l);
					if (!canvas)
					{
						canvas = new Canvas();
						addChild(canvas);
						canvas.visible = false;
						
						addCanvasToDictionary(canvas, l);
						
						debug("InteractieLayerLegends loadLegends renderLegend => LOAD");
						l.renderLegend(canvas, onLegendRendered, getStyle('labelAlign'));
					}
				}
				
			}
			
			return legendsToBeRendered;
		}
		
		private function checkIfAllLegendsAreLoaded(): Boolean
		{
			
			var needLoading: Boolean;
			
			var l: InteractiveLayer;
			var canvas: Canvas;
			
			for each (l in m_layers)
			{
				if (l.hasLegend() && l.visible)
				{
					canvas = getCanvasFromDictionary(l);
					if (!canvas)
					{
						//it needs to be loaded
						needLoading = true;
					}		
				}
			}
			debug("InteractieLayerLegends checkIfAllLegendsAreLoaded needLoading: " + needLoading);
			return needLoading;
		}
		/**
		 * This function render all legens. If legends are not loaded, it loads them first. There can be problem that legend do not need to have set size, so there is problem
		 * with finding correct bounding box. That's why this function is also used for repositioned legends after load. In that case parameter justReposition needs to be set to "true"  
		 * @param justReposition - set to true if you want just reposition legends without loading
		 * 
		 */		
		public function renderLegendsStack(justReposition: Boolean = false): void
		{
			debug("\n\n******************************");
			debug("******************************");
			debug("\trenderLegendsStack justReposition = " + justReposition);
			
			if (checkIfAllLegendsAreLoaded())
			{
				loadLegends();
				return;
			}
			
			if (!justReposition)
			{
				var needsLoaded: int = loadLegends();
				if (needsLoaded > 0)
					return;	
			}
			
			var l: InteractiveLayerWMS;
			
			var posX: int = 0;
			var posY: int = 0;
			
			var maxWidth: int = width;
			var maxHeight: int = height;
			
			var paddingLeft: int = getStyle('paddingLeft');
			var paddingRight: int = getStyle('paddingRight');
			var paddingTop: int = getStyle('paddingTop');
			var paddingBottom: int = getStyle('paddingBottom');
			
			var horizontalAlign: String = getStyle('horizontalAlign');
			var verticalAlign: String = getStyle('verticalAlign');
			var horizontalDirection: String = getStyle('horizontalDirection');
			var verticalDirection: String = getStyle('verticalDirection');
			
			var hAlign: String = horizontalAlign;
			var vAlign: String = verticalAlign;
			var directionX: int = 0;
			var directionY: int = 0;
			
			if ( horizontalDirection == 'left') {
				directionX = -1;
			} else {
				if ( horizontalDirection == 'right') {
					directionX = 1;
				}
			}
			if ( verticalDirection == 'up') {
				directionY = -1;
			} else {
				if ( verticalDirection == 'down') {
					directionY = 1;
				}
			}
					
					
			switch (hAlign)
			{
				case 'left':
					posX = paddingLeft;
					break;
				case 'center':
					posX = maxWidth/2;
					break;
				case 'right':
					posX = maxWidth - paddingRight;
					break;
			}
			switch (vAlign)
			{
				case 'top':
					posY = paddingTop;
					break;
				case 'middle':
					posY = maxHeight/2;
					break;
				case 'bottom':
					posY = maxHeight - paddingBottom;
					break;
			}
			
			var initialX: int = posX;
			var initialY: int = posY;
			
			var startX: int = posX;
			var startY: int = posY;
			var endX: int = posX;
			var endY: int = posY;
			var startX2: int = posX;
			var startY2: int = posY;
			var endX2: int = posX;
			var endY2: int = posY;
			
			var rowItems: int = 0;
			var colItems: int = 0;
			
			var initialReposition: Boolean = false;
			
			debug("\n\nLEGENDS graphics clear");
			graphics.clear();
			
			legendsBkgRectangle = new Rectangle();
			_currentRectangle = new Rectangle();
				
			var gapX: int = 10;
			var gapY: int = 10;
			if (getStyle('horizontalGap'))
			{
				gapX = getStyle('horizontalGap');
			}
			if (getStyle('verticalGap'))
			{
				gapY = getStyle('verticalGap');
			}
				
			var debugPos: Boolean = false;
			
			for each (l in m_layers)
			{
				if (l.hasLegend())
				{
					var canvas: Canvas = getCanvasFromDictionary(l);
					if (canvas)
						canvas.visible = l.visible;
					else
						continue;
						
					if (debugPos)
						debug("LEGENDS layer visible: " + l.visible);
					if (l.visible)
					{
						var rect: Rectangle
						rect = new Rectangle(0,0, canvas.width, canvas.height);
						
						if (debugPos)
							debug("\n LAYER " + l.name + " rect: " + rect + " \n")
						//check if there is place for this legend
						if ( horizontalDirection != 'none') 
						{
							var newMaxWidth: int = (maxWidth - paddingRight - paddingLeft);
							var nextWidth: Number = legendsBkgRectangle.width + rect.width + gapX;
							if (debugPos)
								debug("\t nextWidth: " + nextWidth + " rowItems: " + rowItems + " newMaxWidth: " + newMaxWidth);
							if (nextWidth > newMaxWidth && newMaxWidth > 0 && rowItems > 0)
							{
								if (debugPos)
									debug("\t\tIt'w wider than width, make new row");
								initialReposition = true;
								startX2 = initialX;
								endX2 = initialX;
								posX = initialX;
								if ( verticalAlign == 'top')
									posY = legendsBkgRectangle.height + paddingTop + gapY;
								else {
									if ( verticalAlign == 'bottom' )
										posY = maxHeight - legendsBkgRectangle.height - paddingBottom - gapY;
								}
								rowItems = 0;
							} 
						} 
	
						if ( verticalDirection != 'none') 
						{
							var newMaxHeight: int = (maxHeight - paddingTop - paddingBottom);
							var nextHeight: Number = legendsBkgRectangle.height +  rect.height + gapY;
							if (debugPos)
								debug("\t nextHeight: " + nextHeight + " colItems: " + colItems + " newMaxHeight: " + newMaxHeight);
							if (nextHeight > newMaxHeight && newMaxHeight > 0 && colItems > 0)
							{
								if (debugPos)
									debug("\t\tIt's higher than height, make new column");
								initialReposition = true;
								posY = initialY;
								startY2 = initialY;
								endY2 = initialY;
								if ( horizontalAlign == 'left')
									posX = legendsBkgRectangle.width + paddingLeft + gapX;
								else {
									if ( horizontalAlign == 'right' )
										posX = maxWidth - legendsBkgRectangle.width - paddingLeft - gapX;
								}
								colItems = 0;
							} 
						} 
						
						if (directionX != 0)
							rowItems++;
						if (directionY != 0)
							colItems++;
							
						if (debugPos)
							debug("\n\tposX: " + posX + " posY: " + posY);
						
						
						if (directionX == -1 || horizontalAlign == 'right')
							canvas.x = posX - rect.width;
						if (directionX == 1|| horizontalAlign == 'left')
							canvas.x = posX;
						if (directionY == -1 || verticalAlign == 'bottom')
							canvas.y = posY - rect.height;
						if (directionY == 1 || verticalAlign == 'top')
							canvas.y = posY;
						
						posX += directionX * (rect.width + gapX);
						posY += directionY * (rect.height + gapY);
						
						if (debugPos)
							debug("\n\tnew posX: " + posX + " posY: " + posY);
						
						startX = Math.min(startX, canvas.x);
						startY = Math.min(startY, canvas.y);
						endX = Math.max(endX, canvas.x+ rect.width);
						endY = Math.max(endY, canvas.y + rect.height);
						
						if (debugPos)
						{
							debug("\t\trect: " + rect);
							debug("\t\tcanvas: ["+canvas.x+","+canvas.y+"] size: ["+canvas.width+","+canvas.height+"]");
							debug("\t\tstartX: " + startX + " startY: " + startY + " endX: " + endX + " endY: " + endY);
							debug("\tLegends: ["+maxWidth+","+maxHeight+"]");
						}
						
						drawLegendsBackground(new Rectangle(canvas.x, canvas.y, canvas.width, canvas.height));
						
						legendsBkgRectangle.width = Math.abs(endX - startX);// + paddingLeft + paddingRight;
						legendsBkgRectangle.height = Math.abs(endY - startY);// + paddingTop + paddingBottom;
						
						_currentRectangle = legendsBkgRectangle;
						if (directionX != 0)
						{
							endX2 = Math.max(endX2, canvas.x + rect.width);
							startX2  = Math.min(startX2, canvas.x);
							_currentRectangle.width = Math.abs(endX2 - startX2);// + paddingLeft + paddingRight;
						} else {
							if (directionY != 0)
							{
								startY2 = Math.min(startY2, canvas.y);
								endY2 = Math.max(endY2, canvas.y + rect.height);
								_currentRectangle.height = Math.abs(endY2 - startY2);// + paddingTop + paddingBottom;
							}
						}
						
						if (debugPos)
						{
							debug("\t\tlegendsBkgRectangle: " + legendsBkgRectangle);
							debug("\t\t_currentRectangle: " + _currentRectangle);
						}
					}
				}
			}
			//draw(graphics);
			debug("******************************\n\n");
		}
		
		private function drawLegendsBackground(rect: Rectangle): void
		{
			
			if (getStyle('legendsBackgroundColor'))
			{
				var bkgClr: uint = 0xff0000;
				var bkgAlpha: Number = 1;
				var bkgPadding: int = 0;
						
				if (getStyle('legendsBackgroundColor'))
					bkgClr = getStyle('legendsBackgroundColor');
				if (getStyle('legendsBackgroundAlpha'))
					bkgAlpha = getStyle('legendsBackgroundAlpha');
				if (getStyle('legendsBackgroundPadding'))
					bkgPadding = getStyle('legendsBackgroundPadding');
					
				var gr: Graphics = graphics;
				gr.beginFill(bkgClr, bkgAlpha);
				gr.drawRect(rect.x - bkgPadding, rect.y - bkgPadding, rect.width + bkgPadding * 2, rect.height + bkgPadding * 2);
				gr.endFill();
				
//				debug("drawLegendsBackground "+bkgClr+", "+bkgAlpha);
//				debug("drawLegendsBackground "+width+", "+height);
//				debug("drawLegendsBackground "+(rect.x - bkgPadding)+", "+(rect.y - bkgPadding)+", "+(rect.width + bkgPadding)+", "+(rect.height + bkgPadding));
			}
		}
		private function onLegendRendered(cnv: Canvas): void
		{
			legendsToBeRendered--;
			
			debug("\n\nonLegendRendered  legendsToBeRendered: " +legendsToBeRendered + " canvas: " + cnv.width + ", " + cnv.height + " Position: " + cnv.x + " , " + cnv.y);
			if (legendsToBeRendered < 1)
			{
				debug("ALL LEGENDS ARE LOADED");
				repositionedLegends();
			}
		}
		
		override protected function updateDisplayList(unscaledWidth: Number, unscaledHeight: Number): void
		{
//			graphics.clear();
//			draw(graphics);
		}
		
		private function debug(str: String): void
		{
			return;
			trace(str);
		}
	}
}