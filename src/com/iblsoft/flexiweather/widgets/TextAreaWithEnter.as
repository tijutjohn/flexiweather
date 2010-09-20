package com.iblsoft.flexiweather.widgets
{
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.events.TextEvent;
	import flash.ui.Keyboard;
	
	import mx.controls.TextArea;
	import mx.events.FlexEvent;

	/**
	 *  Dispatched when the user presses the Enter key.
	 *
	 *  @eventType mx.events.FlexEvent.ENTER
	 */
	[Event(name="enter", type="mx.events.FlexEvent")]
	
	public class TextAreaWithEnter extends TextArea
	{
		public function TextAreaWithEnter()
		{
			super();
			
			addEventListener(Event.CHANGE, onChange);
			addEventListener(TextEvent.TEXT_INPUT, onTextInput);
		}
		
		private function onChange(event: Event): void
		{
			trace("TextAreaWithEnter onChange");
			trace(text);
		}
		
		private function onTextInput(event:TextEvent):void
		{
			trace("TextAreaWithEnter onTextInput");
			
		}
		override protected function keyDownHandler(event:KeyboardEvent):void
		{
			super.keyDownHandler(event);
			trace("TextAreaWithEnter onKeyDown: " + event.keyCode + " SHIFT: " + event.shiftKey + " Ctrl: " + event.ctrlKey + " ALT: " + event.altKey);
			
			switch (event.keyCode)
	        {
	            case Keyboard.ENTER:
	            {
	            	if (!event.shiftKey)
	            	{
	                	dispatchEvent(new FlexEvent(FlexEvent.ENTER));
	                	event.preventDefault();
	             	} else {
	             		trace("ENTER (shift)");
	             		textField.text += 'TEST';
	             		textField.dispatchEvent( new Event( Event.CHANGE) );
	             	}
	                break;
	            }
		 	}
		}
		override protected function keyUpHandler(event:KeyboardEvent):void
		{
			super.keyUpHandler(event);
			trace("TextAreaWithEnter onKeyUp: " + event.keyCode + " SHIFT: " + event.shiftKey);
		}
		
	}
}