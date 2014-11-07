package com.iblsoft.flexiweather.ogc.editable
{
	import com.iblsoft.flexiweather.ogc.FeatureUpdateContext;
	import com.iblsoft.flexiweather.ogc.editable.IObjectWithBaseTimeAndValidity;
	import com.iblsoft.flexiweather.ogc.editable.WFSFeatureEditableCurve;
	import com.iblsoft.flexiweather.ogc.editable.WFSFeatureEditableMode;
	import com.iblsoft.flexiweather.ogc.editable.data.FeatureData;
	import com.iblsoft.flexiweather.ogc.editable.data.FeatureDataReflection;
	import com.iblsoft.flexiweather.ogc.wfs.IWFSCurveFeature;
	import com.iblsoft.flexiweather.ogc.wfs.WFSFeatureEditableSprite;
	import com.iblsoft.flexiweather.utils.AnnotationBox;
	import com.iblsoft.flexiweather.utils.CubicBezier;
	import com.iblsoft.flexiweather.utils.ICurveRenderer;
	import com.iblsoft.flexiweather.utils.ISO8601Parser;
	import com.iblsoft.flexiweather.utils.anticollision.AnticollisionLayout;
	import com.iblsoft.flexiweather.utils.draw.DrawMode;
	import com.iblsoft.flexiweather.widgets.InteractiveLayer;

	import flash.display.DisplayObject;
	import flash.display.Graphics;
	import flash.geom.Point;

	import mx.collections.ArrayCollection;

	public class WFSFeatureEditableCurveWithBaseTimeAndValidityAndAnnotation extends WFSFeatureEditableCurveWithBaseTimeAndValidity implements IObjectWithBaseTimeAndValidity, IWFSCurveFeature
	{
//		protected var m_baseTime: Date;
//		protected var m_validity: Date;
//		protected var m_curvePoints: Array;
//
//		protected var m_featureData: FeatureData;

		public function get annotation():AnnotationBox
		{
			if (m_featureData)
			{
				var reflection: FeatureDataReflection = m_featureData.getReflectionAt(m_featureData.reflectionsIDs[0]);
				return getAnnotationForReflectionAt(reflection.reflectionDelta);
			}
			return null;
		}

		override public function get getAnticollisionObject(): DisplayObject
		{
			return annotation;
		}

		public function WFSFeatureEditableCurveWithBaseTimeAndValidityAndAnnotation(
				s_namespace: String, s_typeName: String, s_featureId: String)
		{
			super(s_namespace, s_typeName, s_featureId);
		}

		override protected function drawCurve():void
		{
			drawAnnotation();
		}

		public function createAnnotation(): AnnotationBox
		{
			return null;
		}

		public function drawAnnotation(): void
		{
			var annotation: AnnotationBox;
			var reflection: FeatureDataReflection;
			var _addToLabelLayout: Boolean;

			var a_points: Array = getPoints();

			//create sprites for reflections
			if (m_featureData && m_featureData.reflections)
			{
				var displaySprite: WFSFeatureEditableSprite;
				var pointsCount: int = a_points.length;
				var ptAvg: Point;
				var gr: Graphics;

				//				m_featureData.debug();

				graphics.clear();

				var reflectionIDs: Array = m_featureData.reflectionsIDs;

				for (var i: int = 0; i < totalReflections; i++)
				{
					var reflectionDelta: int = reflectionIDs[i];

					reflection = m_featureData.getReflectionAt(reflectionDelta);
					if (reflection)
					{
						if (m_featureData)
							ptAvg = m_featureData.getReflectionAt(reflection.reflectionDelta).center;
						else if (pointsCount == 1)
							ptAvg = a_points[0] as Point;

						displaySprite = getDisplaySpriteForReflectionAt(reflectionDelta);
						gr = displaySprite.graphics;

						if(a_points.length <= 1)
						{
							displaySprite.clear();
						} else {
							var renderer: ICurveRenderer = getRenderer(reflectionDelta);
							drawFeatureData(renderer, m_featureData);

							displaySprite.points = reflection.points;

							annotation = getAnnotationForReflectionAt(reflectionDelta);
							if (!annotation )
							{
								annotation = createAnnotation();
								addAnnotationForReflectionAt(reflectionDelta, annotation);
							}

							updateAnnotation(annotation, ptAvg);

							if (!mb_spritesAddedToLabelLayout && master)
							{
								master.container.labelLayout.addObstacle(displaySprite, master);
								master.container.labelLayout.addObject(annotation, master, [displaySprite], i);
								_addToLabelLayout = true;
							}

							master.container.labelLayout.updateObjectReferenceLocation(annotation);
						}
					}
				}

				if (!mb_spritesAddedToLabelLayout && _addToLabelLayout)
					mb_spritesAddedToLabelLayout = true;
			}
		}

		public function updateAnnotation(annotation: AnnotationBox, annotationPosition: Point, text: String = ""): void
		{

		}

		public function removeFromLabelLayout(annotation: AnnotationBox, displaySprite: WFSFeatureEditableSprite, labelLayout: AnticollisionLayout): void
		{
			labelLayout.removeObject(this);
			labelLayout.removeObject(annotation);
		}

		public function addToLabelLayout(annotation: AnnotationBox, displaySprite: WFSFeatureEditableSprite, layer: InteractiveLayer, labelLayout: AnticollisionLayout, i_reflection: uint): void
		{
			labelLayout.addObstacle(displaySprite, layer);
			labelLayout.addObject(annotation,  layer,  [displaySprite], i_reflection);
		}
	}

}