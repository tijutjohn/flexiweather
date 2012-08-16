package com.iblsoft.flexiweather.ogc
{
	import com.iblsoft.flexiweather.events.InteractiveLayerEvent;
	import com.iblsoft.flexiweather.net.events.UniURLLoaderErrorEvent;
	import com.iblsoft.flexiweather.net.events.UniURLLoaderEvent;
	import com.iblsoft.flexiweather.ogc.cache.CacheItemMetadata;
	import com.iblsoft.flexiweather.ogc.cache.ICache;
	import com.iblsoft.flexiweather.ogc.cache.ICachedLayer;
	import com.iblsoft.flexiweather.ogc.cache.WMSCache;
	import com.iblsoft.flexiweather.ogc.data.IWMSViewPropertiesLoader;
	import com.iblsoft.flexiweather.ogc.data.ImagePart;
	import com.iblsoft.flexiweather.ogc.data.WMSViewProperties;
	import com.iblsoft.flexiweather.proj.Coord;
	import com.iblsoft.flexiweather.proj.Projection;
	import com.iblsoft.flexiweather.utils.ArrayUtils;
	import com.iblsoft.flexiweather.utils.Serializable;
	import com.iblsoft.flexiweather.utils.Storage;
	import com.iblsoft.flexiweather.widgets.BackgroundJob;
	import com.iblsoft.flexiweather.widgets.BackgroundJobManager;
	import com.iblsoft.flexiweather.widgets.IConfigurableLayer;
	import com.iblsoft.flexiweather.widgets.InteractiveDataLayer;
	import com.iblsoft.flexiweather.widgets.InteractiveLayer;
	import com.iblsoft.flexiweather.widgets.InteractiveWidget;
	
	import flash.display.Bitmap;
	import flash.display.BitmapData;
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
			implements ISynchronisedObject, Serializable, IConfigurableLayer, ICachedLayer
	{
		public static const WMS_STYLE_CHANGED: String = 'wmsStyleChanged';
		
		protected var m_autoRefreshTimer: Timer = new Timer(5000);
		
		public function InteractiveLayerWMS(container: InteractiveWidget, cfg: WMSLayerConfiguration)
		{
			super(container, cfg);
			
			m_autoRefreshTimer.addEventListener(TimerEvent.TIMER_COMPLETE, autoRefreshTimerCompleted);
			m_autoRefreshTimer.repeatCount = 1;
			
			if (container.wmsCacheManager)
			{
				m_cache = container.wmsCacheManager.getWMSCacheForConfiguration(cfg);
			} else {
				m_cache = new WMSCache();
				(m_cache as WMSCache).name = cfg.label + " cache";
			}
			
//			m_currentWMSViewProperties.cache = m_cache;
		}
		
		override public function destroy():void
		{
			super.destroy();
			
			if (m_autoRefreshTimer)
			{
				m_autoRefreshTimer.stop();
				m_autoRefreshTimer.removeEventListener(TimerEvent.TIMER_COMPLETE, autoRefreshTimerCompleted)
			}
		}
		public function serialize(storage: Storage): void
		{
			//super.serialize(storage);
			var s_dimName: String;
			
			var styleName: String;
			if (storage.isLoading())
			{
//				styleName = storage.serializeString("style-name", name);
//				if (styleName)
//					setWMSStyleName(0, styleName);
				
				//TODO do we really need to add here 2nd parameter?
				var primaryLayer: Boolean = storage.serializeBool("primary-layer", true);

				if (primaryLayer) {
					synchronisationRole.setRole(SynchronisationRole.PRIMARY);
				}
				var newAlpha: Number = storage.serializeNumber("transparency", alpha);
				if (newAlpha < 1) {
					alpha = newAlpha;
				}
				
				visible = storage.serializeBool("visible", visible, true);
				
//				for each(s_dimName in getWMSDimensionsNames()) {
//					var level: String = storage.serializeString(s_dimName, null, null);
//					if (level)
//						setWMSDimensionValue('ELEVATION', level );
//				}
				
			} else {
//				styleName = getWMSStyleName(0);
//				if (styleName)
//					storage.serializeString("style-name", styleName, null);
				
//				for each(s_dimName in getWMSDimensionsNames()) {
//					if (s_dimName.toLowerCase() == 'elevation')
//						storage.serializeString('level', getWMSDimensionValue(s_dimName), null);
//				}
				if (alpha < 1)
					storage.serializeNumber("transparency", alpha);
					
				storage.serializeBool("visible", visible);
				
				if (isPrimaryLayer())
					storage.serializeBool("primary-layer", true);
			}
			
			if (m_currentWMSViewProperties)
				m_currentWMSViewProperties.serialize(storage);
		}

		override public function setConfiguration(cfg: WMSLayerConfiguration): void
		{
			super.setConfiguration(cfg);
			
			m_autoRefreshTimer.stop();
			if(m_cfg.autoRefreshPeriod > 0)
				m_autoRefreshTimer.delay = m_cfg.autoRefreshPeriod * 1000.0;
		}

		override protected function onCurrentWMSDataLoadingStarted(event: InteractiveLayerEvent): void
		{
			super.onCurrentWMSDataLoadingStarted(event);
			
			m_autoRefreshTimer.reset();
			
//			debug("onCurrentWMSDataLoadingStarted");
		}
		override protected function onCurrentWMSDataLoadingFinished(event: InteractiveLayerEvent): void
		{
			super.onCurrentWMSDataLoadingFinished(event);
			
			// restartautorefresh timer
			restartAutoRefreshTimer();
//			debug("onCurrentWMSDataLoadingFinished");
		}
		
		override protected function updateData(b_forceUpdate: Boolean): void
		{
			super.updateData(b_forceUpdate);
			
			if(!visible) {
				m_autoRefreshTimer.reset();
				return;
			}
		}

		/*
		public override function draw(graphics: Graphics): void
		{
			super.draw(graphics);
			if(container.height <= 0)
				return;
			if(container.width <= 0)
				return;

			if (m_currentWMSViewProperties)
				m_currentWMSViewProperties.drawWMSData(graphics);
		}
		*/
		
		override public function hasPreview(): Boolean
		{ return true; }
		
		public override function invalidateSize(): void
		{
			super.invalidateSize();
			if (container != null)
			{
				width = container.width;
				height = container.height;
			}
		}
		
		override public function renderPreview(graphics: Graphics, f_width: Number, f_height: Number): void
		{
			if(!width || !height)
				return;
			
			if (status == InteractiveDataLayer.STATE_DATA_LOADED_WITH_ERRORS || status == InteractiveDataLayer.STATE_NO_DATA_AVAILABLE)
			{
				drawNoDataPreview(graphics, f_width, f_height);
				return;
			}
			
			if (!currentViewProperties)
				return;
			
			var imageParts: ArrayCollection = (currentViewProperties as WMSViewProperties).imageParts;
			
			var imagePart: ImagePart;
			
			if(imageParts.length > 0) {
				var matrix: Matrix = new Matrix();
				imagePart = ImagePart(imageParts[0]);
				
				if (imagePart.isBitmap)
					var bitmap: Bitmap = imagePart.m_image as Bitmap;
				else {
					trace("ATTENTION: renderPreviewWMSData image is not bitmap");
					return;
				}
				
				
//				matrix.translate(-f_width / 3, -f_width / 3);
//				matrix.scale(3, 3);
//				matrix.translate(imagePart.m_image.width / 3, imagePart.m_image.height / 3);
//				matrix.invert();
				
				var scaleW: Number = f_width / width;
				var scaleH: Number = f_height / height;
				var scale: Number = Math.max(scaleW, scaleH);
				
				scale = Math.min(scale * 2, 1);
				
				var nw: Number = width * scale;
				var nh: Number = height * scale;
				var xDiff: Number = (nw - f_width) / 2;
				var yDiff: Number = (nh - f_height) / 2;
				
				matrix.scale(scale, scale);
				matrix.translate(-xDiff, -yDiff);
				
				var bd: BitmapData = new BitmapData(width, height, true, 0x00000000);
				bd.draw(this);
				
				graphics.beginBitmapFill(bd, matrix, false, true);
				graphics.drawRect(0,0, f_width, f_height);
				graphics.endFill();
				
//				graphics.beginBitmapFill(bitmap.bitmapData, matrix, false, true);
//				graphics.drawRect(0, 0, f_width, f_height);
//				graphics.endFill();
			}
			
			var b_allImagesOK: Boolean = true;
			for each(imagePart in imageParts) 
			{
				if(!imagePart.mb_imageOK) 
				{
					b_allImagesOK = false;
					break;
				}
			}
			if(!b_allImagesOK) 
			{
				drawNoDataPreview(graphics, f_width, f_height);
			}
		}
		
		protected function restartAutoRefreshTimer(): void
		{
			if(m_cfg.autoRefreshPeriod > 0) {
				m_autoRefreshTimer.reset();
				m_autoRefreshTimer.delay = m_cfg.autoRefreshPeriod * 1000.0;
				m_autoRefreshTimer.start();
			}
		}
		
		protected function autoRefreshTimerCompleted(event: TimerEvent): void
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

