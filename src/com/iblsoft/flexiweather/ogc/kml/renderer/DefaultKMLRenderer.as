package com.iblsoft.flexiweather.ogc.kml.renderer
{
	import com.iblsoft.flexiweather.ogc.kml.data.KMLResourceKey;
	import com.iblsoft.flexiweather.ogc.kml.events.KMLBitmapEvent;
	import com.iblsoft.flexiweather.ogc.kml.features.Geometry;
	import com.iblsoft.flexiweather.ogc.kml.features.GroundOverlay;
	import com.iblsoft.flexiweather.ogc.kml.features.Icon;
	import com.iblsoft.flexiweather.ogc.kml.features.KML;
	import com.iblsoft.flexiweather.ogc.kml.features.KMLFeature;
	import com.iblsoft.flexiweather.ogc.kml.features.KMLLabel;
	import com.iblsoft.flexiweather.ogc.kml.features.LineString;
	import com.iblsoft.flexiweather.ogc.kml.features.LinearRing;
	import com.iblsoft.flexiweather.ogc.kml.features.MultiGeometry;
	import com.iblsoft.flexiweather.ogc.kml.features.Placemark;
	import com.iblsoft.flexiweather.ogc.kml.features.Polygon;
	import com.iblsoft.flexiweather.ogc.kml.features.ScreenOverlay;
	import com.iblsoft.flexiweather.ogc.kml.features.styles.HotSpot;
	import com.iblsoft.flexiweather.ogc.kml.features.styles.IconStyle;
	import com.iblsoft.flexiweather.ogc.kml.features.styles.Style;
	import com.iblsoft.flexiweather.ogc.kml.features.styles.StyleMap;
	import com.iblsoft.flexiweather.ogc.kml.features.styles.StyleSelector;
	import com.iblsoft.flexiweather.ogc.kml.interfaces.IKMLIconFeature;
	import com.iblsoft.flexiweather.ogc.kml.managers.KMLResourceManager;
	import com.iblsoft.flexiweather.plugins.IConsole;
	import com.iblsoft.flexiweather.proj.Coord;
	import com.iblsoft.flexiweather.widgets.InteractiveWidget;
	
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Graphics;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.utils.Dictionary;
	import flash.utils.getTimer;
	
	import mx.collections.ArrayCollection;

	public class DefaultKMLRenderer extends EventDispatcher implements IKMLRenderer
	{
		public static var debugConsole: IConsole;
		
		private var _container: InteractiveWidget;
		
		private var _styleDictionary: StylesDictionary;
		
		public function DefaultKMLRenderer()
		{
			_styleDictionary = new StylesDictionary();
		}
		
		
		public function render(feature: KMLFeature, container: InteractiveWidget): void
		{
			_container = container;
		
			if (feature.kml && feature.kml.resourceManager)
			{
				addResourceManagerListeners(feature.kml.resourceManager);
			}
			
			if (feature is Placemark) {
				renderPlacemark(feature);
			} else if (feature is GroundOverlay) {
				renderGroundOverlay(feature);
			} else if (feature is ScreenOverlay) {
				renderScreenOverlay(feature);
			} else {
				trace("render feature: " + feature);
			}
		}
		
		private function addResourceManagerListeners(resourceManager: KMLResourceManager): void
		{
			if (!resourceManager.hasEventListener(KMLBitmapEvent.BITMAP_LOADED))
			{
				resourceManager.addEventListener(KMLBitmapEvent.BITMAP_LOADED, onBitmapLoaded);
				resourceManager.addEventListener(KMLBitmapEvent.BITMAP_LOAD_ERROR, onBitmapLoadError);
				resourceManager.addEventListener(KMLResourceManager.ALL_RESOURCES_LOADED, onAllResourcesLoaded);
			}
		}
		private function removeResourceManagerListeners(resourceManager: KMLResourceManager): void
		{
			resourceManager.removeEventListener(KMLBitmapEvent.BITMAP_LOADED, onBitmapLoaded);
			resourceManager.removeEventListener(KMLBitmapEvent.BITMAP_LOAD_ERROR, onBitmapLoadError);
			resourceManager.removeEventListener(KMLResourceManager.ALL_RESOURCES_LOADED, onAllResourcesLoaded);
		}
		
		protected function onAllResourcesLoaded(event: Event): void
		{
			var resourceManager: KMLResourceManager = event.target as KMLResourceManager;
			removeResourceManagerListeners(resourceManager);
			
			dispatchEvent(event);
		}
		protected function onBitmapLoaded(event: KMLBitmapEvent): void
		{
			var resource: StyleResource = _styleDictionary.getResource(event.key) as StyleResource
			if (resource.feature is Placemark)
			{
				onPlacemarkIconLoaded(event);
			} else if (resource.feature is GroundOverlay) {
				onGroundOverlayIconLoaded(event);
			} else if (resource.feature is ScreenOverlay) {
				onScreenOverlayIconLoaded(event);
			}
			
			dispatchEvent(event);
		}
		protected function onBitmapLoadError(event: KMLBitmapEvent): void
		{
			var resource: StyleResource = _styleDictionary.getResource(event.key) as StyleResource
			if (resource.feature is Placemark)
			{
				onPlacemarkIconLoadFail(event);
			} else if (resource.feature is GroundOverlay) {
				onGroundOverlayIconLoadFail(event);
			} else if (resource.feature is ScreenOverlay) {
				onScreenOverlayIconLoadFail(event);
			}
			
			dispatchEvent(event);
		}
		
		/*********************************************************************************************
		 * 
		 * 		ScreenOverlay section
		 * 
		 *********************************************************************************************/
		
		protected function renderScreenOverlay(feature: KMLFeature): void
		{
			var time: int = startProfileTimer();
			
			var overlay: ScreenOverlay = feature as ScreenOverlay;	
			if (overlay)
			{
				var icon: Icon = overlay.icon;
				
				var resourceManager: KMLResourceManager = overlay.kml.resourceManager;
				var imageKey: KMLResourceKey = new KMLResourceKey(icon.href, resourceManager.basePath, KMLResourceManager.RESOURCE_TYPE_IMAGE);
				if (!resourceManager.isResourceLoaded(imageKey))
				{
					if (!resourceManager.isResourceLoading(imageKey))
					{
						var imageResource: StyleResource = new StyleResource(imageKey, overlay );
						_styleDictionary.addResource(imageResource);
						
						resourceManager.loadResource(imageKey);
					}
				} else {
					renderScreenOverlayImage(overlay, resourceManager.getBitmapData(imageKey));
				}
			}
			
//			debug("Render screen overlay time: " + stopProfileTimer(time));
		}
		
		protected function onScreenOverlayIconLoaded(event: KMLBitmapEvent): void
		{
			var resource: StyleResource = _styleDictionary.getResource(event.key) as StyleResource
			var overlay: ScreenOverlay = resource.feature as ScreenOverlay;
			
			_styleDictionary.removeStyleFromDictionary(resource);
			
			renderScreenOverlayImage(overlay, event.bitmapData);
		}
		
		protected function onScreenOverlayIconLoadFail(event: KMLBitmapEvent): void
		{
		}
		
		protected function renderScreenOverlayImage(overlay: ScreenOverlay, icon: BitmapData): void
		{
			var gr: Graphics = overlay.kmlIcon.graphics;
			gr.clear();
			
			var xDiff: Number = 0;
			var yDiff: Number = 0;
				
			var widthOnMap: int = icon.width;
			var heightOnMap: int = icon.height;

			var sx: Number; 
			var sy: Number;
			
			if (overlay.size)
			{
				sx = overlay.size.x; 
				sy = overlay.size.y;
			
				if (sx > 0)
					widthOnMap *= sx;
				if (sy > 0)
					heightOnMap *= sy;
			}
				
			sx = widthOnMap / icon.width;
			sy = heightOnMap / icon.height;
			
			
			var w: int = icon.width * sx;
			var h: int = icon.height * sy;
			
			if (overlay.isActive(w, h))
			{
				
				//render ground overlay image
				var m: Matrix = new Matrix();
				//				m.translate(xDiff, yDiff);
				
				xDiff = 0;//-0.5 * icon.width * sx;
				yDiff = 0;//-0.5 * icon.height * sy;
					
				if (overlay.screenXY.xunits == 'fraction')
					xDiff = _container.width * overlay.screenXY.x;
				if (overlay.screenXY.xunits == 'pixels')
					xDiff = overlay.screenXY.x;
				
				if (overlay.screenXY.yunits == 'fraction')
					yDiff = _container.height * (1 - overlay.screenXY.y)
				if (overlay.screenXY.yunits == 'pixels')
					yDiff = _container.height - overlay.screenXY.y;
				
				//need to find correct difference between overlay point and point on screen
				var overlayPoint: Point = new Point(0,0);
				if (overlay.overlayXY)
				{
					if (overlay.overlayXY.xunits == 'fraction')
						overlayPoint.x = icon.width * overlay.overlayXY.x;
					if (overlay.overlayXY.xunits == 'pixels')
						overlayPoint.x = overlay.overlayXY.x;
					
					if (overlay.overlayXY.yunits == 'fraction')
						overlayPoint.y = icon.height * (1 - overlay.overlayXY.y)
					if (overlay.overlayXY.yunits == 'pixels')
						overlayPoint.y = icon.height - overlay.overlayXY.y;
				}
				
				trace("ScreenOverlay image scale: " + sx + " , " + sy);
				trace("ScreenOverlay image pos: " + xDiff + " , " + yDiff);
				trace("ScreenOverlay image overlayPoint: " + overlayPoint);
				trace("ScreenOverlay size: " + overlay.size);
				trace("ScreenOverlay overlay: " + overlay.overlayXY);
				trace("ScreenOverlay screen: " + overlay.screenXY);
				
				xDiff -= overlayPoint.x;
				yDiff -= overlayPoint.y;
				
				m.scale(sx, sy); 
				m.translate(xDiff, yDiff);
			
				gr.beginBitmapFill(icon, m);
				//			gr.drawRect(0,0, icon.width, icon.height);`
				gr.drawRect(xDiff, yDiff, w, h);
				gr.endFill();
			} else {
				//screen overlay is not active, do not display it
			}
		}
		
		/*********************************************************************************************
		 * 
		 * 		End of ScreenOverlay section
		 * 
		 *********************************************************************************************/
		
		
		/*********************************************************************************************
		 * 
		 * 		GroundOverlay section
		 * 
		 *********************************************************************************************/
		
		protected function renderGroundOverlay(feature: KMLFeature): void
		{
			var time: int = startProfileTimer();
			
			var overlay: GroundOverlay = feature as GroundOverlay;	
			if (overlay)
			{
				var styleSelector: StyleSelector = overlay.style;
				var style: Style;
				var icon: Icon = overlay.icon;
				
				//order of coordinates inserted: NorthWest, NorthEast, SouthEast, SouthWest
				var points: ArrayCollection = feature.getPoints();
				if (points.length != 4)
				{
					trace("we expect 4 points in GroundLevel");
				} else {
					var nw: Point = points.getItemAt(0) as Point;
					var ne: Point = points.getItemAt(1) as Point;
					var se: Point = points.getItemAt(2) as Point;
					var sw: Point = points.getItemAt(3) as Point;
					
					feature.x = nw.x;// + (ne.x - nw.x) / 2;
					feature.y = ne.y;// + (se.y - ne.y) / 2;
					trace("renderGroundOverlay overlay pos: ["+feature.x+","+feature.y+"]")
					_container.labelLayout.updateObjectReferenceLocation(feature);
				}
				
				var resourceManager: KMLResourceManager = overlay.kml.resourceManager;
				var imageKey: KMLResourceKey = new KMLResourceKey(icon.href, resourceManager.basePath, KMLResourceManager.RESOURCE_TYPE_IMAGE);
				if (!resourceManager.isResourceLoaded(imageKey))
				{
					if (!resourceManager.isResourceLoading(imageKey))
					{
						var imageResource: StyleResource = new StyleResource(imageKey, overlay );
						_styleDictionary.addResource(imageResource);
						
						resourceManager.loadResource(imageKey);
					}
				} else {
					renderGroundOverlayImage(overlay, resourceManager.getBitmapData(imageKey));
				}
				updateLabelPosition(overlay.kmlLabel, overlay.x + 12, overlay.y + 12);
				
			}
			
//			debug("Render ground overlay time: " + stopProfileTimer(time));
		}
		
		protected function onGroundOverlayIconLoaded(event: KMLBitmapEvent): void
		{
			var resource: StyleResource = _styleDictionary.getResource(event.key) as StyleResource
			var overlay: GroundOverlay = resource.feature as GroundOverlay;
			
			_styleDictionary.removeStyleFromDictionary(resource);
			
			renderGroundOverlayImage(overlay, event.bitmapData);
		}
		
		protected function renderGroundOverlayImage(overlay: GroundOverlay, icon: BitmapData): void
		{
			var gr: Graphics = overlay.kmlIcon.graphics;
			gr.clear();
			
			var xDiff: Number = 0;
			var yDiff: Number = 0;
			
			var points: ArrayCollection = overlay.getPoints();
			if (points.length != 4)
			{
				trace("we expect 4 points in GroundLevel");
			} else {
				var nw: Point = points.getItemAt(0) as Point;
				var ne: Point = points.getItemAt(1) as Point;
				var se: Point = points.getItemAt(2) as Point;
				var sw: Point = points.getItemAt(3) as Point;
				
				
//				overlay.x = nw.x;// + (ne.x - nw.x) / 2;
//				overlay.y = ne.y;// + (se.y - ne.y) / 2;
//				
//				trace("renderGroundOverlayImage overlay pos: ["+overlay.x+","+overlay.y+"]")
				
				var widthOnMap: int = ne.x - nw.x;
				var heightOnMap: int = se.y - ne.y;
				
				//render ground overlay image
				var sx: Number = widthOnMap / icon.width;
				var sy: Number = heightOnMap / icon.height;
				
				var w: int = icon.width * sx;
				var h: int = icon.height * sy;
				
				if (overlay.isActive(w, h))
				{
					trace("GroundOverlay image scale: " + sx + " , " + sy);
					var m: Matrix = new Matrix();
					m.scale(sx, sy); 
					
					xDiff = 0;//-0.5 * icon.width * sx;
					yDiff = 0;//-0.5 * icon.height * sy;
					
					gr.beginBitmapFill(icon, m);
					gr.drawRect(xDiff, yDiff, w, h);
					gr.endFill();
				} else {
					trace("Groundoverlay is not active");
				}
			}
			
		}
		
		protected function onGroundOverlayIconLoadFail(event: KMLBitmapEvent): void
		{
			
		}
		
		
		
		/*********************************************************************************************
		 * 
		 * 		End of GroundOverlay section
		 * 
		 *********************************************************************************************/
		private function startProfileTimer(): int
		{
			return getTimer();
		}
		/**
		 * Return time interval in seconds 
		 * @param startTime
		 * @return 
		 * 
		 */		
		private function stopProfileTimer(startTime: int): Number
		{
			var diff: int = getTimer() - startTime;
			return diff / 1000;
		}
		
		/*********************************************************************************************
		 * 
		 * 		Placemark section
		 * 
		 *********************************************************************************************/
		protected function renderPlacemark(feature: KMLFeature): void
		{
			
			var placemark: Placemark = feature as Placemark;
			renderPlacemarkGeometry(placemark, placemark.geometry);
		}
		
		protected function renderPlacemarkGeometry(placemark: Placemark, geometry: Geometry): void
		{
			var time: int = startProfileTimer();
			if (geometry != null) 
			{
				var placemarkStyles: ObjectStyles = new ObjectStyles(placemark); 
				
				if (geometry is com.iblsoft.flexiweather.ogc.kml.features.Point) 
				{
					
					renderPoint(placemark, placemarkStyles.normalStyle, placemarkStyles.highlightStyle);
					
				} else { 
					if (geometry is LineString) 
					{
//						trace("draw LineString");
						renderLineString(placemark.graphics, placemark.getPoints(), placemark.kmlLabel, placemarkStyles.normalStyle);
						
					} else {
						if (geometry is LinearRing) 
						{
							trace("draw LinearRing");
							renderLinearRing(placemark.graphics, geometry as LinearRing, placemark.kmlLabel, placemarkStyles.normalStyle);
							
						}  else {
							if (geometry is Polygon) 
							{
								trace("draw Polygon");
								renderPolygon(placemark.graphics, geometry as Polygon, placemark.kmlLabel, placemarkStyles.normalStyle);
							} else {
								
								if (geometry is MultiGeometry) 
								{
									trace("draw MultiGeomtre");
									renderMultiGeometry(placemark, geometry as MultiGeometry);
								}
							}
						}
					}
				} 
			}
			
			debug("Render placemark time: " + stopProfileTimer(time));
		}
		
		
		
		protected function onPlacemarkIconLoaded(event: KMLBitmapEvent): void
		{
			var resource: StyleResource = _styleDictionary.getResource(event.key) as StyleResource
			if (resource)
			{
				trace("onPlacemarkIconLoaded  resource found: " + event.key.href)
				var placemark: Placemark = resource.feature as Placemark;
				
				_styleDictionary.removeStyleFromDictionary(resource);
				
	//			var icon: Bitmap = placemark.kml.resourceManager.getBitmap(bd);
				var hotSpot: HotSpot;
				var scale: Number = 1;
				
				var placemarkStyles: ObjectStyles = new ObjectStyles(placemark); 
				
				if (placemarkStyles.normalStyle && placemarkStyles.normalStyle.iconStyle)
				{
					hotSpot = placemarkStyles.normalStyle.iconStyle.hotspot;
					scale = placemarkStyles.normalStyle.iconStyle.scale;
				} else {
					trace("placemark has no style");
				}
				
				var gr: Graphics = placemark.kmlIcon.graphics;
				gr.clear();
				if (event.bitmapData)
					renderPlacemarkIcon(placemark, gr, event.bitmapData, hotSpot, scale);
			} else {
				trace("onPlacemarkIconLoaded  resource not found: " + event.key.href)
			}
		}
		protected function onPlacemarkIconLoadFail(event: KMLBitmapEvent): void
		{
			
		}
		
		private function renderPlacemarkIcon(placemark: Placemark, gr: Graphics, icon: BitmapData, hotSpot: HotSpot, scale: Number): void
		{
			if (isNaN(scale))
				scale = 1;
			
			var scaleX: Number = scale;
			var scaleY: Number = scale;
			
			//fix icon size to 32x32
//			scaleX *= (32 / icon.width);
//			scaleY *= (32 / icon.height);
			
			var xDiff: Number = 0;
			var yDiff: Number = 0;
			var pixelsFraction: Number;
			
			if (hotSpot)
			{
				if (hotSpot.xunits == 'fraction')
					xDiff = scaleX * icon.width * (hotSpot.x - 1);
				if (hotSpot.yunits == 'fraction')
					yDiff = scaleY * icon.height * (hotSpot.y - 1);
				
				if (hotSpot.xunits == 'pixels')
				{
					pixelsFraction = hotSpot.x / icon.width;
					xDiff = scaleX * icon.width * (pixelsFraction - 1);
				}
				if (hotSpot.yunits == 'pixels')
				{
					pixelsFraction = hotSpot.y / icon.height;
					yDiff = scaleY * icon.height * (pixelsFraction - 1);
				}
			} else {
//				trace("no hotspot");
				xDiff = scaleX * icon.width * -1;
				yDiff = scaleY * icon.height * -1;
			}
			var m: Matrix = new Matrix();
			m.scale(scaleX, scaleY);
			m.translate(xDiff, yDiff);
			
//			debug("render placemark icon: ["+placemark.x + " , " + placemark.y + "] scale ["+scaleX+","+scaleY+"]  translate: ["+xDiff+","+yDiff+"]");
//			debug("render placemark icon2: ["+icon.width + " , " + icon.height + "]");
//			debug("render placemark kmlIcon: ["+placemark.kmlIcon.x + " , " + placemark.kmlIcon.y + "] placemark.visible ["+placemark.visible+"]  placemark.kmlIcon.visible: ["+placemark.kmlIcon.visible+"]");
			gr.clear();
			gr.beginBitmapFill(icon, m);
			//			gr.drawRect(0,0, icon.width, icon.height);`
			gr.drawRect(xDiff, yDiff, icon.width * scaleX, icon.height * scaleY);
			gr.endFill();
			
			updateLabelPosition(placemark.kmlLabel, placemark.x + xDiff, placemark.y + yDiff);
		}
		
		
		/**
		 * Render MultiGeometry
		 *  
		 * @param placemark
		 * @param multigeometry
		 * 
		 */		
		protected function renderMultiGeometry(placemark: Placemark, multigeometry: MultiGeometry): void
		{
			for each (var geometry: Geometry in multigeometry.geometries)
			{
				renderPlacemarkGeometry(placemark, geometry);
			}
		}
		
		protected function renderPoint(placemark: Placemark, style: Style, highlightStyle: Style): void
		{
			var iconStyle: IconStyle;
			
			var hotSpot: HotSpot;
			var kmlResourceManager: KMLResourceManager;
			
			// FIXME how to find out base url of placemark
			var pointBaseURL: String = null;
			
			if (style && style.iconStyle)
			{
				kmlResourceManager = style.kml.resourceManager;
				
				iconStyle = style.iconStyle;
				hotSpot = iconStyle.hotspot;
				var isStyleIconLoaded: Boolean;
				var isHighlightStyleIconLoaded: Boolean
				
				if (style.iconStyle.icon && style.iconStyle.icon.href)
				{
					var iconScale: Number = 1;
					var highlightScale: Number = 1;
					
					var iconHref: String = style.iconStyle.icon.href;
					var iconKey: KMLResourceKey = new KMLResourceKey(iconHref, pointBaseURL, KMLResourceManager.RESOURCE_TYPE_ICON);
					isStyleIconLoaded = kmlResourceManager.isResourceLoaded(iconKey);
					
					if (style.iconStyle.scale && !isNaN(style.iconStyle.scale))
						iconScale = style.iconStyle.scale;
					if (highlightStyle)
					{
						if (highlightStyle.iconStyle.scale && !isNaN(highlightStyle.iconStyle.scale))
							highlightScale = highlightStyle.iconStyle.scale;
					}
					
					if (style && !isStyleIconLoaded)
					{
						if (!kmlResourceManager.isResourceLoading(iconKey))
						{
							var iconResource: StyleResource = new StyleResource(iconKey, placemark, style);
							_styleDictionary.addResource(iconResource);
							
							kmlResourceManager.loadResource(iconKey);
						}
					}
					if (highlightStyle && highlightStyle.iconStyle && highlightStyle.iconStyle.icon)
					{
						var highlightHref: String = highlightStyle.iconStyle.icon.href;
						var highlightIconKey: KMLResourceKey = new KMLResourceKey(highlightHref, pointBaseURL, KMLResourceManager.RESOURCE_TYPE_ICON);
						
						isHighlightStyleIconLoaded = kmlResourceManager.isResourceLoaded(highlightIconKey);
						
						if (!isHighlightStyleIconLoaded)
						{
							if (!kmlResourceManager.isResourceLoading(highlightIconKey))
							{
								var highlighIconResource: StyleResource = new StyleResource(highlightIconKey, placemark, highlightStyle);
								_styleDictionary.addResource(highlighIconResource);
								
								kmlResourceManager.loadResource(highlightIconKey);
							}
						}
					} 
				}
			}
			var gr: Graphics = placemark.kmlIcon.graphics;
			gr.clear();
			
			if (isStyleIconLoaded)
			{
				var icon: BitmapData;
				var scale: Number = 1;
				
				if (placemark.kmlIcon.isHighlighted && isHighlightStyleIconLoaded)
				{
					icon = kmlResourceManager.getBitmapData(highlightIconKey);
					scale = highlightScale;
				} else {
					icon = kmlResourceManager.getBitmapData(iconKey);
					scale = iconScale;
				}
				
				renderPlacemarkIcon(placemark, gr, icon, hotSpot, scale);
				
			} else {
				
				if (!iconStyle)
				{
					//if there is no Icon defined, just draw default circle placemark
					gr.beginFill(0xaa0000, 0.3);
					gr.lineStyle(1,0);
					gr.drawCircle(0,0,7);
					gr.endFill();
				}
				updateLabelPosition(placemark.kmlLabel, placemark.x + 12, placemark.y + 12);
			}
			
			var points: ArrayCollection = placemark.getPoints();
			if (points && points.length > 0)
			{
				var point: Point = points.getItemAt(0) as Point;
				
				placemark.x = point.x;
				placemark.y = point.y;
				_container.labelLayout.updateObjectReferenceLocation(placemark);
			}
		}
		
		protected function renderLineString(gr: Graphics, points: ArrayCollection, kmlLabel: KMLLabel, style: Style): void
		{
			var lineWidth: int = 3;
			var lineColor: int = 0x000000;
			if (style && style.lineStyle)
			{
				lineWidth = style.lineStyle.width;
				lineColor = style.lineStyle.color;
			}
			
			gr.clear();
			gr.lineStyle(lineWidth, lineColor);
			if (points && points.length > 1)
			{
				//we are drawing whole line string relatively to first point to be able move whole sprite when drawing is not needed
				var p0: Point = points.getItemAt(0) as Point;
				var sx: int = p0.x;
				var sy: int = p0.y;
				
				var total: int = points.length;
				var cnt: int = 0;
				for (var i: int = 0; i < total; i++)
				{
					var point: Point = points.getItemAt(i) as Point
					if (point)
					{
						if (cnt == 0)
						{
							gr.moveTo(point.x - sx, point.y - sy);
						} else {
							gr.lineTo(point.x - sx, point.y - sy);
						}
						cnt++;
					}
				}
			}
			
			if (point)
				updateLabelPosition(kmlLabel, point.x, point.y); 
		}
		
		protected function renderLinearRing(gr: Graphics, linearRing: LinearRing, kmlLabel: KMLLabel, style: Style): void
		{
			gr.clear();
			
			var lineWidth: int = 3;
			var lineColor: int = 0x000000;
			
			var fillExists: Boolean;
			var outlineExists: Boolean;
			
			if (style && style.lineStyle)
			{
				lineWidth = style.lineStyle.width;
				lineColor = style.lineStyle.color;
			}
			
			if (style && style.polyStyle)
			{
				if (style.polyStyle.outline)
				{
					outlineExists = true;
				}
				
				if (style.polyStyle.fill)
				{
					fillExists = true;
					var fillColor: uint = style.polyStyle.color;
					var fillAlpha: Number = 0.5;
					gr.beginFill(fillColor, fillAlpha);
				}
			}
			
			
			
			
			var coords: Array = linearRing.coordinatesPoints;
			var points: ArrayCollection = new ArrayCollection();
			
			for each (var c: Coord in coords)
			{
				var pt: Point = _container.coordToPoint(c);
				points.addItem(pt);
			}
			
			gr.lineStyle(lineWidth, lineColor);
			if (points && points.length > 1)
			{
				var p0: Point = points.getItemAt(0) as Point;
				var sx: int = p0.x;
				var sy: int = p0.y;
				
				var total: int = points.length;
				var cnt: int = 0;
				for (var i: int = 0; i < total; i++)
				{
					var point: Point = points.getItemAt(i) as Point
					if (point)
					{
						if (cnt == 0)
						{
							gr.moveTo(point.x - sx, point.y - sy);
						} else {
							gr.lineTo(point.x - sx, point.y - sy);
						}
						cnt++;
					}
				}
			}	
			
			if (fillExists)
				gr.endFill();
			
			if (point)
				updateLabelPosition(kmlLabel, point.x, point.y); 
		}
		protected function renderPolygon(gr: Graphics, polygon: Polygon, kmlLabel: KMLLabel, style: Style): void
		{
			//render outerBoundary
			var linearRing: LinearRing = polygon.outerBoundaryIs.linearRing;
			renderLinearRing(gr, linearRing, kmlLabel, style);
		}
		
		/*********************************************************************************************
		 * 
		 * 		End of Placemark section
		 * 
		 *********************************************************************************************/
		
		
		/*********************************************************************************************
		 * 
		 * 		KML Label section
		 * 
		 *********************************************************************************************/
		
		/**
		 * Set KML Feature label position. Label is child of KML feature, so its position is relative to KML Feature.
		 *  
		 * @param label
		 * @param x relative x position of label in pixels
		 * @param y relative y position of label in pixels
		 * 
		 */		
		private function updateLabelPosition(label: KMLLabel, x: int, y: int): void
		{
			//labels are positioned in InteractiveWidget in labelLayout (AnticollisionLayout)
//			return;
			
			if (label)
			{
				label.x = x;
				label.y = y;
//				trace("KMLRenderer updateLabelPosition ["+label.x + ","+label.y+"]");
				_container.labelLayout.updateObjectReferenceLocation(label);
			}
		}
		
		/*********************************************************************************************
		 * 
		 * 		End of KML Label section
		 * 
		 *********************************************************************************************/
		
		private function debug(txt: String): void
		{
			if (debugConsole)
			{
				debugConsole.print("DefaultKMLRenderer: " + txt,'Info','DefaultKMLRenderer');
			}
		}
	}
}
import com.iblsoft.flexiweather.ogc.kml.data.KMLResourceKey;
import com.iblsoft.flexiweather.ogc.kml.features.KMLFeature;
import com.iblsoft.flexiweather.ogc.kml.features.Placemark;
import com.iblsoft.flexiweather.ogc.kml.features.styles.HotSpot;
import com.iblsoft.flexiweather.ogc.kml.features.styles.IconStyle;
import com.iblsoft.flexiweather.ogc.kml.features.styles.Style;
import com.iblsoft.flexiweather.ogc.kml.features.styles.StyleMap;
import com.iblsoft.flexiweather.ogc.kml.features.styles.StyleSelector;

