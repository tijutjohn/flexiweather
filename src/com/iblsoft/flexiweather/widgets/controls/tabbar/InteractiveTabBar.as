package com.iblsoft.flexiweather.widgets.controls.tabbar
{
	
	import com.iblsoft.flexiweather.widgets.controls.tabbar.skins.InteractiveTabBarSkin;
	import com.iblsoft.flexiweather.widgets.controls.tabbar.skins.InteractiveVerticalTabBarSkin;
	
	import flash.events.Event;
	
	import mx.collections.IList;
	import mx.containers.ViewStack;
	import mx.states.OverrideBase;
	
	import spark.components.TabBar;
	
	public class InteractiveTabBar extends TabBar
	{
		public static const DIRECTION_HORIZONTAL: String = 'horizontal';
		public static const DIRECTION_VERTICAL_LEFT: String = 'verticalLeft';
		public static const DIRECTION_VERTICAL_RIGHT: String = 'verticalRight';
		public static const TAB_POSITION_LEFT: String = 'left';
		public static const TAB_POSITION_RIGHT: String = 'right';
		
		private var _direction: String;
		private var _directionChanged: Boolean;
		
		[Bindable]
		public function get direction():String
		{
			return _direction;
		}

		public function set direction(value:String):void
		{
			if (_direction != value)
			{
				_direction = value;
				_directionChanged = true;
				invalidateProperties();
				dispatchEvent(new Event("directionChanged"));
			}
		}
		
		[Bindable]
		public var tabPosition: String;
		
		/**
		 *  @private
		 */    
		override public function set dataProvider(value:IList):void
		{
			super.dataProvider = value;	
		}
		
		public function InteractiveTabBar()
		{
			super();
			//setStyle('skinClass', InteractiveTabBarSkin);
			_direction = DIRECTION_VERTICAL_LEFT;
			updatePropertiesAfterDirectionChange();
		}
		
		override protected function commitProperties():void
		{
			super.commitProperties();
			
			if (_directionChanged)
			{
				updatePropertiesAfterDirectionChange();
				_directionChanged = false;
			}
		}
		
		private function updatePropertiesAfterDirectionChange(): void
		{
			switch(_direction)
			{
				case DIRECTION_HORIZONTAL:
					setStyle('skinClass', InteractiveTabBarSkin);
					break;
				case DIRECTION_VERTICAL_LEFT:
					tabPosition = TAB_POSITION_LEFT;
					setStyle('skinClass', InteractiveVerticalTabBarSkin);
					break;
				case DIRECTION_VERTICAL_RIGHT:
					tabPosition = TAB_POSITION_RIGHT;
					setStyle('skinClass', InteractiveVerticalTabBarSkin);
					break;
			}
		}
		
		public function setCloseableTab(index:int, value:Boolean):void {
			if (index >= 0 && index < dataGroup.numElements) {
				var btn:InteractiveTabBarButton = dataGroup.getElementAt(index) as InteractiveTabBarButton;
				btn.closeable = value;
			}
		}
		public function getCloseableTab(index:int):Boolean {
			if (index >= 0 && index < dataGroup.numElements) {
				var btn:InteractiveTabBarButton = dataGroup.getElementAt(index) as InteractiveTabBarButton;
				return btn.closeable;
			}
			return false;
		}
		
		private function closeHandler(e:InteractiveTabBarEvent):void {
			closeTab(e.index, selectedIndex);
		}
		
		public function closeTab(closedTab:int, selectedTab:int):void {
			if (dataProvider.length == 0) return;
			
			if (dataProvider is IList) {
				dataProvider.removeItemAt(closedTab);
			} else if (dataProvider is ViewStack){
				//remove the entire child from the dataProvider, which also removes it from the ViewStack
				(dataProvider as ViewStack).removeChildAt(closedTab);
			}
			
			//adjust selectedIndex appropriately
			if (dataProvider.length == 0) {
				selectedIndex = -1;
			} else if (closedTab < selectedTab) {
				selectedIndex = selectedTab - 1;
			} else if (closedTab == selectedTab) {
				selectedIndex = (selectedTab == 0 ? 0 : selectedTab - 1);
			} else {
				selectedIndex = selectedTab;
			}
		}
		
		protected override function partAdded(partName:String, instance:Object):void {
			super.partAdded(partName, instance);
			
			if (instance == dataGroup) {
				dataGroup.addEventListener(InteractiveTabBarEvent.CLOSE_TAB, closeHandler);
			}
		}
		
		protected override function partRemoved(partName:String, instance:Object):void {
			super.partRemoved(partName, instance);
			
			if (instance == dataGroup) {
				dataGroup.removeEventListener(InteractiveTabBarEvent.CLOSE_TAB, closeHandler);
			}
		}
	}
}