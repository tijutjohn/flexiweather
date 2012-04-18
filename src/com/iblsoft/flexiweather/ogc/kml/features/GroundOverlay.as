package com.iblsoft.flexiweather.ogc.kml.features
{
	import com.iblsoft.flexiweather.ogc.FeatureUpdateContext;
	import com.iblsoft.flexiweather.ogc.InteractiveLayerFeatureBase;
	import com.iblsoft.flexiweather.ogc.kml.InteractiveLayerKML;
	import com.iblsoft.flexiweather.ogc.kml.interfaces.IKMLIconFeature;
	import com.iblsoft.flexiweather.ogc.kml.interfaces.IKMLLabeledFeature;
	import com.iblsoft.flexiweather.ogc.kml.renderer.IKMLRenderer;
	import com.iblsoft.flexiweather.proj.Coord;
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
		
		public override function cleanup():void
		{
			super.cleanup();
			
			trace("GroundOverlay cleanup");
			if (_latLonBox)
			{
				_latLonBox.cleanupKML();
				_latLonBox = null;
			}
		}
		
//		override public function getCenter(): Coord
//		{
//			var coord: Coord;
//			var lat: Number = latLonBox.north + (latLonBox.south - latLonBox.north)/2 
//			var lon: Number = latLonBox.west + (latLonBox.east - latLonBox.west)/2 
//			
//			coord = new Coord('CRS:84', lat, lon);
//			
//			return coord;
//		}
		
		/** Called after the feature is added to master or after any change (e.g. area change). */
		override public function update(changeFlag: FeatureUpdateContext): void
		{
			if (kmlLabel)
				kmlLabel.text = name;
			
			if (changeFlag.anyChange)
				mb_pointsDirty = true;
			
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
			
			var renderer: IKMLRenderer = (master as InteractiveLayerKML).itemRendererInstance;
			if (changeFlag.fullUpdateNeeded)
			{
				renderer.render(this, master.container);
			} else {
				if (changeFlag.significantlyChanged || changeFlag.viewBBoxSizeChanged)
				{
					renderer.render(this, master.container);
				}
			}
			
			var points: ArrayCollection = getPoints();
			if (points.length != 4)
			{
				trace("we expect 4 points in GroundLevel");
			} else {
				var nwp: flash.geom.Point = points.getItemAt(0) as flash.geom.Point;
				var nep: flash.geom.Point = points.getItemAt(1) as flash.geom.Point;
//				var sep: flash.geom.Point = points.getItemAt(2) as flash.geom.Point;
//				var swp: flash.geom.Point = points.getItemAt(3) as flash.geom.Point;
				
				x = nwp.x;// + (ne.x - nw.x) / 2;
				y = nep.y;// + (se.y - ne.y) / 2;
				trace("roundOverlay update pos: ["+x+","+y+"]")
//					_container.labelLayout.updateObjectReferenceLocation(this);
			}
			super.update(changeFlag);
			
		}
		
		public function get latLonBox():LatLonBox {
			return this._latLonBox;
		}
		public override function toString():String {
			return "GroundOverlay: " + super.toString() + this._latLonBox;
		}
	}
}
