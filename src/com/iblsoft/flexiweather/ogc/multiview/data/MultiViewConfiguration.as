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
		
		public function MultiViewConfiguration()
		{
		}
	}
}