package com.iblsoft.flexiweather.ogc
{
	import com.iblsoft.flexiweather.events.InteractiveLayerEvent;
	import com.iblsoft.flexiweather.ogc.cache.WMSCache;
	import com.iblsoft.flexiweather.utils.UniURLLoaderEvent;
	import com.iblsoft.flexiweather.widgets.BackgroundJobManager;
	import com.iblsoft.flexiweather.widgets.InteractiveLayer;
	import com.iblsoft.flexiweather.widgets.InteractiveWidget;
	
	import flash.display.Bitmap;
	import flash.display.Graphics;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.net.URLRequest;
	
	import mx.logging.Log;
	
	public class InteractiveLayerWMS extends InteractiveLayerMSBase
			implements ISynchronisedObject
	{
		public function InteractiveLayerWMS(container: InteractiveWidget, cfg: WMSLayerConfiguration)
		{
			super(container, cfg);
			
			m_cache = new WMSCache();
		}
		
		override public function updateData(b_forceUpdate: Boolean): void
		{
			super.updateData(b_forceUpdate);
			
			var request: URLRequest = m_cfg.toGetMapRequest(
					container.getCRS(), container.getViewBBox().toBBOXString(),
					int(container.width), int(container.height),
					getWMSStyleListString());
			updateDimensionsInURLRequest(request);
			updateCustomParametersInURLRequest(request);
			var img: Bitmap = null;
			var wmsCache: WMSCache = m_cache as WMSCache;
			
			// invalidate property "displayed" for cached items			
			wmsCache.removeFromScreen();
			
			if(!b_forceUpdate)
			{
				var isCached: Boolean = wmsCache.isImageCached(container.getCRS(), container.getViewBBox(), request)
				var imgTest: Bitmap = wmsCache.getImage(container.getCRS(), container.getViewBBox(), request);
				
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
			}
			if(img == null) {
				m_timer.reset();
				m_job = BackgroundJobManager.getInstance().startJob("Rendering " + m_cfg.ma_layerNames.join("+"));
				m_request = request;
				m_loader.load(request, {
					requestedCRS: container.getCRS(),
					requestedBBox: container.getViewBBox()
				});
				
				invalidateDynamicPart();
				
				var ile: InteractiveLayerEvent = new InteractiveLayerEvent( InteractiveLayerEvent.LAYER_LOADIND_START, true );
				ile.interactiveLayer = this;
				dispatchEvent(ile);
				wmsCache.startImageLoading( container.getCRS(), container.getViewBBox(), request );
			}
			else {
				if(m_cfg.mi_autoRefreshPeriod > 0) {
					m_timer.delay = m_cfg.mi_autoRefreshPeriod * 1000.0;
					m_timer.start();
				}
				m_image = img;
				mb_imageOK = true;
				ms_imageCRS = container.getCRS();
				m_imageBBox = container.getViewBBox();
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
				
				var matrix: Matrix = new Matrix();
				// source image pixels to BBOX
				matrix.scale(m_imageBBox.width / m_image.width, -m_imageBBox.height / m_image.height);
				matrix.translate(m_imageBBox.xMin, m_imageBBox.yMax);
				// BBOX to destination graphics image pixels
				matrix.translate(-currentBBox.xMin, -currentBBox.yMax);
				matrix.scale(container.width / currentBBox.width, -container.height / currentBBox.height);
				//matrix.invert();

				graphics.beginBitmapFill(m_image.bitmapData, matrix, false, true);
				graphics.drawRect(0, 0, m_image.width, m_image.height);
				graphics.endFill();
				
				// fill the area around the map
				var pt00: Point = matrix.transformPoint(new Point(0, 0));
				var ptWH: Point = matrix.transformPoint(new Point(m_image.width - 1, m_image.height - 1));
				if (!(isNaN(container.width) || isNaN(container.height)))
				{
					graphics.beginFill(0xCCCCCC, 1);
					graphics.drawRect(ptWH.x, 0, container.width - ptWH.x, container.height);
					graphics.drawRect(0, 0, pt00.x, container.height);
					graphics.drawRect(pt00.x, 0, ptWH.x - pt00.x, pt00.y);
					graphics.drawRect(pt00.x, ptWH.y, ptWH.x - pt00.x, container.height - ptWH.y);
					graphics.endFill();
				}
			}
		}
		
		
		// Event handlers
		override protected function onDataLoaded(event: UniURLLoaderEvent): void
		{
			trace("WMS onDataLoaded");
			super.onDataLoaded(event);
			
			var wmsCache: WMSCache = m_cache as WMSCache;
			
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

		override public function onAreaChanged(b_finalChange: Boolean): void
		{
			super.onAreaChanged(b_finalChange);
			if(b_finalChange) {
				m_cache.invalidate(ms_imageCRS, m_imageBBox);
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