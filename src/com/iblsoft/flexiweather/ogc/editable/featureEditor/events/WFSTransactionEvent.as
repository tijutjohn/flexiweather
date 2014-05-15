package com.iblsoft.flexiweather.ogc.editable.featureEditor.events
{
	import flash.events.Event;
	
	public class WFSTransactionEvent extends Event
	{
		public static const TRANSACTION_COMPLETE: String = 'transactionComplete';
		public static const TRANSACTION_FAILED: String = 'transactionFailed';
		
		public var transactionType: String;
		
		protected var m_result: Object;
		
		public function get result(): Object
		{
			return m_result;
		}
		
		public function WFSTransactionEvent(type:String, transactionType: String, result: Object, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			super(type, bubbles, cancelable);
			
			this.transactionType = transactionType;
			m_result = result;
		}
		
		override public function clone():Event
		{
			var wte: WFSTransactionEvent = new WFSTransactionEvent(type, transactionType, m_result, bubbles, cancelable);
			return wte;
		}
	}
}