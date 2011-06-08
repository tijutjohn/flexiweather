package com.iblsoft.flexiweather.ogc
{
	import com.iblsoft.flexiweather.utils.AnnotationBox;

	public interface IWFSFeatureWithAnnotation
	{
		function get annotation(): AnnotationBox;	
	}
}