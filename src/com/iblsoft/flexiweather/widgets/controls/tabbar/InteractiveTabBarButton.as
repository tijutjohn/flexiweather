package com.iblsoft.flexiweather.widgets.controls.tabbar
{
	import com.iblsoft.flexiweather.widgets.controls.tabbar.skins.InteractiveTabBarButtonSkin;
	
	import flash.events.Event;
	import flash.events.MouseEvent;
	
	import spark.components.Button;
	import spark.components.ButtonBarButton;
	import spark.components.Label;
	
	[Event('closeTab',type='events.InteractiveTabBarEvent')]
	
	public class InteractiveTabBarButton extends ButtonBarButton 
	{
		[SkinPart("false")]
		public var closeButton:Button;
		
		private var _closeable:Boolean = true;
		
		[Bindable]
		public var backgroundPathData: String;
		
		[Bindable]
		public var labelRotation: int;
		
		[Bindable]
		public var closeButtonX: int;
		[Bindable]
		public var closeButtonY: int;
		
		private var _tabPosition: String;
		private var _tabPositionChanged: Boolean;
		
		[Bindable (event="tabPositionChanged")]
		public function get tabPosition():String
		{
			return _tabPosition;
		}

		public function set tabPosition(value:String):void
		{
			if (_tabPosition != value)
			{
				_tabPosition = value;
				_tabPositionChanged = true;
				invalidateProperties();
				dispatchEvent(new Event("tabPositionChanged"));
			}
		}
		
		public function InteractiveTabBarButton()
		{
			super();
			
			//NOTE: this enables the button's children (aka the close button) to receive mouse events
			this.mouseChildren = true;
			
			_tabPosition = InteractiveTabBar.TAB_POSITION_LEFT;
			
			initializeSkin();			
		}
		
		override protected function measure():void
		{
			super.measure();
		}
		
		override protected function commitProperties():void
		{
			super.commitProperties();
			
			if (_tabPositionChanged)
			{
				updateSkinPathData();
				_tabPositionChanged = false;
			}
		}


		protected function initializeSkin(): void
		{
			updateSkinPathData();
			setStyle('skinClass', InteractiveTabBarButtonSkin);
		}
		
		protected function updateSkinPathData(): void
		{
			//horizontal top
			backgroundPathData = "M 0,25 C 10,23 5,2 15,0 L 50,0 C 60,2 55,23 65,25 Z";
			labelRotation = 0;
			
			closeButtonX = 0 
			closeButtonY = 0;
		}
		
		protected function updateCloseButtonPosition(): void
		{
			(labelDisplay as Label).right = (_closeable ? 30 : 14);
		}
		[Bindable]public function get closeable():Boolean {
			return _closeable;
		}
		public function set closeable(val:Boolean):void {
			if (_closeable != val) {
				_closeable = val;
				closeButton.visible = val;
				updateCloseButtonPosition();
			}
		}
		
		private function closeHandler(e:MouseEvent):void {
			dispatchEvent(new InteractiveTabBarEvent(InteractiveTabBarEvent.CLOSE_TAB, itemIndex, true));
		}
		
		override protected function partAdded(partName:String, instance:Object):void {
			super.partAdded(partName, instance);
			
			if (instance == closeButton) {
				closeButton.addEventListener(MouseEvent.CLICK, closeHandler);
				closeButton.visible = closeable;
			} else if (instance == labelDisplay) {
				updateCloseButtonPosition();
			}
		}
		
		override protected function partRemoved(partName:String, instance:Object):void {
			super.partRemoved(partName, instance);
			
			if (instance == closeButton) {
				closeButton.removeEventListener(MouseEvent.CLICK, closeHandler);
			}
		}
	}
}