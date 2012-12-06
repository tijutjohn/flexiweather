package com.iblsoft.flexiweather.ogc.multiview.data
{
	public class MultiViewConfiguration
	{
		public var rows: int;
		public var columns: int;
		
		public var synchronizators: Array;
		
		/**
		 *  Data information for each view, if needed 
		 */		
		public var viewData: Array;
		
		private var _customData: Object;
		
		public function MultiViewConfiguration()
		{
		}

		/**
		 * In this object custom data can be stored, e.g. frame sychronisator can store timeStep here 
		 */
		public function get customData():Object
		{
			return _customData;
		}

		/**
		 * @private
		 */
		public function set customData(value:Object):void
		{
			_customData = value;
		}

	}
}