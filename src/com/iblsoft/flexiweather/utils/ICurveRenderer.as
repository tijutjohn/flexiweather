package com.iblsoft.flexiweather.utils
{
	import flash.display.Graphics;
	import flash.geom.Point;

	/**
	 * Abstract interface for curve rendering (user by CubicBezier)
	 **/
	public interface ICurveRenderer
	{
		function start(x: Number, y: Number): void;
		function finish(x: Number, y: Number): void;
		function moveTo(x: Number, y: Number): void;
		function lineTo(x: Number, y: Number): void;
		function curveTo(controlX: Number, controlY: Number, anchorX: Number, anchorY: Number): void;
	}
}
