package com.iblsoft.flexiweather.ogc
{
	import com.iblsoft.flexiweather.events.InteractiveLayerEvent;
	import com.iblsoft.flexiweather.ogc.cache.ICache;
	import com.iblsoft.flexiweather.proj.Coord;
	import com.iblsoft.flexiweather.utils.ArrayUtils;
	import com.iblsoft.flexiweather.utils.Duration;
	import com.iblsoft.flexiweather.utils.ISO8601Parser;
	import com.iblsoft.flexiweather.utils.UniURLLoader;
	import com.iblsoft.flexiweather.utils.UniURLLoaderEvent;
	import com.iblsoft.flexiweather.widgets.BackgroundJob;
	import com.iblsoft.flexiweather.widgets.GlowLabel;
	import com.iblsoft.flexiweather.widgets.InteractiveLayer;
	import com.iblsoft.flexiweather.widgets.InteractiveWidget;
	
	import flash.display.Bitmap;
	import flash.display.DisplayObject;
	import flash.display.Graphics;
	import flash.events.DataEvent;
	import flash.events.TimerEvent;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.net.URLRequest;
	import flash.net.URLVariables;
	import flash.utils.Dictionary;
	import flash.utils.Timer;
	
	import mx.binding.utils.BindingUtils;
	import mx.containers.Canvas;
	import mx.controls.Image;
	import mx.core.UIComponent;
	import mx.effects.Fade;
	import mx.events.EffectEvent;
	import mx.logging.Log;
	
	public class InteractiveLayerMSBase extends InteractiveLayer
			implements ISynchronisedObject
	{
		protected var m_loader: UniURLLoader = new UniURLLoader();
		protected var m_featureInfoLoader: UniURLLoader = new UniURLLoader();
		protected var m_image: Bitmap = null;
		protected var mb_imageOK: Boolean = true;

		/**
		 * Bitmap image holder for legend 
		 */		
		protected var m_legendImage: Bitmap = null;
		
		protected var m_job: BackgroundJob;
		protected var m_request: URLRequest;

		protected var ms_imageCRS: String = null;
		protected var m_imageBBox: BBox = null;
		protected var mb_updateAfterMakingVisible: Boolean = false;
		
		protected var m_cfg: WMSLayerConfiguration;
		protected var md_dimensionValues: Dictionary = new Dictionary(); 
		protected var md_customParameters: Dictionary = new Dictionary(); 
		protected var ma_subLayerStyleNames: Array = [];
		
		protected var m_synchronisationRole: SynchronisationRole;

		protected var m_cache: ICache;
		
		protected var m_timer: Timer = new Timer(10000);

		public function InteractiveLayerMSBase(container: InteractiveWidget, cfg: WMSLayerConfiguration)
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
			m_timer.repeatCount = 1;
			
			createEffects();
//			setStyle('addedEffect', fadeIn);
			setStyle('showEffect', fadeIn);
//			setStyle('removedEffect', fadeOut);
			setStyle('hideEffect', fadeOut);
		}
		
		private var fadeIn: Fade;
		private var fadeOut: Fade;
		
		[Bindable]
		public var alphaBackup: Number = 1;
		private function createEffects(): void
		{
			fadeIn = new Fade(this);
			fadeIn.alphaFrom = 0;
			BindingUtils.bindProperty(fadeIn, 'alphaTo', this, "alphaBackup");
			fadeIn.duration = 300;
			
			fadeOut = new Fade(this);
			fadeOut.alphaTo = 0;
			BindingUtils.bindProperty(fadeOut, 'alphaFrom', this, "alpha");
			fadeOut.duration = 300;
			
			fadeIn.addEventListener(EffectEvent.EFFECT_END, onEffectEnd);
			fadeIn.addEventListener(EffectEvent.EFFECT_START, onEffectFadeInStart);
			fadeOut.addEventListener(EffectEvent.EFFECT_START, onEffectFadeOutStart);
			fadeOut.addEventListener(EffectEvent.EFFECT_END, onEffectEnd);
			
		}
		
		private function onEffectFadeInStart(event: EffectEvent): void
		{
//			trace("onEffectFadeInStart 1 _alphaBackup: " + _alphaBackup + " fadeIn.alphaTo: " + fadeIn.alphaTo);
//			fadeIn.alphaTo = _alphaBackup;
			trace("onEffectFadeInStart 2 alphaBackup: " + alphaBackup + " fadeIn.alphaTo: " + fadeIn.alphaTo);
		}
		private function onEffectFadeOutStart(event: EffectEvent): void
		{
//			trace("onEffectFadeOutStart 1 _alphaBackup: " + _alphaBackup + " fadeIn.alphaTo: " + fadeOut.alphaFrom);
//			fadeOut.alphaFrom = alpha
			alphaBackup = alpha;
			trace("onEffectFadeOutStart 2 alphaBackup: " + alphaBackup + " fadeIn.alphaTo: " + fadeOut.alphaFrom);
		}
		private function onEffectEnd(event: EffectEvent): void
		{
			callLater(delayedEffectEnd);
		}
		private function delayedEffectEnd(): void
		{
			var ile: InteractiveLayerEvent = new InteractiveLayerEvent(InteractiveLayerEvent.VISIBILITY_EFFECT_FINISHED);
			dispatchEvent(ile);
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
		
		/**
		 * If you want to change some data in request, you can implement it in this function. 
		 * E.g if you want change request type for tile layer you can override this function and update it
		 *  
		 * 
		 */		
		protected function updateRequestData(request: URLRequest): void
		{
			
		}
		/**
		 * function returns full URL for getting map 
		 * @return 
		 * 
		 */		
		override public function getFullURL(): String
		{
			var request: URLRequest = m_cfg.toGetMapRequest(
					container.getCRS(), container.getViewBBox().toBBOXString(),
					int(container.width), int(container.height),
					getWMSStyleListString());
			updateDimensionsInURLRequest(request);
			updateCustomParametersInURLRequest(request);
			updateRequestData(request);
			
			var s_url: String = request.url;
			if(request.data) {
				if(s_url.indexOf("?") >= 0)
					s_url += "&";
				else
					s_url += "?";
				s_url += request.data;
			}
			
			if (request.data.STYLE && request.data.STYLE.length > 0)
			{
				
			}
			return s_url;
		}
		
		public function updateData(b_forceUpdate: Boolean): void
		{
			if(m_job != null)
				m_job.cancel();
			m_job = null;
			if(m_request != null)
				m_loader.cancel(m_request);
			m_request = null;

			if(!visible) {
				mb_updateAfterMakingVisible = true;
				m_image = null;
				ms_imageCRS = null;
				m_imageBBox = null;
				m_timer.reset();
				return;
			}
			
		}

		public override function draw(graphics: Graphics): void
		{
			super.draw(graphics);
		}
		
		override public function onAreaChanged(b_finalChange: Boolean): void
		{
			super.onAreaChanged(b_finalChange);
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
        	//rerender legend
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
		
		private function getLegendForStyleName(styleName: String): Object
		{
//			if (ma
			return null;
		}
		// map legend
        override public function hasLegend(): Boolean
        { 
        	//check if layer has legend	
        	var styleName: String = getWMSStyleName(0);
        	if (!styleName)
        		styleName = '';
        	var style: Object = getWMSStyleObject(0, styleName);
        	
        	if (style)
        		return style.legend;
        		
        	return false;
       	}

		
		 override public function removeLegend(canvas: Canvas): void
		 {
		 	super.removeLegend(canvas);
		 	
		 	if (canvas)
		 	{
		 		while (canvas.numChildren > 0)
		 		{
		 			var disp: UIComponent = canvas.getChildAt(0) as UIComponent;
		 			if (disp is Image)
		 			{
		 				((disp as Image).source as Bitmap).bitmapData.dispose();
		 			}
		 			canvas.removeChildAt(0);
		 			disp = null;
		 		}	
		 	}
		 }
		 
        /**
         * Render legend. If legend is not cached, it needs to be loaded. 
         * @param canvas
         * @param callback
         * @param labelAlign
         * @param hintSize
         * @return 
         * 
         */		
        override public function renderLegend(canvas: Canvas, callback: Function, labelAlign: String = 'left', useCache: Boolean = false, hintSize: Rectangle = null): Rectangle
        {
        	super.renderLegend(canvas, callback, labelAlign, useCache, hintSize);
        	
        	var styleName: String = getWMSStyleName(0);
        	if (!styleName)
        		styleName = '';
        	var style: Object = getWMSStyleObject(0, styleName);
        	
        	var legendObject: Object = style.legend;
        	
        	var w: int = legendObject.width;
        	var h: int = legendObject.height;
        	if (hintSize)
        	{
        		w = hintSize.width;
        		h = hintSize.height;
        	}
        		
//			m_legendCanvas = canvas;
//			m_legendLabelAlign = labelAlign;
//        	m_legendCallBack = callback;
			
			trace("renderLegend url: " + legendObject.url);
          	if (!useCache || (useCache && !isLegendCachedBySize(w, h)))
        	{
	        	var url: URLRequest = m_cfg.toGetLegendRequest(
						w, h,
						style.name);
						
				updateURLWithDimensions(url);
						
				var associatedData: Object = {canvas: canvas, labelAlign: labelAlign, callback: callback, useCache: useCache};
				
				var legendLoader: UniURLLoader = new UniURLLoader();
				legendLoader.addEventListener(UniURLLoader.DATA_LOADED, onLegendLoaded);
				legendLoader.addEventListener(UniURLLoader.DATA_LOAD_FAILED, onLegendLoadFailed);
			
	        	legendLoader.load(url, associatedData);
	        	
        	} else {
        		createLegend(m_legendImage, canvas, labelAlign, callback);
        	}
        	
        	var gap: int = 2;
    		var labelHeight: int = 12;
        	return new Rectangle(0,0, w, h + gap + labelHeight);
        }
        
        /**
         * Check if legend image is cached. If last legend loaded has same width and height. 
         * @param newWidth
         * @param newHeight
         * 
         */        
        private function isLegendCachedBySize(newWidth: int, newHeight: int): Boolean
        {
        	if (m_legendImage)
        	{
        		if (m_legendImage.width == newWidth && m_legendImage.height == newHeight)
        		{
        			// legend is cached
        			return true;
        		}
        	}
        	return false;
        }
        
        public function getLegendFromCanvas(cnv: Canvas): Image
        {
        	var image: Image;
			if (cnv.numChildren > 1)
			{
				var imageTest: DisplayObject = cnv.getChildAt(cnv.numChildren - 1);
				if (imageTest is Image)
				{
					image = imageTest as Image;
				}
			}
			
			return image;
        }
        
        public function isLegendCached(cnv: Canvas): Boolean
        {
        	var image: Image = getLegendFromCanvas(cnv);
        	return (image != null);
        }
        
        private function clearLegendCache(): void
        {
        	if (m_legendImage)
        	{
        		if (m_legendImage.width > 0 && m_legendImage.height > 0)
        		{
        			m_legendImage.bitmapData.dispose();
        			m_legendImage = null;
        		}
        	}
        }
        
        private function removeLegendListeners(legendLoader: UniURLLoader): void
        {
        	legendLoader.removeEventListener(UniURLLoader.DATA_LOADED, onLegendLoaded);
			legendLoader.removeEventListener(UniURLLoader.DATA_LOAD_FAILED, onLegendLoadFailed);
        }
        /**
         * Function which handle legend load 
         * @param event
         * 
         */        
        protected function onLegendLoaded(event: UniURLLoaderEvent): void
		{
			trace("InteractiveLayerWMS onLegendLoaded ");
			var result: * = event.result;
			if(result is Bitmap) {
				
				var useCache: Boolean = event.associatedData.useCache;
				if (useCache)
					m_legendImage = result;
				createLegend(result, event.associatedData.canvas, event.associatedData.labelAlign, event.associatedData.callback);
			}
			removeLegendListeners(event.target as UniURLLoader);
		}
		
		/**
		 * 
		 * @param image
		 * @param cnv
		 * @param labelAlign
		 * @param callback
		 * @param useCache
		 * 
		 */		
		private function createLegend(bitmap: Bitmap, cnv: Canvas, labelAlign: String, callback: Function): void
		{
			var gap: int = 2;
			var labelHeight: int = 12;
			
			//add legend label (name of the layer)
			var label: GlowLabel;
			if (cnv.numChildren > 0)
			{
				var labelTest: DisplayObject = cnv.getChildAt(0);
				if (labelTest is GlowLabel && labelTest.name != 'styleLabel')
				{
					label = labelTest as GlowLabel;
				}
			}
			if (!label)
			{
			 	label = new GlowLabel();
				cnv.addChild(label);
			}
			
			 	
			label.glowBlur = 5;
			label.glowColor = 0xffffff;
			label.text = name;
			label.width = bitmap.width;
			label.setStyle('textAlign', labelAlign);
			
			//add legend image
			var image: Image;
			if (cnv.numChildren > 1)
			{
				var imageTest: DisplayObject = cnv.getChildAt(cnv.numChildren - 1);
				if (imageTest is Image)
				{
					image = imageTest as Image;
				}
			}
			if (!image)
			{
			 	image = new Image();
				cnv.addChild(image);
			}
			 	
			image.source = bitmap;
			image.width = bitmap.width;
			image.height = bitmap.height;
			image.y = labelHeight + gap;
			
			cnv.width = image.width;
			cnv.height = image.height + labelHeight + gap;
			
			
			if(callback != null) {
				callback.apply(null, [cnv]);
			}
		}
		protected function onLegendLoadFailed(event: UniURLLoaderEvent): void
		{
			trace("onLegendLoadFailed");
			removeLegendListeners(event.target as UniURLLoader);
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
        	
        	//trace("getWMSDimensionsValues ["+s_dimName+"] = " +createDimensionsValuesString(a_dimValues));
        	return a_dimValues;
        }
        
        private function updateURLWithDimensions(url: URLRequest): void
        {
        	var str: String = '';
        	
        	if (!url.data)
        	{
        		url.data = new Object();
        	}
        	for each(var layer: WMSLayer in getWMSLayers()) 
        	{
        		for each(var dim: WMSDimension in layer.dimensions) {
        			
        			var value: Object = getWMSDimensionValue(dim.ms_name);
        			if (!value)
        				value = dim.ms_default;
        				
        			url.data[dim.ms_name] = value.toString();
        			
        		}
        	}
        	
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
        	if (m_cfg.mb_legendIsDimensionDependant)
        	{
        		clearLegendCache();
        	}
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
    						title: style.title != null  ? style.title : style.name,
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

        public function getWMSStyleObject(i_subLayer: uint, styleName: String = ''): Object
        {
			var layer:WMSLayer = m_cfg.ma_layerConfigurations[i_subLayer] as WMSLayer;
			if (layer && layer.ma_styles && layer.ma_styles.length > 0) {
				if (styleName == '')
					return layer.ma_styles[0];
				else {
					for each (var styleObj: Object in layer.ma_styles)
					{
						if (styleObj.name == styleName)
							return styleObj;
					}
				}
			}
        	return null;
        }
        public function getWMSEffectiveStyleName(i_subLayer: uint): String
        {
        	var s_styleName: String = getWMSStyleName(i_subLayer);
        	if(s_styleName == null) {
				var layer:WMSLayer = m_cfg.ma_layerConfigurations[i_subLayer] as WMSLayer;
				if (layer && layer.ma_styles && layer.ma_styles.length > 0) {
					return layer.ma_styles[0].name;
				}
        	}
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
			var ile: InteractiveLayerEvent = new InteractiveLayerEvent( InteractiveLayerEvent.LAYER_LOADED, true );
			ile.interactiveLayer = this;
			dispatchEvent(ile);
			
			m_request = null;
			if(m_cfg.mi_autoRefreshPeriod > 0) {
				m_timer.reset();
				m_timer.delay = m_cfg.mi_autoRefreshPeriod * 1000.0;
				m_timer.start();
			}
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
				m_featureInfoCallBack.call(null, String(event.result), this);
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
		
		override public function set visible(b_visible: Boolean): void
		{
			var b_visiblePrev: Boolean = super.visible;
			super.visible = b_visible;
			
			if(!b_visiblePrev && b_visible && mb_updateAfterMakingVisible) {
				mb_updateAfterMakingVisible = false;
				updateData(true);
			}
		}

		override public function clone(): InteractiveLayer
		{
			var newLayer: InteractiveLayerWMS = new InteractiveLayerWMS(container, m_cfg);
			newLayer.alpha = alpha
			newLayer.zOrder = zOrder;
			newLayer.visible = visible;
					
			var styleName: String = getWMSStyleName(0)
			newLayer.setWMSStyleName(0, styleName);
			trace("\n\n CLONE InteractiveLayerWMS ["+newLayer.name+"] alpha: " + newLayer.alpha + " zOrder: " +  newLayer.zOrder);
			
			return newLayer;
			
		}
	
		public function get configuration(): WMSLayerConfiguration
		{ return m_cfg; }

		public function get dataLoader(): UniURLLoader
		{ return m_loader; } 

		public function get synchronisationRole(): SynchronisationRole
		{ return m_synchronisationRole; }
	}
}