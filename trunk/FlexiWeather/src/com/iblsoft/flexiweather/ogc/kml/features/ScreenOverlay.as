package com.iblsoft.flexiweather.ogc.kml.features
{
	import com.iblsoft.flexiweather.ogc.FeatureUpdateContext;
	import com.iblsoft.flexiweather.ogc.InteractiveLayerFeatureBase;
	import com.iblsoft.flexiweather.ogc.kml.InteractiveLayerKML;
	import com.iblsoft.flexiweather.ogc.kml.data.KMLReflectionData;
	import com.iblsoft.flexiweather.ogc.kml.renderer.IKMLRenderer;

	public class ScreenOverlay extends Overlay
	{
		private var _overlayXY: KMLVec2;
		private var _screenXY: KMLVec2;
		private var _rotationXY: KMLVec2;
		private var _size: KMLVec2;

		public function ScreenOverlay(kml: KML, s_namespace: String, x: XMLList)
		{
			super(kml, s_namespace, x);
			var kmlns: Namespace = new Namespace(s_namespace);
			createIcon();
			var overlayXYxml: XML = (this.xml.kmlns::overlayXY)[0] as XML;
			var screenXYxml: XML = (this.xml.kmlns::screenXY)[0] as XML;
			var rotationXYxml: XML = (this.xml.kmlns::rotationXY)[0] as XML;
			var sizeXml: XML = (this.xml.kmlns::size)[0] as XML;
			if (overlayXYxml)
				this._overlayXY = new KMLVec2(overlayXYxml);
			if (screenXYxml)
				this._screenXY = new KMLVec2(screenXYxml);
			if (rotationXYxml)
				this._rotationXY = new KMLVec2(rotationXYxml);
			if (sizeXml)
				this._size = new KMLVec2(sizeXml);
		}

		public override function cleanup(): void
		{
			super.cleanup();
			if (_overlayXY)
				_overlayXY = null;
			if (_screenXY)
				_screenXY = null;
			if (_rotationXY)
				_rotationXY = null;
			if (_size)
				_size = null;
		}

		/** Called after the feature is added to master or after any change (e.g. area change). */
		override public function update(changeFlag: FeatureUpdateContext): void
		{
			// FIXME  update should be done after dictionary will be created
			if (!_kmlReflectionDictionary)
				return;
			if (kmlLabel)
				kmlLabel.text = name;
			/*
			if(mb_pointsDirty)
			{
				var iw: InteractiveWidget = m_master.container;
				var c: Coord;
				var coord: Object;
				var geometryCoordinates: Coordinates;

				//TODO need to find better solutions for all classes which have coordinates

				//order of coordinates inserted: NorthWest, NorthEast, SouthEast, SouthWest

				var coordsArray: Array = [];//coordinates;
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
			*/
			updateCoordsReflections();
			_kmlReflectionDictionary.updateKMLFeature(this);
			var reflection: KMLReflectionData = _kmlReflectionDictionary.getReflection(0) as KMLReflectionData;
			if (master)
			{
				var renderer: IKMLRenderer = (master as InteractiveLayerKML).itemRendererInstance;
				if (changeFlag.fullUpdateNeeded)
					renderer.render(this, master.container);
			}
			super.update(changeFlag);
		}

		public function get overlayXY(): KMLVec2
		{
			return this._overlayXY;
		}

		public function get screenXY(): KMLVec2
		{
			return this._screenXY;
		}

		public function get rotationXY(): KMLVec2
		{
			return this._rotationXY;
		}

		public function get size(): KMLVec2
		{
			return this._size;
		}
	}
}
