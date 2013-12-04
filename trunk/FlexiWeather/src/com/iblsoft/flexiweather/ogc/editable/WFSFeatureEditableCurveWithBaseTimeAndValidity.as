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
	import com.iblsoft.flexiweather.proj.Coord;
	import com.iblsoft.flexiweather.utils.CubicBezier;
	import com.iblsoft.flexiweather.utils.ICurveRenderer;
	import com.iblsoft.flexiweather.utils.ISO8601Parser;
	import com.iblsoft.flexiweather.utils.draw.DrawMode;
	
	import flash.display.Graphics;
	import flash.geom.Point;
	
	public class WFSFeatureEditableCurveWithBaseTimeAndValidity extends WFSFeatureEditableCurve implements IObjectWithBaseTimeAndValidity, IWFSCurveFeature
	{
		protected var m_baseTime: Date;
		protected var m_validity: Date;
		protected var m_curvePoints: Array;

		public function WFSFeatureEditableCurveWithBaseTimeAndValidity(
				s_namespace: String, s_typeName: String, s_featureId: String)
		{
			super(s_namespace, s_typeName, s_featureId);
		}

		public function getRenderer(reflection: int): ICurveRenderer
		{
			return null;
		}
		
		public function clearGraphics(): void
		{
			graphics.clear();
		}
		
		override public function update(changeFlag: FeatureUpdateContext): void
		{
			super.update(changeFlag);
			
			clearGraphics();
			
			beforeCurveRendering();
			
			computeCurve();
			drawCurve();
			
			afterCurveRendering();
		}
		
		protected function beforeCurveRendering(): void
		{
			
		}
		protected function afterCurveRendering(): void
		{
			
		}
		
		protected function computeCurve(): void
		{
			var a_points: Array = getPoints();
			
			if(a_points.length > 1) 
			{
				if (master)
				{
					m_featureData = new FeatureData(this.toString() + " FeatureData");
					
					//curves will be not drawn, just compute, to be able to draw each reflection separately
					if (smooth)
						master.container.drawSmoothPolyLine(getRenderer, a_points, DrawMode.PLAIN, false, true, m_featureData);
					else
						master.container.drawGeoPolyLine(getRenderer, a_points, DrawMode.PLAIN, false, true, m_featureData);
				}
			}
		}
		
	 	protected function drawCurve(): void
		{
			var reflection: WFSEditableReflectionData;
			var _addToLabelLayout: Boolean;
			
			var a_points: Array = getPoints();
			
			//create sprites for reflections
			var totalReflections: uint = ml_movablePoints.totalReflections;
			
			var displaySprite: WFSFeatureEditableSprite;
			
			var pointsCount: int = a_points.length;
			var ptAvg: Point;
			var gr: Graphics;
			
			
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
						reflection.displaySprite = getDisplaySpriteForReflection(reflection.reflectionDelta);
						if (reflection.displaySprite)
							addChild(reflection.displaySprite);
					}
					if (reflection.displaySprite) {
						displaySprite = reflection.displaySprite as WFSFeatureEditableSprite;
						gr = reflection.displaySprite.graphics;
					} else {
						gr = graphics;
					}
					
					if(pointsCount <= 1)
					{
						if (reflection.displaySprite)
							displaySprite.clear();
						//						trace("displaySprite.clear: pointsCount: " + pointsCount);
					} else {
						var renderer: ICurveRenderer = getRenderer(reflection.reflectionDelta);
						if (m_featureData)
						{
							gr.clear();
							//							trace("reflection.displaySprite: " + reflection.displaySprite.parent);
							var reflectionData: FeatureDataReflection = m_featureData.getReflectionAt(reflection.reflectionDelta);
							if (reflectionData)
								drawFeatureReflection(renderer, reflectionData);
						}
						if (displaySprite)
							displaySprite.points = reflection.points;
					}
				}
			}
		}
		
		private function convertCoordToScreen(p: Point): Point
		{
			return p;
			
//			var result: Point = master.container.coordToPoint(new Coord(master.container.crs, p.x, p.y));
//			return result
		}
		
		protected function drawFeatureReflection(g: ICurveRenderer, m_featureDataReflection: FeatureDataReflection): void
		{
			if (!g || !m_featureDataReflection || !m_featureDataReflection.lines)
			{
				return;
			}
			
			var p: Point;
			var points: Array = m_featureDataReflection.points;
			
			var linesCount: int = m_featureDataReflection.lines.length;
			var pointsCount: int = points.length;
			
			if (pointsCount == 0 && m_featureDataReflection.computingScheduled)
			{
				m_featureDataReflection.validate();
				points = m_featureDataReflection.points;
				pointsCount = points.length;
			}
			
			if (pointsCount > 0)
			{
				p = convertCoordToScreen(m_featureDataReflection.startPoint);
				
				g.start(p.x, p.y);
				g.moveTo(p.x, p.y);
				
				for (var i: int = 1; i < pointsCount; i++)
				{
					p = convertCoordToScreen(points[i] as Point);
					g.lineTo(p.x, p.y);
				}
				
				g.finish(p.x, p.y);
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
	}
}
