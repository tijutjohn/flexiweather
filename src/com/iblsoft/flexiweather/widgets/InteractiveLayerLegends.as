package com.iblsoft.flexiweather.widgets
{
	import com.iblsoft.flexiweather.events.InteractiveLayerEvent;
	
	import flash.display.Graphics;
	import flash.geom.Rectangle;
	
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
		
		private var _legendsToBeRendered: uint;
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
				l.removeLegend();
			}
		}
		
		override public function refresh(b_force:Boolean):void
		{
			super.refresh(b_force);
			
//			trace("Legends refresh");
		}
		override public function draw(graphics:Graphics):void
		{
			super.draw(graphics);
			
			drawLegendsBackground(legendsBkgRectangle);
		}
		
		override public function onAreaChanged(b_finalChange:Boolean):void
		{
			super.onAreaChanged(b_finalChange);
			
//			trace("Legends onAreaChanged");
		}
		override public function onContainerSizeChanged():void
		{
			super.onContainerSizeChanged();
			
//			trace("Legends onContainerSizeChanged");
			
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
			trace("repositionedLegends: " + legendsBkgRectangle);	
			
			var ile: InteractiveLayerEvent = new InteractiveLayerEvent( InteractiveLayerEvent.LEGENDS_AREA_UPDATED);
			ile.area = legendsBkgRectangle;
			dispatchEvent(ile);
		}
		
		/**
		 * Load legends and do not layout them 
		 * @return 
		 * 
		 */		
		private function loadLegends(): Boolean
		{
			_legendsToBeRendered = 0;
			var l: InteractiveLayer;
			
			//find total count of layers for which legend should be rendered
			for each (l in m_layers)
			{
				if (l.hasLegend() && l.visible)
				{
					_legendsToBeRendered++;
				}
			}
			
			for each (l in m_layers)
			{
				if (l.hasLegend() && l.visible)
				{
					var canvas: Canvas;
					if (l.legendCanvas)
					{
						canvas = l.legendCanvas;
					} else {
						canvas = new Canvas();
						addChild(canvas);
					}
					canvas.visible = false;
					l.renderLegend(canvas, onLegendRendered, getStyle('labelAlign'));
				}
				
			}
			
			return true;
		}
		/**
		 * This function render all legens. If legends are not loaded, it loads them first. There can be problem that legend do not need to have set size, so there is problem
		 * with finding correct bounding box. That's why this function is also used for repositioned legends after load. In that case parameter justReposition needs to be set to "true"  
		 * @param justReposition - set to true if you want just reposition legends without loading
		 * 
		 */		
		public function renderLegendsStack(justReposition: Boolean = false): void
		{
			trace("\n\n******************************");
			trace("******************************");
			trace("\trenderLegendsStack justReposition = " + justReposition);
			
			if (!justReposition)
			{
				loadLegends();
				return;	
			}
//			_legendsToBeRendered = 0;
			var l: InteractiveLayer;
			
			//find total count of layers for which legend should be rendered
//			for each (l in m_layers)
//			{
//				if (l.hasLegend() && l.visible)
//				{
//					_legendsToBeRendered++;
//				}
//			}
			
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
			
//			trace("renderLegendsStack horizontal align: " + horizontalAlign + " vertical: " + verticalAlign);
//			trace("posX: " + posX + " posY: " + posY);
			var initialReposition: Boolean = false;
			
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
				
			if (justReposition)
			{
				trace("    ");
			}
			for each (l in m_layers)
			{
				if (l.hasLegend() && l.visible)
				{
					var canvas: Canvas;
					if (l.legendCanvas)
					{
						canvas = l.legendCanvas;
					} else {
						canvas = new Canvas();
						addChild(canvas);
					}
					canvas.visible = true;
					
					var rect: Rectangle
					if (!justReposition)
					{
//						var rect: Rectangle = l.renderLegend(canvas, onLegendRendered, getStyle('labelAlign'), new Rectangle(0,0,300,24));
						rect = l.renderLegend(canvas, onLegendRendered, getStyle('labelAlign'));
					} else {
						rect = new Rectangle(0,0, l.legendCanvas.width, l.legendCanvas.height);
					}
					
					trace("\n LAYER " + l.name + " rect: " + rect + " \n")
					//check if there is place for this legend
					if ( horizontalDirection != 'none') 
					{
						var newMaxWidth: int = (maxWidth - paddingRight - paddingLeft);
						var nextWidth: Number = legendsBkgRectangle.width + rect.width + gapX;
						trace("\t nextWidth: " + nextWidth + " rowItems: " + rowItems + " newMaxWidth: " + newMaxWidth);
						if (nextWidth > newMaxWidth && newMaxWidth > 0 && rowItems > 0)
						{
							trace("\t\tIt'w wider than width, make new row");
							initialReposition = true;
							startX2 = initialX;
							endX2 = initialX;
							posX = initialX;
							if ( verticalAlign == 'top')
								posY = legendsBkgRectangle.height + paddingTop + gapY;
							else {
								if ( verticalAlign == 'bottom' )
									posY = maxHeight - legendsBkgRectangle.height - paddingTop - gapY;
							}
							rowItems = 0;
						} 
					} 

					if ( verticalDirection != 'none') 
					{
						var newMaxHeight: int = (maxHeight - paddingTop - paddingBottom);
						var nextHeight: Number = legendsBkgRectangle.height +  rect.height + gapY;
						trace("\t nextHeight: " + nextHeight + " colItems: " + colItems + " newMaxHeight: " + newMaxHeight);
						if (nextHeight > newMaxHeight && newMaxHeight > 0 && colItems > 0)
						{
							trace("\t\tIt's higher than height, make new column");
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
						
					trace("\n\tposX: " + posX + " posY: " + posY);
					
					
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
					trace("\n\tnew posX: " + posX + " posY: " + posY);
					
					startX = Math.min(startX, canvas.x);
					startY = Math.min(startY, canvas.y);
					endX = Math.max(endX, canvas.x+ rect.width);
					endY = Math.max(endY, canvas.y + rect.height);
					
					trace("\t\trect: " + rect);
					trace("\t\tcanvas: ["+canvas.x+","+canvas.y+"] size: ["+canvas.width+","+canvas.height+"]");
					trace("\t\tstartX: " + startX + " startY: " + startY + " endX: " + endX + " endY: " + endY);
					trace("\tLegends: ["+maxWidth+","+maxHeight+"]");
					
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
					trace("\t\tlegendsBkgRectangle: " + legendsBkgRectangle);
					trace("\t\t_currentRectangle: " + _currentRectangle);
				}
			}
			draw(graphics);
			trace("******************************\n\n");
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
					
				var bkgX: int;
				var bkgY: int;
				
				var hAlign: String = getStyle('horizontalAlign');
				var vAlign: String = getStyle('verticalAlign');
				
				if (!rect)
					rect = new Rectangle(0,0,0,0);
				
				switch (hAlign)
				{
					case 'left':
						bkgX = getStyle('paddingLeft');
						break;
					case 'center':
						bkgX = width/2 - 0.5 * rect.width;
						break;
					case 'right':
						bkgX = width - rect.width - getStyle('paddingRight');
						break;
				}
				switch (vAlign)
				{
					case 'top':
						bkgY = getStyle('paddingTop');
						break;
					case 'middle':
						bkgY = height/2 - rect.height /2;
						break;
					case 'bottom':
						bkgY = height - rect.height - getStyle('paddingBottom');
						break;
				}
				
				var gr: Graphics = graphics;
				gr.beginFill(bkgClr, bkgAlpha);
	//			gr.drawRect(bkgX - bkgPadding, bkgY - bkgPadding, rect.width + bkgPadding * 2, rect.height + bkgPadding * 2);
				gr.drawRect(bkgX, bkgY, rect.width + bkgPadding, rect.height + bkgPadding);
	//			gr.drawRect(bkgX , bkgY , rect.width , rect.height);
				gr.endFill();
			}
		}
		private function onLegendRendered(cnv: Canvas): void
		{
			_legendsToBeRendered--;
			
			
//			trace("onLegendRendered  _legendsToBeRendered: " +_legendsToBeRendered + " canvas: " + cnv.width + ", " + cnv.height + " Position: " + cnv.x + " , " + cnv.y);
			if (_legendsToBeRendered < 1)
			{
				trace("ALL LEGENDS ARE LOADED");
				repositionedLegends();
			}
		}
		
	}
}