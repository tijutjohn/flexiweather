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
	import com.iblsoft.flexiweather.proj.Coord;
	import com.iblsoft.flexiweather.utils.CubicBezier;
	import com.iblsoft.flexiweather.utils.ICurveRenderer;
	import com.iblsoft.flexiweather.utils.ISO8601Parser;
	import com.iblsoft.flexiweather.utils.draw.DrawMode;
	import com.iblsoft.flexiweather.widgets.InteractiveWidget;
	
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
		
		public function getRendererGraphics(reflection: int): Graphics
		{
			var gr: Graphics = graphics;
			
			var displaySprite: WFSFeatureEditableSprite = getDisplaySpriteForReflectionAt(reflection);
			if (displaySprite)
			{
				gr = displaySprite.graphics;
			}
			return gr;
		}
		
		public function clearGraphics(): void
		{
			graphics.clear();
		}
		
		override public function update(changeFlag: FeatureUpdateContext): void
		{
			if (!master)
				return;
			
			trace("WFSFeatureEditableCurveWithBaseTimeAndValidity update");
			super.update(changeFlag);
			
			clearGraphics();
			
			beforeCurveRendering();
			
			//precompute curve (FeatureData) for drawing
			computeCurve();

			// draw curve
			drawCurve();
			
			//draw editable points (user can drag them)
			updateEditablePoints(changeFlag);
			
			afterCurveRendering();
		}
		
/*
		override protected function updateCoordsReflections(): void
		{
			if (!master)
				return;
			
			if (m_featureData)
			{
				//			var reflections: Dictionary = new Dictionary();
//				ml_movablePoints.cleanup();
				var iw: InteractiveWidget = master.container;
				var crs: String = iw.getCRS();
				var total: int = m_featureData.reflections.length;
				for (var i: int = 0; i < total; i++)
				{
//					var coord: Coord = coordinates[i] as Coord;
//					var pointReflections: Array = iw.mapCoordToViewReflections(coord);
//					var reflectionsCount: int = pointReflections.length;
					var reflection: FeatureDataReflection = m_featureData.getReflectionAt(i);
					var reflectionDelta: int = reflection.reflectionDelta;
					var reflectionPoints: Array = reflection.points;
					var pointsTotal: int = reflectionPoints.length;
					
					for (var j: int = 0; j < pointsTotal; j++)
					{
//						var pointReflectedObject: Object = pointReflections[j];
//						var pointReflected: Point = pointReflectedObject.point;
						var pointReflected: Point = reflectionPoints[j] as Point;
						if (pointReflected)
						{
							var isEdgePoint: Boolean = isReflectionEdgePoint(reflectionPoints, j);
							var coordReflected: Coord = new Coord(crs, pointReflected.x, pointReflected.y);
							//					trace(this + " updateCoordsReflections coordReflected: " + coordReflected);
							//					reflectionDictionary.addReflectedCoordAt(coordReflected, i, j, pointReflectedObject.reflection, iw);
							//					reflectionDictionary.addReflectedCoordAt(coordReflected, i, pointReflectedObject.reflection, iw);
							reflectionDictionary.addReflectedCoord(coordReflected, reflectionDelta, isEdgePoint, iw);
						}
					}
				}
			} else {
				super.updateCoordsReflections();
			}
		}
*/		
		protected function isReflectionEdgePoint(points: Array, position: int): Boolean
		{
			var total: int = points.length;
			//check if next point is null
			if (position < (total - 1))
			{
				if (points[position + 1] == null)
					return true;
			}
			//check if previous point is null
			if (position > 0)
			{
				if (points[position - 1] == null)
					return true;
			}
			return false;
		}
		
		protected function beforeCurveRendering(): void
		{
			
		}
		protected function afterCurveRendering(): void
		{
			
		}
		
		protected function computeCurve(): void
		{
			trace("WFSFeatureEditableCurveWithBaseTimeAndValidity computeCurve");
			
			var a_points: Array = getPoints();
			
//			if(a_points.length > 0) 
//			{
				if (master)
				{
					if (!m_featureData)
						m_featureData = createFeatureData();
					else
						m_featureData.clear();
					
					//DEBUG - check for non smooth (to have less coordinates
//					smooth = false;
					
					//curves will be not drawn, just compute, to be able to draw each reflection separately
					if (smooth)
						master.container.drawSmoothPolyLine(getRenderer, a_points, DrawMode.PLAIN, false, true, m_featureData);
					else
						master.container.drawGeoPolyLine(getRenderer, a_points, DrawMode.PLAIN, false, true, m_featureData);
				}
//			}
		}
		
	 	protected function drawCurve(): void
		{
			trace("WFSFeatureEditableCurveWithBaseTimeAndValidity drawCurve");
			
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
				
				for (var i: int = 0; i < totalReflections; i++)
				{
					reflection = m_featureData.getReflectionAt(i) as FeatureDataReflection;
					if (reflection)
					{
						var reflectionDelta: int = reflection.reflectionDelta;
						
						if (m_featureData)
							ptAvg = m_featureData.getReflectionAt(reflectionDelta).center;
						else if (pointsCount == 1) 
							ptAvg = a_points[0] as Point;
						
						displaySprite = getDisplaySpriteForReflectionAt(reflectionDelta);
						gr = displaySprite.graphics;
						
						if(pointsCount <= 1)
						{
							displaySprite.clear();
							//						trace("displaySprite.clear: pointsCount: " + pointsCount);
						} else {
							gr.clear();
							var renderer: ICurveRenderer = getRenderer(reflectionDelta);
							drawFeatureReflection(renderer, reflection);
							
							if (displaySprite)
								displaySprite.points = reflection.points;
						}
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
				
				g.clear();
				
				g.start(p.x, p.y);
				g.moveTo(p.x, p.y);
				trace("\ndrawFeatureReflection moveTO: [" + p.x + " , " + p.y + " ]");
				var bNewLine: Boolean = false;
				for (var i: int = 1; i < pointsCount; i++)
				{
					p = points[i] as Point;
					if (p)
					{
						p = convertCoordToScreen(p);
						if (bNewLine) {
							g.moveTo(p.x, p.y);
//							trace("drawFeatureReflection lineTO: [" + p.x + " , " + p.y + " ]");
						} else {
							g.lineTo(p.x, p.y);
//							trace("drawFeatureReflection lineTO: [" + p.x + " , " + p.y + " ]");
						}
						bNewLine = false;
					} else {
						bNewLine = true;
					}
				}
				
				g.finish(p.x, p.y);
				trace("\n");
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
				var points: Array = m_points.getPointsForReflection(0);
				ma_points = CubicBezier.calculateHermitSpline(points, false);
				//ma_points = CubicBezier.calculateHermitSpline(m_points,  
			}
			if (mi_editMode == WFSFeatureEditableMode.MOVE_POINTS)
			{
				if (mi_actSelectedMoveablePointIndex > -1)
				{
					selectMoveablePoint(mi_actSelectedMoveablePointIndex, mi_actSelectedMoveablePointReflectionIndex);
				}
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
