package com.iblsoft.flexiweather.widgets.errors
{
	import com.iblsoft.flexiweather.utils.LoggingUtils;
	import com.iblsoft.flexiweather.utils.LoggingUtilsErrorEvent;
	
	import flash.display.DisplayObject;
	import flash.events.MouseEvent;
	import flash.ui.Mouse;
	
	import mx.collections.ArrayCollection;
	import mx.core.FlexGlobals;
	import mx.managers.PopUpManager;
	
	import spark.components.Button;
	import spark.components.Group;

	public class ErrorJournal extends Group
	{
		private var _button: Button;
		private var errors: ArrayCollection;
		
		public function ErrorJournal()
		{
			errors = new ArrayCollection();
		}
		
		override protected function createChildren(): void
		{
			super.createChildren();
			
			_button = new Button();
			
			LoggingUtils.instance.addEventListener(LoggingUtilsErrorEvent.ERROR_LOG_ENTRY, onErrorLogEntry);
		}
		
		private function onErrorLogEntry(event: LoggingUtilsErrorEvent): void
		{
			var data: ErrorJournalDataItem = new ErrorJournalDataItem(-1, event.message, event.errorObject);
			errors.addItem(data);
			
			invalidateProperties();
		}
		
		override protected function childrenCreated(): void
		{
			_button.addEventListener(MouseEvent.CLICK, onWarningsButtonClicked);
			_button.visible = false;
			addElement(_button);
		}
		
		override protected function commitProperties():void
		{
			super.commitProperties();
			
			if (_button)
			{
				_button.label = "Show Warnings";
				
				if (errors && errors.length > 0)
					_button.visible = true;
				else
					_button.visible = false;
			}
			
		}
		
		private function onWarningsButtonClicked(event: MouseEvent): void
		{
			var popup: ErrorJournalPopup = new ErrorJournalPopup();
			
			popup.errors = errors;
			
			PopUpManager.addPopUp(popup, FlexGlobals.topLevelApplication as DisplayObject);
			PopUpManager.centerPopUp(popup);
			
		}
	}
}