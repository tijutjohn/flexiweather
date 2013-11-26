package com.iblsoft.flexiweather.ogc.editable
{
	import com.iblsoft.flexiweather.ogc.FeatureUpdateContext;
	import com.iblsoft.flexiweather.ogc.data.WFSEditableReflectionData;
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
			var reflection: WFSEditableReflectionData;
			var _addToLabelLayout: Boolean;
			
			var a_points: Array = getPoints();
			
			//create sprites for reflections
			var totalReflections: uint = ml_movablePoints.totalReflections;
			//			var blackColor: uint = getCurrentColor(0x000000);
			
			var displaySprite: WFSFeatureEditableSprite;
			var pointsCount: int = a_points.length;
			var ptAvg: Point;
			
			for (var i: int = 0; i < totalReflections; i++)
			{
				reflection = ml_movablePoints.getReflection(i) as WFSEditableReflectionData;
				if (reflection)
				{
					if (m_featureData)
						ptAvg = m_featureData.getReflectionAt(reflection.reflectionDelta).center;
					else if (pointsCount == 1) 
						ptAvg = a_points[0] as Point;
					
					if (!reflection.displaySprite)
					{
						reflection.displaySprite = getDisplaySpriteForReflection(reflection.reflectionDelta); //new CloudFeatureSprite(this);
						addChild(reflection.displaySprite);
					}
					displaySprite = reflection.displaySprite as WFSFeatureEditableSprite;
					
					if(a_points.length <= 1)
					{
						displaySprite.clear();
					} else {
						var renderer: ICurveRenderer = getRenderer(reflection.reflectionDelta);
						if (m_featureData)
						{
							reflection.displaySprite.graphics.clear();
							var reflectionData: FeatureDataReflection = m_featureData.getReflectionAt(reflection.reflectionDelta);
							if (reflectionData)
								drawFeatureReflection(renderer, reflectionData);
						}
						displaySprite.points = reflection.points;
						
						if (reflection.annotation )
						{
							annotation = reflection.annotation ;
						} else {
							annotation = createAnnotation();
							reflection.addAnnotation(annotation);
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

		/*
		public function getRenderer(reflection: int): ICurveRenderer
		{
			return null;
		}
		
		override public function update(changeFlag: FeatureUpdateContext): void
		{
			super.update(changeFlag);
			
			drawCurve();
		}
		
		protected function drawCurve(): void
		{
			var a_points: Array = getPoints();
			
			if(a_points.length > 1) 
			{
				if (master)
				{
					m_featureData = new FeatureData(this.toString() + " FeatureData");
					if (smooth)
						master.container.drawSmoothPolyLine(getRenderer, a_points, DrawMode.PLAIN, false, m_featureData);
					else
						master.container.drawGeoPolyLine(getRenderer, a_points, DrawMode.PLAIN, false, m_featureData);
				}
			}
		}
		
		override public function toInsertGML(xmlInsert: XML): void
		{
			addInsertGMLProperty(xmlInsert, null, "baseTime", ISO8601Parser.dateToString(m_baseTime));
			addInsertGMLProperty(xmlInsert, null, "validity", ISO8601Parser.dateToString(m_validity));
			super.toInsertGML(xmlInsert);
		}

		override public function toUpdateGML(xmlUpdate: XML): void
		{
			addUpdateGMLProperty(xmlUpdate, null, "baseTime", ISO8601Parser.dateToString(m_baseTime));
			addUpdateGMLProperty(xmlUpdate, null, "validity", ISO8601Parser.dateToString(m_validity));
			super.toUpdateGML(xmlUpdate);
		}
		
		override public function fromGML(gml: XML): void
		{
			var ns: Namespace = new Namespace(ms_namespace);
			m_baseTime = ISO8601Parser.stringToDate(gml.ns::baseTime);
			m_validity = ISO8601Parser.stringToDate(gml.ns::validity);
			super.fromGML(gml);
		}

		public function get baseTime(): Date
		{
			return m_baseTime;
		}

		public function set baseTime(baseTime: Date): void
		{
			m_baseTime = baseTime;
		}

		public function get validity(): Date
		{
			return m_validity;
		}

		public function set validity(validity: Date): void
		{
			m_validity = validity;
		}

		override public function set editMode(i_mode: int): void
		{
			super.editMode = i_mode;
			if (mi_editMode == WFSFeatureEditableMode.ADD_POINTS_ON_CURVE)
			{
				// PREPARE CURVE POINTS
				ma_points = CubicBezier.calculateHermitSpline(m_points, false);
					//ma_points = CubicBezier.calculateHermitSpline(m_points,  
			}
		}
		protected function createHitMask(curvesPoints: Array): void
		{
			for each (var curvePoints: Array in curvesPoints)
			{
				if (curvePoints.length > 1)
				{
					// CREATE CURVE MASK
					graphics.lineStyle(10, 0xFF0000, 0.0);
					graphics.moveTo(curvePoints[0].x, curvePoints[0].y);
					for (var p: int = 1; p < curvePoints.length; p++)
					{
						graphics.lineTo(curvePoints[p].x, curvePoints[p].y);
					}
				}
			}
		}
		*/
	}

}