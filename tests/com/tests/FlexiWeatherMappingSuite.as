package com.tests
{
	import com.tests.interactiveWidget.IWMapFunctions;
	import com.tests.interactiveWidget.MapBBoxToProjectionExtentParts;
	import com.tests.interactiveWidget.MapBBoxToViewReflections;
	import com.tests.interactiveWidget.MapCoordToViewReflections;

	[Suite]
	[RunWith("org.flexunit.runners.Suite")]
	public class FlexiWeatherMappingSuite
	{
		public var test1:com.tests.interactiveWidget.IWMapFunctions;
		public var testExternParts:com.tests.interactiveWidget.MapBBoxToProjectionExtentParts;
		public var testBBoxwReflections:com.tests.interactiveWidget.MapBBoxToViewReflections;
		public var testCoordReflections:com.tests.interactiveWidget.MapCoordToViewReflections;

	}
}