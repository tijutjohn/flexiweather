package com.iblsoft.flexiweather.widgets.errors
{
	public class ErrorJournalDataItem
	{
		public var errorCode: int;
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