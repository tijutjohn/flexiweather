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
		private var _viewData: Array;
		
		private var _customData: Object;
		
		public function MultiViewConfiguration()
		{
		}


		public function get viewData():Array
		{
			return _viewData;
		}

		public function set viewData(value:Array):void
		{
			_viewData = value;
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