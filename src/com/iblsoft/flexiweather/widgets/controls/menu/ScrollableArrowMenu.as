/***********************************************************************************************
 *
 *	Created:	14.11.2014
 *	Authors:	Franto Kormanak
 *
 *	Copyright (c) 2014, IBL Software Engineering spol. s r. o., <escrow@iblsoft.com>.
 *	All rights reserved. Unauthorised use, modification or redistribution is prohibited.
 *
 ***********************************************************************************************/

package com.iblsoft.flexiweather.widgets.controls.menu
{
	import flash.display.DisplayObjectContainer;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.events.TimerEvent;
	import flash.utils.Timer;

	import mx.controls.Button;
	import mx.controls.Menu;
	import mx.controls.listClasses.IListItemRenderer;
	import mx.controls.menuClasses.IMenuItemRenderer;
	import mx.controls.scrollClasses.ScrollBar;
	import mx.core.Application;
	import mx.core.ScrollPolicy;
	import mx.core.mx_internal;
	import mx.events.ScrollEvent;
	import mx.managers.PopUpManager;
	import mx.styles.CSSStyleDeclaration;
	import mx.styles.StyleManager;

	use namespace mx_internal;

//	[IconFile("ScrollableArrowMenu.png")]

	/**
	 *  Name of CSS style declaration that specifies style for button used to control the vertical
	 *  scrolling. This button appears on the top of the ScrollableArrowMenu control.
	 *
	 *  @default undefined
	 */
	[Style(name="upButtonStyleName", type="String", inherit="no")]

	/**
	 *  Name of CSS style declaration that specifies style for button used to control the vertical
	 *  scrolling. This button appears on the bottom of the ScrollableArrowMenu control.
	 *
	 *  @default undefined
	 */
	[Style(name="downButtonStyleName", type="String", inherit="no")]


	/**
	 * An extension of ScrollableMenu that uses two arrow buttons placed at the top and
	 * bottom of the menu for scrolling.
	 *
	 * @see flexlib.controls.ScrollableMenu
	 */
	public class ScrollableArrowMenu extends ScrollableMenu
	{
		[Embed (source="/assets/icons/common/up.png")]
		private static var DEFAULT_UP_BUTTON:Class;

		[Embed (source="/assets/icons/common/down.png")]
		private static var DEFAULT_DOWN_BUTTON:Class;

		/**
		 * @private
		 * The buttons that are used for the scrolling up and down
		 */
		private var upButton:Button;

		/**
		 * @private
		 * The buttons that are used for the scrolling up and down
		 */
		private var downButton:Button;

		/**
		 * @private
		 * We use a timer to control the scrolling while the mouse is over the buttons
		 */
		private var timer:Timer;

		/**
		 * The delay between scrolling the list, so a smaller number
		 * here will increase the speed of the scrolling. This is in ms.
		 */
		public var scrollSpeed:Number = 80;

		/**
		 * Specifies how many rows to scroll each time. Leaving it at 1 makes
		 * for the smoothest scrolling
		 */
		public var scrollJump:Number = 1;

		/**
		 * @private
		 */
		private var _arrowScrollPolicy:String = ScrollPolicy.AUTO;

		/**
		 * Just like verticalScrollPolicy, except it controls how we display the up and down arrows
		 * for scrolling.
		 *
		 * <p>If this is set to ScrollPolicy.OFF we never show the arrows.
		 * If it's ScrollPolicy.ON we always show the arrows. And if it's ScrollPolicy.AUTO
		 * then we show the arrows if they are needed. OFF and AUTO are the only ones
		 * that should probably be used, since ON gets in the way of the first menu item
		 * in the list.</p>
		 */

		public function get arrowScrollPolicy():String {
			return _arrowScrollPolicy;
		}

		/**
		 * @private
		 */
		public function set arrowScrollPolicy(value:String):void {
			this._arrowScrollPolicy = value;

			invalidateDisplayList();
		}

		/**
		 * We have to override the static function createMenu so that we create a
		 * ScrollableMenu instead of a normal Menu.
		 */
		public static function createMenu(parent:DisplayObjectContainer, mdp:Object, showRoot:Boolean=true):ScrollableArrowMenu
		{
			var menu:ScrollableArrowMenu = new ScrollableArrowMenu();
			menu.tabEnabled = false;

			menu.owner = DisplayObjectContainer(Application.application);
			menu.showRoot = showRoot;
			popUpMenu(menu, parent, mdp);
			return menu;
		}

		/**
		 * Constructor
		 */
		public function ScrollableArrowMenu()
		{
			super();
			this.verticalScrollPosition = 0;
		}

		/*
		private static function initializeStyles():void
		{
			var selector:CSSStyleDeclaration = StyleManager.getStyleDeclaration("ScrollableArrowMenu");

			if(!selector)
			{
				selector = new CSSStyleDeclaration();
			}

			selector.defaultFactory = function():void
			{
				this.upButtonStyleName = "upButton";
				this.downButtonStyleName = "downButton";
			}

			StyleManager.setStyleDeclaration("ScrollableArrowMenu", selector, false);



			// Style for the left arrow for tab scrolling
			var upStyleName:String = selector.getStyle("upButtonStyleName");
			var upSelector:CSSStyleDeclaration = StyleManager.getStyleDeclaration("." + upStyleName);

			if(!upSelector)
			{
				upSelector = new CSSStyleDeclaration();
			}

			upSelector.defaultFactory = function():void
			{
				this.icon = DEFAULT_UP_BUTTON;
				this.fillAlphas = [1,1,1,1];
				this.cornerRadius = 0;
			}

			StyleManager.setStyleDeclaration("." + upStyleName, upSelector, false);

			// Style for the down arrow button
			var downStyleName:String = selector.getStyle("downButtonStyleName");
			var downSelector:CSSStyleDeclaration = StyleManager.getStyleDeclaration("." + downStyleName);

			if(!downSelector)
			{
				downSelector = new CSSStyleDeclaration();
			}

			downSelector.defaultFactory = function():void
			{
				this.icon = DEFAULT_DOWN_BUTTON;
				this.fillAlphas = [1,1,1,1];
				this.cornerRadius = 0;
			}

			StyleManager.setStyleDeclaration("." + downStyleName, downSelector, false);

		}
		*/
//		initializeStyles();

		override public function initialize():void {
			super.initialize();

			//initialize the default styles
//			ScrollableArrowMenu.initializeStyles();
		}

		/**
		 * We override createChildren so we can instantiate our up and down buttons
		 * and add them as children.
		 */
		override protected function createChildren():void {
			super.createChildren();

			upButton = new Button();

			downButton = new Button();

			upButton.styleName = getStyle("upButtonStyleName");
			downButton.styleName = getStyle("downButtonStyleName");

			upButton.setStyle('icon', DEFAULT_UP_BUTTON);
			downButton.setStyle('icon', DEFAULT_DOWN_BUTTON);

			addChild(upButton);
			addChild(downButton);

			upButton.addEventListener(MouseEvent.ROLL_OVER, startScrollingUp);
			upButton.addEventListener(MouseEvent.ROLL_OUT, stopScrolling);

			downButton.addEventListener(MouseEvent.ROLL_OVER, startScrollingDown);
			downButton.addEventListener(MouseEvent.ROLL_OUT, stopScrolling);

			//we're using an event listener to check if we should still be showing the
			//up and down buttons. This checks every time the list is scrolled at all.
			this.addEventListener(ScrollEvent.SCROLL, checkButtons);
		}

		override protected function createSubMenu():Menu {
			var menu :ScrollableArrowMenu= new ScrollableArrowMenu();
			menu.arrowScrollPolicy = this.arrowScrollPolicy;
			return  menu;
		}

		/**
		 * We've got to layout the up and down buttons now. They are overlaid on the list
		 * at the very top and bottom.
		 */
		override protected  function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void {
			super.updateDisplayList(unscaledWidth, unscaledHeight);


			var w:Number = unscaledWidth;

			if(verticalScrollBar && verticalScrollBar.visible) {
				w = unscaledWidth - ScrollBar.THICKNESS;
			}

			upButton.setActualSize(w, 15);
			downButton.setActualSize(w, 15);

			upButton.move(0, 0);
			downButton.move(0, measuredHeight - downButton.height);

			checkButtons(null);
		}

		/**
		 * @private
		 *
		 * This method is used to hide or show the up and down buttons, depending on where we
		 * are scrolled in the list and what the setting of arrowScrollPolicy is
		 */
		private function checkButtons(event:Event):void {
			if(this.arrowScrollPolicy == ScrollPolicy.AUTO) {
				upButton.visible = upButton.enabled = (this.verticalScrollPosition != 0);
				downButton.visible = downButton.enabled = (this.verticalScrollPosition != this.maxVerticalScrollPosition);
			}
			else if(this.arrowScrollPolicy == ScrollPolicy.ON) {
				upButton.visible = downButton.visible = true;
				upButton.enabled = (this.verticalScrollPosition != 0);
				downButton.enabled = (this.verticalScrollPosition != this.maxVerticalScrollPosition);
			}
			else {
				upButton.visible = upButton.enabled = downButton.visible = downButton.enabled = false;
			}
		}

		/**
		 * @private
		 *
		 * We start a timer that updates the verticalScrollPosition at a regular interval
		 * until the mouse rolls off the button.
		 */
		private function startScrollingUp(event:Event):void {
			if(timer && timer.running) {
				timer.stop();
			}

			timer = new Timer(this.scrollSpeed);
			timer.addEventListener(TimerEvent.TIMER, scrollUp);

			timer.start();
		}

		/**
		 * @private
		 */
		private function startScrollingDown(event:Event):void {
			if(timer && timer.running) {
				timer.stop();
			}

			timer = new Timer(this.scrollSpeed);
			timer.addEventListener(TimerEvent.TIMER, scrollDown);

			timer.start();
		}

		/**
		 * @private
		 */
		private function stopScrolling(event:Event):void {
			event.currentTarget.removeEventListener(MouseEvent.MOUSE_UP, stopScrolling);

			if(timer && timer.running) {
				timer.stop();
			}
		}

		/**
		 * @private
		 */
		private function scrollUp(event:TimerEvent = null):void {
			if(this.verticalScrollPosition - scrollJump > 0) {
				this.verticalScrollPosition -= scrollJump;
//				this.selectedIndex += scrollJump;
//				this.selectedIndex = Math.min(listItems.length - this.verticalScrollPosition - 1, this.selectedIndex)

			}
			else {
				this.verticalScrollPosition = 0;
			}

			checkButtons(null);
		}

		/**
		 * @private
		 */
		private function scrollDown(event:TimerEvent = null):void {
			if(this.verticalScrollPosition + scrollJump < this.maxVerticalScrollPosition) {
				this.verticalScrollPosition += scrollJump;
//				this.selectedIndex -= scrollJump;
//				this.selectedIndex = Math.max(-1, this.selectedIndex)
			}
			else {
				this.verticalScrollPosition = this.maxVerticalScrollPosition;
			}

			checkButtons(null);
		}

		override protected function mouseWheelHandler(event:MouseEvent):void
		{
			super.mouseWheelHandler(event);

			if (event.delta < 0)
				scrollDown();
			if (event.delta > 0)
				scrollUp();
		}

		override protected function showPrevious(): void
		{
			scrollUp();
		}
		override protected function showNext(): void
		{
			scrollDown();
		}
	}
}