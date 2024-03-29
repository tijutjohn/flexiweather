package com.iblsoft.flexiweather.widgets.data
{
	import com.iblsoft.flexiweather.utils.LoggingUtils;
	import com.iblsoft.flexiweather.utils.Serializable;
	import com.iblsoft.flexiweather.utils.Storage;

	import flash.events.EventDispatcher;

	public class InteractiveLayerLegendsOrientation extends EventDispatcher implements Serializable
	{
		public var label: String;
		public var horizontalAlign: String;
		public var horizontalDirection: String;
		public var verticalAlign: String;
		public var verticalDirection: String;

		public function InteractiveLayerLegendsOrientation(orientationShortcut: String = null)
		{
			if (orientationShortcut)
				updateFromShortcut(orientationShortcut);
		}

		public function serialize(storage:Storage):void
		{
			label = storage.serializeString('label', label);
			horizontalAlign = storage.serializeString('horizontal-align', horizontalAlign);
			horizontalDirection = storage.serializeString('horizontal-direction', horizontalDirection);
			verticalAlign = storage.serializeString('vertical-align', verticalAlign);
			verticalDirection = storage.serializeString('vertical-direction', verticalDirection);
		}


		public function updateFromShortcut(shortcut: String): void
		{
			switch(shortcut)
			{
				//Bottom - Top, Right
				case "BTR":
					label = 'Bottom - Top, Right';
					horizontalAlign = 'right';
					verticalAlign = 'bottom';
					horizontalDirection = 'none';
					verticalDirection = 'up';
					break;
				//Bottom - Top, Left
				case "BTL":
					label = 'Bottom - Top, Left';
					horizontalAlign = 'left';
					verticalAlign = 'bottom';
					horizontalDirection = 'none';
					verticalDirection = 'up';
					break;
				//Bottom, Left - Right
				case "BLR":
					label = 'Bottom, Left - Right';
					horizontalAlign = 'left';
					verticalAlign = 'bottom';
					horizontalDirection = 'right';
					verticalDirection = 'none';
					break;
				//Bottom, Right - Left
				case "BRL":
					label = 'Bottom, Right - Left';
					horizontalAlign = 'right';
					verticalAlign = 'bottom';
					horizontalDirection = 'left';
					verticalDirection = 'none';
					break;
				//Top, Left - Right
				case "TLR":
					label = 'Top, Left - Right';
					horizontalAlign = 'left';
					verticalAlign = 'top';
					horizontalDirection = 'right';
					verticalDirection = 'none';
					break;
				//Top, Right - Left
				case "TRL":
					label = 'Top, Right - Left';
					horizontalAlign = 'right';
					verticalAlign = 'top';
					horizontalDirection = 'left';
					verticalDirection = 'none';
					break;
				//Top - Bottom, Left
				case "TBL":
					label = 'Top - Bottom, Left';
					horizontalAlign = 'left';
					verticalAlign = 'top';
					horizontalDirection = 'none';
					verticalDirection = 'down';
					break;
				//Top - Bottom, Right
				case "TBR":
					label = 'Top - Bottom, Right';
					horizontalAlign = 'right';
					verticalAlign = 'top';
					horizontalDirection = 'none';
					verticalDirection = 'down';
					break;
			}
		}

		override public function toString(): String
		{
			return "InteractiveLayerLegendsOrientation: " +  label;
		}
	}
}