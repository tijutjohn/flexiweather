package com.iblsoft.flexiweather.ogc.kml.features
{
	import com.iblsoft.flexiweather.ogc.BBox;
	import com.iblsoft.flexiweather.ogc.FeatureUpdateContext;
	import com.iblsoft.flexiweather.ogc.InteractiveLayerFeatureBase;
	import com.iblsoft.flexiweather.ogc.kml.InteractiveLayerKML;
	import com.iblsoft.flexiweather.ogc.kml.data.KMLFeaturesReflectionDictionary;
	import com.iblsoft.flexiweather.ogc.kml.data.KMLReflectionData;
	import com.iblsoft.flexiweather.ogc.kml.interfaces.IKMLLabeledFeature;
	import com.iblsoft.flexiweather.ogc.kml.renderer.IKMLRenderer;
	import com.iblsoft.flexiweather.proj.Coord;
	import com.iblsoft.flexiweather.proj.Projection;
	import com.iblsoft.flexiweather.widgets.InteractiveWidget;
	
	import flash.geom.Point;
	
	import mx.collections.ArrayCollection;

	/**
	*	Class that represents an Entry element within an Atom feed
	*
	* 	@langversion ActionScript 3.0
	*	@playerversion Flash 8.5
	*	@tiptext
	*
	* 	@see http://www.atomenabled.org/developers/syndication/atom-format-spec.php#rfc.section.4.1.2
	*/
	public class GroundOverlay extends Overlay implements IKMLLabeledFeature
	{
		private var _latLonBox: LatLonBox;

		/**
		*	Constructor for class.
		*
		*	@param x An XML document that contains an individual Entry element from
		*	an Aton XML feed.
		*
		* 	@langversion ActionScript 3.0
		*	@playerversion Flash 8.5
		*	@tiptext
		*/
		public function GroundOverlay(kml: KML, s_namespace: String, x: XMLList)
		{
			super(kml, s_namespace, x);
			var kmlns: Namespace = new Namespace(s_namespace);
			createIcon();
			this._latLonBox = new LatLonBox(s_namespace, this.xml.kmlns::LatLonBox);
		}

		public override function cleanup(): void
		{
			super.cleanup();
			if (_latLonBox)
			{
				_latLonBox.cleanupKML();
				_latLonBox = null;
			}
		}

		override protected function updateCoordsReflections( bCheckCoordIsInside: Boolean = true): void
		{
			//FIXME need to chack correct coordinate e.g. for Placemark Polygon
			_kmlReflectionDictionary.cleanup();
//			var reflectionIDs: Array = _kmlReflectionDictionary.reflectionIDs;
//			var currCoordinates: Array = currentCoordinates;
//			var total: int = currentCoordinates.length;
//			var coordsPosition: Array = [];
//			for (var i: int = 0; i < total; i++)
//			{
//				coordsPosition.push(i);
//			}
			
//			var coordsArray: Array = []; //coordinates;
			var nw: Coord = new Coord("CRS:84", _latLonBox.west, _latLonBox.north);
//			coordsArray.push(nw);
			var ne: Coord = new Coord("CRS:84", _latLonBox.east, _latLonBox.north);
//			coordsArray.push(ne);
			var se: Coord = new Coord("CRS:84", _latLonBox.east, _latLonBox.south);
//			coordsArray.push(se);
			var sw: Coord = new Coord("CRS:84", _latLonBox.west, _latLonBox.south);
//			coordsArray.push(sw);
			
			updateGroundOverlayCoordsReflections(nw, sw, ne, se);
		}
		
		private function updateGroundOverlayCoordsReflections(coordTopLeft: Coord, coordBottomLeft: Coord, coordTopRight: Coord, coordBottomRight: Coord): void
		{
			var iw: InteractiveWidget = master.container;
			var crs: String = iw.getCRS();
			var projection: Projection = iw.getCRSProjection();
			var viewBBox: BBox = iw.getViewBBox();
			var currCoordinates: Array = currentCoordinates;
			//			var visibleCoords: int = 0;
			var invisibleCoords: Array = [];
				
				var pointReflections: Array = iw.mapRectangleCoordToViewReflections(coordTopLeft, coordBottomLeft, coordTopRight, coordBottomRight);
				
				var reflectionsCount: int = pointReflections.length;
				for (var j: int = 0; j < reflectionsCount; j++)
				{
					var pointReflectedObject: Object = pointReflections[j];
					
					var reflectedRectangle: BBox = new BBox(pointReflectedObject.pointTopLeft.x, pointReflectedObject.pointBottomLeft.y, pointReflectedObject.pointBottomRight.x, pointReflectedObject.pointTopRight.y);
					
					var reflectionInsideViewBBox: Boolean = viewBBox.contains(reflectedRectangle);
					var reflectionIntersectedViewBBox: Boolean = viewBBox.intersects(reflectedRectangle);
					
					if (!reflectionInsideViewBBox && !reflectionIntersectedViewBBox)
					{
						continue;
					}
					
					var pointTopLeftReflected: flash.geom.Point = pointReflectedObject.pointTopLeft as flash.geom.Point;
					var pointTopRightReflected: flash.geom.Point = pointReflectedObject.pointTopRight as flash.geom.Point;
					var pointBottomLeftReflected: flash.geom.Point = pointReflectedObject.pointBottomLeft as flash.geom.Point;
					var pointBottomRightReflected: flash.geom.Point = pointReflectedObject.pointBottomRight as flash.geom.Point;
					
					var coordTopLeftReflected: Coord = new Coord(crs, pointTopLeftReflected.x, pointTopLeftReflected.y);
					var coordTopRightReflected: Coord = new Coord(crs, pointTopRightReflected.x, pointTopRightReflected.y);
					var coordBottomLeftReflected: Coord = new Coord(crs, pointBottomLeftReflected.x, pointBottomLeftReflected.y);
					var coordBottomRightReflected: Coord = new Coord(crs, pointBottomRightReflected.x, pointBottomRightReflected.y);
					
					_kmlReflectionDictionary.addReflectedCoordAt(coordTopLeftReflected, 0, j, pointReflectedObject.reflection);
					_kmlReflectionDictionary.addReflectedCoordAt(coordTopRightReflected, 1, j, pointReflectedObject.reflection);
					_kmlReflectionDictionary.addReflectedCoordAt(coordBottomRightReflected, 2, j, pointReflectedObject.reflection);
					_kmlReflectionDictionary.addReflectedCoordAt(coordBottomLeftReflected, 3, j, pointReflectedObject.reflection);
				}
		}
		
		/** Called after the feature is added to master or after any change (e.g. area change). */
		override public function update(changeFlag: FeatureUpdateContext): void
		{
			if (!kmlReflectionDictionary)
				return;
			
			if (kmlLabel)
				kmlLabel.text = name;
			if (changeFlag.anyChange)
				mb_pointsDirty = true;
			if (mb_pointsDirty)
			{
				var c: Coord;
				var coord: Object;
				var geometryCoordinates: Coordinates;
				//TODO need to find better solutions for all classes which have coordinates
				//order of coordinates inserted: NorthWest, NorthEast, SouthEast, SouthWest
				var coordsArray: Array = []; //coordinates;
				var nw: Coord = new Coord("CRS:84", _latLonBox.west, _latLonBox.north);
				coordsArray.push(nw);
				var ne: Coord = new Coord("CRS:84", _latLonBox.east, _latLonBox.north);
				coordsArray.push(ne);
				var se: Coord = new Coord("CRS:84", _latLonBox.east, _latLonBox.south);
				coordsArray.push(se);
				var sw: Coord = new Coord("CRS:84", _latLonBox.west, _latLonBox.south);
				coordsArray.push(sw);
				coordinates = coordsArray;
			}
			updateCoordsReflections( false );
			_kmlReflectionDictionary.updateKMLFeature(this);
			var reflection: KMLReflectionData = _kmlReflectionDictionary.getReflection(0) as KMLReflectionData;
			var renderer: IKMLRenderer = (master as InteractiveLayerKML).itemRendererInstance;

			super.update(changeFlag);
			
			renderer.render(this, master.container);
		}

		override public function set x(value: Number): void
		{
			super.x = value;
		}

		public function get latLonBox(): LatLonBox
		{
			return this._latLonBox;
		}

		public override function toString(): String
		{
			return "GroundOverlay: " + super.toString() + this._latLonBox;
		}
	}
}
