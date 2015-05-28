/***********************************************************************************************
 *
 *	Created:	08.04.2015
 *	Authors:	Franto Kormanak
 *
 *	Copyright (c) 2015, IBL Software Engineering spol. s r. o., <escrow@iblsoft.com>.
 *	All rights reserved. Unauthorised use, modification or redistribution is prohibited.
 *
 ***********************************************************************************************/

package com.iblsoft.flexiweather.widgets.controls
{
	import spark.components.Button;
	import spark.components.HGroup;
	import spark.components.Label;
	import spark.components.ToggleButton;
	import flash.events.Event;

	[Event(name="notificationVisibleChange",type="flash.events.Event")]
	public class NotifyToggleButton extends ToggleButton
	{
		public static const NOTIFICATIONVISIBLE_CHANGE_EVENT:String = "notificationVisibleChange";

		private var _notificationVisible: Boolean;

		[SkinPart (required="true")]
		public var newItemslabelDisplay: Label;

		private var _newItemsCount: int;
		private var _newItemsCountChanged: Boolean;


		[Bindable(event="notificationVisibleChange")]
		public function get notificationVisible():Boolean
		{
			return _notificationVisible;
		}

		public function set notificationVisible(value:Boolean):void
		{
			if (_notificationVisible != value)
			{
				_notificationVisible = value;
				dispatchEvent(new Event(NOTIFICATIONVISIBLE_CHANGE_EVENT));
			}
		}

		[Bindable]
		public function get newItemsCount():int
		{
			return _newItemsCount;
		}

		public function set newItemsCount(value:int):void
		{
			if (_newItemsCount != value)
			{
				_newItemsCount = value;
				_newItemsCountChanged = true;
				invalidateProperties();
			}
		}

		public function NotifyToggleButton()
		{
			super();
		}

		override protected function commitProperties(): void
		{
			super.commitProperties();

			if (_newItemsCountChanged)
			{
				newItemslabelDisplay.text = newItemsCount.toString();
				notificationVisible = _newItemsCount > 0;
				notify();
				_newItemsCountChanged = false;
			}
		}

		override protected function getCurrentSkinState():String
		{
			var skinState: String = super.getCurrentSkinState();

			if (_notifyActive)
			{
				_notifyWasPreviousState = true;
				if (selected)
					skinState = "notifyAndSelected";
				else
					skinState = "notify";
			} else {
				if (_notifyWasPreviousState)
				{
					if (selected)
						skinState = "upAndSelected";
					else
						skinState = "up";
					_notifyWasPreviousState = false;
				}
			}

			return skinState;
		}

		private var _notifyActive: Boolean;
		private var _notifyWasPreviousState: Boolean;
		public function notify(): void
		{
			_notifyActive = true;
			invalidateSkinState()
		}

		public function notifyPhaseFinished(): void
		{
			_notifyActive = false;
			invalidateSkinState();
		}
	}
}