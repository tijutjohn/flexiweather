package com.iblsoft.flexiweather.widgets.containers.panels
{
	import com.iblsoft.flexiweather.widgets.containers.panels.skins.IntTabBarPanelSkin;
	import com.iblsoft.flexiweather.widgets.controls.tabbar.InteractiveTabBar;
	
	import flash.display.SimpleButton;
	import flash.events.Event;
	import flash.events.MouseEvent;
	
	import mx.binding.utils.BindingUtils;
	import mx.binding.utils.ChangeWatcher;
	import mx.collections.ArrayCollection;
	import mx.collections.IList;
	import mx.containers.ViewStack;
	import mx.core.IVisualElement;
	import mx.events.FlexEvent;
	
	import spark.components.NavigatorContent;
	import spark.components.Panel;
	import spark.components.SkinnableContainer;
	import spark.components.supportClasses.ListBase;
	import spark.effects.Animate;
	import spark.effects.animation.MotionPath;
	import spark.effects.animation.SimpleMotionPath;
	import spark.effects.easing.EaseInOutBase;
	import spark.effects.easing.EasingFraction;
	import spark.effects.easing.Elastic;
	
	public class InteractiveTabBarPanel extends SkinnableContainer
	{
		public static const TAB_POSITION_LEFT: String = 'left';
		public static const TAB_POSITION_RIGHT: String = 'right';
		
		[SkinPart (required="true")]
		public var tabBar: InteractiveTabBar;
		
		
		[Bindable]
		public var contentLeft: int;
		
		[Bindable]
		public var contentRight: int;
		
		private var _tabPosition: String;
		private var _tabPositionChanged: Boolean;
		
		private var _opened: Boolean;
		private var _openedChanged: Boolean;

		private var _viewStack: ViewStack;
		private var _viewStackChanged: Boolean;
		
		private var _positionAnimation: Animate;
		
		[Bindable]
		public function get viewStack():ViewStack
		{
			return _viewStack;
		}

		public function set viewStack(value:ViewStack):void
		{
			if (_viewStack != value)
			{
				_viewStack = value;
				_viewStackChanged = true;
				invalidateProperties();
			}
		}

		[Bindable (event="openedChanged")]
		public function get opened():Boolean
		{
			return _opened;
		}

		public function set opened(value:Boolean):void
		{
			if (_opened != value)
			{
				_opened = value;
				_openedChanged = true;
				invalidateProperties();
				dispatchEvent(new Event("openedChanged"));
			}
		}

		[Bindable (event="tabPositionChanged")]
		public function get tabPosition():String
		{
			return _tabPosition;
		}
		
		[Bindable]
		public var tabBarDataProvider: ArrayCollection;
		
		
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
		
		public function InteractiveTabBarPanel()
		{
			super();
			
			initializeAnimation();
			initializeSkin();
			
			addEventListener(FlexEvent.CREATION_COMPLETE, onCreationComplete);
			
		}
		
		override protected function partAdded(partName:String, instance:Object):void
		{
			super.partAdded(partName, instance);
			
			if (instance == tabBar)
			{
				if (viewStack)
					bindTabBarViewStack();
				
				tabBar.addEventListener(MouseEvent.CLICK, onTabBarClick);
			}
		}
		
		override protected function measure():void
		{
			super.measure();
			
			trace("InteractiveTabBarPanel measure: ");
		}
		
		private var m_oldSelectedIndex: int = -1;
		private function onTabBarClick(event: MouseEvent): void
		{
			trace("Tab bar click");
			var currentlySelectedIndex: int = tabBar.selectedIndex;
			
			if (currentlySelectedIndex == m_oldSelectedIndex)
			{
				//same tab was selected
				opened = !opened;
			} else {
				if (!opened)
					callLater(openLater);
			}
			
			m_oldSelectedIndex = currentlySelectedIndex;
		}
		
		private function onCreationComplete(event: FlexEvent): void
		{
			removeEventListener(FlexEvent.CREATION_COMPLETE, onCreationComplete);
			
			_openedChanged = true;
			invalidateProperties();
		}
		private function openLater(): void
		{
			opened = true;
		}
		
		private function bindTabBarViewStack(): void
		{
			var watcher: ChangeWatcher = BindingUtils.bindProperty(tabBar, "dataProvider", this, "viewStack");
		}
		
		private function initializeAnimation():void
		{
			_positionAnimation =  new Animate();
			_positionAnimation.easer = new EaseInOutBase(EasingFraction.OUT);
			_positionAnimation.duration = 200;
		}
		
		private function animatePosition(property: String, toValue: Number): void
		{
			_positionAnimation.stop();
			
			var currentValue: Number = this[property];
			
			if (currentValue != toValue)
			{
				var path: SimpleMotionPath = new SimpleMotionPath(property, this[property], toValue);
				_positionAnimation.motionPaths = Vector.<MotionPath>([path]);
				_positionAnimation.play([this]);
			}
		}
		protected function initializeSkin():void
		{
//			updateSkinPathData();
//			setStyle('skinClass', InteractiveTabBarPanelSkin);
			setStyle('skinClass', IntTabBarPanelSkin);
		}
		
		override protected function commitProperties():void
		{
			super.commitProperties();
			
			if (_tabPositionChanged && tabBar)
			{
				switch(tabPosition)
				{
					default:
					case TAB_POSITION_LEFT:
						tabBar.direction = InteractiveTabBar.DIRECTION_VERTICAL_LEFT;
						break;
					case TAB_POSITION_RIGHT:
						tabBar.direction = InteractiveTabBar.DIRECTION_VERTICAL_RIGHT;
						break;
				}
				_tabPositionChanged = false;
			}
			
			if (_viewStackChanged)
			{
				if (tabBar)
					bindTabBarViewStack();
				
				_viewStackChanged;
			}
			
			if (_openedChanged)
			{
				tabBar.invalidateDisplayList();
				
				var newPos: int = 0;
				if (!_opened)
				{
					newPos = -1 * (width - 25);
				}
				if (tabPosition == TAB_POSITION_LEFT)
				{
					animatePosition('left', newPos);
//					this.left = newPos;
				} else {
					animatePosition('right', newPos);
//					this.right = newPos;
				}
			}
		}
	}
}