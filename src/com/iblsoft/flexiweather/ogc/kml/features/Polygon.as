package com.iblsoft.flexiweather.ogc.kml.features
{

	/**
	*	Class that represents an Entry element within an Atom feed
	*
	* 	@langversion ActionScript 3.0
	*	@playerversion Flash 8.5
	*	@tiptext
	*
	* 	@see http://www.atomenabled.org/developers/syndication/atom-format-spec.php#rfc.section.4.1.2
	*/
	public class Polygon extends Geometry
	{
		//todo: add constants for the enum values?
		/*
			<Polygon id="ID">
			<!-- specific to Polygon -->
			<extrude>0</extrude>                       <!-- boolean -->
			<tessellate>0</tessellate>                 <!-- boolean -->
			<altitudeMode>clampToGround</altitudeMode>
			<!-- kml:altitudeModeEnum: clampToGround, relativeToGround, or absolute -->
			<!-- or, substitute gx:altitudeMode: clampToSeaFloor, relativeToSeaFloor -->
			<outerBoundaryIs>
			<LinearRing>
			<coordinates>...</coordinates>         <!-- lon,lat[,alt] -->
			</LinearRing>
			</outerBoundaryIs>
			<innerBoundaryIs>
			<LinearRing>
			<coordinates>...</coordinates>         <!-- lon,lat[,alt] -->
			</LinearRing>
			</innerBoundaryIs>
			</Polygon>
		*/
		// Can contain: <extrude>, <tessellate>, <altitudeMode>, <coordinates>, <outerBoundaryIs>, <innerBoundaryIs>*
		// there must be 1 outerBoundayIs (LineString) REQUIRED
		private var _outerBoundaryIs: OuterBoundaryIs;
		// there can be 0 or more inner boundaries (LineString)
		private var _innerBoundaryIs: Array;

		// todo add innerBoundaryIs support
		/**
		*	Constructor for class.
		*
		*	@param x An XML document that contains an individual Entry element from
		*	an Aton XML feed.
		*
		*/
		public function Polygon(s_namespace: String, x: XMLList)
		{
			super(s_namespace, x);
			var kml: Namespace = new Namespace(s_namespace);
			this._outerBoundaryIs = new OuterBoundaryIs(s_namespace, this.xml.kml::outerBoundaryIs);
		}

		override public function cleanupKML(): void
		{
			super.cleanupKML();
			if (_outerBoundaryIs)
			{
				_outerBoundaryIs.cleanupKML();
				_outerBoundaryIs = null;
			}
		}

		public function get outerBoundaryIs(): OuterBoundaryIs
		{
			return this._outerBoundaryIs;
		}

		public override function toString(): String
		{
			return "Polygon: " + "outerBoundaryIs: " + this._outerBoundaryIs;
		}
	}
}
