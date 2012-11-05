package com.iblsoft.flexiweather.ogc.editable
{

	public class WFSFeatureEditableMode
	{
		public static var STANDARD: int = 1;
		public static var ADD_POINTS: int = 2;
		public static var MOVE_POINTS: int = 3;
		public static var ADD_POINTS_WITH_MOVE_POINTS: int = 4;
		public static var ADD_POINTS_ON_CURVE: int = 5;
		public static var EDIT_WIND_BARBS_POINTS: int = 6;

		public function WFSFeatureEditableMode()
		{
		}
	}
}
