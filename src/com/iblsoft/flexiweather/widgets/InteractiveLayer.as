package com.iblsoft.flexiweather.widgets
{
	import com.iblsoft.flexiweather.events.InteractiveLayerEvent;
	import com.iblsoft.flexiweather.ogc.BBox;
	import com.iblsoft.flexiweather.proj.Coord;
	
	import flash.display.Graphics;
	import flash.events.MouseEvent;
	import flash.geom.Rectangle;
	
	import mx.containers.Canvas;
	import mx.core.UIComponent;
	
	public class InteractiveLayer extends UIComponent
	{
		public var container: InteractiveWidget;
		private var mb_dynamicPartInvalid: Boolean = false;
		private var mi_zOrder: int = 0;
		
		protected var m_legendCallBack: Function;
		protected var m_legendCanvas: Canvas;
		protected var m_legendLabelAlign: String;
		
		public function get legendCanvas(): Canvas
		{
			return m_legendCanvas;
		}
		
		public static var ID: int = 0;
		
		override public function set visible(b_visible: Boolean): void
		{
			super.visible = b_visible;
			
			var ile: InteractiveLayerEvent = new InteractiveLayerEvent(InteractiveLayerEvent.VISIBILITY_CHANGED);
			dispatchEvent(ile);
			
			if (container)
				container.onLayerVisibilityChanged(this);
		}
		
		public function InteractiveLayer(container: InteractiveWidget)
		{
			super();
			
			mouseEnabled = false;
			mouseFocusEnabled = false;

			//FIX for diplaying Layers in List. If there are multiple isntances of same Layer types
			//there were problem with pairing layer uid and itemRenderer. This is fix/workaround to have alway
			//unique UID set
			
			InteractiveLayer.ID++;
			uid = 'interactiveLayer'+InteractiveLayer.ID;
			
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
		
		/**
		 * Called by InteractiveWidget when layer is removed from it.
		 * This method should implement cleanup of any side effects of the layer out of the
		 * layer's graphics scope (for example use of labelLayout, created UI components etc.)
		 **/ 
		public function destroy(): void
		{
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
        
        // map legend
        public function hasLegend(): Boolean
        { return false; }
        
        public function removeLegend(canvas: Canvas): void
        {  }

        public function renderLegend(canvas: Canvas, callback: Function, labelAlign: String = 'left', useCache: Boolean = false , hintSize: Rectangle = null): Rectangle
        {	return new Rectangle(); }
        
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
		
		/**
		 * Clone interactiveLayer 
		 * 
		 */		
		public function clone(): InteractiveLayer
		{
			return new InteractiveLayer(container);	
		}
	}
}