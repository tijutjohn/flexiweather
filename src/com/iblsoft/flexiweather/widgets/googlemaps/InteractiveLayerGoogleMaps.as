package com.iblsoft.flexiweather.widgets.googlemaps
{
	import com.google.maps.LatLng;
	import com.google.maps.LatLngBounds;
	import com.google.maps.Map3D;
	import com.google.maps.MapEvent;
	import com.google.maps.MapType;
	import com.google.maps.interfaces.IMapType;
	import com.iblsoft.flexiweather.ILayerConfiguration;
	import com.iblsoft.flexiweather.ogc.BBox;
	import com.iblsoft.flexiweather.proj.Coord;
	import com.iblsoft.flexiweather.proj.Projection;
	import com.iblsoft.flexiweather.utils.Serializable;
	import com.iblsoft.flexiweather.utils.Storage;
	import com.iblsoft.flexiweather.widgets.IConfigurableLayer;
	import com.iblsoft.flexiweather.widgets.InteractiveLayer;
	import com.iblsoft.flexiweather.widgets.InteractiveWidget;
	
	import flash.display.Graphics;
	import flash.events.Event;
	import flash.geom.Point;
	
	public class InteractiveLayerGoogleMaps extends InteractiveLayer implements Serializable, IConfigurableLayer
	{
		private var m_map: Map3D;
		private var mb_mapIsReady: Boolean;
		private var mb_mapIsInitialized: Boolean;
		
		private var m_cfg: GoogleMapLayerConfiguration;

		public function get configuration(): ILayerConfiguration
		{
			return m_cfg;
		}
		public function InteractiveLayerGoogleMaps(container:InteractiveWidget, cfg: GoogleMapLayerConfiguration)
		{
			super(container);
			
			m_cfg = cfg;
			
		}
		
		public function setAnimationModeEnable(value: Boolean): void
		{
			//do nothing
		}
		
		public function serialize(storage: Storage): void
		{
			trace("InteractiveLayerGoogleMaps serialize");
		}
		
		override protected  function createChildren():void
		{
			super.createChildren();
			
			m_map = new Map3D();
			//FIXME remove harcoded GoogleMap API Key to configuration
			m_map.sensor = "false";
			m_map.key="ABQIAAAAH8k5scGjdxg3Yv6Rib0PTRSGpsRUUtKRAxSpaWXDxfvzoVavuhRINMFI-z2FR2XOe7s5zVypkDNl4A";
			m_map.addEventListener(MapEvent.MAP_READY, onMapReady);
			
			addChild(m_map);
		}
		
		override protected function childrenCreated():void
		{
			super.childrenCreated();
			
			
			
		}
		
		private function onMapReady(event:Event):void 
		{
			mouseChildren = false;
			mouseEnabled = false;
			trace("GoogleMaps onMapReady");
			mb_mapIsReady = true;
			updateData(false);
//			dir = new Directions();
//			dir.addEventListener(DirectionsEvent.DIRECTIONS_SUCCESS,onDirectionsLoaded);
//			dir.load("645 Carlton Road, Markham, ON to Fawnbrook Circle, Markham, ON");
		}
		
		override public function onContainerSizeChanged(): void
		{
			super.onContainerSizeChanged();
			m_map.setSize(new Point(container.width, container.height));
			
		}
		
		override public function onAreaChanged(b_finalChange: Boolean): void
		{
			super.onAreaChanged(b_finalChange);
			if(b_finalChange) {
				updateData(false);
			}
			else
				invalidateDynamicPart();
		}
		
		private function initializeMap(): void
		{
			mb_mapIsInitialized = true;
			
//			m_map.enabled = false;
			m_map.disableControlByKeyboard();
			m_map.disableDragging();
			m_map.disableScrollWheelZoom();
			
			if (container)
				m_map.setSize(new Point(container.width, container.height));
			else
				m_map.setSize(new Point(width, height));
			m_map.x=0;
			m_map.y=0;
			
			m_map.mouseChildren = false;
			m_map.mouseEnabled = false;
			mouseChildren = false;
			mouseEnabled = false;
			
			//set view bbox on adding google maps to negotiate current bbox
			var _bbox: BBox = container.getViewBBox();
			trace("google maps initializeMap _bbox: " + _bbox);
			container.setViewBBox(_bbox, true);
		}
		
		override public function negotiateBBox(newBBox: BBox): BBox
		{
			if (m_map &&  mb_mapIsReady)
			{
				if (!mb_mapIsInitialized)
				{
					initializeMap();
				}
				
				var s_crs: String = container.getCRS();
				var _bbox: BBox = newBBox;
				
				
				var _swCoord: Coord = new Coord(s_crs, _bbox.xMin, _bbox.yMin).toLaLoCoord(); 
				var _neCoord: Coord = new Coord(s_crs, _bbox.xMax, _bbox.yMax).toLaLoCoord();
				
				var toDegree: Number =  1;//180 / Math.PI;
				var toRad: Number =  Math.PI / 180;
				 
				var _sw: LatLng = new LatLng(_swCoord.y * toDegree, _swCoord.x * toDegree);
				var _ne: LatLng = new LatLng(_neCoord.y * toDegree, _neCoord.x * toDegree);  
				
//				var _bounds: LatLngBounds = new LatLngBounds(_sw, _ne);  
				
				var _bounds: LatLngBounds = new LatLngBounds();
				_bounds.extend(_sw);  
				_bounds.extend(_ne);  
				
				trace("OLD ZOOM: " + m_map.getZoom());
				var f_zoom: Number = m_map.getBoundsZoomLevel(_bounds);
				var _center: LatLng = _bounds.getCenter();  
	//			var zoom: Number = 3;
				if (isNaN(f_zoom))
				{
					f_zoom = 3;
				}
	  			trace("zoom: " + f_zoom)
	  			trace("_center: " + _center);
	  			try {
//	  				m_map.setCenter(new LatLng(40.736072,-73.992062), 14, MapType.NORMAL_MAP_TYPE);
					m_map.setCenter(_center, f_zoom);
	  			} catch (err: Error) {
	  				trace("GoogleMaps setCenter error: " + err.message);
	  			}
	  			
	  			trace("old _bounds: " + _bounds)
	  			_bounds = m_map.getLatLngBounds();
	  			trace("new _bounds: " + _bounds)
	  			
	  			var _projection: Projection = Projection.getByCRS(s_crs);
	  			var f_westLongRad: Number = _bounds.getWest() * toRad;
	  			var f_eastLongRad: Number = _bounds.getEast() * toRad;
	  			var f_northLatRad: Number = _bounds.getNorth() * toRad;
	  			var f_southLatRad: Number = _bounds.getSouth() * toRad;
	  			
	  			var _swPoint: Point = _projection.laLoToPrjPt(f_westLongRad, f_southLatRad);
	  			var _nePoint: Point = _projection.laLoToPrjPt(f_eastLongRad, f_northLatRad);
//	  			var _googleMapsBBox: BBox = new BBox(_swPoint.x, _swPoint.y, _nePoint.x, _nePoint.y);
	  			var _googleMapsBBox: BBox = new BBox(_swPoint.x, _swPoint.y, _nePoint.x, _nePoint.y);
	  			
	  			trace("InteractiveLayerGoogleMaps negotiateBBox oldBBox: " + _bbox.toLaLoString(s_crs));
	  			trace("InteractiveLayerGoogleMaps negotiateBBox newBBox: " + _googleMapsBBox.toLaLoString(s_crs));
	  			
	  			//test
//	  			_swCoord = new Coord(s_crs, _googleMapsBBox.xMin, _googleMapsBBox.yMin).toLaLoCoord(); 
//				_neCoord = new Coord(s_crs, _googleMapsBBox.xMax, _googleMapsBBox.yMax).toLaLoCoord();
//				trace("new bbox coords: " + _swCoord.toNiceString() + " | " + _neCoord.toNiceString());
	  			return _googleMapsBBox;
			}
			
			return newBBox;
		}
		
		private function getCenter(bounds: LatLngBounds): LatLng
		{
			var sw: LatLng = bounds.getSouthWest();
			var ne: LatLng = bounds.getNorthEast();
			
			var center1: LatLng = bounds.getCenter();
			
			var minLat: Number = Math.min(sw.lat(), ne.lat());
			var maxLat: Number = Math.max(sw.lat(), ne.lat());
			var minLng: Number = Math.min(sw.lng(), ne.lng());
			var maxLng: Number = Math.max(sw.lng(), ne.lng());
			var center2: LatLng = new LatLng(minLat + (maxLat - minLat) / 2, minLng  + (maxLng - minLng) / 2);
			
			trace("getCenter  1: " + center1 + " center2: " + center2);
			return center2;
		}
		public function updateData(b_forceUpdate: Boolean): void
		{
			if (m_map &&  mb_mapIsReady)
			{
				if (!mb_mapIsInitialized)
				{
					initializeMap();
				}
//				var _swCoord: Coord = new Coord(s_crs, _bbox.yMin, _bbox.xMin).toLaLoCoord(); 
//				var _neCoord: Coord = new Coord(s_crs, _bbox.yMax, _bbox.xMax).toLaLoCoord(); 
				var s_crs: String = container.getCRS();
				var _bbox: BBox = container.getViewBBox();
				
				var _swCoord: Coord = new Coord(s_crs, _bbox.xMin, _bbox.yMin).toLaLoCoord(); 
				var _neCoord: Coord = new Coord(s_crs, _bbox.xMax, _bbox.yMax).toLaLoCoord();
				
				var toDegree: Number =  1;// 180 / Math.PI;
				 
				var _sw: LatLng = new LatLng(_swCoord.y * toDegree, _swCoord.x * toDegree);
				var _ne: LatLng = new LatLng(_neCoord.y * toDegree, _neCoord.x * toDegree);  
//				var _bounds: LatLngBounds = new LatLngBounds(_sw, _ne);  
	  			
	  			var _bounds: LatLngBounds = new LatLngBounds();
				_bounds.extend(_sw);  
				_bounds.extend(_ne);  
				
				var _currBounds: LatLngBounds = m_map.getLatLngBounds();
				if (_bounds.equals(_currBounds))
				{
					//do not do anything, bounds are already set corretly)
					trace("do not do anything, bounds are already set corretly");
					return;
				}
	  			trace("InteractiveLayerGoogleMaps updateData bbox: " + _bbox.toLaLoString(s_crs))
//	  			trace("_swCoord: " + _swCoord)
//	  			trace("_neCoord: " + _neCoord)
//	  			trace("_sw: " + _sw)
//	  			trace("_ne: " + _ne)
	  			trace("InteractiveLayerGoogleMaps updateData _bounds: " + _bounds)
	  			
				// Create a bounding box  
	  
				// Center map in the center of the bounding box  
				// and calculate the appropriate zoom level
				var f_zoom: Number = m_map.getBoundsZoomLevel(_bounds);
//				var _center: LatLng = _bounds.getCenter();  
				var _center: LatLng = getCenter(_bounds);
	//			var zoom: Number = 3;
				if (isNaN(f_zoom)) {
//					f_zoom = 3;
					callLater(updateData, [b_forceUpdate]);
					return;
				}
	  			trace("InteractiveLayerGoogleMaps updateData zoom: " + f_zoom)
	  			trace("InteractiveLayerGoogleMaps updateData _center: " + _center);
	  			try {
//	  				m_map.setCenter(new LatLng(40.736072,-73.992062), 14, MapType.NORMAL_MAP_TYPE);
					m_map.setCenter(_center, f_zoom);
	  			} catch (err: Error) {
	  				trace("GoogleMaps setCenter error: " + err.message);
	  			}
	  			
	  			trace("InteractiveLayerGoogleMaps updateData old _bounds: " + _bounds)
	  			_bounds = m_map.getLatLngBounds();
	  			trace("InteractiveLayerGoogleMaps updateData new _bounds: " + _bounds)
	  			
			} else {
				callLater(updateData, [b_forceUpdate]);
			}

		}
		
		
		override public function renderPreview(graphics: Graphics, f_width: Number, f_height: Number): void
		{
//			if(m_image != null) {
//				var matrix: Matrix = new Matrix();
//				matrix.translate(-f_width / 3, -f_width / 3);
//				matrix.scale(3, 3);
//				matrix.translate(m_image.width / 3, m_image.height / 3);
//				matrix.invert();
//  				graphics.beginBitmapFill(m_image.bitmapData, matrix, false, true);
//				graphics.drawRect(0, 0, f_width, f_height);
//				graphics.endFill();
//			}
//			if(!mb_imageOK) {
				graphics.lineStyle(2, 0xcc0000, 0.7, true);
				graphics.moveTo(0, 0);
				graphics.lineTo(f_width - 1, f_height - 1);
				graphics.moveTo(0, f_height - 1);
				graphics.lineTo(f_width - 1, 0);
//			}
		}
		
		public function setMapType(type: IMapType): void
		{
			m_map.setMapType(type);
		}
		
	}
}