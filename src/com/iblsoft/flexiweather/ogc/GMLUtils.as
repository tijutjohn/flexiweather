package com.iblsoft.flexiweather.ogc
{
	import com.iblsoft.flexiweather.proj.Coord;
	import com.iblsoft.flexiweather.proj.Projection;

	public class GMLUtils
	{
		public static function parseGML3Coordinates2D(xml: XML): Array
		{
			var l: Array = [];
			// "http://www.opengis.net/gml"
			for each (var node: XML in xml.children())
			{
				if (node.localName() == "posList")
					return parseGML3PosList2D(node);
				else if (node.localName() == "pos")
				{
					var s_coords: String = String(node);
					var a_bits: Array = s_coords.split(/\s/);
					var s_srs: String = node.@srsName;
					if (s_srs == null || s_srs == "")
						s_srs = Projection.CRS_GEOGRAPHIC;
					l.push(new Coord(s_srs, Number(a_bits[0]), Number(a_bits[1])));
				}
				else if (node.localName() == "coordinates")
					return parseGML2Coordinates2D(node);
			}
			return l;
		}

		public static function parseGML2Coordinates2D(xml: XML): Array
		{
			var a_coords: Array = [];
			var s_coords: String = String(xml);
			var a_bits: Array = s_coords.split(/\s/);
			for each (var s: String in a_bits)
			{
				var a_coordBits: Array = s.split(",", 2);
				a_coords.push(new Coord(Projection.CRS_GEOGRAPHIC, Number(a_coordBits[0]), Number(a_coordBits[1])));
			}
			return a_coords;
		}

		public static function parseGML3PosList2D(xmlPosList: XML): Array
		{
			var a_coords: Array = [];
			var s_coords: String = String(xmlPosList);
			var a_bits: Array = s_coords.split(/\s/);
			var s_srs: String = xmlPosList.@srsName;
			if (s_srs == null || s_srs == "")
				s_srs = Projection.CRS_GEOGRAPHIC;
			for (var i: uint = 0; i + 1 < a_bits.length; i += 2)
			{
				a_coords.push(new Coord(s_srs, Number(a_bits[i]), Number(a_bits[i + 1])));
			}
			return a_coords;
		}

		public static function encodeGML3Coordinates2D(l_coords: Array): XML
		{
			var s_sameCRS: String = null;
			var c: Coord;
			for each (c in l_coords)
			{
				if (s_sameCRS == null)
					s_sameCRS = c.crs;
				else
				{
					if (s_sameCRS != c.crs)
					{
						s_sameCRS = null;
						break;
					}
				}
			}
			var x: XML;
			var s: String;
			if (s_sameCRS == null)
			{
				for each (c in l_coords)
				{
					s = c.x + " " + c.y;
					if (x)
					{
						x.appendChild(<gml:pos xmlns:gml="http://www.opengis.net/gml" srsName={c.crs}>{s}</gml:pos>
								);
					}
				}
				return x;
			}
			else
			{
				s = "";
				for each (c in l_coords)
				{
					if (s.length > 0)
						s += " ";
					s += c.x + " " + c.y;
				}
				x = <gml:posList xmlns:gml="http://www.opengis.net/gml" srsName={s_sameCRS}>{s}</gml:posList>
						;
			}
			return x;
		}
	}
}
