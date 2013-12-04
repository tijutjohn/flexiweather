package com.iblsoft.flexiweather.ogc.kml.features
{
	import com.google.maps.geom.Point3D;
	import com.iblsoft.flexiweather.constants.AnticollisionDisplayMode;
	import com.iblsoft.flexiweather.ogc.FeatureUpdateContext;
	import com.iblsoft.flexiweather.ogc.InteractiveLayerFeatureBase;
	import com.iblsoft.flexiweather.ogc.events.FeatureEvent;
	import com.iblsoft.flexiweather.ogc.kml.InteractiveLayerKML;
	import com.iblsoft.flexiweather.ogc.kml.controls.KMLLabel;
	import com.iblsoft.flexiweather.ogc.kml.controls.KMLSprite;
	import com.iblsoft.flexiweather.ogc.kml.data.KMLReflectionData;
	import com.iblsoft.flexiweather.ogc.kml.events.KMLParsingStatusEvent;
	import com.iblsoft.flexiweather.ogc.kml.interfaces.IKMLLabeledFeature;
	import com.iblsoft.flexiweather.ogc.kml.managers.KMLParserManager;
	import com.iblsoft.flexiweather.ogc.kml.managers.KMLResourceManager;
	import com.iblsoft.flexiweather.ogc.kml.renderer.IKMLRenderer;
	import com.iblsoft.flexiweather.proj.Coord;
	import com.iblsoft.flexiweather.syndication.ParsingTools;
	import com.iblsoft.flexiweather.utils.ArrayUtils;
	import com.iblsoft.flexiweather.utils.anticollision.AnticollisionLayout;
	import com.iblsoft.flexiweather.utils.anticollision.AnticollisionLayoutObject;
	import com.iblsoft.flexiweather.utils.geometry.ILineSegmentApproximableBounds;
	import com.iblsoft.flexiweather.utils.geometry.LineSegment;
	import com.iblsoft.flexiweather.widgets.InteractiveWidget;
	
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.geom.Point;
	import flash.utils.Dictionary;
	
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
	public class Placemark extends KMLFeature implements IKMLLabeledFeature, ILineSegmentApproximableBounds
	{
		private var _geometry: Geometry;
		private var _multigeometry: Geometry;

		override public function set x(value: Number): void
		{
			super.x = value;
		}

		override public function set y(value: Number): void
		{
			super.y = value;
		}

		override public function set visible(value: Boolean): void
		{
			super.visible = value;
		}

		override public function getPoints(): Array
		{
			if (_geometry is Polygon)
			{
				var linearRing: LinearRing = (_geometry as Polygon).outerBoundaryIs.linearRing;
				return linearRing.coordinatesPoints;
			}
			return m_points;
		}

		override public function get coordinates(): Array
		{
			return m_coordinates;
		}

//		private var _spritesAddedToLabelLayout: Boolean;
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
		public function Placemark(kml: KML, s_namespace: String, x: XMLList)
		{
			super(kml, s_namespace, x);
			addEventListener(FeatureEvent.PRESENCE_IN_VIEW_BBOX_CHANGED, onPresenceInViewBBoxChanged);
		}

		private function onPresenceInViewBBoxChanged(event: FeatureEvent): void
		{
			var labelLayout: AnticollisionLayout = master.container.labelLayout;
//			if (event.insideViewBBox)
//			{
//				labelLayout.addObject(
//			} else {
//				labelLayout.removeObject();
//			}
		}

		public override function cleanup(): void
		{
			super.cleanup();
			var totalReflections: int = kmlReflectionDictionary.totalReflections;
			var kmlSprite: KMLSprite;
			for (var i: int = 0; i < totalReflections; i++)
			{
				var kmlReflection: KMLReflectionData = kmlReflectionDictionary.getReflection(i) as KMLReflectionData;
				if (kmlReflection)
				{
					kmlSprite = kmlReflection.displaySprite as KMLSprite;
					if (kmlSprite)
					{
						if (kmlSprite.kmlLabel)
						{
							if (kmlSprite.kmlLabel.anticollisionLayoutObject)
								removeLabelFromAnticollisionLayout(kmlSprite.kmlLabel);
							kmlSprite.kmlLabel.cleanup();
						}
						kmlSprite.cleanup();
					}
					kmlReflection.remove();
				}
			}
			kmlReflectionDictionary.destroy();
			_kmlReflectionDictionary = null;
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
			
			mb_kmlFeatureParsingSupportedFeature = false;
			
			var time: int = startProfileTimer();
			createIcon();
			var kmlns: Namespace = new Namespace(s_namespace);
			// Features are: <Point>, <LineString>, <LinearRing>, <Polygon>, <MultiGeometry>, <Model>
			// We'll only support <Point>, <LineString>, <LinearRing>, <Polygon>
			
			if (ParsingTools.nullCheck(this.xml.kmlns::Point)) {
				this._geometry = new com.iblsoft.flexiweather.ogc.kml.features.Point(s_namespace, this.xml.kmlns::Point);
				mb_kmlFeatureParsingSupportedFeature = true;
			}
			if (ParsingTools.nullCheck(this.xml.kmlns::LineString)) {
				this._geometry = new LineString(s_namespace, this.xml.kmlns::LineString);
				mb_kmlFeatureParsingSupportedFeature = true;
			}
			if (ParsingTools.nullCheck(this.xml.kmlns::LinearRing)) {
				this._geometry = new LinearRing(s_namespace, this.xml.kmlns::LinearRing);
				mb_kmlFeatureParsingSupportedFeature = true;
			}
			if (ParsingTools.nullCheck(this.xml.kmlns::Polygon)) {
				this._geometry = new Polygon(s_namespace, this.xml.kmlns::Polygon);
				mb_kmlFeatureParsingSupportedFeature = true;
			}
			if (ParsingTools.nullCheck(this.xml.kmlns::MultiGeometry)) {
				this._geometry = new MultiGeometry(s_namespace, this.xml.kmlns::MultiGeometry);
				mb_kmlFeatureParsingSupportedFeature = true;
			}
			if (!mb_kmlFeatureParsingSupportedFeature)
			{
				changeKMLFeatureParsingStatus(KMLParsingStatusEvent.FEATURE_PARSING_PARTIALLY_SUCCESFULL);
			} else {
				changeKMLFeatureParsingStatus(KMLParsingStatusEvent.FEATURE_PARSING_SUCCESFULL);
			}
			//			debug("Placemark parseKML: " + (stopProfileTimer(time)) + "ms");
		}

		public override function setMaster(master: InteractiveLayerFeatureBase): void
		{
			super.setMaster(master);
//			master.container.labelLayout.addObstacle(this);
//			var lo: AnticollisionLayoutObject = master.container.labelLayout.addObject(kmlLabel, master, [this], AnticollisionLayout.DISPLACE_HIDE);
//			lo.anchorColor = 0x888888;
//			lo.anchorAlpha = 0.5;
//			lo.displacementMode = AnticollisionLayout.DISPLACE_AUTOMATIC_SIMPLE;
//			
//			master.container.objectLayout.addObject(this);
		/*
		master.container.labelLayout.addObstacle(this);
		if (kmlLabel)
		{
			var lo: AnticollisionLayoutObject = master.container.labelLayout.addObject(kmlLabel, master, [this], AnticollisionLayout.DISPLACE_HIDE);
			lo.anchorColor = 0x888888;
			lo.anchorAlpha = 0.5;
			lo.displacementMode = AnticollisionLayout.DISPLACE_AUTOMATIC_SIMPLE;
		}
		*/
//			master.container.objectLayout.addObject(this);
		}

		override protected function get currentCoordinates(): Array
		{
//			if (geometry is Polygon)
//			{
//				var linearRing: LinearRing = (geometry as Polygon).outerBoundaryIs.linearRing;
//				return linearRing.coordinatesPoints;
//			}
//			if (geometry is MultiGeometry)
//			{
//				trace("what should be returned for multigeometry???");
//				var multiGeometry: MultiGeometry = geometry as MultiGeometry;
//				var multiGeometryCoordinates: Array = [];
//				for each (var geometryItem: Geometry in multiGeometry.geometries)
//				{
//					var currCoordinates: Array; 
//					if (geometryItem.hasOwnProperty("coordinates"))
//					{
//						if (geometryItem['coordinates'] is Array)
//							currCoordinates = geometryItem['coordinates'] as Array;
//						else if (geometryItem['coordinates'] is Coordinates) {
//							currCoordinates = (geometryItem['coordinates'] as Coordinates).coordsList;
//						}
//							
//					}
//					else if (geometryItem is Polygon) {
//						var linearRing: LinearRing = (geometryItem as Polygon).outerBoundaryIs.linearRing;
//						currCoordinates = linearRing.coordinatesPoints;
//					}
//					
//					for each (var coordinate: * in currCoordinates)
//						multiGeometryCoordinates.push(coordinate);
//				}
//				return multiGeometryCoordinates;
//			}
			return coordinates;
		}

		protected function updateGeometryCoordinates(currGeometry: Geometry, partOfMultiGeometry: Boolean = false): void
		{
			var arr: Array;
			var origCoords: Array;
			var coordsTemp: Array;					
			if (currGeometry is com.iblsoft.flexiweather.ogc.kml.features.Point)
			{
				origCoords = coordinates;
				arr = updateCoordinates(currGeometry as com.iblsoft.flexiweather.ogc.kml.features.Point);
				ArrayUtils.unionArrays(origCoords, arr);
				if (!partOfMultiGeometry)
					coordinates = origCoords;
				else {
					coordsTemp = coordinates;
					ArrayUtils.unionArrays(coordsTemp, origCoords);
					coordinates = coordsTemp;
				}
			}
			if (currGeometry is LineString)
			{
				origCoords = coordinates;
				arr = updateCoordinates(currGeometry as LineString);
				ArrayUtils.unionArrays(origCoords, arr);
				
				if (!partOfMultiGeometry)
					coordinates = origCoords;
				else {
					coordsTemp = coordinates;
					ArrayUtils.unionArrays(coordsTemp, origCoords);
					coordinates = coordsTemp;
				}
			}
			if (currGeometry is LinearRing)
			{
				origCoords = coordinates;
				arr = updateCoordinates(currGeometry as LinearRing);
				ArrayUtils.unionArrays(origCoords, arr);
				if (!partOfMultiGeometry)
					coordinates = origCoords;
				else {
					coordsTemp = coordinates;
					ArrayUtils.unionArrays(coordsTemp, origCoords);
					coordinates = coordsTemp;
				}
			}
			if (currGeometry is Polygon)
			{
				var linearRing: LinearRing = (currGeometry as Polygon).outerBoundaryIs.linearRing;
				linearRing.coordinatesPoints = updateCoordinates(linearRing, true);
				
				if (!partOfMultiGeometry)
					coordinates = linearRing.coordinatesPoints;
				else {
					coordsTemp = coordinates;
					ArrayUtils.unionArrays(coordsTemp, linearRing.coordinatesPoints);
					coordinates = coordsTemp;
				}
			}
			if (currGeometry is MultiGeometry)
			{
				var multigeometry: MultiGeometry = currGeometry as MultiGeometry;
				coordinates = [];
				for each (var geometryItem: Geometry in multigeometry.geometries)
				{
					updateGeometryCoordinates(geometryItem, true);
				}
				
				if (partOfMultiGeometry) {
					coordsTemp = coordinates;
					ArrayUtils.unionArrays(coordsTemp, linearRing.coordinatesPoints);
					coordinates = coordsTemp;
				}
			}
		}

		override protected function createKMLLabel(parent: Sprite): KMLLabel
		{
			var kmlSprite: KMLSprite = parent as KMLSprite;
			if (kmlSprite && !kmlSprite.kmlLabel)
				kmlSprite.kmlLabel = super.createKMLLabel(kmlSprite);
			return kmlSprite.kmlLabel;
		}

		/** Called after the feature is added to master or after any change (e.g. area change). */
		/**
		 * 
		 * @param changeFlag
		 * 
		 */
		override public function update(changeFlag: FeatureUpdateContext): void
		{
			if (!m_master)
				return;
			if (kmlLabel)
				kmlLabel.text = name;
			if (changeFlag.anyChange)
				mb_pointsDirty = true;
			if (mb_pointsDirty)
			{
				if (_geometry)
				{
					var iw: InteractiveWidget = m_master.container;
					var c: Coord;
					var coord: Object;
					var geometryCoordinates: Coordinates;
					//TODO need to find better solutions for all classes which have coordinates
					var coordsArray: Array = []; //coordinates;
					coordinates = [];
					updateGeometryCoordinates(_geometry);
				}
			}
			
			super.update(changeFlag);
			
			updateCoordsReflections();
			
			_kmlReflectionDictionary.updateKMLFeature(this);
			
			var reflection: KMLReflectionData = _kmlReflectionDictionary.getReflection(0) as KMLReflectionData;
			var renderer: IKMLRenderer = (master as InteractiveLayerKML).itemRendererInstance;
			if (changeFlag.fullUpdateNeeded)
				renderer.render(this, master.container);
			else
			{
				if (changeFlag.viewBBoxSizeChanged)
				{
//					if (drawingFeature)
//					{
					renderer.render(this, master.container);
//					}
				}
			}
			if (_geometry)
			{
				var points: ArrayCollection;
				var point: flash.geom.Point;
				var _addToLabelLayout: Boolean;
				var totalReflections: int = kmlReflectionDictionary.totalReflections;
				var labelLayout: AnticollisionLayout = master.container.labelLayout;
				var labelsCreation: Boolean;
				var kmlSprite: KMLSprite;
				
				//we need to get reflections of first point in coordinate (it ca be hidden and in that way, there will be problems to find first point (to set correct position)
				var firstPointReflections: Dictionary = getReflectedCoordinate(coordinates[0] as Coord);
				
				for (var i: int = 0; i < totalReflections; i++)
				{
					var removeLabel: Boolean = false;
					var kmlReflection: KMLReflectionData = kmlReflectionDictionary.getReflection(i) as KMLReflectionData;
					if (kmlReflection.points && kmlReflection.points.length > 0)
					{
//						var iconPoint: flash.geom.Point = kmlReflection.points[0] as flash.geom.Point;
						if (firstPointReflections[kmlReflection.reflectionDelta])
						{
							var iconPoint: flash.geom.Point = firstPointReflections[kmlReflection.reflectionDelta].point as flash.geom.Point;
							if (kmlReflection.displaySprite && iconPoint && featureScale > 0)
							{
								kmlSprite = kmlReflection.displaySprite as KMLSprite;
								kmlSprite.visible = true;
								kmlSprite.x = iconPoint.x;
								kmlSprite.y = iconPoint.y;
								if (name && name.length > 0)
								{
									createKMLLabel(kmlSprite);
									kmlSprite.kmlLabel.text = name;
									labelsCreation = true;
								}
								if (kmlSprite.kmlLabel && !kmlSprite.kmlLabel.visible)
									kmlSprite.kmlLabel.visible = true;
								if (master && kmlSprite.kmlLabel && !kmlSprite.kmlLabel.anticollisionLayoutObject)
								{
									addLabelToAnticollisionLayout(kmlSprite.kmlLabel);
									_addToLabelLayout = true;
								}
								labelLayout.updateObjectReferenceLocation(kmlSprite);
							}
							else
								removeLabel = true;
						} else
							removeLabel = true;
					} else
						removeLabel = true;
				}
				if (removeLabel)
				{
					if (kmlReflection.displaySprite)
					{
						kmlSprite = kmlReflection.displaySprite as KMLSprite;
						kmlSprite.visible = false;
						if (kmlSprite.kmlLabel)
						{
							//remove label
							labelLayout.removeObject(kmlSprite.kmlLabel);
							kml.resourceManager.pushKMLLabel(kmlSprite.kmlLabel);
							kmlSprite.kmlLabel = null;
						}
					}
				}
				if (labelsCreation)
				{
					//we need to render placemark if labels was created, to apply correct styles on labels
					renderer.render(this, master.container);
				}
//				if (!_spritesAddedToLabelLayout && _addToLabelLayout)
//					_spritesAddedToLabelLayout = true;
			}
		}

		override protected function addLabelToAnticollisionLayout(kmlLabel: KMLLabel): void
		{
			super.addLabelToAnticollisionLayout(kmlLabel);
			var labelLayout: AnticollisionLayout = master.container.labelLayout;
//			var anticollisionLayoutObject: AnticollisionLayoutObject = labelLayout.addObject(kmlSprite.kmlLabel, [], i, AnticollisionDisplayMode.HIDE_IF_OCCUPIED);
			var anticollisionLayoutObject: AnticollisionLayoutObject = labelLayout.addObject(kmlLabel, null, [], 0, AnticollisionDisplayMode.HIDE_IF_OCCUPIED);
//			kmlSprite.anticollisionLayoutObject = anticollisionLayoutObject;
//			kmlSprite.kmlLabel.anticollisionLayoutObject = anticollisionLayoutObject;
			kmlLabel.anticollisionLayoutObject = anticollisionLayoutObject;
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
				var coordsArray: Array = []; //coordinates;
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

		public function get geometry(): Geometry
		{
			return this._geometry;
		}

		public override function toString(): String
		{
			return "Placemark: [" + name + "]geometry: " + this._geometry + " parent: " + parentFeature + " document: " + parentDocument;
		}

		public function getLineSegmentApproximationOfBounds(): Array
		{
			var geometry: Geometry = this._geometry;
			if (geometry is LineString || geometry is Polygon || geometry is LinearRing)
				return createStraightLineSegmentApproximation(false);
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
