package com.iblsoft.flexiweather.ogc.kml.features
{

	public class Geometry extends KmlObject
	{
		public function Geometry(s_namespace: String, x: XMLList)
		{
			super(s_namespace, x);
			var kml: Namespace = new Namespace(s_namespace);
		}

		public override function toString(): String
		{
			return "Geometry: " + super.toString();
		}
	}
}
