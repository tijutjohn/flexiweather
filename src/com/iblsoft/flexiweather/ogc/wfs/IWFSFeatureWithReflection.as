package com.iblsoft.flexiweather.ogc.wfs
{
	import com.iblsoft.flexiweather.ogc.data.WFSEditableReflectionData;
	import com.iblsoft.flexiweather.ogc.data.WFSEditableReflectionDictionary;

	public interface IWFSFeatureWithReflection
	{
		function get totalReflections(): int;
		function get reflectionDictionary(): WFSEditableReflectionDictionary;
		function getReflection(id: int): WFSEditableReflectionData;
	}
}
