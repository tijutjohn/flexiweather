package com.iblsoft.flexiweather.ogc.editable
{
	import com.iblsoft.flexiweather.ogc.editable.IObjectWithBaseTimeAndValidity;
	import com.iblsoft.flexiweather.ogc.editable.WFSFeatureEditableCurve;
	import com.iblsoft.flexiweather.ogc.editable.WFSFeatureEditableMode;
	import com.iblsoft.flexiweather.utils.CubicBezier;
	import com.iblsoft.flexiweather.utils.ISO8601Parser;

	public class WFSFeatureEditableCurveWithBaseTimeAndValidity extends WFSFeatureEditableCurve
			implements IObjectWithBaseTimeAndValidity
	{
		protected var m_baseTime: Date;
		protected var m_validity: Date;
		
		protected var m_curvePoints: Array;
		
		public function WFSFeatureEditableCurveWithBaseTimeAndValidity(
				s_namespace: String, s_typeName: String, s_featureId: String)
		{
			super(s_namespace, s_typeName, s_featureId);
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
		{ return m_baseTime; }

		public function set baseTime(baseTime: Date): void 
		{ m_baseTime = baseTime; }

		public function get validity(): Date
		{ return m_validity; }

		public function set validity(validity: Date): void
		{ m_validity = validity; } 
		
		override public function set editMode(i_mode: int): void
		{
			super.editMode = i_mode;
			
			if (mi_editMode == WFSFeatureEditableMode.ADD_POINTS_ON_CURVE){
				// PREPARE CURVE POINTS
				ma_points = CubicBezier.calculateHermitSpline(m_points.toArray(), false);
				//ma_points = CubicBezier.calculateHermitSpline(m_points.toArray(),  
			}
		}
		
		/**
		 * 
		 */
		protected function createHitMask(curvesPoints: Array): void
		{
			for each (var curvePoints: Array in curvesPoints)
			{
				// CREATE CURVE MASK
				graphics.lineStyle(10, 0xFF0000, 0.0);
				graphics.moveTo(curvePoints[0].x, curvePoints[0].y);
				for (var p: int = 1; p < curvePoints.length; p++){
					graphics.lineTo(curvePoints[p].x, curvePoints[p].y);
				}
			}
		}
	}
}