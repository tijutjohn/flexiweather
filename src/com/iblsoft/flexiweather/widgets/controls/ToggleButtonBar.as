package com.iblsoft.flexiweather.widgets.controls
{
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.utils.Dictionary;
	
	import mx.collections.ArrayCollection;
	import mx.core.IVisualElement;
	import mx.events.CollectionEvent;
	import mx.events.CollectionEventKind;
	import mx.events.FlexEvent;
	import mx.managers.IFocusManagerComponent;
	
	import spark.components.Button;
	import spark.components.ButtonBar;
	import spark.components.ButtonBarButton;
	import spark.components.Group;
	import spark.components.IItemRenderer;
	import spark.components.SkinnableDataContainer;
	import spark.components.ToggleButton;
	import spark.events.ListEvent;
	import spark.events.RendererExistenceEvent;
	import spark.layouts.HorizontalLayout;
	import spark.layouts.supportClasses.LayoutBase;

	[Event(name="toggleBarButtonClick", type="com.iblsoft.flexiweather.widgets.controls.ToggleButtonBarEvent")]
	[Event(name="toggleBarButtonSelect", type="com.iblsoft.flexiweather.widgets.controls.ToggleButtonBarEvent")]
	[Event(name="toggleBarButtonUnselect", type="com.iblsoft.flexiweather.widgets.controls.ToggleButtonBarEvent")]
	[Event(name="toggleBarButtonSelectExclusive", type="com.iblsoft.flexiweather.widgets.controls.ToggleButtonBarEvent")]
	[Event(name="toggleBarButtonUnselectExclusive", type="com.iblsoft.flexiweather.widgets.controls.ToggleButtonBarEvent")]
	
	/**
	 * ButtonBar which support multiple selection and will handle also all 3 types of buttons we need
	 * - normal button (toggle: false, exclusive: false)
	 * - toggle button (toggle: true, exclusive: false) - normal toggle button, changing of toggle state does not affect any other buttons
	 * - exclusive button (toggle: false/true, exclusive: true) - exclusive toggle button is always toggle button, so "toggle" property is ignored. Switching exclusive button to "toggle" state, switch off all other exclusive buttons
	 */

	public class ToggleButtonBar extends ButtonBar
	{
		
		private var _buttons: Dictionary;
		

		public function ToggleButtonBar()
		{
			super();
			
			_buttons = new Dictionary();
			
			setStyle('skinClass', ToggleButtonBarSkin);
		}
		
		public function getRendererForData(data: ToggleButtonBarItemData): IVisualElement
		{
			if (_buttons)
			{
				for each (var currData: ButtonDictionaryData in _buttons)
				{
					if (currData.data == data)
						return currData.btn;
				}
			}
			return null;
		}
		public function getDataForRenderer(renderer: IVisualElement): ToggleButtonBarItemData
		{
			if (_buttons)
			{
				for each (var data: ButtonDictionaryData in _buttons)
				{
					if (data.btn == renderer)
						return data.data;
				}
			}
			return null;
		}

		override protected function dataGroup_rendererAddHandler(event:RendererExistenceEvent):void
		{
//			super.dataGroup_rendererAddHandler(event);
			
			const renderer:IVisualElement = event.renderer; 
			if (renderer)
			{
				renderer.addEventListener(MouseEvent.ROLL_OVER, item_mouseEventHandler);
				renderer.addEventListener(MouseEvent.ROLL_OUT, item_mouseEventHandler);
				
				var data: ToggleButtonBarItemData = event.data as ToggleButtonBarItemData;
				
				switch (data.type)
				{
					case ToggleButtonBarItemData.NORMAL:
						renderer.addEventListener(MouseEvent.CLICK, onNormalButtonClick);
						_buttons[renderer] = new ButtonDictionaryData(renderer, data);
						break;
					case ToggleButtonBarItemData.TOGGLE:
						renderer.addEventListener(Event.CHANGE, onToggleButtonChange);
						renderer.addEventListener(MouseEvent.CLICK, onToggleButtonClick);
						_buttons[renderer] = new ButtonDictionaryData(renderer, data);
						break;
					case ToggleButtonBarItemData.EXCLUSIVE:
						renderer.addEventListener(Event.CHANGE, onExclusiveButtonChange);
						renderer.addEventListener(MouseEvent.CLICK, onExclusiveButtonClick);
						_buttons[renderer] = new ButtonDictionaryData(renderer, data);
						break;
				}	
//				renderer.addEventListener(MouseEvent.CLICK, item_clickHandler);
				if (renderer is IFocusManagerComponent)
					IFocusManagerComponent(renderer).focusEnabled = false;
				
				if (renderer is ToggleButtonBarButton)
				{
					ToggleButtonBarButton(renderer).toolTip = data.tooltip;
					ToggleButtonBarButton(renderer).type = data.type;
					ToggleButtonBarButton(renderer).enabled = data.enabled;
				}
				
				if (renderer is ButtonBarButton)
					ButtonBarButton(renderer).allowDeselection = !requireSelection;
			}
		}
		
		/**
		 *  @private
		 *  Static constant representing no item in focus. 
		 */
		private static const TYPE_MAP:Object = { rollOver: "itemRollOver",
			rollOut:  "itemRollOut" };
		
		private function item_mouseEventHandler(event:MouseEvent):void
		{
			var type:String = event.type;
			type = TYPE_MAP[type];
			if (hasEventListener(type))
			{
				var itemRenderer: IItemRenderer = event.currentTarget as IItemRenderer;
				
				var itemIndex:int = -1;
				if (itemRenderer)
					itemIndex = itemRenderer.itemIndex;
				else
					itemIndex = dataGroup.getElementIndex(event.currentTarget as IVisualElement);
				
				var listEvent:ListEvent = new ListEvent(type, false, false,
					event.localX,
					event.localY,
					event.relatedObject,
					event.ctrlKey,
					event.altKey,
					event.shiftKey,
					event.buttonDown,
					event.delta,
					itemIndex,
					dataProvider.getItemAt(itemIndex),
					itemRenderer);
				
				dispatchEvent(listEvent);
			}
		}

		private function onNormalButtonClick(event: MouseEvent): void
		{
			trace("onNormalButtonClick");
			var btn: IVisualElement = event.target as IVisualElement;
			var data: ToggleButtonBarItemData = getDataForRenderer(btn);
			var e: ToggleButtonBarEvent = new ToggleButtonBarEvent(ToggleButtonBarEvent.CLICK, data);
			dispatchEvent(e);
		}
		private function onToggleButtonChange(event: Event): void
		{
			var btn: IVisualElement = event.target as IVisualElement;
			var data: ToggleButtonBarItemData = getDataForRenderer(btn);
			var e: ToggleButtonBarEvent;
			var toggleButton: ToggleButton = ToggleButton(btn);
			
			if (toggleButton)
			{
				if (toggleButton.selected)
				{
					e = new ToggleButtonBarEvent(ToggleButtonBarEvent.SELECT, data);
				} else {
					e = new ToggleButtonBarEvent(ToggleButtonBarEvent.UNSELECT, data);
				}
				dispatchEvent(e);
			}
		}
		private function onToggleButtonClick(event: MouseEvent): void
		{
			trace("onToggleButtonClick");
			var btn: IVisualElement = event.target as IVisualElement;
			var data: ToggleButtonBarItemData = getDataForRenderer(btn);
			var e: ToggleButtonBarEvent = new ToggleButtonBarEvent(ToggleButtonBarEvent.CLICK, data);
			dispatchEvent(e);
			
		}
		private function onExclusiveButtonChange(event: Event): void
		{
			var btn: IVisualElement = event.target as IVisualElement;
			var data: ToggleButtonBarItemData = getDataForRenderer(btn);
			var e: ToggleButtonBarEvent;
			var toggleButton: ToggleButton = ToggleButton(btn);
			
			if (toggleButton)
			{
				if (toggleButton.selected)
				{
					e = new ToggleButtonBarEvent(ToggleButtonBarEvent.SELECT_EXCLUSIVE, data);
				} else {
					e = new ToggleButtonBarEvent(ToggleButtonBarEvent.UNSELECT_EXCLUSIVE, data);
				}
				dispatchEvent(e);
			}
		}
		private function onExclusiveButtonClick(event: MouseEvent): void
		{
			var btn: IVisualElement = event.target as IVisualElement;
			var buttonData: ToggleButtonBarItemData = getDataForRenderer(btn);
			var e: ToggleButtonBarEvent = new ToggleButtonBarEvent(ToggleButtonBarEvent.CLICK, buttonData);
			dispatchEvent(e);
			
			var clickedButton: ToggleButton = event.target as ToggleButton;
			
			for each (var data: ButtonDictionaryData in _buttons)
			{
				var currButton: ToggleButton = data.btn as ToggleButton;
				
				if (data.data.type == ToggleButtonBarItemData.EXCLUSIVE && currButton && clickedButton != currButton)
				{
					if (currButton.selected)
					{
						currButton.selected = false;
						var unselectEvent: ToggleButtonBarEvent = new ToggleButtonBarEvent(ToggleButtonBarEvent.UNSELECT_EXCLUSIVE, data.data);
						dispatchEvent(unselectEvent);
					}
				}
			}
		}
	}
}

import com.iblsoft.flexiweather.widgets.controls.ToggleButtonBarItemData;

import mx.core.IVisualElement;

import spark.components.Button;
import spark.components.supportClasses.ButtonBase;

class ButtonDictionaryData
{
	public var btn: IVisualElement;
	public var data: ToggleButtonBarItemData;
	
	public function ButtonDictionaryData(btn: IVisualElement, data: ToggleButtonBarItemData)
	{
		this.btn = btn;
		this.data = data;
	}
}