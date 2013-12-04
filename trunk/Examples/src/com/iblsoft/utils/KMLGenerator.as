package com.iblsoft.utils
{
	import com.iblsoft.flexiweather.ogc.BBox;

	public class KMLGenerator
	{
		public function KMLGenerator()
		{
		}

		static public function generateKMLWithPlacemarks(totalPlacemarks: int, area: BBox, bWithLabels: Boolean = true): String
		{
			var kml: XML = <kml xmlns="http://www.opengis.net/kml/2.2"/>
					;
			var doc: XML = <Document/>
			if (bWithLabels)
			{
				var style: XML = <Style id="myStyle"/>
						;
				var labelStyle: XML = <LabelStyle/>
				var color: XML = new XML('<color>ff00ffff</color>');
				var colorMode: XML = new XML('<colorMode>normal</colorMode>');
				var scale: XML = new XML('<scale>2</scale>');
				labelStyle.appendChild(color);
				labelStyle.appendChild(colorMode);
				labelStyle.appendChild(scale);
				style.appendChild(labelStyle);
				doc.appendChild(style);
			}
			for (var i: int = 0; i < totalPlacemarks; i++)
			{
				var placemark: XML = <Placemark/>
				if (bWithLabels)
				{
//					var customName: String = generateName();
					var customName: String = "p" + i;
					var name: XML = new XML('<name>' + customName + '</name>');
					var styleUrl: XML = new XML('<styleUrl>#myStyle</styleUrl>');
					placemark.appendChild(name);
					placemark.appendChild(styleUrl);
				}
				var point: XML = <Point/>
				var x: Number = -180 + Math.random() * 360;
				var y: Number = -90 + Math.random() * 180;
				var coordinates: XML = new XML("<coordinates>" + x + "," + y + ",0</coordinates>");
				point.appendChild(coordinates);
				placemark.appendChild(point);
				doc.appendChild(placemark);
			}
			kml.appendChild(doc);
			var ret: String = '<?xml version="1.0" encoding="utf-8"?>';
			ret += "\n" + kml.toXMLString();
			return ret;
		}

		static public function generateName(): String
		{
			var name: String = '';
			var len: int = int(Math.random() * 6) + 4;
			for (var i: int = 0; i < len; i++)
			{
				name += String.fromCharCode(64 + int(Math.random() * 26));
			}
			return name;
		}
	}
}
