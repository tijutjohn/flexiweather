package com.iblsoft.flexiweather.widgets.controls.tabbar
{
	import com.iblsoft.flexiweather.widgets.controls.tabbar.skins.InteractiveVerticalTabBarButtonSkin;
	
	public class InteractiveVerticalTabBarButton extends InteractiveTabBarButton 
	{
		override public function setStyle(styleProp:String, newValue:*):void
		{
			super.setStyle(styleProp, newValue);
		}
		
		public function InteractiveVerticalTabBarButton()
		{
			super();
		}
		
		override protected function initializeSkin():void
		{
			updateSkinPathData();
			setStyle('skinClass', InteractiveVerticalTabBarButtonSkin);
		}
		
		override protected function updateCloseButtonPosition(): void
		{
			if (tabPosition == InteractiveTabBar.TAB_POSITION_LEFT) 
				closeButtonY = (closeable ? 30 : 14);
//				closeButtonY = (closeable ? measuredHeight - 30 : measuredHeight - 14);
			if (tabPosition == InteractiveTabBar.TAB_POSITION_RIGHT)
				closeButtonY = (closeable ? 30 : 14);
		}
		
		override protected function updateSkinPathData(): void
		{
			if (tabPosition == InteractiveTabBar.TAB_POSITION_LEFT) {
				backgroundPathData = "M 0,0 C 2,10 23,5 25,15 L 25,50 C 23,60 2,55 0,65 Z";
				labelRotation = 90;
				closeButtonX = 6; 
				closeButtonY = measuredHeight - 14;
				if (closeButton)
					closeButtonY -= closeButton.measuredHeight;
			}
			else if (tabPosition == InteractiveTabBar.TAB_POSITION_RIGHT) {
				backgroundPathData = "M 25,0 C 23,10 2,5 0,15 L 0,50 C 2,60 23,55 25,65 Z";
				labelRotation = 270;
				closeButtonX = 6; 
				closeButtonY = 14;
			}
		}
		
	}
}