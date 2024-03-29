package com.iblsoft.flexiweather.ogc.editable.features.curves.withAnnotation
{
	import com.iblsoft.flexiweather.ogc.FeatureUpdateContext;
	import com.iblsoft.flexiweather.ogc.InteractiveLayerFeatureBase;
	import com.iblsoft.flexiweather.ogc.InteractiveLayerWFS;
	import com.iblsoft.flexiweather.ogc.data.ReflectionData;
	import com.iblsoft.flexiweather.ogc.editable.WFSFeatureEditableClosableCurveWithBaseTimeAndValidity;
	import com.iblsoft.flexiweather.ogc.editable.WFSFeatureEditableClosableCurveWithBaseTimeAndValidityAndAnnotation;
	import com.iblsoft.flexiweather.ogc.editable.WFSFeatureEditableCurveWithBaseTimeAndValidityAndAnnotation;
	import com.iblsoft.flexiweather.ogc.editable.annotations.ThunderstormAreaAnnotation;
	import com.iblsoft.flexiweather.ogc.editable.data.FeatureDataReflection;
	import com.iblsoft.flexiweather.ogc.wfs.IWFSFeatureWithAnnotation;
	import com.iblsoft.flexiweather.ogc.wfs.IWFSFeatureWithReflection;
	import com.iblsoft.flexiweather.ogc.wfs.WFSFeatureEditableSprite;
	import com.iblsoft.flexiweather.proj.Coord;
	import com.iblsoft.flexiweather.symbology.IcingCurveRenderer;
	import com.iblsoft.flexiweather.symbology.StyledLineCurveRenderer;
	import com.iblsoft.flexiweather.utils.AnnotationBox;
	import com.iblsoft.flexiweather.utils.CubicBezier;
	import com.iblsoft.flexiweather.utils.ICurveRenderer;
	import com.iblsoft.flexiweather.utils.draw.DrawMode;
	import com.iblsoft.flexiweather.utils.geometry.ILineSegmentApproximableBounds;
	import com.iblsoft.flexiweather.utils.geometry.LineSegment;

	import flash.display.BitmapData;
	import flash.display.Graphics;
	import flash.geom.Point;

	import mx.collections.ArrayCollection;

	/**
	 * For front styles see for example http://en.wikipedia.org/wiki/Weather_front
	 **/
	public class WFSFeatureEditableThunderstormArea extends WFSFeatureEditableClosableCurveWithBaseTimeAndValidityAndAnnotation
		implements IWFSFeatureWithAnnotation, IWFSFeatureWithReflection
	{

		public var type: String;


		public function WFSFeatureEditableThunderstormArea(s_namespace: String, s_typeName: String, s_featureId: String)
		{
			super(s_namespace, s_typeName, s_featureId);
		}

		override public function getRenderer(reflection: int): ICurveRenderer
		{
			var i_color: uint = getCurrentColor(0xfc0019);
			var gr: Graphics = getRendererGraphics(reflection);

			var renderer: StyledLineCurveRenderer = new StyledLineCurveRenderer(gr, 2, i_color, 1, StyledLineCurveRenderer.STYLE_DASHDOT);
			return renderer;
		}

		override public function getDisplaySpriteForReflection(id: int): WFSFeatureEditableSprite
		{
			return new ThunderstormAreaSprite(this);
		}

		override public function createAnnotation(): AnnotationBox
		{
			return new ThunderstormAreaAnnotation();
		}

		override public function updateAnnotation(annotation: AnnotationBox, annotationPosition: Point, text: String = ""): void
		{
			if (!annotationPosition)
				return;

			if (annotation is ThunderstormAreaAnnotation)
			{
				var thunderstormAreaAnnotation: ThunderstormAreaAnnotation = annotation as ThunderstormAreaAnnotation;

				annotation = thunderstormAreaAnnotation;

				var showAnnotations: Boolean = m_points && m_points.length > 1 && visible;
				var i_color: uint = getCurrentColor(0xfc0019);

				thunderstormAreaAnnotation.color = i_color;
				thunderstormAreaAnnotation.thunderstormAreaData = this;
				thunderstormAreaAnnotation.visible = showAnnotations;
				thunderstormAreaAnnotation.x = annotationPosition.x - thunderstormAreaAnnotation.width / 2.0;
				thunderstormAreaAnnotation.y = annotationPosition.y - thunderstormAreaAnnotation.height / 2.0;
				thunderstormAreaAnnotation.update();
			}
		}


		public override function cleanup(): void
		{

			if (master && master.container && master.container.labelLayout)
			{
				var thunderstormAreaTextInfo: ThunderstormAreaAnnotation;
				var reflection: FeatureDataReflection;
				var displaySprite: WFSFeatureEditableSprite;

				var reflectionIDs: Array = m_featureData.reflectionsIDs;

				for (var i: int = 0; i < totalReflections; i++)
				{
					var reflectionDelta: int = reflectionIDs[i];

					reflection = m_featureData.getReflectionAt(reflectionDelta);

					thunderstormAreaTextInfo = getAnnotationForReflectionAt(reflectionDelta) as ThunderstormAreaAnnotation;
					displaySprite = getDisplaySpriteForReflectionAt(reflectionDelta);

					master.container.labelLayout.removeObject(thunderstormAreaTextInfo);
					master.container.labelLayout.removeObject(displaySprite);
				}
			}

			super.cleanup();
		}

		/**
		 *
		 */
		protected function beginFill(): void
		{
			if (isCurveClosed()){
				graphics.beginBitmapFill(createFillBitmap(), null, true, false);
			}
		}

		/**
		 *
		 */
		protected function endFill(): void
		{
			if (isCurveClosed()){
				graphics.endFill();
			}
		}

		/**
		 *
		 */
		protected function createFillBitmap(): BitmapData
		{
			return(new BitmapData(16, 16, true, 0x50FFFFFF));
		}

		/**
		 *
		 */
		protected function getHexARGB(color: uint, n_alpha: Number = 255): uint
		{
			var r: uint = ((color & 0xFF0000) >> 16);
			var g: uint = ((color & 0x00FF00) >> 8);
			var b: uint = ((color & 0x0000FF));

			var ret: uint = n_alpha << 24;
			ret += (r << 16);
			ret += (g << 8);
			ret += (b);

			return(ret);
		}

		override public function toInsertGML(xmlInsert: XML): void
		{
			var gml: Namespace = new Namespace("http://www.opengis.net/gml");
			super.toInsertGML(xmlInsert);
			addInsertGMLProperty(xmlInsert, null, "type", type);
		}

		override public function toUpdateGML(xmlUpdate: XML): void
		{
			super.toUpdateGML(xmlUpdate);
			addUpdateGMLProperty(xmlUpdate, null, "type", type);
		}

		override public function fromGML(gml: XML): void
		{
			super.fromGML(gml);
			var ns: Namespace = new Namespace(ms_namespace);
			type = gml.ns::type[0];
		}

		public function getType(): String
		{
			return(type);
		}
	}
}


