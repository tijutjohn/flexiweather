package com.iblsoft.flexiweather.widgets
{
	import com.iblsoft.flexiweather.ogc.BBox;
	import com.iblsoft.flexiweather.proj.Coord;
	
	import flash.display.Graphics;
	import flash.events.MouseEvent;
	
	import mx.core.UIComponent;
	
	public class InteractiveLayer extends UIComponent
	{
		public var container: InteractiveWidget;
		private var mb_dynamicPartInvalid: Boolean = false;
		private var mb_visible: Boolean = true;
		private var mb_enabled: Boolean = true;
		private var mi_zOrder: int = 0;
		
		public function InteractiveLayer(container: InteractiveWidget)
		{
			super();
			this.container = container;
		}
		
		public function draw(graphics: Graphics): void
		{
			mb_dynamicPartInvalid = false;
		}
		
		override protected function updateDisplayList(unscaledWidth: Number, unscaledHeight: Number): void
		{
			graphics.clear();
			draw(graphics);
		}
		
		public function invalidateDynamicPart(b_invalid: Boolean = true): void
		{
			mb_dynamicPartInvalid = b_invalid;
			invalidateDisplayList();
		}
		
		public function isDynamicPartInvalid(): Boolean
		{ return mb_dynamicPartInvalid; }
		
		public function onAreaChanged(b_finalChange: Boolean): void
		{}

		public function onContainerSizeChanged(): void
		{
			this.x = container.x;
			this.y = container.y;
			this.width = container.width;
			this.height = container.height;
		}

        public function onMouseDown(event: MouseEvent): Boolean
        { return false; }

        public function onMouseUp(event: MouseEvent): Boolean
        { return false; }

        public function onMouseMove(event: MouseEvent): Boolean
        { return false; }

        public function onMouseWheel(event: MouseEvent): Boolean
        { return false; }
        
        public function onMouseClick(event: MouseEvent): Boolean
        { return false; }

        public function onMouseDoubleClick(event: MouseEvent): Boolean
        { return false; }

        public function onMouseRollOver(event: MouseEvent): Boolean
        { return false; }
        
        public function onMouseRollOut(event: MouseEvent): Boolean
        { return false; }
        
        // data refreshing
        public function refresh(b_force: Boolean): void
        {}
        
        // feature info
        public function hasFeatureInfo(): Boolean
        { return false; }

        public function getFeatureInfo(coord: Coord, callback: Function): void
        {}
        
        // extent access
        public function hasExtent(): Boolean
        { return false; }
        
        public function getExtent(): BBox
        { return null; }

        // preview & layer setup support
        public function hasPreview(): Boolean
        { return false; }

		public function renderPreview(graphics: Graphics, f_width: Number, f_height: Number): void
		{}
		
		public function get zOrder(): int
		{ return mi_zOrder; }

		public function set zOrder(i_zOrder: int): void 
		{
			mi_zOrder = i_zOrder;
			if(container != null)
				container.orderLayers();
		}
	}
}