package com.iblsoft.flexiweather.ogc.editable
{
	import com.iblsoft.flexiweather.ogc.FeatureBase;
	import com.iblsoft.flexiweather.ogc.FeatureUpdateContext;
	import com.iblsoft.flexiweather.ogc.GMLUtils;
	import com.iblsoft.flexiweather.ogc.editable.WFSFeatureEditable;
	import com.iblsoft.flexiweather.ogc.editable.data.FeatureData;
	import com.iblsoft.flexiweather.ogc.editable.data.FeatureDataPoint;
	import com.iblsoft.flexiweather.ogc.editable.data.FeatureDataReflection;
	import com.iblsoft.flexiweather.ogc.wfs.IWFSIconSprite;
	import com.iblsoft.flexiweather.ogc.wfs.WFSFeatureEditableSprite;
	import com.iblsoft.flexiweather.ogc.wfs.WFSFeatureEditableSpriteWithAnnotation;
	import com.iblsoft.flexiweather.utils.AnnotationBox;
	import com.iblsoft.flexiweather.utils.ISO8601Parser;
	import com.iblsoft.flexiweather.utils.anticollision.AnticollisionLayout;
	import com.iblsoft.flexiweather.utils.draw.DrawMode;
	import com.iblsoft.flexiweather.widgets.InteractiveLayer;

	import flash.display.DisplayObject;
	import flash.display.Graphics;
	import flash.geom.Point;

	import mx.collections.ArrayCollection;

	public class WFSFeatureEditableWithBaseTimeAndValidityAndAnnotation extends WFSFeatureEditableWithBaseTimeAndValidity implements IObjectWithBaseTimeAndValidity
	{
		public function get annotation():AnnotationBox
		{
			if (m_featureData)
			{
				var reflection: FeatureDataReflection = m_featureData.getReflectionAt(0);
				return getAnnotationForReflectionAt(reflection.reflectionDelta);
			}
			return null;
		}

		override public function get getAnticollisionObject(): DisplayObject
		{
			return annotation;
		}

		public function WFSFeatureEditableWithBaseTimeAndValidityAndAnnotation(
				s_namespace: String, s_typeName: String, s_featureId: String)
		{
			super(s_namespace, s_typeName, s_featureId);
		}

		override public function update(changeFlag:FeatureUpdateContext):void
		{
			super.update(changeFlag);

			drawAnnotation();

		}
		public function createAnnotation(): AnnotationBox
		{
			return null;
		}

		public function drawAnnotation(): void
		{
			var a_points: Array = getPoints();

			var annotation: AnnotationBox;
			var reflection: FeatureDataReflection;
			var _addToLabelLayout: Boolean;
			var displaySpriteWithAnnotation: WFSFeatureEditableSpriteWithAnnotation;
			var gr: Graphics;

			graphics.clear();
			//create sprites for reflections


			var reflectionIDs: Array = m_featureData.reflectionsIDs;

			for (var i: int = 0; i < totalReflections; i++)
			{
				var reflectionDelta: int = reflectionIDs[i];

				reflection = m_featureData.getReflectionAt(reflectionDelta);
				if (reflection)
				{
					reflection.validate();

					displaySpriteWithAnnotation = getDisplaySpriteForReflectionAt(reflectionDelta) as WFSFeatureEditableSpriteWithAnnotation;
					gr = displaySpriteWithAnnotation.graphics;

					if (!displaySpriteWithAnnotation.parent)
						addChild(displaySpriteWithAnnotation);

					annotation = getAnnotationForReflectionAt(reflectionDelta);
					if (!annotation )
					{
						annotation = createAnnotation();
						addAnnotationForReflectionAt(reflectionDelta, annotation);
					}

					var pt: Point = Point(reflection.editablePoints[0]);
					if (pt)
					{
						if (mb_isIconFeature && !displaySpriteWithAnnotation.bitmapLoaded && m_loadedIconBitmapData)
						{
							if (displaySpriteWithAnnotation is IWFSIconSprite)
							{
								(displaySpriteWithAnnotation as IWFSIconSprite).setBitmap(m_loadedIconBitmapData, pt, 0);
							}
						}
//						trace("WFSFeatureEditableWithBaseTimeAndValidityAndAnnotation PT is  " + pt);
						displaySpriteWithAnnotation.points = [pt];


						var isAnnotationInAnticollision: Boolean
						var isDisplayObjectInAnticollision: Boolean
						if (master)
						{
							isDisplayObjectInAnticollision = master.container.labelLayout.isObjectInside(displaySpriteWithAnnotation);
							isAnnotationInAnticollision = master.container.labelLayout.isObjectInside(annotation);
							//							if (!mb_spritesAddedToLabelLayout && master)
//							if (featureIsVisible)
//							{
//
//								var annotationDatelineSplitVisibility: Boolean = checkAnnotationVisibilityForSplittedFeature(annotationPositions, annotationPositions[reflectionDelta] as AnnotationPosition, projectionWidth / 2);

								//								trace("Reflection : " + reflectionDelta + " isAnnotationInAnticollision: " + isAnnotationInAnticollision + " annotationDatelineSplitVisibility: " + annotationDatelineSplitVisibility);

								if (!isDisplayObjectInAnticollision)
								{
									//if object is not in anticollision layout and it should be there, we should add it
									displaySpriteWithAnnotation.visible = true;
									master.container.labelLayout.addObstacle(displaySpriteWithAnnotation, master);
								} else {
									trace("\tDisplaySprite is already in Anticollision");
								}
								if (!isAnnotationInAnticollision)
								{
									//if annotation is not in anticollision layout and it should be there, we should add it
//									if (annotationDatelineSplitVisibility)
//									{
										annotation.visible = true;
										master.container.labelLayout.addObject(annotation, master, [displaySpriteWithAnnotation], i);
										//								_addToLabelLayout = true;
//									}
								}
//								else {
//									annotation.visible = false;
//									trace("\tAnnotation is already in Anticollision");
//
//									if (!annotationDatelineSplitVisibility)
//									{
//										master.container.labelLayout.removeObject(annotation);
//										trace("\t\tAnnotation is already visible for different reflection (Should be splitted on dateline)");
//									}
//								}
//							} else {
								//for non visible features, remove them from anticollision
//								if (isDisplayObjectInAnticollision)
//									master.container.labelLayout.removeObject(displaySprite);
//								if (isAnnotationInAnticollision)
//									master.container.labelLayout.removeObject(annotation);
//							}
						}

//						master.container.labelLayout.updateObjectReferenceLocation(annotation);


//						if (!mb_spritesAddedToLabelLayout && master)
//						{
//							addToLabelLayout(annotation, displaySpriteWithAnnotation, master, master.container.labelLayout, i);
//							_addToLabelLayout = true;
//						} else {
//							master.container.anticollisionObjectVisible(displaySpriteWithAnnotation, annotation.visible);
//						}
						displaySpriteWithAnnotation.update(this, annotation, getCurrentColor(0x000000), master.container.labelLayout, pt);
					} else {
						trace("WFSFeatureEditableWithBaseTimeAndValidityAndAnnotation PT is  NULL");
					}
				}
			}

//			if (!mb_spritesAddedToLabelLayout && _addToLabelLayout)
//				mb_spritesAddedToLabelLayout = true;

		}

		public function updateAnnotation(annotation: AnnotationBox, annotationPosition: Point, text: String = ""): void
		{
			annotation.update()
		}

		public function removeFromLabelLayout(annotation: AnnotationBox, displaySprite: WFSFeatureEditableSprite, labelLayout: AnticollisionLayout): void
		{
			labelLayout.removeObject(displaySprite);
			labelLayout.removeObject(annotation);
		}

		public function addToLabelLayout(annotation: AnnotationBox, displaySprite: WFSFeatureEditableSprite, layer: InteractiveLayer, labelLayout: AnticollisionLayout, i_reflection: uint): void
		{
			labelLayout.addObstacle(displaySprite, layer);
			labelLayout.addObject(annotation,  layer,  [displaySprite], i_reflection);
		}
	}
}
