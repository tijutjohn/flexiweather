package com.iblsoft.flexiweather.ogc
{
	import com.iblsoft.flexiweather.events.InteractiveLayerEvent;
	import com.iblsoft.flexiweather.ogc.cache.WMSCache;
	import com.iblsoft.flexiweather.proj.Coord;
	import com.iblsoft.flexiweather.utils.Serializable;
	import com.iblsoft.flexiweather.utils.Storage;
	import com.iblsoft.flexiweather.utils.UniURLLoaderEvent;
	import com.iblsoft.flexiweather.widgets.BackgroundJobManager;
	import com.iblsoft.flexiweather.widgets.IConfigurableLayer;
	import com.iblsoft.flexiweather.widgets.InteractiveLayer;
	import com.iblsoft.flexiweather.widgets.InteractiveWidget;
	
	import flash.display.Bitmap;
	import flash.display.Graphics;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.net.URLRequest;
	
	import mx.logging.Log;
	
	[Event(name="wmsStyleChanged", type="flash.events.Event")]
	
	public class InteractiveLayerWMS extends InteractiveLayerMSBase
			implements ISynchronisedObject, Serializable, IConfigurableLayer
	{
		public static const WMS_STYLE_CHANGED: String = 'wmsStyleChanged';
		
		public function InteractiveLayerWMS(container: InteractiveWidget, cfg: WMSLayerConfiguration)
		{
			super(container, cfg);
			
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
				if (primaryLayer)
				{
					synchronisationRole.setRole(SynchronisationRole.PRIMARY);
				}
				var newAlpha: Number = storage.serializeNumber("transparency", alpha);
				if (newAlpha < 1)
				{
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
		
		override public function updateData(b_forceUpdate: Boolean): void
		{
			super.updateData(b_forceUpdate);
			
			var i_width: int = int(container.width);
			var i_height: int = int(container.height);
			
			if (forcedLayerWidth > 0)
				i_width = forcedLayerWidth;
			if (forcedLayerHeight> 0)
				i_height = forcedLayerHeight;
			
			var currCRS: String = container.getCRS(); 
			var viewBBox: BBox = container.getViewBBox(); 
			
			var request: URLRequest = m_cfg.toGetMapRequest(
					currCRS, viewBBox.toBBOXString(),
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
				var isCached: Boolean = wmsCache.isImageCached(currCRS, viewBBox, request)
				var imgTest: Bitmap = wmsCache.getImage(currCRS, viewBBox, request);
				
//				trace("isCached: " + isCached + " imgTest: " + imgTest);
				if (isCached)
				{
					if (imgTest == null)
					{
//						trace("Image does not exists, but it's already loading");
						return;
					}
//					invalidateDynamicPart();
				}
				if (imgTest != null)
				{
					img = imgTest;
				}
			} else {
				// invalidate property "displayed" for cached items		
				wmsCache.removeFromScreen();
			}
			
			if(img == null) {
				m_timer.reset();
				m_job = BackgroundJobManager.getInstance().startJob("Rendering " + m_cfg.ma_layerNames.join("+"));
				m_request = request;
				m_loader.load(request, {
					requestedCRS: currCRS,
					requestedBBox: viewBBox
				});
				
				invalidateDynamicPart();
				
				var ile: InteractiveLayerEvent = new InteractiveLayerEvent( InteractiveLayerEvent.LAYER_LOADING_START, true );
				ile.interactiveLayer = this;
				dispatchEvent(ile);
				wmsCache.startImageLoading( currCRS, viewBBox, request );
			}
			else {
				if(m_cfg.mi_autoRefreshPeriod > 0) {
					m_timer.delay = m_cfg.mi_autoRefreshPeriod * 1000.0;
					m_timer.start();
				}
				m_image = img;
				mb_imageOK = true;
				ms_imageCRS = currCRS;
				m_imageBBox = viewBBox;
				invalidateDynamicPart();
			}
		}

		public override function draw(graphics: Graphics): void
		{
			super.draw(graphics);
			if(m_image != null) {
				if(container.height <= 0)
					return;
				if(container.width <= 0)
					return;
				var currentBBox: BBox = container.getViewBBox();

				// Check if CRS last rendered image == current CRS of container
				if(container.getCRS() != ms_imageCRS)
					return; // otherwise we cannot draw it
				
				var ptImageStartPoint: Point =
						container.coordToPoint(new Coord(ms_imageCRS, m_imageBBox.xMin, m_imageBBox.yMax));
				var ptImageEndPoint: Point =
					container.coordToPoint(new Coord(ms_imageCRS, m_imageBBox.xMax, m_imageBBox.yMin));
				ptImageEndPoint.x += 1;
				ptImageEndPoint.y += 1;

				//trace("InteractiveLayerWMS.draw(): image-w=" + m_image.width + " image-h=" + m_image.height);
				var ptImageSize: Point = ptImageEndPoint.subtract(ptImageStartPoint);
				ptImageSize.x = int(Math.round(ptImageSize.x));
				ptImageSize.y = int(Math.round(ptImageSize.y));

				var matrix: Matrix = new Matrix();
				matrix.scale(ptImageSize.x / m_image.width, ptImageSize.y / m_image.height);
				//trace("InteractiveLayerWMS.draw(): scale-x=" + matrix.a + " scale-y=" + matrix.d);
				
				matrix.translate(ptImageStartPoint.x, ptImageStartPoint.y);
				graphics.beginBitmapFill(m_image.bitmapData, matrix, true, true);
				//trace("InteractiveLayerWMS.draw(): x=" + ptImageStartPoint.x + " y=" + ptImageStartPoint.y + " w=" + ptImageSize.x + " h=" + ptImageSize.y);
				graphics.drawRect(ptImageStartPoint.x, ptImageStartPoint.y, ptImageSize.x, ptImageSize.y);
				graphics.endFill();
			}
		}
		
		
		// Event handlers
		override protected function onDataLoaded(event: UniURLLoaderEvent): void
		{
			super.onDataLoaded(event);
			
			var wmsCache: WMSCache = m_cache as WMSCache;
			if (_invalidateCacheAfterImageLoad)
			{
				wmsCache.invalidate(ms_imageCRS, m_imageBBox);
				_invalidateCacheAfterImageLoad = false;
			}
			
			var result: * = event.result;
			if(result is Bitmap) {
				m_image = result;
				mb_imageOK = true;
				ms_imageCRS = event.associatedData.requestedCRS;
				m_imageBBox = event.associatedData.requestedBBox;
				wmsCache.addImage(
						m_image,
						event.associatedData.requestedCRS,
						event.associatedData.requestedBBox,
						event.request);
				onJobFinished();
				return;
			}
			ExceptionUtils.logError(Log.getLogger("WMS"), result,
					"Error accessing layers '" + m_cfg.ma_layerNames.join(","))
			onDataLoadFailed(null);
		}

		private var _invalidateCacheAfterImageLoad: Boolean;
		override public function onAreaChanged(b_finalChange: Boolean): void
		{
			super.onAreaChanged(b_finalChange);
			if(b_finalChange) {
//				trace("WMS onAreaChanged ms_imageCRS: " + ms_imageCRS + " m_imageBBox: " + m_imageBBox);
				_invalidateCacheAfterImageLoad = true;
//				m_cache.invalidate(ms_imageCRS, m_imageBBox);
				updateData(false);
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
			
			trace("\n\n CLONE InteractiveLayerWMS ["+newLayer.name+"] alpha: " + newLayer.alpha + " zOrder: " +  newLayer.zOrder);
			trace("OLD: " + name + " label: " + id);
			return newLayer;
			
		}
	
	}
}