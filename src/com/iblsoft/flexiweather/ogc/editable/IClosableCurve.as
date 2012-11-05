package com.iblsoft.flexiweather.ogc.editable
{
	import com.iblsoft.flexiweather.proj.Coord;

	public interface IClosableCurve
	{
		function closeCurve(): void;
		function isCurveClosed(): Boolean;
		function openCurve(i_afterPointIndex: uint, cSplitPoint: Coord = null): void;
	}
}
