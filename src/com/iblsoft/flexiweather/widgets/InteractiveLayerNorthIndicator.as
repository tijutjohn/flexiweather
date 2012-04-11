package com.iblsoft.flexiweather.widgets
{
	public class InteractiveLayerNorthIndicator extends InteractiveLayer
	{
		public function InteractiveLayerNorthIndicator(container:InteractiveWidget)
		{
			super(container);
		}
	}
}
import flash.display.Graphics;

import mx.core.UIComponent;

class NorthIndicator extends UIComponent {
	
	public function NorthIndicator()
	{
		
	}
	
	public function draw(): void
	{
		var gr: Graphics = graphics;
		gr.lineStyle(1,0);
	}
}