import flash.utils.Dictionary;

class ObjectStyles
{
	public var normalStyle: Style;
	public var highlightStyle: Style;
	
	private var _placemark: Placemark;
	
	public function ObjectStyles(placemark: Placemark)
	{
		_placemark = placemark;
		analyzeStyles();
	}
	
	private function analyzeStyles(): void
	{
		var styleSelector: StyleSelector = _placemark.style;
		var styleURL: String;
		
		var highlightStyleURL: String;
		
		var iconStyle: IconStyle;
		var hotSpot: HotSpot;
		
		if (styleSelector)
		{
			if (styleSelector is Style)
			{
				normalStyle = styleSelector as Style;
			} else {
				if (styleSelector is StyleMap) {
					
					normalStyle = (styleSelector as StyleMap).style;
					styleURL = (styleSelector as StyleMap).styleUrl;
					
					highlightStyle = (styleSelector as StyleMap).getStyleByKey('highlight');
					highlightStyleURL = (styleSelector as StyleMap).getStyleUrlByKey('highlight');
					
					if (!normalStyle)
					{
						trace("renderPlacemark styleSelector defined in way => StyleMap with styleUrl");
						normalStyle = _placemark.parentDocument.getStyleByID(styleURL);
					}
					if (!highlightStyle)
					{
						trace("renderPlacemark highlight styleSelector defined in way => StyleMap with styleUrl");
						highlightStyle = _placemark.parentDocument.getStyleByID(highlightStyleURL);
					}
				}
			}
			
			//					trace("check placemark style");
		} else {
			trace("placemark has no style");
		}
	}
}



class StylesDictionary
{
	private var _dictionary: Dictionary;
	
	public function StylesDictionary(): void
	{
		_dictionary = new Dictionary();		
	}
	
	public function removeStyleFromDictionary(style: StyleResource): void
	{
		delete _dictionary[style];
	}
	
	public function addResource(resource: StyleResource): void
	{
//		trace("\n StylesDictionary addResource: " + resource.key.toString());
		var id: String = resource.key.toString();
		_dictionary[id] = resource;
		
	}
	public function getResource(key: KMLResourceKey): StyleResource
	{
//		trace("\n StylesDictionary getResource: " + key.toString());
		if (_dictionary)
		{
			var id: String = key.toString();
			return _dictionary[id] as StyleResource;
		}
		return null;
	}
	
	public function resourceExists(key: KMLResourceKey): Boolean
	{
		return getResource(key) != null;
	}
	
}

class StyleResource
{
	public var key: KMLResourceKey
	public var feature: KMLFeature;
	public var style: Style;
	
	public function StyleResource(key: KMLResourceKey, feature: KMLFeature, style: Style = null)
	{
		this.key = key;
		this.feature = feature;
		this.style = style;
	}
	
	
	
}