package com.iblsoft.flexiweather.ogc.editable.annotations
{
	import com.iblsoft.flexiweather.ogc.editable.features.curves.withAnnotation.WFSFeatureEditableThunderstormArea;
	import com.iblsoft.flexiweather.ogc.net.loaders.WFSIconLoader;
	import com.iblsoft.flexiweather.utils.AnnotationBox;
	import com.iblsoft.flexiweather.utils.ColorUtils;
	
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.geom.ColorTransform;
	import flash.geom.Rectangle;

	public class ThunderstormAreaAnnotation extends AnnotationBox
	{
		
		public static const NAME_SLIGHT_OR_MODERATE_WITHOUT_HAIL: String = "Slight or Moderate without Hail";
		public static const NAME_SLIGHT_OR_MODERATE_WITH_HAIL: String = "Slight or Moderate with Hail";
		public static const NAME_HEAVY_WITHOUT_HAIL: String = "Heavy without Hail";
		public static const NAME_COMBINED_WITH_DUST_OR_SAND: String = "Combined with Dust or Sand";
		public static const NAME_HEAVY_WITH_HAIL: String = "Heavy with Hail";
		public static const NAME_RAIN: String = "Rain";
		
		public static const TYPE_SLIGHT_OR_MODERATE_WITHOUT_HAIL: String = "SlightOrModerateWithoutHail";
		public static const TYPE_SLIGHT_OR_MODERATE_WITH_HAIL: String = "SlightOrModerateWithHail";
		public static const TYPE_HEAVY_WITHOUT_HAIL: String = "HeavyWithoutHail";
		public static const TYPE_COMBINED_WITH_DUST_OR_SAND: String = "CombinedWithDustOrSand";
		public static const TYPE_HEAVY_WITH_HAIL: String = "HeavyWithHail";
		public static const TYPE_RAIN: String = "Rain";
			
		//private var m_label: TextField = new TextField();
		
		//private var m_BaseLabel: TextField = new TextField();
		//private var m_TopLabel: TextField = new TextField();
		
		private var m_areaFeature: WFSFeatureEditableThunderstormArea;
		
		private var mn_iconsWidth: Number = 24;
		
		private var ms_actIconLoaded: String = '';
		
		private var m_iconBitmap: Bitmap = new Bitmap();
		private var m_iconBitmapOrig: Bitmap;
		
		override public function set visible(value:Boolean):void
		{
			if (m_areaFeature)
				value = value && m_areaFeature.presentInViewBBox;
			
			if (super.visible != value)
			{
				super.visible = value;
			} 
		}
		
		public function ThunderstormAreaAnnotation()
		{
			super();
			
			var baseBitmapData: BitmapData = new BitmapData(24, 24, true, 0xFFFFFF);
			
			m_iconBitmap.bitmapData = baseBitmapData;
			
			addChild(m_iconBitmap);
		}
		
		/**
		 * 
		 */
		public function onIconLoaded(mBitmap: Bitmap): void
		{
			if (mBitmap){
				var nBitmapData: BitmapData = mBitmap.bitmapData.clone();
				
				m_iconBitmap.bitmapData = nBitmapData; //mBitmap.bitmapData.clone();
				m_iconBitmap.x = 2;
				m_iconBitmap.y = 2;
				
				m_iconBitmapOrig = new Bitmap(mBitmap.bitmapData.clone());
				
				updateContent();
			}
		}
		
		public override function updateContent(): void
		{
			super.updateContent();
			
			if (m_areaFeature){
				// FILL BASE DATA
				var nIcon: String = resolveIconName();
			
				if (nIcon != ms_actIconLoaded){
					ms_actIconLoaded = nIcon;
					WFSIconLoader.getInstance().getIcon(nIcon, this, onIconLoaded, 'synop/weather');
				}
				if (m_iconBitmap)
				{
					ColorUtils.updateSymbolColor(color, m_iconBitmap, m_iconBitmapOrig);
				}
				
			}
		}
		
		public override function measureContent(): void
		{
			measuredWidth = mn_iconsWidth + 4; 
			measuredHeight = mn_iconsWidth + 6; 
		}
		
		/**
		 * 
		 */
		internal function resolveIconName(): String
		{
			var retIconName: String = '';
			var type: String = m_areaFeature.getType();
			
			switch (type)
			{
				case TYPE_SLIGHT_OR_MODERATE_WITHOUT_HAIL: //'Slight or Moderate without Hail'){
					retIconName = '95';
					break;
				case TYPE_SLIGHT_OR_MODERATE_WITH_HAIL:  // 'Slight or Moderate with Hail'){
					retIconName = '96';
					break;
				case TYPE_HEAVY_WITHOUT_HAIL: // 'Heavy without Hail'){
					retIconName = '97';
					break;
				case TYPE_COMBINED_WITH_DUST_OR_SAND: // 'Combined with Dust or Sand'){
					retIconName = '98';
					break;
				case TYPE_HEAVY_WITH_HAIL: // 'Heavy with Hail'){
					retIconName = '99';
					break;
				case TYPE_RAIN: 
					retIconName = 'thunderstorm_rain';
					break;
			} 
			
			return(retIconName);
		}
		
		public function set thunderstormAreaData(val: WFSFeatureEditableThunderstormArea): void
		{
			m_areaFeature = val;
			
			updateContent();
		}
		
		public function get thunderstormAreaData(): WFSFeatureEditableThunderstormArea
		{ return m_areaFeature; }
	}
}