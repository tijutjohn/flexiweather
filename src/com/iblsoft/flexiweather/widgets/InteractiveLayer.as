package com.iblsoft.flexiweather.widgets
{
	import com.iblsoft.flexiweather.events.InteractiveLayerEvent;
	import com.iblsoft.flexiweather.ogc.BBox;
	import com.iblsoft.flexiweather.ogc.kml.data.KMZFile;
	import com.iblsoft.flexiweather.proj.Coord;
	
	import flash.display.Graphics;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.Rectangle;
	
	import mx.core.UIComponent;
	import mx.effects.Effect;
	import mx.events.EffectEvent;
	import mx.events.FlexEvent;
	
	[Event(name = "layerInitialized", type = "com.iblsoft.flexiweather.events.InteractiveLayerEvent")]
	public class InteractiveLayer extends UIComponent
	{
		private static var layerUID: int = 0;
		protected var m_layerID: int;


		private var _container: InteractiveWidget;
		
		public function get container():InteractiveWidget
		{
			return _container;
		}

		public function set container(value:InteractiveWidget):void
		{
			_container = value;
		}

		public function get layerID(): int
		{
			return m_layerID;
		}
		
		protected var m_layerWasDestroyed: Boolean;
		protected var _type: String;

		/**
		 * Layer type. String representation of layer type. Useful when user wants to get layer from InteractiveWidget or InteractiveLayerComposer
		 * and wants just compare type by string. (e.g type == 'pan').
		 */
		public function get type(): String
		{
			return _type;
		}
		
		
		
		private var mb_dynamicPartInvalid: Boolean = false;
		private var mi_zOrder: int = 0;
		protected var m_legendCallBack: Function;
		protected var m_legendGroup: InteractiveLayerLegendGroup;
		protected var m_legendLabelAlign: String;
		
		[Bindable]
		public var layerName: String;
		private var _forcedLayerWidth: int = 0;

		
		public function get forcedLayerWidth(): int
		{
			return _forcedLayerWidth;
		}

		public function set forcedLayerWidth(value: int): void
		{
			_forcedLayerWidth = value;
		}
		private var _forcedLayerHeight: int = 0;

		public function get forcedLayerHeight(): int
		{
			return _forcedLayerHeight;
		}

		public function set forcedLayerHeight(value: int): void
		{
			_forcedLayerHeight = value;
		}

		public function get legendGroup(): InteractiveLayerLegendGroup
		{
			return m_legendGroup;
		}
		public static var ID: int = 0;

		override public function set alpha(value:Number):void
		{
			if (super.alpha != value)
			{
				super.alpha = value;
				dispatchEvent(new InteractiveLayerEvent(InteractiveLayerEvent.ALPHA_CHANGED, true));
			}
		}
		
		[Bindable (event="visibilityChanged")]
		override public function get visible(): Boolean
		{
			return super.visible;
		}

		override public function set visible(b_visible: Boolean): void
		{
			if (super.visible != b_visible)
			{
				var effect: Effect;
				
				if (b_visible) {
					effect = getStyle('showEffect');
				} else {
					effect = getStyle('hideEffect');
				}
				
				if (effect)
				{
					effect.addEventListener(EffectEvent.EFFECT_END, onVisibleEffectEnd);
					effect.addEventListener(EffectEvent.EFFECT_START, onVisibleEffectStart);
				}
				super.visible = b_visible;
				
//				var ile: InteractiveLayerEvent = new InteractiveLayerEvent(InteractiveLayerEvent.VISIBILITY_CHANGED);
//				dispatchEvent(ile);
//				if (container)
//					container.onLayerVisibilityChanged(this);
				
				if (!effect)
					callLater(visibilityChanged);
				
				dispatchEvent(new Event("visibilityChanged"));
			}
		}
		
		private function onVisibleEffectStart(event: EffectEvent): void
		{
			
		}
		
		private function onVisibleEffectEnd(event: EffectEvent): void
		{
			visibilityChanged();
		}
		
		private function visibilityChanged(): void
		{
			var ile: InteractiveLayerEvent = new InteractiveLayerEvent(InteractiveLayerEvent.VISIBILITY_CHANGED);
			dispatchEvent(ile);
			if (container)
				container.onLayerVisibilityChanged(this);
		}
		
		protected var _layerInitialized: Boolean;
		
		public function get layerInitialized(): Boolean
		{
			return _layerInitialized;
		}

		
		/**
		 * One of InteractiveLayerPrintQuality constants 
		 */		
		private var _printQuality: String;
		
		public function get printQuality():String
		{
			return _printQuality;
		}
		
		public function set printQuality(value:String):void
		{
			_printQuality = value;
		}
		
		/**
		 * Return true of layer supports vector data (can load them and display them) 
		 * @return 
		 * 
		 */		
		public function get supportsVectorData(): Boolean
		{
			return false;
		}
		public function InteractiveLayer(container: InteractiveWidget = null)
		{
			m_layerID = layerUID++;
			
			super();
			mouseEnabled = false;
			mouseFocusEnabled = false;
			//FIX for diplaying Layers in List. If there are multiple isntances of same Layer types
			//there were problem with pairing layer uid and itemRenderer. This is fix/workaround to have alway
			//unique UID set
			InteractiveLayer.ID++;
			uid = 'interactiveLayer' + InteractiveLayer.ID;
			this.container = container;
			addEventListener(FlexEvent.CREATION_COMPLETE, onLayerCreationComplete);
			addEventListener(Event.ADDED_TO_STAGE, onLayerAddedToStage);
		}

		
		private function onLayerAddedToStage(event: Event): void
		{
			removeEventListener(Event.ADDED_TO_STAGE, onLayerAddedToStage);
			initializeLayerAfterAddToStage();
		}
		
		private function onLayerCreationComplete(event: FlexEvent): void
		{
			removeEventListener(FlexEvent.CREATION_COMPLETE, onLayerCreationComplete);
			initializeLayer();
		}

		/**
		 * Override this function and add functionality, which needs to be done when layer is added to display list
		 *
		 */
		protected function initializeLayerAfterAddToStage(): void
		{
			callLater(delayedInitializeLayerAfterAddToStage);
		}
		
		protected function delayedInitializeLayerAfterAddToStage(): void
		{
			if (!_layerInitialized)
			{
				_layerInitialized = true;
				notifyLayerInitialized();
			}
			
		}
		
		/**
		 * Override this function and add functionality, which needs to be done when layer is created
		 *
		 */
		protected function initializeLayer(): void
		{
		}

		protected function notifyLayerInitialized(): void
		{
			dispatchEvent(new InteractiveLayerEvent(InteractiveLayerEvent.LAYER_INITIALIZED, true));
		}

		/**
		 * Call this function if you want clear layer graphics
		 * @param graphics
		 *
		 */
		public function clear(graphics: Graphics): void
		{
			graphics.clear();
		}

		/**
		 * Main draw function. Draw layer data here
		 * @param graphics
		 *
		 */
		public function draw(graphics: Graphics): void
		{
			mb_dynamicPartInvalid = false;
		}

		protected function drawNoDataPreview(graphics: Graphics, f_width: Number, f_height: Number): void
		{
			graphics.lineStyle(2, 0xcc0000, 0.7, true);
			graphics.moveTo(0, 0);
			graphics.lineTo(f_width - 1, f_height - 1);
			graphics.moveTo(0, f_height - 1);
			graphics.lineTo(f_width - 1, 0);
		}

		override protected function updateDisplayList(unscaledWidth: Number, unscaledHeight: Number): void
		{
//			trace(this + " updateDisplayList unscaledWidth: " + unscaledWidth + " unscaledHeight: " + unscaledHeight);
			clear(graphics);
			draw(graphics);
		}

		public function invalidateDynamicPart(b_invalid: Boolean = true): void
		{
			mb_dynamicPartInvalid = b_invalid;
			invalidateDisplayList();
		}

		public function get layerWasDestroyed(): Boolean
		{
			return m_layerWasDestroyed;
		}

		/**
		 * Called by InteractiveWidget when layer is removed from it.
		 * This method should implement cleanup of any side effects of the layer out of the
		 * layer's graphics scope (for example use of labelLayout, created UI components etc.)
		 **/
		public function destroy(): void
		{
			_layerInitialized = false;
			m_layerWasDestroyed = true;
			
			addEventListener(Event.ADDED_TO_STAGE, onLayerAddedToStage, false, 0, true);
		}

		public function isDynamicPartInvalid(): Boolean
		{
			return mb_dynamicPartInvalid;
		}

		public function onAreaChanged(b_finalChange: Boolean): void
		{
		}

		public function onContainerSizeChanged(): void
		{
			this.x = 0;
			this.y = 0;
			if (container)
			{
				this.width = container.width;
				this.height = container.height;
			}
		}

		protected function notifyLayerChanged(change: String): void
		{
			if (container)
				container.notifyWidgetChanged(change, this);
			else
				trace(this + " [notifyLayerChanged] was changed (" + change + "), but there is no InteractiveWidget assigned");
		}

		public function negotiateBBox(newBBox: BBox, changeZoom: Boolean = true): BBox
		{
			return newBBox;
		}

		public function onMouseDown(event: MouseEvent): Boolean
		{
			return false;
		}

		public function onMouseUp(event: MouseEvent): Boolean
		{
			return false;
		}

		public function onMouseMove(event: MouseEvent): Boolean
		{
			return false;
		}

		public function onMouseWheel(event: MouseEvent): Boolean
		{
			return false;
		}

		public function onMouseClick(event: MouseEvent): Boolean
		{
			return false;
		}

		public function onMouseDoubleClick(event: MouseEvent): Boolean
		{
			return false;
		}

		public function onMouseRollOver(event: MouseEvent): Boolean
		{
			return false;
		}

		public function onMouseRollOut(event: MouseEvent): Boolean
		{
			return false;
		}

		// data refreshing
		public function refresh(b_force: Boolean): void
		{
		}

		// feature info
		public function hasFeatureInfo(): Boolean
		{
			return false;
		}

		public function getFeatureInfo(coord: Coord, callback: Function): void
		{
		}

		// map legend
		public function hasLegend(): Boolean
		{
			return false;
		}

		public function invalidateLegend(): void
		{
		}

		public function removeLegend(group: InteractiveLayerLegendGroup): void
		{
		}

		public function renderLegend(group: InteractiveLayerLegendGroup, callback: Function, legendScaleX: Number, legendScaleY: Number, labelAlign: String = 'left', useCache: Boolean = false, hintSize: Rectangle = null): Rectangle
		{
			return new Rectangle();
		}

		// extent access
		public function hasExtent(): Boolean
		{
			return false;
		}

		public function getExtent(): BBox
		{
			return null;
		}

		// preview & layer setup support
		public function hasPreview(): Boolean
		{
			return false;
		}

		public function renderPreview(graphics: Graphics, f_width: Number, f_height: Number): void
		{
		}

		public function get zOrder(): int
		{
			return mi_zOrder;
		}

		public function set zOrder(i_zOrder: int): void
		{
			if (mi_zOrder != i_zOrder)
			{
				mi_zOrder = i_zOrder;
				if (container != null)
					container.invalidateLayersOrder();
			}
		}

		public function getFullURLWithSize(width: int, height: int): String
		{
			return '';
		}

		public function getFullURL(): String
		{
			return '';
		}

		/**
		 * Clone interactiveLayer
		 *
		 */
		public function clone(): InteractiveLayer
		{
			var layer: InteractiveLayer = new InteractiveLayer(container);
			updatePropertyForCloneLayer(layer);
			return layer;
		}
		
		/**
		 * You can update all properties, which needs to be updated when clone InteractiveLayer. 
		 * Please override this function in all layers which extend InteractiveLayer  
		 * @param layer
		 * 
		 */		
		protected function updatePropertyForCloneLayer(layer: InteractiveLayer): void
		{
			layer.id = id;
			layer.alpha = alpha;
			layer.zOrder = zOrder;
			layer.visible = visible;
			layer.layerName = layerName;
		}

		override public function toString(): String
		{
			return "InteractiveLayer " + name + " / " + m_layerID;
		}
	}
}
