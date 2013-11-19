package com.iblsoft.flexiweather.ogc.wfs
{
	import com.iblsoft.flexiweather.ogc.editable.IClosableCurve;
	import com.iblsoft.flexiweather.ogc.editable.WFSFeatureEditable;
	import com.iblsoft.flexiweather.ogc.editable.WFSFeatureEditableWithBaseTimeAndValidityAndAnnotation;
	import com.iblsoft.flexiweather.proj.Coord;
	import com.iblsoft.flexiweather.utils.AnnotationBox;
	import com.iblsoft.flexiweather.utils.CubicBezier;
	import com.iblsoft.flexiweather.utils.CurveLineSegment;
	import com.iblsoft.flexiweather.utils.CurveLineSegmentRenderer;
	import com.iblsoft.flexiweather.utils.anticollision.AnticollisionLayout;
	import com.iblsoft.flexiweather.utils.anticollision.AnticollisionLayoutObject;
	import com.iblsoft.flexiweather.utils.anticollision.IAnticollisionLayoutObject;
	import com.iblsoft.flexiweather.utils.geometry.ILineSegmentApproximableBounds;
	import com.iblsoft.flexiweather.widgets.InteractiveWidget;
	
	import flash.display.Sprite;
	import flash.geom.Point;

	public class WFSFeatureEditableSpriteWithAnnotation extends WFSFeatureEditableSprite implements ILineSegmentApproximableBounds, IAnticollisionLayoutObject
	{
		private var _annotation: AnnotationBox;
		
		public function WFSFeatureEditableSpriteWithAnnotation(feature: WFSFeatureEditable)
		{
			super(feature);
		}
		

		public function get annotation():AnnotationBox
		{
			return _annotation;
		}

		public function set annotation(value:AnnotationBox):void
		{
			_annotation = value;
		}

		public function update(feature: WFSFeatureEditableWithBaseTimeAndValidityAndAnnotation, annotation: AnnotationBox, blackColor: uint, labelLayout: AnticollisionLayout, pt: Point): void
		{
			
		}
	}
}
