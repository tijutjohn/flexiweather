package com.iblsoft.flexiweather.widgets.googlemaps
{
	import com.google.maps.LatLng;
	import com.google.maps.LatLngBounds;
	import com.google.maps.Map;
	import com.google.maps.Map3D;
	import com.google.maps.MapAction;
	import com.google.maps.MapEvent;
	import com.google.maps.MapMouseEvent;
	import com.google.maps.MapOptions;
	import com.google.maps.MapType;
	import com.google.maps.MapZoomEvent;
	import com.google.maps.View;
	import com.google.maps.interfaces.IMapType;
	import com.iblsoft.flexiweather.ogc.BBox;
	import com.iblsoft.flexiweather.ogc.ILayerConfiguration;
	import com.iblsoft.flexiweather.proj.Coord;
	import com.iblsoft.flexiweather.proj.Projection;
	import com.iblsoft.flexiweather.utils.Serializable;
	import com.iblsoft.flexiweather.utils.Storage;
	import com.iblsoft.flexiweather.widgets.IConfigurableLayer;
	import com.iblsoft.flexiweather.widgets.InteractiveDataLayer;
	import com.iblsoft.flexiweather.widgets.InteractiveLayer;
	import com.iblsoft.flexiweather.widgets.InteractiveWidget;
	
	import flash.display.Bitmap;
	import flash.display.Graphics;
	import flash.events.Event;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.utils.setTimeout;
	
	import mx.collections.ArrayCollection;
	
	public class InteractiveLayerGoogleMaps extends InteractiveDataLayer implements Serializable, IConfigurableLayer
	{
		public static const MAP_UDPATED: String = 'mapUpdated';
		
//		private var m_map: Map3D;
		private var m_map: Map;
		private var mb_mapIsReady: Boolean;
		private var mb_mapIsInitialized: Boolean;
		
		public var negotiatedBBoxes: ArrayCollection = new ArrayCollection();
		
		private var m_cfg: GoogleMapLayerConfiguration;

		private var _mapType: String;
		public function get mapType(): String
		{
			return _mapType;
		}
		public function get configuration(): ILayerConfiguration
		{
			return m_cfg;
		}
		public function InteractiveLayerGoogleMaps(container:InteractiveWidget, cfg: GoogleMapLayerConfiguration)
		{
			super(container);
			
			m_cfg = cfg;
			
		}
		
		override public function toString(): String
		{
			if (m_map && m_map.isLoaded())
			{
				return 'InteractiveLayerGoogleMaps ['+uid+'] type: ';
			}
			return 'InteractiveLayerGoogleMaps ['+uid+']';
		}
		
		public function setAnimationModeEnable(value: Boolean): void
		{
			//do nothing
		}
		
		public function serialize(storage: Storage): void
		{
//			customTrace("InteractiveLayerGoogleMaps serialize");
			
			if (storage.isLoading())
			{
				var newAlpha: Number = storage.serializeNumber("transparency", alpha);
				if (newAlpha < 1)
				{
					alpha = newAlpha;
				}
				_mapType = storage.serializeString('map-type', _mapType);
			} else {
				storage.serializeString('map-type', _mapType, GoogleMapLayerConfiguration.MAP_TYPE_NORMAL);
				if (alpha < 1)
					storage.serializeNumber("transparency", alpha);
			}	
		}
		
		public static var mapID: int = 0;
		
		override protected  function createChildren():void
		{
			super.createChildren();
			
			//FIXME why is this call 3 times??
			
			if (!m_map)
			{
				mapID++;
				
				m_map = new Map();
				m_map.id = mapID.toString();
				
				//FIXME remove harcoded GoogleMap API Key to configuration
				m_map.sensor = "false";
				m_map.key="ABQIAAAAH8k5scGjdxg3Yv6Rib0PTRSGpsRUUtKRAxSpaWXDxfvzoVavuhRINMFI-z2FR2XOe7s5zVypkDNl4A";
				
				//this must be set, otherwise google maps will not work in AIR (on mobiles)
				m_map.url = 'http://www.iblsoft.com';
				
				m_map.addEventListener(MapEvent.COMPONENT_INITIALIZED, onComponentInitialized);
				m_map.addEventListener(MapEvent.MAP_READY, onMapReady);
				m_map.addEventListener(MapEvent.MAP_READY_INTERNAL, onMapReadyInternal);
				m_map.addEventListener(MapEvent.MAP_PREINITIALIZE, onMapPreinitialize);
				m_map.addEventListener(MapEvent.VIEW_CHANGED, onMapViewChanged);
				m_map.addEventListener(MapEvent.TILES_LOADED, onMapTilesLoaded);
				m_map.addEventListener(MapZoomEvent.ZOOM_CHANGED, onMapZoomChanged);
	//			m_map.addEventListener(MapMouseEvent.DRAG_START, onMapDragStart);
	//			m_map.addEventListener(MapMouseEvent.DRAG_STEP, onMapDragStep);
				m_map.percentWidth = 100;
				m_map.percentHeight = 100;
				addChild(m_map);
			}
		}
		
		protected function onMapZoomChanged(event:MapZoomEvent):void
		{
			// TODO Auto-generated method stub
//			customTrace("Google Maps ["+m_map.id+"] zoom changed: " + event.zoomLevel + " ("+m_map.getZoom()+") feature: " + event.feature);
		}
		
		private function onMapViewChanged(event:MapEvent):void
		{
			// TODO Auto-generated method stub
			var viewbbox: BBox = getViewBBox();
//			customTrace("Google Maps ["+m_map.id+"] view changed:  feature: " + event.feature);
			
		}
		private function onMapTilesLoaded(event:MapEvent):void
		{
			// TODO Auto-generated method stub
			var viewbbox: BBox = getViewBBox();
//			customTrace("Google Maps ["+m_map.id+"] onMapTilesLoaded zoom: " + m_map.getZoom() + " center: " + m_map.getCenter());
			
		}
		
		private function onComponentInitialized(event:MapEvent):void
		{
//			customTrace(this + " onComponentInitialized");
			
		}
		private function onMapReadyInternal(event:MapEvent):void
		{
//			customTrace(this + " onMapReadyInternal");
			
		}
		private function onMapPreinitialize(event:MapEvent):void
		{
//			customTrace(this + " onMapPreinitialize");
			var mapOptions: MapOptions = new MapOptions();
			var mapType: String = m_cfg.mapType;
			if (_mapType)
				mapType = _mapType;

			mapOptions.mapType = getGoogleMapType(mapType);
			
			(event.currentTarget as Map).setInitOptions(mapOptions);
		}
		
		private function getGoogleMapType(type: String): IMapType
		{
			switch (type)
			{
				case GoogleMapLayerConfiguration.MAP_TYPE_NORMAL:
					return MapType.NORMAL_MAP_TYPE;
					break;
				case GoogleMapLayerConfiguration.MAP_TYPE_PHYSICAL:
					return MapType.PHYSICAL_MAP_TYPE;
					break;
				case GoogleMapLayerConfiguration.MAP_TYPE_SATELLITE:
					return MapType.SATELLITE_MAP_TYPE;
					break;
				case GoogleMapLayerConfiguration.MAP_TYPE_HYBRID:
					return MapType.HYBRID_MAP_TYPE;
					break;
			}
			return MapType.NORMAL_MAP_TYPE;
		}
		private function getMapTypeFromGoogleMapType(type: IMapType): String
		{
			switch (type)
			{
				case MapType.NORMAL_MAP_TYPE:
					return GoogleMapLayerConfiguration.MAP_TYPE_NORMAL;
					break;
				case MapType.PHYSICAL_MAP_TYPE:
					return GoogleMapLayerConfiguration.MAP_TYPE_PHYSICAL;
					break;
				case MapType.SATELLITE_MAP_TYPE:
					return GoogleMapLayerConfiguration.MAP_TYPE_SATELLITE;
					break;
				case MapType.HYBRID_MAP_TYPE:
					return GoogleMapLayerConfiguration.MAP_TYPE_HYBRID;
					break;
			}
			return GoogleMapLayerConfiguration.MAP_TYPE_NORMAL;
		}
		
		private function onMapReady(event:Event):void 
		{
			m_map.disableDragging();
			m_map.disableContinuousZoom();
			
//			mouseChildren = false;
//			mouseEnabled = false;
			
//			customTrace(this + " onMapReady");
			mb_mapIsReady = true;
		}

		override public function destroy(): void
		{
			super.destroy();
			if (m_map)
			{
				mb_mapIsInitialized = false;
				m_map.removeEventListener(MapEvent.MAP_READY, onMapReady);
//				m_map.unload();
				removeChild(m_map);
				
				m_map = null;
			}
		}
		
		
		override public function onContainerSizeChanged(): void
		{
			super.onContainerSizeChanged();
			m_map.setSize(new Point(container.width, container.height));
			
		}
		private function showMap(): void
		{
			if (m_map)
				m_map.visible = true;
			
		}
		private function hideMap(): void
		{
			if (m_map)
				m_map.visible = false;
			
		}
		private function inCRSCompatible(): Boolean
		{
			var newCRS: String = container.crs;
			if (newCRS != 'EPSG:900913')
			{
				hideMap();
				return false;
			}
			
			showMap();
			return true;
			
		}
		override public function onAreaChanged(b_finalChange: Boolean): void
		{
			super.onAreaChanged(b_finalChange);
			
			//check if CRS is supported
			if (!inCRSCompatible())
				return;
			
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
			m_map.disableContinuousZoom();
			m_map.disableDragging();
			m_map.disableScrollWheelZoom();
//			m_map.viewMode = View.VIEWMODE_2D;
			
			if (container)
				m_map.setSize(new Point(container.width, container.height));
			else
				m_map.setSize(new Point(width, height));
			m_map.x=0;
			m_map.y=0;
			
			m_map.width = container.width;
			m_map.height = container.height;
			
			m_map.mouseChildren = false;
			m_map.mouseEnabled = false;
			mouseChildren = false;
			mouseEnabled = false;
			
			_layerJustCreated = true;
			
			callLater(setInitialBBoxRequest);
//			setTimeout(setInitialBBoxRequest, 1000);
		}
		
		private function setInitialBBoxRequest(): void
		{
//			set view bbox on adding google maps to negotiate current bbox
			var _bbox: BBox = container.getViewBBox();
//			customTrace(this + "  initializeMap SET _bbox: " + _bbox + " LaLo: " + _bbox.toLaLoString(container.getCRS()));
			container.setViewBBox(_bbox, true);
			
		}
		public function getViewBBox(): BBox
		{ 
			if (m_map)
			{
				var bbox: BBox;
				
				try {
					var latLngBounds: LatLngBounds = m_map.getLatLngBounds();
					bbox= new BBox(latLngBounds.getSouth(), latLngBounds.getWest(), latLngBounds.getNorth(), latLngBounds.getEast());
//					customTrace("InteractiveLayerGoogleMaps getViewBBox ["+m_map.id+"] latLngBounds: " + latLngBounds);
//					customTrace("InteractiveLayerGoogleMaps getViewBBox ["+m_map.id+"] bbox: " + bbox.toLaLoString("CRS:84"));
				} catch (e: Error) {
					bbox = new BBox(0,0,0,0);
				} finally {
					
				}				
				return bbox;
			}
			return null; 
		}
		
		private var _layerJustCreated: Boolean;
		override public function negotiateBBox(newBBox: BBox, changeZoom: Boolean = true): BBox
		{
			if (!inCRSCompatible())
				return newBBox;

			//TODO need to be sure, that newBBox is set with CRS from container...otherwise newBBox.toLaLoString(s_crs) will be wrong..
			
			var s_crs: String = container.getCRS();
//			customTrace("InteractiveLayerGoogleMaps negotiateBBox: ["+m_map.id+"] START: " + newBBox.toBBOXString());
//			customTrace("InteractiveLayerGoogleMaps negotiateBBox: ["+m_map.id+"] START lalo: " + newBBox.toLaLoString(s_crs));
			if (_layerJustCreated)
			{
				//for the first time after layer creation always change zoom (because CRS of widget is not changed, but layer is added as new layer, so it needs to set correct zoom
				changeZoom = true;
				_layerJustCreated = false;
			}
			if (m_map &&  mb_mapIsReady)
			{
				if (!mb_mapIsInitialized)
				{
					initializeMap();
					return newBBox;
				}
			
				
				
				var _bbox: BBox = newBBox;
				
				
				var _swCoord: Coord = new Coord(s_crs, _bbox.xMin, _bbox.yMin).toLaLoCoord(); 
				var _neCoord: Coord = new Coord(s_crs, _bbox.xMax, _bbox.yMax).toLaLoCoord();
				
				var toDegree: Number =  1;//180 / Math.PI;
				var toRad: Number =  Math.PI / 180;
				 
				var _sw: LatLng = new LatLng(_swCoord.y * toDegree, _swCoord.x * toDegree);
				var _ne: LatLng = new LatLng(_neCoord.y * toDegree, _neCoord.x * toDegree);  
				
				var _bounds: LatLngBounds = new LatLngBounds(_sw, _ne);  
				var _origMapCenter: LatLng = getCenter(_bounds);
				var _origMapCenter2: LatLng = m_map.getCenter();
				var oldZoom: Number = m_map.getZoom();
				var f_zoom: Number = getZoom(_bounds);
				
//				customTrace("InteractiveLayerGoogleMaps negotiateBBox: START PROPS: zoom: OLD: " + oldZoom + " NEW: " + f_zoom + " CENTER: OLD: " + _origMapCenter2 + " NEW: " + _origMapCenter);
				if (changeZoom)
				{
					if (isNaN(f_zoom))
					{
						setTimeout(delayedSetCenter, 500, _bbox, _bounds, -1, changeZoom);
						return newBBox;
					}
				}
				var _origBBoxCenter: Point = _bbox.center;
				
				var _centerCoord: Coord = new Coord(s_crs, _origBBoxCenter.x, _origBBoxCenter.y).toLaLoCoord(); 
				var _center: LatLng = new LatLng(_centerCoord.y, _centerCoord.x, true);
				
//	  			customTrace("\nGoogle Maps maps center: " + _center.lng() + " , " + _center.lat());
//	  			customTrace("Google Maps bbox center: " + _centerCoord.x + " , " + _centerCoord.y);
//	  			customTrace("\nGoogle Maps negotiateBBox SIZE: " + m_map.width + " , " + m_map.height);
				
//	  			customTrace("Google Maps negotiateBBox newBBox: " + newBBox + " changeZoom: " + changeZoom)
//	  			customTrace("Google Maps negotiateBBox _bounds: " + _bounds)
//	  			customTrace("Google Maps negotiateBBox zoom: " + f_zoom + " old zoom: " + oldZoom)
//	  			customTrace("_center: " + _center);
	  			try {
					if (changeZoom)
					{
						m_map.setCenter(_center, f_zoom);
					} else {
						m_map.setCenter(_center);
					}
	  			} catch (err: Error) {
	  				customTrace("GoogleMaps setCenter error: " + err.message);
					setTimeout(delayedSetCenter, 500, _bbox, _bounds, f_zoom, changeZoom);
//					callLater(delayedSetCenter(_center, f_zoom));
					return newBBox;
	  			}
	  			
//	  			customTrace("old _bounds: " + _bounds)
	  			_bounds = m_map.getLatLngBounds();
//	  			customTrace("new _bounds: " + _bounds)
	  			
	  			var _projection: Projection = Projection.getByCRS(s_crs);
	  			var f_westLongRad: Number = _bounds.getWest() * toRad;
	  			var f_eastLongRad: Number = _bounds.getEast() * toRad;
	  			var f_northLatRad: Number = _bounds.getNorth() * toRad;
	  			var f_southLatRad: Number = _bounds.getSouth() * toRad;
	  			
	  			var _swPoint: Point = _projection.laLoToPrjPt(f_westLongRad, f_southLatRad);
	  			var _nePoint: Point = _projection.laLoToPrjPt(f_eastLongRad, f_northLatRad);
//	  			var _googleMapsBBox: BBox = new BBox(_swPoint.x, _swPoint.y, _nePoint.x, _nePoint.y);
	  			var _googleMapsBBox: BBox = new BBox(_swPoint.x, _swPoint.y, _nePoint.x, _nePoint.y);
	  			
//	  			customTrace("InteractiveLayerGoogleMaps negotiateBBox oldBBox: " + _bbox.toLaLoString(s_crs));
//	  			customTrace("InteractiveLayerGoogleMaps negotiateBBox newBBox: " + _googleMapsBBox.toLaLoString(s_crs));
	  			
	  			//test
//	  			_swCoord = new Coord(s_crs, _googleMapsBBox.xMin, _googleMapsBBox.yMin).toLaLoCoord(); 
//				_neCoord = new Coord(s_crs, _googleMapsBBox.xMax, _googleMapsBBox.yMax).toLaLoCoord();
//				customTrace("new bbox coords: " + _swCoord.toNiceString() + " | " + _neCoord.toNiceString());
				
//				customTrace("InteractiveLayerGoogleMaps negotiateBBox: ["+m_map.id+"] END 2: " + _googleMapsBBox.toBBOXString());
//				customTrace("InteractiveLayerGoogleMaps negotiateBBox: ["+m_map.id+"] END 2 lalo: " + _googleMapsBBox.toLaLoString(s_crs));
				
				//at the end set original center and bounds back
//				customTrace("InteractiveLayerGoogleMaps negotiateBBox: ["+m_map.id+"] set props back zoom: " + oldZoom + " , center: " + _origMapCenter2);
//				m_map.setCenter(_origMapCenter2, oldZoom);
//				customTrace("InteractiveLayerGoogleMaps negotiateBBox: ["+m_map.id+"] end PROPS: zoom: : " + m_map.getZoom() + " CENTER: " + m_map.getCenter());
				
				dispatchEvent(new Event(MAP_UDPATED));
				
				negotiatedBBoxes.addItemAt(_googleMapsBBox, 0);
				
	  			return _googleMapsBBox;
			}
//			customTrace("InteractiveLayerGoogleMaps negotiateBBox: ["+m_map.id+"] END 1: " + newBBox.toBBOXString());
//			customTrace("InteractiveLayerGoogleMaps negotiateBBox: ["+m_map.id+"] END 1 lalo: " + newBBox.toLaLoString(s_crs));
			
			return newBBox;
		}
		
		
		private function delayedSetCenter(_bbox: BBox, _bounds: LatLngBounds, f_zoom: Number, changeZoom: Boolean): void
		{
			if (changeZoom)
			{
				// if f_zoom was -1, it was not possible top set it before, get zoom now
				if (f_zoom == -1)
				{
					var oldZoom: Number = m_map.getZoom();
					f_zoom = getZoom(_bounds);
					if (isNaN(f_zoom))
					{
						setTimeout(delayedSetCenter, 500, _bbox, _bounds, -1, true);
						return;
					}
				}
			}
			var s_crs: String = container.getCRS();
			
			var _origBBoxCenter: Point = _bbox.center;
			var _centerCoord: Coord = new Coord(s_crs, _origBBoxCenter.x, _origBBoxCenter.y).toLaLoCoord(); 
			var _center: LatLng = new LatLng(_centerCoord.y, _centerCoord.x, true);
			
			try {
				if (changeZoom)
				{
					m_map.setCenter(_center, f_zoom);
				} else {
					m_map.setCenter(_center);
				}
			} catch (err: Error) {
				customTrace("GoogleMaps delayedSetCenter setCenter error: " + err.message);
//				callLater(delayedSetCenter(_center, f_zoom));
				setTimeout(delayedSetCenter, 500, _bbox, _bounds, f_zoom, changeZoom);
				return;
			}
			
			var _bounds: LatLngBounds = m_map.getLatLngBounds();
			
			var toRad: Number =  Math.PI / 180;
			
			var _projection: Projection = Projection.getByCRS(s_crs);
			var f_westLongRad: Number = _bounds.getWest() * toRad;
			var f_eastLongRad: Number = _bounds.getEast() * toRad;
			var f_northLatRad: Number = _bounds.getNorth() * toRad;
			var f_southLatRad: Number = _bounds.getSouth() * toRad;
			
			var _swPoint: Point = _projection.laLoToPrjPt(f_westLongRad, f_southLatRad);
			var _nePoint: Point = _projection.laLoToPrjPt(f_eastLongRad, f_northLatRad);
			var _googleMapsBBox: BBox = new BBox(_swPoint.x, _swPoint.y, _nePoint.x, _nePoint.y);
			
			
			container.setViewBBox(_googleMapsBBox, true, true);
		}
		
		private function getZoom(_bounds: LatLngBounds): Number
		{
			var f_zoom: Number = m_map.getBoundsZoomLevel(_bounds);
//			customTrace("GET ZOOM: " + f_zoom + " for bounds: " + _bounds);
			return f_zoom;
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
			
//			customTrace("getCenter  1: " + center1 + " center2: " + center2);
			return center2;
		}
		public function updateData(b_forceUpdate: Boolean): void
		{
			if (!inCRSCompatible())
				return;

			if (m_map &&  mb_mapIsReady)
			{
				if (!mb_mapIsInitialized)
				{
					initializeMap();
					callLater(updateData, [b_forceUpdate]);
					return;
				}
				if (container.width > 0 && container.height > 0)
				{
					m_map.width = container.width;
					m_map.height = container.height;
				}
				
				var s_crs: String = container.getCRS();
				var _bbox: BBox = container.getViewBBox();
				
//				customTrace("\n\nGoogleMaps ["+m_map.id+"]  updateData: to ["+s_crs+"] bbox: " + _bbox.toLaLoString(s_crs));
					
				var _swCoord: Coord = new Coord(s_crs, _bbox.xMin, _bbox.yMin).toLaLoCoord(); 
				var _neCoord: Coord = new Coord(s_crs, _bbox.xMax, _bbox.yMax).toLaLoCoord();
				
				var toDegree: Number =  1;// 180 / Math.PI;
				 
				var _sw: LatLng = new LatLng(_swCoord.y * toDegree, _swCoord.x * toDegree);
				var _ne: LatLng = new LatLng(_neCoord.y * toDegree, _neCoord.x * toDegree);  
	  			
				var _bounds: LatLngBounds = new LatLngBounds(_sw, _ne);  
				
				
				var _currBounds: LatLngBounds = m_map.getLatLngBounds();
				if (_bounds.equals(_currBounds))
				{
					//do not do anything, bounds are already set corretly)
//					customTrace("do not do anything, bounds are already set corretly");
					return;
				}
//	  			customTrace("InteractiveLayerGoogleMaps updateData bbox: " + _bbox.toLaLoString(s_crs))
//	  			customTrace("_swCoord: " + _swCoord)
//	  			customTrace("_neCoord: " + _neCoord)
//	  			customTrace("_sw: " + _sw)
//	  			customTrace("_ne: " + _ne)
//	  			customTrace("InteractiveLayerGoogleMaps updateData ["+m_map.id+"]  _bounds: " + _bounds)
	  			
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
//	  			customTrace("\n InteractiveLayerGoogleMaps updateData ["+m_map.id+"] zoom: " + f_zoom)
//	  			customTrace("InteractiveLayerGoogleMaps updateData _center: " + _center);
	  			try {
//	  				m_map.setCenter(new LatLng(40.736072,-73.992062), 14, MapType.NORMAL_MAP_TYPE);
					m_map.setCenter(_center, f_zoom);
	  			} catch (err: Error) {
	  				customTrace("GoogleMaps setCenter error: " + err.message);
	  			}
	  			
//	  			customTrace("InteractiveLayerGoogleMaps updateData ["+m_map.id+"] old _bounds: " + _bounds)
	  			_bounds = m_map.getLatLngBounds();
//	  			customTrace("InteractiveLayerGoogleMaps updateData ["+m_map.id+"] new _bounds: " + _bounds)
				
//				customTrace("InteractiveLayerGoogleMaps updateData: ["+m_map.id+"] end PROPS: zoom: : " + m_map.getZoom() + " CENTER: " + m_map.getCenter());
				var currViewBBox: BBox = getViewBBox();
//				customTrace("InteractiveLayerGoogleMaps updateData: ["+m_map.id+"] end PROPS: viewBBox: : " + currViewBBox.toLaLoString("CRS:84"));
				var cBBox: BBox = container.getViewBBox();
				cBBox = cBBox.forProjection('CRS:84');
				
				if (!currViewBBox.equals(cBBox))
				{
//					customTrace("bboxes are not same, try udpateData again");
					callLater(updateData, [b_forceUpdate]);
				} else {
					dispatchEvent(new Event(MAP_UDPATED));
				}
			} else {
				callLater(updateData, [b_forceUpdate]);
			}

		}
		
		
		override public function hasPreview():Boolean
		{
			return true;
		}
		override public function renderPreview(graphics: Graphics, f_width: Number, f_height: Number): void
		{
			if (!inCRSCompatible())
			{
				graphics.lineStyle(2, 0xcc0000, 0.7, true);
				graphics.moveTo(0, 0);
				graphics.lineTo(f_width - 1, f_height - 1);
				graphics.moveTo(0, f_height - 1);
				graphics.lineTo(f_width - 1, 0);
				return;
			}

			try {
				var bitmap: Bitmap = m_map.getPrintableBitmap();
				var matrix: Matrix = new Matrix();
				matrix.translate(-f_width / 3, -f_width / 3);
				matrix.scale(3, 3);
				matrix.translate(bitmap.width / 3, bitmap.height / 3);
				matrix.invert();
	  			graphics.beginBitmapFill(bitmap.bitmapData, matrix, false, true);
				graphics.drawRect(0, 0, f_width, f_height);
				graphics.endFill();
			} catch (error: Error) {

				graphics.lineStyle(2, 0xcc0000, 0.7, true);
				graphics.moveTo(0, 0);
				graphics.lineTo(f_width - 1, f_height - 1);
				graphics.moveTo(0, f_height - 1);
				graphics.lineTo(f_width - 1, 0);
			}

		}
		
		
		public function setMapType(type: IMapType): void
		{
			_mapType = getMapTypeFromGoogleMapType(type);
			m_map.setMapType(type);
		}
		
		private function customTrace(str: String): void
		{
//			trace(str);
		}
		
	}
}