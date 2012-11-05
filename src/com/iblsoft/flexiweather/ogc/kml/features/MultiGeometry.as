package com.iblsoft.flexiweather.ogc.kml.features
{

	public class MultiGeometry extends Geometry
	{
		private var _geometries: Array;

		public function MultiGeometry(s_namespace: String, x: XMLList)
		{
			super(s_namespace, x);
			_geometries = new Array();
			parse(s_namespace);
		}

		private function parse(s_namespace: String): void
		{
			var kmlns: Namespace = new Namespace(s_namespace);
			var i: XML;
			for each (i in this.xml.kmlns::Point)
			{
				var point: Point = new Point(s_namespace, XMLList(i))
				addGeometry(point);
			}
			for each (i in this.xml.kmlns::LineString)
			{
				var lineString: LineString = new LineString(s_namespace, XMLList(i))
				addGeometry(lineString);
			}
			for each (i in this.xml.kmlns::LinearRing)
			{
				var linearRing: LinearRing = new LinearRing(s_namespace, XMLList(i))
				addGeometry(linearRing);
			}
			for each (i in this.xml.kmlns::Polygon)
			{
				var polygon: Polygon = new Polygon(s_namespace, XMLList(i))
				addGeometry(polygon);
			}
			for each (i in this.xml.kmlns::MultiGeometry)
			{
				var multiGeometry: MultiGeometry = new MultiGeometry(s_namespace, XMLList(i))
				addGeometry(multiGeometry);
			}
		}

		override public function cleanupKML(): void
		{
			super.cleanupKML();
			if (_geometries)
			{
				while (_geometries.length > 0)
				{
					var geometry: Geometry = _geometries.shift();
					geometry.cleanupKML();
					geometry = null;
				}
				_geometries = null;
			}
		}

		private function addGeometry(geometry: Geometry): void
		{
			_geometries.push(geometry);
		}

		public function get geometries(): Array
		{
			return this._geometries;
		}

		public override function toString(): String
		{
			return "MultiGeometry: geometries: " + this._geometries.length;
		}
	}
}
