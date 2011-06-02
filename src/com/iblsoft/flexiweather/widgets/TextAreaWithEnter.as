package com.iblsoft.flexiweather.widgets
{
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.events.TextEvent;
	import flash.ui.Keyboard;
	
	import mx.events.FlexEvent;
	
	import spark.components.TextArea;

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
		private var _shiftPressed: Boolean;
		
		override protected function keyDownHandler(event:KeyboardEvent):void
		{
			super.keyDownHandler(event);
			
			
			switch (event.keyCode)
	        {
	            case Keyboard.SHIFT:
	            	_shiftPressed = true;
	            	break;
	            	
	            case Keyboard.ENTER:
	            {
	            	if (event.shiftKey && !_shiftPressed)
	            	{
	            		_shiftPressed = true;
	            	}
	            	if (!_shiftPressed)
	            	{
	            		if (textDisplay.text.length > 0)
	            		{
	                		dispatchEvent(new FlexEvent(FlexEvent.ENTER));
		                	event.preventDefault();
	              		} else {
	              			event.preventDefault();
	              			event.stopImmediatePropagation();
	              			event.stopPropagation();
	              			return;
	              		}
	                	
	                	textDisplay.text = '';
//	             		textDisplay.validateNow();
//	             		textDisplay.dispatchEvent( new Event( Event.CHANGE) );
	             		
	             	} else {
	             		trace("ENTER (shift)");
	             		textDisplay.text += '\r';
//	             		textDisplay.validateNow();
//	             		textDisplay.dispatchEvent( new Event( Event.CHANGE) );
	             		
//	             		selectionBeginIndex = textDisplay.text.length;
//	             		selectionEndIndex = textDisplay.text.length;
	             	}
	                break;
	            }
		 	}
		 	
		 	trace("TextAreaWithEnter onKeyDown: " + event.keyCode + " SHIFT: " + event.shiftKey + " /_shiftPressed: " + _shiftPressed + " Ctrl: " + event.ctrlKey + " ALT: " + event.altKey);
		 	
		}
		override protected function keyUpHandler(event:KeyboardEvent):void
		{
			super.keyUpHandler(event);
//			trace("TextAreaWithEnter onKeyUp: " + event.keyCode + " SHIFT: " + event.shiftKey);
			
			switch (event.keyCode)
	        {
	            case Keyboard.SHIFT:
	            	_shiftPressed = false;
	            	break;
	        }
		}
		
	}
}