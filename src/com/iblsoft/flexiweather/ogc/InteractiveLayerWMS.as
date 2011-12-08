package com.iblsoft.flexiweather.ogc
{
	import com.iblsoft.flexiweather.events.InteractiveLayerEvent;
	import com.iblsoft.flexiweather.ogc.cache.WMSCache;
	import com.iblsoft.flexiweather.proj.Coord;
	import com.iblsoft.flexiweather.proj.Projection;
	import com.iblsoft.flexiweather.utils.ArrayUtils;
	import com.iblsoft.flexiweather.utils.Serializable;
	import com.iblsoft.flexiweather.utils.Storage;
	import com.iblsoft.flexiweather.utils.UniURLLoaderEvent;
	import com.iblsoft.flexiweather.widgets.BackgroundJob;
	import com.iblsoft.flexiweather.widgets.BackgroundJobManager;
	import com.iblsoft.flexiweather.widgets.IConfigurableLayer;
	import com.iblsoft.flexiweather.widgets.InteractiveDataLayer;
	import com.iblsoft.flexiweather.widgets.InteractiveLayer;
	import com.iblsoft.flexiweather.widgets.InteractiveWidget;
	
	import flash.display.Bitmap;
	import flash.display.Graphics;
	import flash.events.TimerEvent;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.net.URLRequest;
	import flash.utils.Timer;
	
	import mx.collections.ArrayCollection;
	import mx.events.DynamicEvent;
	import mx.logging.Log;
	
	[Event(name="wmsStyleChanged", type="flash.events.Event")]
	
	public class InteractiveLayerWMS extends InteractiveLayerMSBase
			implements ISynchronisedObject, Serializable, IConfigurableLayer
	{
		public static const WMS_STYLE_CHANGED: String = 'wmsStyleChanged';
		
		protected var ma_requests: ArrayCollection = new ArrayCollection(); // of URLRequest
		
		protected var ma_imageParts: ArrayCollection = new ArrayCollection(); // of ImagePart

		protected var m_autoRefreshTimer: Timer = new Timer(10000);
		
		protected var mi_updateCycleAge: uint = 0;
		
		public function InteractiveLayerWMS(container: InteractiveWidget, cfg: WMSLayerConfiguration)
		{
			super(container, cfg);
			
			m_autoRefreshTimer.addEventListener(TimerEvent.TIMER_COMPLETE, onAutoRefreshTimerComplete)
			m_autoRefreshTimer.repeatCount = 1;
			
			m_cache = new WMSCache();
			(m_cache as WMSCache).name = cfg.label + " cache";
		}
		
		public function serialize(storage: Storage): void
		{
			//super.serialize(storage);
			var s_dimName: String;
			
			var styleName: String;
			if (storage.isLoading())
			{
				styleName = storage.serializeString("style-name", name);
				if (styleName)
					setWMSStyleName(0, styleName);
				
				//TODO do we really need to add here 2nd parameter?
				var primaryLayer: Boolean = storage.serializeBool("primary-layer", true);

				if (primaryLayer) {
					synchronisationRole.setRole(SynchronisationRole.PRIMARY);
				}
				var newAlpha: Number = storage.serializeNumber("transparency", alpha);
				if (newAlpha < 1) {
					alpha = newAlpha;
				}
				for each(s_dimName in getWMSDimensionsNames()) {
					var level: String = storage.serializeString(s_dimName, null, null);
					if (level)
						setWMSDimensionValue('ELEVATION', level );
				}
				
			} else {
				styleName = getWMSStyleName(0);
				if (styleName)
					storage.serializeString("style-name", styleName, null);
				
				for each(s_dimName in getWMSDimensionsNames()) {
					if (s_dimName.toLowerCase() == 'elevation')
						storage.serializeString('level', getWMSDimensionValue(s_dimName), null);
				}
				if (alpha < 1)
					storage.serializeNumber("transparency", alpha);
				
				if (isPrimaryLayer())
					storage.serializeBool("primary-layer", true);
			}
		}

		override public function setConfiguration(cfg: WMSLayerConfiguration): void
		{
			super.setConfiguration(cfg);
			
			m_autoRefreshTimer.stop();
			if(m_cfg.mi_autoRefreshPeriod > 0)
				m_autoRefreshTimer.delay = m_cfg.mi_autoRefreshPeriod * 1000.0;
		}

		override protected function updateData(b_forceUpdate: Boolean): void
		{
			super.updateData(b_forceUpdate);
			++mi_updateCycleAge;
			
			if(ma_requests.length > 0) {
				for each(var request: URLRequest in ma_requests)
					m_loader.cancel(request);
				ma_requests.removeAll();
			}
			
			if(!visible) {
				m_autoRefreshTimer.reset();
				return;
			}
			
			var i_width: int = int(container.width);
			var i_height: int = int(container.height);

			if (forcedLayerWidth > 0)
				i_width = forcedLayerWidth;
			if (forcedLayerHeight > 0)
				i_height = forcedLayerHeight;
			
			var s_currentCRS: String = container.getCRS();
			var currentViewBBox: BBox = container.getViewBBox();

			var f_horizontalPixelSize: Number = currentViewBBox.width / i_width;
			var f_verticalPixelSize: Number = currentViewBBox.height / i_height;

			var projection: Projection = Projection.getByCRS(s_currentCRS);
			var parts: Array = container.mapBBoxToProjectionExtentParts(currentViewBBox);
//			var parts: Array = container.mapBBoxToViewParts(projection.extentBBox);
			
			for each(var partBBoxToUpdate: BBox in parts) {
				updateDataPart(
						s_currentCRS, partBBoxToUpdate,
						uint(Math.round(partBBoxToUpdate.width / f_horizontalPixelSize)),
						uint(Math.round(partBBoxToUpdate.height / f_verticalPixelSize)),
						b_forceUpdate);
			}
		}
		
		private function updateDataPart(s_currentCRS: String, currentViewBBox: BBox, i_width: uint, i_height: uint, b_forceUpdate: Boolean): void
		{
			var request: URLRequest = m_cfg.toGetMapRequest(
				s_currentCRS, currentViewBBox.toBBOXString(),
				i_width, i_height,
				getWMSStyleListString());
			
			if (!request)
				return;
			
			updateDimensionsInURLRequest(request);
			updateCustomParametersInURLRequest(request);
			
			var img: Bitmap = null;

			var wmsCache: WMSCache = m_cache as WMSCache;
			if(!b_forceUpdate)
			{
				var isCached: Boolean = wmsCache.isImageCached(s_currentCRS, currentViewBBox, request)
				var imgTest: Bitmap = wmsCache.getImage(s_currentCRS, currentViewBBox, request);
				if (isCached && imgTest != null) {
					img = imgTest;
				}
			} else {
				// invalidate property "displayed" for cached items		
				wmsCache.removeFromScreen();
			}
			
			var imagePart: ImagePart = new ImagePart();
			imagePart.mi_updateCycleAge = mi_updateCycleAge;
			imagePart.ms_imageCRS = s_currentCRS;
			imagePart.m_imageBBox = currentViewBBox;
			
			if(img == null) {
				ma_requests.addItem(request);
				if(ma_requests.length == 1) {
					m_autoRefreshTimer.reset();
					
					notifyLoadingStart();
//					var ile: InteractiveLayerEvent = new InteractiveLayerEvent(InteractiveLayerEvent.LAYER_LOADING_START, true);
//					ile.interactiveLayer = this;
//					dispatchEvent(ile);
				}
				
				m_loader.load(request,
						{ requestedImagePart: imagePart },
						"Rendering " + m_cfg.ma_layerNames.join("+"));
				
				invalidateDynamicPart();
				
				wmsCache.startImageLoading(s_currentCRS, currentViewBBox, request);
			}
			else {
				// found in the cache
				imagePart.m_image = img;
				imagePart.mb_imageOK = true;
				for(var i: int = 0; i < ma_imageParts.length; ) {
					if(imagePart.intersectsOrHasDifferentCRS(ma_imageParts[i])) {
						trace("InteractiveLayerWMS.updateDataPart(): removing old " + i + " part "
								+ ImagePart(ma_imageParts[i]).ms_imageCRS + ": "
								+ ImagePart(ma_imageParts[i]).m_imageBBox.toString()
								+ " will remain " + (ma_imageParts.length - 1) + " part(s)");
						ma_imageParts.removeItemAt(i);
					}
					else
						++i;
				}
				ma_imageParts.addItem(imagePart);
				onFinishedRequest(null);
				invalidateDynamicPart();
			}
		}
		

		public override function draw(graphics: Graphics): void
		{
			super.draw(graphics);
			if(container.height <= 0)
				return;
			if(container.width <= 0)
				return;

			var s_currentCRS: String = container.getCRS();
//			trace("InteractiveLayerWMS.draw(): currentViewBBox=" + container.getViewBBox().toString());
			for each(var imagePart: ImagePart in ma_imageParts) {
				// Check if CRS of the image part == current CRS of the container
				if(s_currentCRS != imagePart.ms_imageCRS)
					continue; // otherwise we cannot draw it
				
				var reflectedBBoxes:Array = container.mapBBoxToViewReflections(imagePart.m_imageBBox);
				for each(var reflectedBBox: BBox in reflectedBBoxes) {
//					trace("\t InteractiveLayerWMS.draw(): drawing reflection " + reflectedBBox.toString());
					drawImagePart(imagePart.m_image, imagePart.ms_imageCRS, reflectedBBox);
				}
			}
		}
		
		private function drawImagePart(image: Bitmap, s_imageCRS: String, imageBBox: BBox): void
		{
			var ptImageStartPoint: Point =
				container.coordToPoint(new Coord(s_imageCRS, imageBBox.xMin, imageBBox.yMax));
			var ptImageEndPoint: Point =
				container.coordToPoint(new Coord(s_imageCRS, imageBBox.xMax, imageBBox.yMin));
			ptImageEndPoint.x += 1;
			ptImageEndPoint.y += 1;
			
			//trace("InteractiveLayerWMS.draw(): image-w=" + m_image.width + " image-h=" + m_image.height);
			var ptImageSize: Point = ptImageEndPoint.subtract(ptImageStartPoint);
			ptImageSize.x = int(Math.round(ptImageSize.x));
			ptImageSize.y = int(Math.round(ptImageSize.y));
			
			var matrix: Matrix = new Matrix();
			matrix.scale(ptImageSize.x / image.width, ptImageSize.y / image.height);
			//trace("InteractiveLayerWMS.draw(): scale-x=" + matrix.a + " scale-y=" + matrix.d);
			
			matrix.translate(ptImageStartPoint.x, ptImageStartPoint.y);
			graphics.beginBitmapFill(image.bitmapData, matrix, true, true);
			//trace("InteractiveLayerWMS.draw(): x=" + ptImageStartPoint.x + " y=" + ptImageStartPoint.y + " w=" + ptImageSize.x + " h=" + ptImageSize.y);
			graphics.drawRect(ptImageStartPoint.x, ptImageStartPoint.y, ptImageSize.x, ptImageSize.y);
			graphics.endFill();
		}
		
		override public function hasPreview(): Boolean
		{ return true; }
		
		override public function renderPreview(graphics: Graphics, f_width: Number, f_height: Number): void
		{
			if (status == InteractiveDataLayer.STATE_DATA_LOADED_WITH_ERRORS)
			{
				drawNoDataPreview(graphics, f_width, f_height);
				return;
			}
			
			var imagePart: ImagePart;
			if(ma_imageParts.length > 0) {
				var matrix: Matrix = new Matrix();
				imagePart = ImagePart(ma_imageParts[0]);
				matrix.translate(-f_width / 3, -f_width / 3);
				matrix.scale(3, 3);
				matrix.translate(imagePart.m_image.width / 3, imagePart.m_image.height / 3);
				matrix.invert();
				graphics.beginBitmapFill(imagePart.m_image.bitmapData, matrix, false, true);
				graphics.drawRect(0, 0, f_width, f_height);
				graphics.endFill();
			}
			var b_allImagesOK: Boolean = true;
			for each(imagePart in ma_imageParts) {
				if(!imagePart.mb_imageOK) {
					b_allImagesOK = false;
					break;
				}
			}
			if(!b_allImagesOK) {
				drawNoDataPreview(graphics, f_width, f_height);
			}
		}
		
		private function drawNoDataPreview(graphics: Graphics, f_width: Number, f_height: Number): void
		{
			graphics.lineStyle(2, 0xcc0000, 0.7, true);
			graphics.moveTo(0, 0);
			graphics.lineTo(f_width - 1, f_height - 1);
			graphics.moveTo(0, f_height - 1);
			graphics.lineTo(f_width - 1, 0);
			
		}
		
		// Event handlers
		override protected function onDataLoaded(event: UniURLLoaderEvent): void
		{
			super.onDataLoaded(event);

			var imagePart: ImagePart = event.associatedData.requestedImagePart;
//			trace("InteractiveLayerWMS.onDataLoaded(): received part "
//					+ imagePart.ms_imageCRS + ": "
//					+ imagePart.m_imageBBox.toString());

			var wmsCache: WMSCache = m_cache as WMSCache;
			/* FIXME:
			if (_invalidateCacheAfterImageLoad)
			{
				wmsCache.invalidate(ms_imageCRS, m_imageBBox);
				_invalidateCacheAfterImageLoad = false;
			}
			*/

			var result: * = event.result;
			if(result is Bitmap) {
				imagePart.m_image = result;
				imagePart.mb_imageOK = true;
				imagePart.mi_updateCycleAge = mi_updateCycleAge;
				
				for(var i: int = 0; i < ma_imageParts.length; ) {
					if(imagePart.intersectsOrHasDifferentCRS(ma_imageParts[i])) {
//						trace("InteractiveLayerWMS.onDataLoaded(): removing old " + i + " part "
//							+ ImagePart(ma_imageParts[i]).ms_imageCRS + ": "
//							+ ImagePart(ma_imageParts[i]).m_imageBBox.toString());
						ma_imageParts.removeItemAt(i);
					}
					else
						++i;
				}
				ma_imageParts.addItem(imagePart);
				wmsCache.addImage(
						imagePart.m_image,
						imagePart.ms_imageCRS,
						imagePart.m_imageBBox,
						event.request);
				invalidateDynamicPart();
			}
			else {
				ExceptionUtils.logError(Log.getLogger("WMS"), result,
						"Error accessing layer(s) '" + m_cfg.ma_layerNames.join(",") + "' - unexpected response type")
			}

			onFinishedRequest(event.request);
		}
		
		override protected function onDataLoadFailed(event: UniURLLoaderEvent): void
		{
			// event is null if this method was called internally by this class
			super.onDataLoadFailed(event);

			var imagePart: ImagePart = event.associatedData.requestedImagePart;
			imagePart.m_image = null;
			imagePart.mb_imageOK = false;
			invalidateDynamicPart();
			onFinishedRequest(event.request);
		}
		
		private function onFinishedRequest(request: URLRequest): void
		{
			if(request)
			{
				var id: int = ma_requests.getItemIndex(request);
				if (id > -1)
					ma_requests.removeItemAt(id);
			}

			if(ma_requests.length == 0) {
				for(var i: int = 0; i < ma_imageParts.length; ) {
					if(ma_imageParts[i].mi_updateCycleAge < mi_updateCycleAge) {
//						trace("InteractiveLayerWMS.onFinishedRequest(): removing old " + i + " part "
//							+ ImagePart(ma_imageParts[i]).ms_imageCRS + ": "
//							+ ImagePart(ma_imageParts[i]).m_imageBBox.toString());
						ma_imageParts.removeItemAt(i);
					}
					else
						++i;
				}
				// finished loading of all requests
				// restartautorefresh timer
				if(m_cfg.mi_autoRefreshPeriod > 0) {
					m_autoRefreshTimer.reset();
					m_autoRefreshTimer.delay = m_cfg.mi_autoRefreshPeriod * 1000.0;
					m_autoRefreshTimer.start();
				}
//				var ile: InteractiveLayerEvent = new InteractiveLayerEvent(InteractiveLayerEvent.LAYER_LOADED, true);
//				ile.interactiveLayer = this;
//				dispatchEvent(ile);
			}
		}
		
		protected function onAutoRefreshTimerComplete(event: TimerEvent): void
		{
			invalidateData(true);
		}
		
		private var _invalidateCacheAfterImageLoad: Boolean;
		override public function onAreaChanged(b_finalChange: Boolean): void
		{
			super.onAreaChanged(b_finalChange);
			if(b_finalChange) {
				//				trace("WMS onAreaChanged ms_imageCRS: " + ms_imageCRS + " m_imageBBox: " + m_imageBBox);
				_invalidateCacheAfterImageLoad = true;
				//				m_cache.invalidate(ms_imageCRS, m_imageBBox);
				invalidateData(false);
			}
			else
				invalidateDynamicPart();
		}
		
		override public function clone(): InteractiveLayer
		{
			var newLayer: InteractiveLayerWMS = new InteractiveLayerWMS(container, m_cfg);
			newLayer.id = id;
			newLayer.alpha = alpha;
			newLayer.zOrder = zOrder;
			newLayer.visible = visible;
			
			var styleName: String = getWMSStyleName(0)
			newLayer.setWMSStyleName(0, styleName);
			
			//clone all dimensions
			var dimNames: Array = getWMSDimensionsNames();
			for each (var dimName: String in dimNames)
			{
				var value : String = getWMSDimensionValue(dimName);
				newLayer.setWMSDimensionValue(dimName, value);
			}
			return newLayer;
		}
		
		override public function toString(): String
		{
			return "InteractiveLayerWMS " + name  ;
		}
	}
}

import com.iblsoft.flexiweather.ogc.BBox;
import com.iblsoft.flexiweather.proj.Projection;

import flash.display.Bitmap;

class ImagePart
{
	public var mi_updateCycleAge: uint;
	public var m_image: Bitmap = null;
	public var mb_imageOK: Boolean = false;
	public var ms_imageCRS: String = null;
	public var m_imageBBox: BBox = null;
	
	public function intersectsOrHasDifferentCRS(other: ImagePart): Boolean
	{
		if(!Projection.equalCRSs(ms_imageCRS, other.ms_imageCRS))
			return true;
		var intersection: BBox = m_imageBBox.intersected(other.m_imageBBox);
		return intersection && intersection.width > 1e-6 && intersection.height > 1e-6;
	}
};
