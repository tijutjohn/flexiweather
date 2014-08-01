package com.iblsoft.flexiweather.ogc.wfs
{
	import com.iblsoft.flexiweather.utils.ICurveRenderer;
	
	import flash.display.Graphics;

	public interface IWFSCurveFeature
	{
		function getRenderer(reflection: int): ICurveRenderer;
		function getRendererGraphics(reflection: int): Graphics;
	}
}