package com.iblsoft.flexiweather.ogc.editable
{
	import com.iblsoft.flexiweather.ogc.FeatureBase;
	import com.iblsoft.flexiweather.ogc.FeatureUpdateContext;
	import com.iblsoft.flexiweather.ogc.GMLUtils;
	import com.iblsoft.flexiweather.ogc.data.WFSEditableReflectionData;
	import com.iblsoft.flexiweather.ogc.editable.WFSFeatureEditable;
	import com.iblsoft.flexiweather.ogc.wfs.WFSFeatureEditableSprite;
	import com.iblsoft.flexiweather.ogc.wfs.WFSFeatureEditableSpriteWithAnnotation;
	import com.iblsoft.flexiweather.utils.AnnotationBox;
	import com.iblsoft.flexiweather.utils.ISO8601Parser;
	import com.iblsoft.flexiweather.utils.anticollision.AnticollisionLayout;
	import com.iblsoft.flexiweather.widgets.InteractiveLayer;
	
	import flash.display.DisplayObject;
	import flash.geom.Point;
	
	import mx.collections.ArrayCollection;

	public class WFSFeatureEditableWithBaseTimeAndValidityAndAnnotation extends WFSFeatureEditableWithBaseTimeAndValidity implements IObjectWithBaseTimeAndValidity
	{
		public function get annotation():AnnotationBox
		{
			if (totalReflections > 0)
			{
				var reflection: WFSEditableReflectionData = getReflection(0);  
				return reflection.annotation as AnnotationBox;
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
			var reflection: WFSEditableReflectionData;
			var _addToLabelLayout: Boolean;
			var displaySpriteWithAnnotation: WFSFeatureEditableSpriteWithAnnotation;
			
			//create sprites for reflections
			var totalReflections: uint = ml_movablePoints.totalReflections;
			
			for (var i: int = 0; i < totalReflections; i++)
			{
				reflection = ml_movablePoints.getReflection(i) as WFSEditableReflectionData;
				if (!reflection.displaySprite)
				{
					reflection.displaySprite = getDisplaySpriteForReflection(reflection.reflectionDelta);
					addChild(reflection.displaySprite);
				}
				displaySpriteWithAnnotation = reflection.displaySprite as WFSFeatureEditableSpriteWithAnnotation;
				
				if (reflection.annotation )
				{
					annotation = reflection.annotation ;
				} else {
					annotation = createAnnotation();
					reflection.addAnnotation(annotation);
				}
				
				var pt: Point = reflection.points[0] as Point;
				displaySpriteWithAnnotation.points = [pt];
				
				if (!mb_spritesAddedToLabelLayout && master)
				{
					addToLabelLayout(annotation, displaySpriteWithAnnotation, master, master.container.labelLayout, i);
					_addToLabelLayout = true;
				} else {
					master.container.anticollisionObjectVisible(displaySpriteWithAnnotation, annotation.visible);
				}
				
				
				//FIXME fix this commented line
//				displaySpriteWithAnnotation.update(this, blackColor, master.container.labelLayout, pt);
				displaySpriteWithAnnotation.update(this, annotation, getCurrentColor(0x000000), master.container.labelLayout, pt);
				
				
				//				radiationSprite.x = Point(reflection.points[0]).x;
				//				radiationSprite.y = Point(reflection.points[0]).y;
			}
			
			if (!mb_spritesAddedToLabelLayout && _addToLabelLayout)
				mb_spritesAddedToLabelLayout = true;
			
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
