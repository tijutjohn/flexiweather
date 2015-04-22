package com.iblsoft.flexiweather.utils
{
	import flash.display.Graphics;
	import flash.geom.Point;

	/**
	 * Abstract interface for curve rendering (user by CubicBezier)
	 **/
	public interface ICurveRenderer
	{
		function clear(): void;
		function start(x: Number, y: Number): void;
		function finish(x: Number, y: Number): void;
		function firstPoint(x: Number, y: Number): void;
		function lastPoint(x: Number, y: Number): void;
		function moveTo(x: Number, y: Number): void;
		function lineTo(x: Number, y: Number): void;
		function curveTo(controlX: Number, controlY: Number, anchorX: Number, anchorY: Number): void;
		function drawRoundRect(x: Number, y: Number, w: Number, h: Number, ellipseWidth: Number, ellipseHeight: Number): void;
	}
}
