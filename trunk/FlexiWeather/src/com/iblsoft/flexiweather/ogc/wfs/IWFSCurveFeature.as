package com.iblsoft.flexiweather.ogc.wfs
{
	import com.iblsoft.flexiweather.utils.ICurveRenderer;

	public interface IWFSCurveFeature
	{
		function getRenderer(reflection: int): ICurveRenderer;
	}
}