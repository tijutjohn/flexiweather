package com.iblsoft.flexiweather.ogc.wfs
{
	import com.iblsoft.flexiweather.ogc.data.WFSEditableReflectionData;

	public interface IWFSFeatureWithReflection
	{
		function get totalReflections(): int;
		function getReflection(id: int): WFSEditableReflectionData;
	}
}