package com.iblsoft.flexiweather.utils
{

	public interface IObjectPoolObject
	{
		function isFree(): Boolean;
		function addedToPool(): void;
		function freeForReuse(): void;
	}
}
