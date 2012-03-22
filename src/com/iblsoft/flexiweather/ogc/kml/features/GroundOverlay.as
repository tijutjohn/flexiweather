package com.iblsoft.flexiweather.ogc.kml.features
{
	import com.iblsoft.flexiweather.ogc.InteractiveLayerFeatureBase;
	import com.iblsoft.flexiweather.ogc.kml.interfaces.IKMLIconFeature;
	import com.iblsoft.flexiweather.ogc.kml.interfaces.IKMLLabeledFeature;
	import com.iblsoft.flexiweather.proj.Coord;
	import com.iblsoft.flexiweather.widgets.InteractiveWidget;


	/**
	*	Class that represents an Entry element within an Atom feed
	* 
	* 	@langversion ActionScript 3.0
	*	@playerversion Flash 8.5
	*	@tiptext
	* 
	* 	@see http://www.atomenabled.org/developers/syndication/atom-format-spec.php#rfc.section.4.1.2
	*/
	public class GroundOverlay extends Overlay implements IKMLLabeledFeature, IKMLIconFeature
	{
		private var _latLonBox:LatLonBox;
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
		public function GroundOverlay(kml: KML, s_namespace: String, x:XMLList)
		{
			super(kml, s_namespace, x);
			
			var kmlns:Namespace = new Namespace(s_namespace);

			createIcon();
			
			this._latLonBox = new LatLonBox(s_namespace, this.xml.kmlns::LatLonBox);
		}	
		
		/** Called after the feature is added to master or after any change (e.g. area change). */
		override public function update(): void
		{
			
			kmlLabel.text = name;
			
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
			super.update();
			
		}
		
		public function get latLonBox():LatLonBox {
			return this._latLonBox;
		}
		public override function toString():String {
			return "GroundOverlay: " + super.toString() + this._latLonBox;
		}
	}
}
