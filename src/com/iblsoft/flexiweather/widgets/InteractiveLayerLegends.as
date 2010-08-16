package com.iblsoft.flexiweather.widgets
{
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
		
		public function renderLegendsStack(): void
		{
			_legendsToBeRendered = 0;
			var l: InteractiveLayer;
			
			//find total count of layers for which legend should be rendered
			for each (l in m_layers)
			{
				if (l.hasLegend())
				{
					_legendsToBeRendered++;
				}
			}
			
			var posX: int = 0;
			var posY: int = 0;
			
			var hAlign: String = getStyle('horizontalAlign');
			var vAlign: String = getStyle('verticalAlign');
			var sizeX: int = 0;		 
			var sizeY: int = 0;		 
			var directionX: int = 0;
			var directionY: int = 0;
			
			if ( getStyle('horizontalDirection') == 'left') {
				directionX = -1;
			} else {
				if ( getStyle('horizontalDirection') == 'right') {
					directionX = 1;
				}
			}
			if ( getStyle('verticalDirection') == 'up') {
				directionY = -1;
			} else {
				if ( getStyle('verticalDirection') == 'down') {
					directionY = 1;
				}
			}
					
					
			switch (hAlign)
			{
				case 'left':
					posX = getStyle('paddingLeft');
					break;
				case 'center':
					posX = width/2;
					sizeX = -0.5;
					break;
				case 'right':
					posX = width - getStyle('paddingRight');
					sizeX = -1;
					break;
			}
			switch (vAlign)
			{
				case 'top':
					posY = getStyle('paddingTop');
					break;
				case 'middle':
					posY = height/2;
					sizeY = -0.5;
					break;
				case 'bottom':
					posY = height - getStyle('paddingBottom');
					sizeY = -1;
					break;
			}
			
			var startX: int = posX;
			var startY: int = posY;
			var endX: int = posX;
			var endY: int = posY;
			
//			trace("renderLegendsStack horizontal align: " + getStyle('horizontalAlign') + " vertical: " + getStyle('verticalAlign'));
//			trace("posX: " + posX + " posY: " + posY);
			var initialReposition: Boolean = false;
			
			legendsBkgRectangle = new Rectangle();
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
					var rect: Rectangle = l.renderLegend(canvas, onLegendRendered, getStyle('labelAlign'), new Rectangle(0,0,300,24));
					
					if (!initialReposition)
					{
						posX += sizeX * rect.width;
						posY += sizeY * rect.height;
						initialReposition = true;
					}
					
//					trace("posX: " + posX + " posY: " + posY);
					
					canvas.x = posX;
					canvas.y = posY;
					
					var gapX: int = 0;
					var gapY: int = 0;
					if (getStyle('horizontalGap'))
					{
						gapX = getStyle('horizontalGap');
					}
					if (getStyle('verticalGap'))
					{
						gapY = getStyle('verticalGap');
					}
					posX += directionX * (rect.width + gapX);
					posY += directionY * (rect.height + gapY);
					
					
					
					startX = Math.min(startX, canvas.x);
					startY = Math.min(startY, canvas.y);
					endX = Math.max(endX, canvas.x+ rect.width);
					endY = Math.max(endY, canvas.y + rect.height);
					
				}
				
				var bkgClr: uint = 0xff0000;
				var bkgPadding: int = 0;
				if (getStyle('legendsBackgroundColor'))
					bkgClr = getStyle('legendsBackgroundColor');
				if (getStyle('legendsBackgroundPadding'))
					bkgPadding = getStyle('legendsBackgroundPadding');
				
				legendsBkgRectangle.width = Math.abs(endX - startX) + bkgPadding * 2;
				legendsBkgRectangle.height = Math.abs(endY - startY) + bkgPadding * 2;
				
				draw(graphics);
			}
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
//			if (_legendsToBeRendered < 1)
//			{
//				trace("ALL LEGENDS ARE LOADED");
//			}
		}
		
	}
}