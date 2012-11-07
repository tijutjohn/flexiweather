package com.iblsoft.flexiweather.ogc.multiview.data
{
	public class MultiViewConfiguration
	{
		public var rows: int;
		public var columns: int;
		
		/**
		 * If selectesIndex == -1, there is no selection 
		 */		
		public var selectedIndex: int;
		
		public var synchronizators: Array;
		
		/**
		 *  Data information for each view, if needed 
		 */		
		public var viewData: Array;
		
		/**
		 * In this object custom data can be stored, e.g. frame sychronisator can store timeStep here 
		 */		
		public var customData: Object;
		
		public function MultiViewConfiguration()
		{
		}
	}
}