package com.iblsoft.flexiweather.ogc.kml.features
{
	import com.google.maps.geom.Point3D;
	import com.iblsoft.flexiweather.ogc.FeatureUpdateChange;
	import com.iblsoft.flexiweather.ogc.InteractiveLayerFeatureBase;
	import com.iblsoft.flexiweather.ogc.kml.InteractiveLayerKML;
	import com.iblsoft.flexiweather.ogc.kml.interfaces.IKMLIconFeature;
	import com.iblsoft.flexiweather.ogc.kml.interfaces.IKMLLabeledFeature;
	import com.iblsoft.flexiweather.ogc.kml.renderer.IKMLRenderer;
	import com.iblsoft.flexiweather.proj.Coord;
	import com.iblsoft.flexiweather.syndication.ParsingTools;
	import com.iblsoft.flexiweather.utils.AnticollisionLayout;
	import com.iblsoft.flexiweather.utils.AnticollisionLayoutObject;
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
			
			var kmlns:Namespace = new Namespace(s_namespace);

			createIcon();
			
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
		}
		
		public override function setMaster(master: InteractiveLayerFeatureBase): void
		{
			super.setMaster(master);
			
			master.container.labelLayout.addObstacle(this);
			var lo: AnticollisionLayoutObject = master.container.labelLayout.addObject(kmlLabel, [this], AnticollisionLayout.DISPLACE_HIDE);
			lo.anchorColor = 0x888888;
			lo.anchorAlpha = 0.5;
			lo.displacementMode = AnticollisionLayout.DISPLACE_AUTOMATIC_SIMPLE;
			
			master.container.objectLayout.addObject(this);
		}
		
		/** Called after the feature is added to master or after any change (e.g. area change). */
		override public function update(changeFlag: FeatureUpdateChange): void
		{
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
					if (_geometry is com.iblsoft.flexiweather.ogc.kml.features.Point)
					{
						coordinates = updateCoordinates(_geometry as com.iblsoft.flexiweather.ogc.kml.features.Point);
					}
					if (_geometry is LineString)
					{
						coordinates = updateCoordinates(_geometry as LineString);
					}
					if (_geometry is LinearRing)
					{
						coordinates = updateCoordinates(_geometry as LinearRing);
					}
					if (_geometry is Polygon)
					{
						var linearRing: LinearRing = (_geometry as Polygon).outerBoundaryIs.linearRing;
						linearRing.coordinatesPoints = updateCoordinates(linearRing, true);
					}
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
					var points: ArrayCollection = getPoints();
					if (points && points.length > 0)
					{
						var point: flash.geom.Point = points.getItemAt(0) as flash.geom.Point;
						
						x = point.x;
						y = point.y;
						//_container.labelLayout.updateObjectReferenceLocation(placemark);
					}
			}
			
		}
		
		public function get drawingFeature(): Boolean
		{
			return (_geometry is LineString || _geometry is LinearRing || _geometry is Polygon);
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
