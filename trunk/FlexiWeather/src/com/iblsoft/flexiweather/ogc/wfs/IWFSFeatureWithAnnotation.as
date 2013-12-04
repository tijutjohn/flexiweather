package com.iblsoft.flexiweather.ogc.wfs
{
	import com.iblsoft.flexiweather.ogc.FeatureBase;
	import com.iblsoft.flexiweather.utils.AnnotationBox;
	import com.iblsoft.flexiweather.utils.anticollision.AnticollisionLayout;
	import com.iblsoft.flexiweather.widgets.InteractiveLayer;
	
	import flash.geom.Point;

	public interface IWFSFeatureWithAnnotation
	{
		function get annotation(): AnnotationBox;
		function createAnnotation(): AnnotationBox;
		function drawAnnotation(): void;
		function updateAnnotation(annotation: AnnotationBox, annotationPosition: Point, text: String = ""): void;
		function addToLabelLayout(annotation: AnnotationBox, displaySprite: WFSFeatureEditableSprite, layer: InteractiveLayer, labelLayout: AnticollisionLayout, i_reflection: uint): void
		function removeFromLabelLayout(annotation: AnnotationBox, displaySprite: WFSFeatureEditableSprite, labelLayout: AnticollisionLayout): void;
	}
}