import com.iblsoft.flexiweather.ogc.editable.WFSFeatureEditable;
import com.iblsoft.flexiweather.ogc.editable.features.curves.withAnnotation.WFSFeatureEditableThunderstormArea;
import com.iblsoft.flexiweather.ogc.wfs.WFSFeatureEditableSprite;
import com.iblsoft.flexiweather.ogc.wfs.WFSFeatureEditableSpriteWithAnnotation;
import com.iblsoft.flexiweather.utils.CubicBezier;
import com.iblsoft.flexiweather.utils.geometry.LineSegment;
import com.iblsoft.flexiweather.widgets.InteractiveWidget;

import flash.geom.Point;

class ThunderstormAreaSprite extends WFSFeatureEditableSpriteWithAnnotation
{

	public function ThunderstormAreaSprite(feature: WFSFeatureEditable)
	{
		super(feature);
	}

	override public function getPointsForLineSegmentApproximationOfBounds(): Array
	{
		var thunderstormArea: WFSFeatureEditableThunderstormArea = _feature as WFSFeatureEditableThunderstormArea;
		var iw: InteractiveWidget = thunderstormArea.master.container;

		//distanceValidator, pixelDistanceValidator, datelineBetweenPixelPositions
		var pts: Array = CubicBezier.calculateHermitSpline(points, thunderstormArea.isCurveClosed(), iw.pixelDistanceValidator, iw.datelineBetweenPixelPositions);

		return pts;
	}
}
