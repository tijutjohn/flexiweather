package com.iblsoft.flexiweather.ogc.wfs
{
	import com.iblsoft.flexiweather.utils.AnnotationBox;

	public interface IWFSFeatureWithAnnotation
	{
		function get annotation(): AnnotationBox;	
	}
}