package com.iblsoft.flexiweather.ogc.editable
{

	public interface IObjectWithBaseTimeAndValidity
	{
		function get baseTime(): Date
		function set baseTime(baseTime: Date): void
		function get validity(): Date
		function set validity(validity: Date): void
	}
}
