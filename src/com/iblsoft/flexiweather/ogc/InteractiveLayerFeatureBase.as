package com.iblsoft.flexiweather.ogc
{
	import com.iblsoft.flexiweather.ogc.editable.WFSFeatureEditable;
	import com.iblsoft.flexiweather.widgets.InteractiveDataLayer;
	import com.iblsoft.flexiweather.widgets.InteractiveWidget;
	
	import flash.display.Sprite;
	
	import mx.collections.ArrayCollection;
	
	public class InteractiveLayerFeatureBase extends InteractiveDataLayer
	{
		private var ma_features: ArrayCollection = new ArrayCollection();
		private var m_featuresContainer: Sprite = new Sprite();
		
		protected var ms_serviceURL: String = null;
		protected var m_version: Version;
		
		protected var mb_useMonochrome: Boolean = false;
		protected var mi_monochromeColor: uint = 0x333333;
		
		public function InteractiveLayerFeatureBase(container: InteractiveWidget,
													version: Version)
		{
			super(container);
			
			m_version = version;
			m_featuresContainer.mouseEnabled = false;
			m_featuresContainer.mouseChildren = false;
			addChild(m_featuresContainer);
		}
		
		/**
		 * Creates new features from XML and remove old features if bRemoveOld = true 
		 * @param xml
		 * @param bRemoveOld Boolean flag if old features must be removed (Load = true, Import = false)
		 * 
		 */		
		public function createFeaturesFromXML( xml: XML, bIsImport: Boolean = false): ArrayCollection
		{
			return null;
		}
		
		
		public function addFeature(feature: FeatureBase): void
		{
			feature.setMaster(this);
			feature.update();
			m_featuresContainer.addChild(feature);
			ma_features.addItem(feature);
			onFeatureAdded(feature);
		}
		
		protected function onFeatureAdded(feature: FeatureBase): void
		{
			invalidateDynamicPart();
		}
		
		protected function onFeatureRemoved(feature: FeatureBase): void
		{
			invalidateDynamicPart();
		}
		
		public function set useMonochrome(val: Boolean): void
		{
			var b_needUpdate: Boolean = false;
			if(mb_useMonochrome != val)
				b_needUpdate = true;
			
			mb_useMonochrome = val;
			
			if(b_needUpdate) {
				for(var i: int = 0; i < m_featuresContainer.numChildren; i++){
					if(m_featuresContainer.getChildAt(i) is WFSFeatureEditable){
						WFSFeatureEditable(m_featuresContainer.getChildAt(i)).update();
					}
				}
			}
		}
		
		public function get useMonochrome(): Boolean
		{ return mb_useMonochrome; }
		
		public function set monochromeColor(i_color: uint): void
		{
			var b_needUpdate: Boolean = false;
			if(mi_monochromeColor != i_color)
				b_needUpdate = true;
			
			mi_monochromeColor = i_color;
			
			if(b_needUpdate) {
				for(var i: int = 0; i < m_featuresContainer.numChildren; i++) {
					if(m_featuresContainer.getChildAt(i) is WFSFeatureEditable) {
						WFSFeatureEditable(m_featuresContainer.getChildAt(i)).update();
					}
				}
			}
		}
		
		public function get monochromeColor(): uint
		{ return mi_monochromeColor; }
		
		public function get featuresContainer(): Sprite
		{ return m_featuresContainer; }
		
		public function set features(value: ArrayCollection): void
		{
			ma_features = value;
		}
		// getters & setters		
		public function get features(): ArrayCollection
		{ return ma_features; }
		
		public function get serviceURL(): String
		{ return ms_serviceURL; }
		
		public function set serviceURL(s_serviceURL: String): void
		{ ms_serviceURL = s_serviceURL; }
	}
}