package com.iblsoft.flexiweather.ogc.editable
{
	import com.iblsoft.flexiweather.ogc.GMLUtils;
	import com.iblsoft.flexiweather.ogc.editable.WFSFeatureEditable;
	import com.iblsoft.flexiweather.utils.ISO8601Parser;

	public class WFSFeatureEditableWithBaseTimeAndValidity extends WFSFeatureEditable implements IObjectWithBaseTimeAndValidity
	{
		protected var m_baseTime: Date;
		protected var m_validity: Date;

		public function WFSFeatureEditableWithBaseTimeAndValidity(
				s_namespace: String, s_typeName: String, s_featureId: String)
		{
			super(s_namespace, s_typeName, s_featureId);
		}

		override public function toInsertGML(xmlInsert: XML): void
		{
			addInsertGMLProperty(xmlInsert, null, "baseTime", ISO8601Parser.dateToString(m_baseTime));
			addInsertGMLProperty(xmlInsert, null, "validity", ISO8601Parser.dateToString(m_validity));
			super.toInsertGML(xmlInsert);
			var l: XML = <gml:location xmlns:gml="http://www.opengis.net/gml"/>
					;
			var pt: XML = <gml:Point xmlns:gml="http://www.opengis.net/gml"/>
					;
			l.appendChild(pt);
			var gml: Namespace = new Namespace("http://www.opengis.net/gml");
			pt.appendChild(GMLUtils.encodeGML3Coordinates2D(coordinates));
			xmlInsert.appendChild(l);
		}

		override public function toUpdateGML(xmlUpdate: XML): void
		{
			addUpdateGMLProperty(xmlUpdate, null, "baseTime", ISO8601Parser.dateToString(m_baseTime));
			addUpdateGMLProperty(xmlUpdate, null, "validity", ISO8601Parser.dateToString(m_validity));
			super.toUpdateGML(xmlUpdate);
			var pt: XML = <gml:Point xmlns:gml="http://www.opengis.net/gml"/>
					;
			pt.appendChild(GMLUtils.encodeGML3Coordinates2D(coordinates));
			addUpdateGMLProperty(xmlUpdate, "http://www.opengis.net/gml", "location", pt);
		}

		override public function fromGML(gml: XML): void
		{
			var ns: Namespace = new Namespace(ms_namespace);
			var nsGML: Namespace = new Namespace("http://www.opengis.net/gml");
			m_baseTime = ISO8601Parser.stringToDate(gml.ns::baseTime);
			m_validity = ISO8601Parser.stringToDate(gml.ns::validity);
			super.fromGML(gml);
			var xmlLocation: XML = gml.nsGML::location[0];
			var xmlPoint: XML = xmlLocation.nsGML::Point[0];
			coordinates = GMLUtils.parseGML3Coordinates2D(xmlPoint);
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
	}
}
