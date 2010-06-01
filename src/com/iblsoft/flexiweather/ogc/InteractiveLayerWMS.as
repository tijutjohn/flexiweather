package com.iblsoft.flexiweather.ogc
{
	import com.iblsoft.flexiweather.proj.Coord;
	import com.iblsoft.flexiweather.utils.ArrayUtils;
	import com.iblsoft.flexiweather.utils.Duration;
	import com.iblsoft.flexiweather.utils.ISO8601Parser;
	import com.iblsoft.flexiweather.utils.UniURLLoader;
	import com.iblsoft.flexiweather.utils.UniURLLoaderEvent;
	import com.iblsoft.flexiweather.widgets.BackgroundJob;
	import com.iblsoft.flexiweather.widgets.BackgroundJobManager;
	import com.iblsoft.flexiweather.widgets.InteractiveLayer;
	import com.iblsoft.flexiweather.widgets.InteractiveWidget;
	
	import flash.display.Bitmap;
	import flash.display.Graphics;
	import flash.events.DataEvent;
	import flash.events.TimerEvent;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.net.URLRequest;
	import flash.net.URLVariables;
	import flash.utils.Dictionary;
	import flash.utils.Timer;
	
	import mx.logging.Log;
	
	public class InteractiveLayerWMS extends InteractiveLayer
			implements ISynchronisedObject
	{
		protected var m_loader: UniURLLoader = new UniURLLoader();
		protected var m_featureInfoLoader: UniURLLoader = new UniURLLoader();
		protected var m_image: Bitmap = null;
		protected var mb_imageOK: Boolean = true;

		protected var m_job: BackgroundJob;
		protected var m_request: URLRequest;

		protected var ms_imageCRS: String = null;
		protected var m_imageBBox: BBox = null;
		
		protected var m_cfg: WMSLayerConfiguration;
		protected var md_dimensionValues: Dictionary = new Dictionary(); 
		protected var md_customParameters: Dictionary = new Dictionary(); 
		protected var ma_subLayerStyleNames: Array = [];
		
		protected var m_synchronisationRole: SynchronisationRole;
		public function get synchronisationRole(): SynchronisationRole
		{
			return m_synchronisationRole;
		}
		
		protected var m_cache: WMSCache = new WMSCache();
		
		protected var m_timer: Timer = new Timer(10000);

		public function InteractiveLayerWMS(container: InteractiveWidget, cfg: WMSLayerConfiguration)
		{
			super(container);
			m_loader.addEventListener(UniURLLoader.DATA_LOADED, onDataLoaded);
			m_loader.addEventListener(UniURLLoader.DATA_LOAD_FAILED, onDataLoadFailed);
			
			m_featureInfoLoader.addEventListener(UniURLLoader.DATA_LOADED, onFeatureInfoLoaded);
			m_featureInfoLoader.addEventListener(UniURLLoader.DATA_LOAD_FAILED, onFeatureInfoLoadFailed);
			
			m_synchronisationRole = new SynchronisationRole();
			
			setConfiguration(cfg);
			//filters = [ new GlowFilter(0xffffe0, 0.8, 2, 2, 2) ];
			m_timer.addEventListener(TimerEvent.TIMER_COMPLETE, onAutoRefreshTimerComplete)
			m_timer.repeatCount = 1
		}
		
		public function setConfiguration(cfg: WMSLayerConfiguration): void
		{
			if(m_cfg != null) {
				m_cfg.removeEventListener(WMSLayerConfiguration.CAPABILITIES_UPDATED, onCapabilitiesUpdated);
			}
			m_cfg = cfg;

			m_timer.stop();
			if(m_cfg.mi_autoRefreshPeriod > 0)
				m_timer.delay = m_cfg.mi_autoRefreshPeriod * 1000.0;
			m_cfg.addEventListener(WMSLayerConfiguration.CAPABILITIES_UPDATED, onCapabilitiesUpdated);
			
//			updateData(true);
		}
		
		public function updateData(b_forceUpdate: Boolean): void
		{
			if(m_job != null)
				m_job.cancel();
			m_job = null;
			if(m_request != null)
				m_loader.cancel(m_request);
			m_request = null;
			
			var request: URLRequest = m_cfg.toGetMapRequest(
					container.getCRS(), container.getViewBBox().toBBOXString(),
					int(container.width), int(container.height),
					getWMSStyleListString());
			updateDimensionsInURLRequest(request);
			updateCustomParametersInURLRequest(request);
			var img: Bitmap = null;

			if(!b_forceUpdate)
				img = m_cache.getImage(container.getCRS(), container.getViewBBox(), request);
			if(img == null) {
				m_timer.reset();
				m_job = BackgroundJobManager.getInstance().startJob("Rendering " + m_cfg.ma_layerNames.join("+"));
				m_request = request;
				m_loader.load(request, {
					requestedCRS: container.getCRS(),
					requestedBBox: container.getViewBBox()
				});
				invalidateDynamicPart();
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
				graphics.beginFill(0xCCCCCC, 1);
				graphics.drawRect(ptWH.x, 0, container.width - ptWH.x, container.height);
				graphics.drawRect(0, 0, pt00.x, container.height);
				graphics.drawRect(pt00.x, 0, ptWH.x - pt00.x, pt00.y);
				graphics.drawRect(pt00.x, ptWH.y, ptWH.x - pt00.x, container.height - ptWH.y);
				graphics.endFill();
			}
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
		
		override public function onContainerSizeChanged(): void
		{
			super.onContainerSizeChanged();
			updateData(false);
		}
		
        override public function refresh(b_force: Boolean): void
        {
        	super.refresh(b_force);
        	updateData(b_force);
        }

		override public function hasPreview(): Boolean
		{ return true; }

		override public function renderPreview(graphics: Graphics, f_width: Number, f_height: Number): void
		{
			if(m_image != null) {
				var matrix: Matrix = new Matrix();
				matrix.translate(-f_width / 3, -f_width / 3);
				matrix.scale(3, 3);
				matrix.translate(m_image.width / 3, m_image.height / 3);
				matrix.invert();
  				graphics.beginBitmapFill(m_image.bitmapData, matrix, false, true);
				graphics.drawRect(0, 0, f_width, f_height);
				graphics.endFill();
			}
			if(!mb_imageOK) {
				graphics.lineStyle(2, 0xcc0000, 0.7, true);
				graphics.moveTo(0, 0);
				graphics.lineTo(f_width - 1, f_height - 1);
				graphics.moveTo(0, f_height - 1);
				graphics.lineTo(f_width - 1, 0);
			}
		}
		
		override public function hasFeatureInfo(): Boolean
		{
        	for each(var layer: WMSLayer in getWMSLayers()) {
        		if(layer.mb_queryable)
        			return true;
        	}
        	return false;
		}
		
		protected var m_featureInfoCallBack: Function;
		
		override public function getFeatureInfo(coord: Coord, callback: Function): void
		{
			var a_queryableLayerNames: Array = [];
        	for each(var layer: WMSLayer in getWMSLayers()) {
        		if(layer.mb_queryable)
        			a_queryableLayerNames.push(layer.name);
        	}
			var pt: Point = container.coordToPoint(coord);
			var url: URLRequest = m_cfg.toGetFeatureInfoRequest(
					container.getCRS(), container.getViewBBox().toBBOXString(),
					int(container.width), int(container.height),
					a_queryableLayerNames, int(Math.round(pt.x)), int(Math.round(pt.y)),
					getWMSStyleListString());
			updateDimensionsInURLRequest(url);
			updateCustomParametersInURLRequest(url);
			m_featureInfoCallBack = callback;
			m_featureInfoLoader.load(url);
		}
		
		override public function hasExtent(): Boolean
        {
        	return getExtent() != null;
        }
        
        override public function getExtent(): BBox
        {
        	if(m_cfg.service == null)
        		return null;
        	var bbox: BBox = null;
        	for each(var layer: WMSLayer in getWMSLayers()) {
        		var b: BBox = layer.getBBoxForCRS(container.getCRS());
        		if(b == null)
        			continue;
        		if(bbox == null)
        			bbox = b;
        		else
        			bbox = bbox.extendedWith(b);
        	}
			return bbox;
        }
		
		public function getWMSLayers(): Array
		{
			var a: Array = [];
        	for each(var s_layerName: String in m_cfg.ma_layerNames) {
        		var layer: WMSLayer = m_cfg.service.getLayerByName(s_layerName);
        		if(layer != null)
        			a.push(layer);
        	}
        	return a;
		}
        
        public function getWMSDimensionsNames(): Array
        {
			var a_dimNames: Array = [];
        	for each(var layer: WMSLayer in getWMSLayers()) {
        		for each(var dim: WMSDimension in layer.dimensions) {
        			if(a_dimNames.indexOf(dim.name) < 0)
        				a_dimNames.push(dim.name);
        		}
        	}
        	return a_dimNames;
        }
        
		// returns null is no such dimension exist
        public function getWMSDimensionUnitsName(s_dimName: String): String
        {
			var s_units: String = null;
			var b_anyDimensionFound: Boolean = false;
        	for each(var layer: WMSLayer in getWMSLayers()) {
        		for each(var dim: WMSDimension in layer.dimensions) {
        			if(dim.name != s_dimName)
        				continue;
        			if(dim.ms_units == null)
        				continue;
        			b_anyDimensionFound = true;
        			if(s_units == null)
        				s_units = dim.ms_units;
        			else {
        				if(dim.ms_units != s_units)
        					return "mixed units";
        			}
        		}
        	}
        	if(b_anyDimensionFound && s_units == null)
        		return "no units";
        	return s_units;
        }

		// returns null is no such dimension exist
        public function getWMSDimensionDefaultValue(s_dimName: String): String
        {
			var s_defaultValue: String = null;
			var b_anyDimensionFound: Boolean = false;
        	for each(var layer: WMSLayer in getWMSLayers()) {
        		for each(var dim: WMSDimension in layer.dimensions) {
        			if(dim.name != s_dimName)
        				continue;
        			if(dim.ms_units == null)
        				continue;
        			b_anyDimensionFound = true;
        			if(s_defaultValue == null)
        				s_defaultValue = dim.ms_default;
        			else {
        				if(dim.ms_default != s_defaultValue)
        					return "mixed values";
        			}
        		}
        	}
        	if(b_anyDimensionFound && s_defaultValue == null)
        		return "";
        	return s_defaultValue;
        }
		// returns null is no such dimension exist
        public function getWMSDimensionsValues(s_dimName: String, b_intersection: Boolean = true): Array
        {
			var a_dimValues: Array;
        	for each(var layer: WMSLayer in getWMSLayers()) {
        		for each(var dim: WMSDimension in layer.dimensions) {
        			if(dim.name != s_dimName)
        				continue;
        			if(a_dimValues == null)
        				a_dimValues = dim.values;
        			else {
        				if(b_intersection)
        					a_dimValues = ArrayUtils.intersectedArrays(a_dimValues, dim.values);
        				else
        					ArrayUtils.unionArrays(a_dimValues, dim.values);
        			}
        		}
        	}
        	return a_dimValues;
        }

		/**
		 * It returns date from RUN and FORECAST set for this layer 
		 * @return 
		 * 
		 */		
		public function getWMSCurrentDate(): Date
		{
			var run: String = getWMSDimensionValue('RUN');
			var forecast: String = getWMSDimensionValue('FORECAST');
			
			trace('run: ' + run + ' forecast: ' + forecast);
			
			return new Date();
		}
        public function setWMSDimensionValue(s_dimName: String, s_value: String): void
        {
        	if(s_value != null)
        		md_dimensionValues[s_dimName] = s_value;
        	else
        		delete md_dimensionValues[s_dimName];
        	// if "run" changed, then even time axis changes
        	if(m_cfg.ms_dimensionRunName != null && s_dimName == m_cfg.ms_dimensionRunName) {
				dispatchEvent(new SynchronisedVariableChangeEvent(
						SynchronisedVariableChangeEvent.SYNCHRONISED_VARIABLE_DOMAIN_CHANGED, "frame"));
        	}
        	//if "forecast" changed, we need to update timeline, so we need to dispatch event
        	if(m_cfg.ms_dimensionForecastName != null && s_dimName == m_cfg.ms_dimensionForecastName) {
				dispatchEvent(new SynchronisedVariableChangeEvent(
						SynchronisedVariableChangeEvent.SYNCHRONISED_VARIABLE_CHANGED, "frame"));
        	}
        	//if "time" changed, we need to update timeline, so we need to dispatch event
        	if(m_cfg.ms_dimensionTimeName != null && s_dimName == m_cfg.ms_dimensionTimeName) {
				dispatchEvent(new SynchronisedVariableChangeEvent(
						SynchronisedVariableChangeEvent.SYNCHRONISED_VARIABLE_CHANGED, "frame"));
        	}
        }

        public function getWMSDimensionValue(s_dimName: String,
        		b_returnDefault: Boolean = false): String
        {
        	if(s_dimName in md_dimensionValues) 
        		return md_dimensionValues[s_dimName];
        	else {
        		if(b_returnDefault)
        			return getWMSDimensionDefaultValue(s_dimName);
        		return null;
        	}
        }
        
        /**
        * For each WMS sub-layer, returns array of objects having .name and .label properties
        * or null if the sub-layer doesn't have any styles. This is bound together
        * into one final array having that many items as is the number of WMS sub-layers.
        **/
        public function getWMSStyles(): Array
        {
        	var b_foundAnyStyle: Boolean = false;
			var a_styles: Array = [];
        	for each(var layer: WMSLayer in getWMSLayers()) {
        		var a_layerStyles: Array = [];
    			for each(var style: Object in layer.ma_styles) {
    				b_foundAnyStyle = true;
    				a_layerStyles.push({
    						label: style.title != null ? (style.title + " (" + style.name + ")") : style.name,
    						name: style.name
    				});
    			} 
        		a_styles.push(a_layerStyles.length > 0 ? a_layerStyles : null);
        	}
        	return b_foundAnyStyle ? a_styles : null;
        }
        
        public function getWMSStyleName(i_subLayer: uint): String
        {
        	if(i_subLayer in ma_subLayerStyleNames)
        		return ma_subLayerStyleNames[i_subLayer];
        	else
        		return null;
        }

        public function setWMSStyleName(i_subLayer: uint, s_styleName: String): void
        {
        	if(s_styleName != null)
	       		ma_subLayerStyleNames[i_subLayer] = s_styleName;
	       	else
	       		delete ma_subLayerStyleNames[i_subLayer];
        }
        
        public function getWMSStyleListString(): String
        {
        	var s: String = "";
			for(var i_subLayer: uint = 0; i_subLayer < m_cfg.ma_layerNames.length; ++i_subLayer) {
				if(i_subLayer > 0)
					s += ",";
				if(i_subLayer in ma_subLayerStyleNames)
					s += ma_subLayerStyleNames[i_subLayer];
				else if(i_subLayer in m_cfg.ma_styleNames)
					s += m_cfg.ma_styleNames[i_subLayer];
			}
			return s;
        }
        
        public function setWMSCustomParameter(s_parameter: String, s_value: String): void
        {
        	if(s_value != null)
        		md_customParameters[s_parameter] = s_value;
        	else
        		delete md_customParameters[s_parameter];
        }

		/**
		 * Populates URLRequest with dimension values.
		 **/
		public function updateDimensionsInURLRequest(url: URLRequest): void
		{
			for(var s_dimName: String in md_dimensionValues) {
				if(url.data == null)
					url.data = new URLVariables();
				url.data[m_cfg.dimensionToParameterName(s_dimName)] = md_dimensionValues[s_dimName];
			}
		}

		/**
		 * Populates URLRequest with custom parameter values.
		 **/
		public function updateCustomParametersInURLRequest(url: URLRequest): void
		{
			for(var s_parameter: String in md_customParameters) {
				if(url.data == null)
					url.data = new URLVariables();
				url.data[s_parameter] = md_customParameters[s_parameter];
			}
		 }

		// ISynchronisedObject implementation
		public function getSynchronisedVariables(): Array
		{
			var a: Array = [];

			if(m_cfg.dimensionTimeName != null
					|| (m_cfg.dimensionRunName != null && m_cfg.dimensionForecastName != null))
				a.push("frame");

			if(m_cfg.dimensionRunName != null)
				a.push("run");

			if(m_cfg.dimensionVerticalLevelName != null)
				a.push("level");
			return a;
		}

		public function isPrimaryLayer(): Boolean
		{
			if (m_synchronisationRole)
			{
				return m_synchronisationRole.isPrimary;
			}
			return false;
		}
	
		public function canSynchronisedVariableWith(s_variable: String, value: Object): Boolean
		{
			return false;
		}

		public function getSynchronisedVariableValue(s_variableId: String): Object
		{
			if(s_variableId == "frame") {
				if(m_cfg.dimensionTimeName != null) {
					return ISO8601Parser.stringToDate(getWMSDimensionValue(m_cfg.dimensionTimeName, true));
				}
				else if(m_cfg.dimensionRunName != null && m_cfg.dimensionForecastName != null) {
					var run: Date = ISO8601Parser.stringToDate(
							getWMSDimensionValue(m_cfg.dimensionRunName, true));
					var forecast: Duration = ISO8601Parser.stringToDuration(
							getWMSDimensionValue(m_cfg.dimensionForecastName, true));
					if (run != null && forecast != null)
						return new Date(run.time + forecast.milisecondsTotal);
						
					return null;
				}
			}
			return null;
		}

		public function getSynchronisedVariableValuesList(s_variableId: String): Array
		{
			if(s_variableId == "frame") {
				if(m_cfg.dimensionTimeName != null) {
					var l_times: Array = getWMSDimensionsValues(m_cfg.dimensionTimeName);
					var l_resultTimes: Array = [];
					for each(var time: Object in l_times) {
						l_resultTimes.push(time.data);
					}
					return l_resultTimes;
				}
				else if(m_cfg.dimensionRunName != null && m_cfg.dimensionForecastName != null) {
					var run: Date = ISO8601Parser.stringToDate(getWMSDimensionValue(m_cfg.dimensionRunName, true));
					if(run == null)
						return [];
					var l_forecasts: Array = getWMSDimensionsValues(m_cfg.dimensionForecastName);
					var l_resultForecasts: Array = [];
					for each(var forecast: Object in l_forecasts) {
						l_resultForecasts.push(new Date(run.time + Duration(forecast.data).milisecondsTotal));
					}
					return l_resultForecasts;
				}
				else
					return [];
			}
			else
				return null;
		}

		public function synchroniseWith(s_variableId: String, value: Object): Boolean
		{
			if(s_variableId == "frame") {
				if(m_cfg.dimensionTimeName != null) {
					var frame: Date = value as Date;
					// TODO: interpolation vs. find nearest value?
					setWMSDimensionValue(m_cfg.dimensionTimeName, ISO8601Parser.dateToString(frame));
					dispatchEvent(new SynchronisedVariableChangeEvent(
							SynchronisedVariableChangeEvent.SYNCHRONISED_VARIABLE_CHANGED, "frame"));
					return true;
				}
				else if(m_cfg.dimensionRunName != null && m_cfg.dimensionForecastName != null) {
					var run: Date = ISO8601Parser.stringToDate(
							getWMSDimensionValue(m_cfg.dimensionRunName, true));
					var forecast: Duration = new Duration(((value as Date).time - run.time) / 1000.0);
					var l_forecasts: Array = getWMSDimensionsValues(m_cfg.dimensionForecastName);
					// TODO: interpolation vs. find nearest value?
					var ofNearest: Object = null;
					for each(var of: Object in l_forecasts) {
						if(ofNearest == null ||
							Math.abs(Duration(of.data).secondsTotal - forecast.secondsTotal)
									< Math.abs(Duration(ofNearest.data).secondsTotal - forecast.secondsTotal)) {
							ofNearest = of;
						}
					}
					if(ofNearest != null) {
						setWMSDimensionValue(m_cfg.dimensionForecastName, ofNearest.value);
						dispatchEvent(new SynchronisedVariableChangeEvent(
								SynchronisedVariableChangeEvent.SYNCHRONISED_VARIABLE_CHANGED, "frame"));
						return true;
					}
				}
			}
			return false;
		}
		
		// Event handlers
		protected function onDataLoaded(event: UniURLLoaderEvent): void
		{
			m_request = null;
			if(m_cfg.mi_autoRefreshPeriod > 0) {
				m_timer.reset();
				m_timer.delay = m_cfg.mi_autoRefreshPeriod * 1000.0;
				m_timer.start();
			}
			var result: * = event.result;
			if(result is Bitmap) {
				m_image = result;
				mb_imageOK = true;
				ms_imageCRS = event.associatedData.requestedCRS;
				m_imageBBox = event.associatedData.requestedBBox;
				m_cache.addImage(
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

		protected function onDataLoadFailed(event: UniURLLoaderEvent): void
		{
			m_request = null;
			if(m_cfg.mi_autoRefreshPeriod > 0) {
				m_timer.reset();
				m_timer.delay = m_cfg.mi_autoRefreshPeriod * 1000.0;
				m_timer.start();
			}
			if(event != null) {
				ExceptionUtils.logError(Log.getLogger("WMS"), event,
						"Error accessing layers '" + m_cfg.ma_layerNames.join(","))
			}
			m_image = null;
			mb_imageOK = false;
			ms_imageCRS = null;
			m_imageBBox = null;
			onJobFinished();
		}
		
		protected function onCapabilitiesUpdated(event: DataEvent): void
		{
			dispatchEvent(new SynchronisedVariableChangeEvent(
					SynchronisedVariableChangeEvent.SYNCHRONISED_VARIABLE_DOMAIN_CHANGED, "frame"));
		}

		protected function onFeatureInfoLoaded(event: UniURLLoaderEvent): void
		{
			if(m_featureInfoCallBack != null) {
				m_featureInfoCallBack.call(null, String(event.result));
			}
			m_featureInfoCallBack = null;
		}
		
		protected function onFeatureInfoLoadFailed(event: UniURLLoaderEvent): void
		{
			m_featureInfoCallBack.call(null, event.result.toString());
			m_featureInfoCallBack = null;
		}
		
		protected function onJobFinished(): void
		{
			if(m_job != null) {
				m_job.finish();
				m_job = null;
			}
			invalidateDynamicPart();
		}
		
		protected function onAutoRefreshTimerComplete(event: TimerEvent): void
		{
			updateData(true);
		}
		
		override public function get name(): String
		{ return m_cfg.label; }

		public function get configuration(): WMSLayerConfiguration
		{ return m_cfg; }

		public function get dataLoader(): UniURLLoader
		{ return m_loader; } 
	}
}

import com.iblsoft.flexiweather.ogc.BBox;
import flash.utils.Dictionary;
import flash.net.URLRequest;
import flash.display.Bitmap;

class WMSCacheKey
{
	internal var ms_key: String;
	internal var ms_crs: String;
	internal var m_bbox: BBox;

	public function WMSCacheKey(s_crs: String, bbox: BBox, url: URLRequest)
	{
		ms_crs = s_crs;
		m_bbox = bbox;
		ms_key = s_crs + "|" + bbox.toBBOXString();
		var a: Array = []
		if(url != null) {
			for(var s: String in url.data) {
				a.push(s);
			}
			a.sort();
			for each(s in a) {
				ms_key += "|" + s + "=" + url.data[s]; 
			}
		} 
	}
	
	public function toString(): String
	{ return ms_key; }
}

class WMSCache
{
	protected var md_cache: Dictionary = new Dictionary();
	
	public function getImage(s_crs: String, bbox: BBox, url: URLRequest): Bitmap
	{
		var ck: WMSCacheKey = new WMSCacheKey(s_crs, bbox, url);
		var s_key: String = ck.toString(); 
		if(s_key in md_cache) {
			md_cache[s_key].lastUsed = new Date();
			return md_cache[s_key].image;
		}
		return null;
	}

	public function addImage(img: Bitmap, s_crs: String, bbox: BBox, url: URLRequest): void
	{
		var ck: WMSCacheKey = new WMSCacheKey(s_crs, bbox, url);
		var s_key: String = ck.toString(); 
		md_cache[s_key] = {
			cacheKey: ck,
			lastUsed: new Date(),
			image: img
		};
	}
	
	public function invalidate(s_crs: String, bbox: BBox): void
	{
		var a: Array = [];
		for(var s_key: String in md_cache) {
			var ck: WMSCacheKey = md_cache[s_key].cacheKey; 
			if(ck.ms_crs == s_crs && ck.m_bbox.equals(bbox))
				a.push(s_key);
		}
		for each(s_key in a) {
			trace("WMSCache.invalidate(): removing image with key: " + md_cache[s_key].toString());
			delete md_cache[s_key];
		}
	}
	
	
}
