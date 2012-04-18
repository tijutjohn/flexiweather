package com.iblsoft.flexiweather.ogc.kml.features
{
	import com.google.maps.geom.Point3D;
	import com.iblsoft.flexiweather.ogc.FeatureUpdateContext;
	import com.iblsoft.flexiweather.ogc.InteractiveLayerFeatureBase;
	import com.iblsoft.flexiweather.ogc.kml.InteractiveLayerKML;
	import com.iblsoft.flexiweather.ogc.kml.interfaces.IKMLIconFeature;
	import com.iblsoft.flexiweather.ogc.kml.interfaces.IKMLLabeledFeature;
	import com.iblsoft.flexiweather.ogc.kml.managers.KMLParserManager;
	import com.iblsoft.flexiweather.ogc.kml.renderer.IKMLRenderer;
	import com.iblsoft.flexiweather.proj.Coord;
	import com.iblsoft.flexiweather.syndication.ParsingTools;
	import com.iblsoft.flexiweather.utils.AnticollisionLayout;
	import com.iblsoft.flexiweather.utils.AnticollisionLayoutObject;
	import com.iblsoft.flexiweather.utils.ArrayUtils;
	import com.iblsoft.flexiweather.utils.geometry.ILineSegmentApproximableBounds;
	import com.iblsoft.flexiweather.utils.geometry.LineSegment;
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
	public class Placemark extends KMLFeature implements IKMLLabeledFeature, IKMLIconFeature, ILineSegmentApproximableBounds
	{
		private var _geometry:Geometry;
		private var _multigeometry:Geometry;
		
		override public function getPoints(): ArrayCollection
		{ 
			if (_geometry is Polygon)
			{
				var linearRing: LinearRing = (_geometry as Polygon).outerBoundaryIs.linearRing;
				
				return new ArrayCollection(linearRing.coordinatesPoints);
			}
			return m_points; 
		}
		
		override public function get coordinates(): Array
		{ 
			if (_geometry is Polygon)
			{
				trace("get Placemark Polygon coordinates");
			}
			return m_coordinates.toArray(); 
		}  		
		
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
		public function Placemark(kml: KML, s_namespace: String, x:XMLList)
		{
			super(kml, s_namespace, x);
			

		}
		public override function cleanup():void
		{
			super.cleanup();
			
			trace("Placemark cleanup");
			
			if (_geometry)
			{
				_geometry.cleanupKML();
				_geometry = null;
			}
			if (_multigeometry)
			{
				_multigeometry.cleanupKML();
				_multigeometry = null;
			}
			
		}
		override protected function parseKML(s_namespace: String, kmlParserManager: KMLParserManager): void
		{
			super.parseKML(s_namespace, kmlParserManager);
			
			var time: int = startProfileTimer();
			
			if (name && name.length > 0)
			{
//				createKMLLabel();
			}
			
			createIcon();
			
			var kmlns:Namespace = new Namespace(s_namespace);
			
			// Features are: <Point>, <LineString>, <LinearRing>, <Polygon>, <MultiGeometry>, <Model>
			// We'll only support <Point>, <LineString>, <LinearRing>, <Polygon>
			if (ParsingTools.nullCheck(this.xml.kmlns::Point)) {
				this._geometry = new com.iblsoft.flexiweather.ogc.kml.features.Point(s_namespace, this.xml.kmlns::Point);
			}
			if (ParsingTools.nullCheck(this.xml.kmlns::LineString)) {
				this._geometry = new LineString(s_namespace, this.xml.kmlns::LineString);
			}
			if (ParsingTools.nullCheck(this.xml.kmlns::LinearRing)) {
				this._geometry = new LinearRing(s_namespace, this.xml.kmlns::LinearRing);
			}
			if (ParsingTools.nullCheck(this.xml.kmlns::Polygon)) {
				this._geometry = new Polygon(s_namespace, this.xml.kmlns::Polygon);
			}
			if (ParsingTools.nullCheck(this.xml.kmlns::MultiGeometry)) {
				this._geometry = new MultiGeometry(s_namespace, this.xml.kmlns::MultiGeometry);
			}
			
//			debug("Placemark parseKML: " + (stopProfileTimer(time)) + "ms");
		}
		
		public override function setMaster(master: InteractiveLayerFeatureBase): void
		{
			super.setMaster(master);
			
//			master.container.labelLayout.addObstacle(this);
//			var lo: AnticollisionLayoutObject = master.container.labelLayout.addObject(kmlLabel, [this], AnticollisionLayout.DISPLACE_HIDE);
//			lo.anchorColor = 0x888888;
//			lo.anchorAlpha = 0.5;
//			lo.displacementMode = AnticollisionLayout.DISPLACE_AUTOMATIC_SIMPLE;
//			
//			master.container.objectLayout.addObject(this);
			/*
			master.container.labelLayout.addObstacle(this);
			if (kmlLabel)
			{
				var lo: AnticollisionLayoutObject = master.container.labelLayout.addObject(kmlLabel, [this], AnticollisionLayout.DISPLACE_HIDE);
				lo.anchorColor = 0x888888;
				lo.anchorAlpha = 0.5;
				lo.displacementMode = AnticollisionLayout.DISPLACE_AUTOMATIC_SIMPLE;
			}
			*/
//			master.container.objectLayout.addObject(this);
		}
		
		protected function updateGeometryCoordinates(currGeometry: Geometry): void
		{
			var arr: Array;
			var origCoords: Array;
			if (currGeometry is com.iblsoft.flexiweather.ogc.kml.features.Point)
			{
				origCoords = coordinates;
				arr = updateCoordinates(currGeometry as com.iblsoft.flexiweather.ogc.kml.features.Point);
				ArrayUtils.unionArrays(origCoords, arr);
				coordinates = origCoords;
			}
			if (currGeometry is LineString)
			{
				origCoords = coordinates;
				arr = updateCoordinates(currGeometry as LineString);
				ArrayUtils.unionArrays(origCoords, arr);
				coordinates = origCoords;
			}
			if (currGeometry is LinearRing)
			{
				origCoords = coordinates;
				arr = updateCoordinates(currGeometry as LinearRing);
				ArrayUtils.unionArrays(origCoords, arr);
				coordinates = origCoords;
			}
			if (currGeometry is Polygon)
			{
				var linearRing: LinearRing = (currGeometry as Polygon).outerBoundaryIs.linearRing;
				linearRing.coordinatesPoints = updateCoordinates(linearRing, true);
			}
			if (currGeometry is MultiGeometry)
			{
				//TODO update coordinates in MultiGeometry items
				trace("TODO update coordinates in MultiGeometry items");
				var multigeometry: MultiGeometry = currGeometry as MultiGeometry;
				for each (var geometryItem: Geometry in multigeometry.geometries)
				{
					updateGeometryCoordinates(geometryItem)
				}
			}
		}
		/** Called after the feature is added to master or after any change (e.g. area change). */
		override public function update(changeFlag: FeatureUpdateContext): void
		{
			if (!m_master)
				return;
			
			if (kmlLabel)
				kmlLabel.text = name;
			
			if (changeFlag.anyChange)
				mb_pointsDirty = true;
			
			if(mb_pointsDirty) 
			{
				if (_geometry)
				{
					var iw: InteractiveWidget = m_master.container;
					var c: Coord;
					var coord: Object;
					var geometryCoordinates: Coordinates;
					
					//TODO need to find better solutions for all classes which have coordinates
					
					var coordsArray: Array = [];//coordinates;
					coordinates = [];
					updateGeometryCoordinates(_geometry);
				}
			}
			
			super.update(changeFlag);
			
			var renderer: IKMLRenderer = (master as InteractiveLayerKML).itemRendererInstance;
			if (changeFlag.fullUpdateNeeded)
			{
				renderer.render(this, master.container);
			} else {
				if (changeFlag.viewBBoxSizeChanged)
				{
					if (drawingFeature)
					{
						renderer.render(this, master.container);
					}
				}
			}
			
			if (_geometry)
			{
				var points: ArrayCollection;
				var point: flash.geom.Point;
				if (_geometry is MultiGeometry)
				{
					var multigeometry: MultiGeometry = _geometry as MultiGeometry;
					for each (var geometryItem: Geometry in multigeometry.geometries)
					{
						points = getPoints();
						if (points && points.length > 0)
						{
							point = points.getItemAt(0) as flash.geom.Point;
							
							x = point.x;
							y = point.y;
							//_container.labelLayout.updateObjectReferenceLocation(placemark);
						}
					}
				} else  {
					points = getPoints();
					if (points && points.length > 0)
					{
						point = points.getItemAt(0) as flash.geom.Point;
						
						if (point is Coord)
						{
							point = iw.coordToPoint(point as Coord);
						}
						x = point.x;
						y = point.y;
						//_container.labelLayout.updateObjectReferenceLocation(placemark);
					}
				}
			}
			
		}
		
		public function get drawingFeature(): Boolean
		{
			var simpleDrawing: Boolean = (_geometry is LineString || _geometry is LinearRing || _geometry is Polygon);
			
			if (_geometry is MultiGeometry)
			{
				var multiGeometry: MultiGeometry = _geometry as MultiGeometry;
				for each (var geometry: Geometry in multiGeometry.geometries)
				{
					simpleDrawing = simpleDrawing || (geometry is LineString || geometry is LinearRing || geometry is Polygon);
				}
			}
			return simpleDrawing;
		}
		public function get iconFeature(): Boolean
		{
			return (_geometry is com.iblsoft.flexiweather.ogc.kml.features.Point);
		}
		
		private function updateCoordinates(geometry: Geometry, convertToPoint: Boolean = false): Array
		{
			var c: Coord;
			var coord: Object;
			var geometryCoordinates: Coordinates;
			
			if (geometry.hasOwnProperty('coordinates'))
			{
				var coordsArray: Array = [];//coordinates;
				geometryCoordinates = geometry['coordinates'] as Coordinates;
				for each (coord in geometryCoordinates.coordsList)
				{
					c = new Coord("CRS:84", coord.lon, coord.lat);
					//							c = new Coord(iw.getCRS(), coord.lon, coord.lat);
					coordsArray.push(c);
				}
				return coordsArray;
			}
			
			return null;
		}
		
		public function get geometry():Geometry {
			return this._geometry;
		}
		
		public override function toString():String {
			return "Placemark: ["+name+"]geometry: " + this._geometry + " parent: " + parentFeature + " document: " + parentDocument;
		}
		
		public function getLineSegmentApproximationOfBounds():Array
		{
			var geometry: Geometry = this._geometry;
			if (geometry is LineString || geometry is Polygon || geometry is LinearRing)
			{
				return createStraightLineSegmentApproximation(false);
			}
			if (geometry is com.iblsoft.flexiweather.ogc.kml.features.Point)
			{
				var point: com.iblsoft.flexiweather.ogc.kml.features.Point = geometry as com.iblsoft.flexiweather.ogc.kml.features.Point;
				
				if (!m_master)
					return null;
				
				var iw: InteractiveWidget = m_master.container;
				
				var obj: Object = point.coordinates.coordsList[0];
				var c: Coord = new Coord("CRS:84", parseFloat(obj.lon), parseFloat(obj.lat));
				var pt: flash.geom.Point = iw.coordToPoint(c);
				
				return [new LineSegment(pt.x, pt.y, pt.x, pt.y)];
			}
			return null;
		}
		
	}
}
