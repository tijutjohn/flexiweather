package com.iblsoft.flexiweather.widgets.errors
{
	public class ErrorJournalDataItem
	{
		[Bindable]
		public var errorCode: int;
		[Bindable]
		public var errorMessage: String;
		public var errorObject: Object;
		
		public function ErrorJournalDataItem(errorCode: int, errorMessage: String, errorObject: Object)
		{
			this.errorCode = errorCode;
			this.errorMessage = errorMessage;
			this.errorObject = errorObject;
		}
	}
}