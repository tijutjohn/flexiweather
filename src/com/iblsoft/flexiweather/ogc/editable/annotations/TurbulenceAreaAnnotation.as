package com.iblsoft.flexiweather.ogc.editable.annotations
{
	import com.iblsoft.flexiweather.net.loaders.UniURLLoader;
	import com.iblsoft.flexiweather.ogc.editable.features.curves.withAnnotation.WFSFeatureEditableTurbulenceArea;
	import com.iblsoft.flexiweather.ogc.net.loaders.WFSIconLoader;
	import com.iblsoft.flexiweather.utils.AnnotationBox;
	import com.iblsoft.flexiweather.utils.ColorUtils;
	
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextFormat;

	public class TurbulenceAreaAnnotation extends AnnotationBox
	{
		//Turbulence Area Degree
		public static const NAME_MODERATE_IN_CLEAR_AIR: String = 'Moderate in clear air';
		public static const NAME_SEVERE_IN_CLEAR_AIR: String = 'Severe in clear air';
		public static const NAME_MODERATE_ISOL_SEVERE: String = 'Moderate ISOL Severe';
		public static const NAME_MODERATE_OCNL_SEVERE: String = 'Moderate OCNL Severe';
		public static const NAME_MODERATE_FRQ_SEVERE: String = 'Moderate FRQ Severe';
		
		public static const TYPE_MODERATE_IN_CLEAR_AIR: String = 'ClearAirModerate';
		public static const TYPE_SEVERE_IN_CLEAR_AIR: String = 'ClearAirSevere';
		public static const TYPE_MODERATE_ISOL_SEVERE: String = 'ModerateISOLSevere';
		public static const TYPE_MODERATE_OCNL_SEVERE: String = 'ModerateOCNLSevere';
		public static const TYPE_MODERATE_FRQ_SEVERE: String = 'ModerateFRQSevere';
		
		
		private var m_BaseLabel: TextField = new TextField();
		private var m_TopLabel: TextField = new TextField();
		private var m_DegreeLabel: TextField = new TextField();
		
		private var m_turbulenceFeature: WFSFeatureEditableTurbulenceArea;
		
		private var mn_iconsWidth: Number = 24;
		
		private var m_loader: UniURLLoader = new UniURLLoader();
		
		private var ms_actIconLoaded: String = '';
		private var ms_actIcon2Loaded: String = '';
		
		private var m_iconBitmap: Bitmap = new Bitmap();
		private var m_icon2Bitmap: Bitmap = new Bitmap(); // THIS ICON IS NEEDED WHEN USING 'Moderate ISOL Severe', 'Moderate OCNL Severe', 'Moderate FRQ Severe'
		
		private var m_originalSymbolBitmap: Bitmap;
		private var m_originalSymbol2Bitmap: Bitmap;
		
		public function TurbulenceAreaAnnotation()
		{
			super();
			
			var baseBitmapData: BitmapData = new BitmapData(24, 24, true, 0xFFFFFF);
			
			m_iconBitmap.bitmapData = baseBitmapData;
			
			//addChild(m_label);
			addChild(m_BaseLabel);
			addChild(m_iconBitmap);
			addChild(m_DegreeLabel);
			addChild(m_icon2Bitmap);
			addChild(m_TopLabel);
			
			var nFormat: TextFormat = new TextFormat('_sans', 11);
			
			/*m_BaseLabel.border = true;
			m_TopLabel.border = true;
			m_DegreeLabel.border = true;*/
			
			m_BaseLabel.defaultTextFormat = nFormat;
			m_TopLabel.defaultTextFormat = nFormat;
			m_DegreeLabel.defaultTextFormat = nFormat;
			
			m_BaseLabel.setTextFormat(nFormat);
			m_TopLabel.setTextFormat(nFormat);
			m_DegreeLabel.setTextFormat(nFormat);
			
			m_BaseLabel.multiline = true;
			m_TopLabel.multiline = true;
			m_DegreeLabel.multiline = true;
			
			m_BaseLabel.selectable = false;
			m_TopLabel.selectable = false;
			m_DegreeLabel.selectable = false;
			
			m_BaseLabel.autoSize = TextFieldAutoSize.CENTER;
			m_TopLabel.autoSize = TextFieldAutoSize.CENTER;
			m_DegreeLabel.autoSize = TextFieldAutoSize.CENTER;
			
		}
		
		/**
		 * 
		 */
		public function onIconLoaded(mBitmap: Bitmap): void
		{
			if (mBitmap){
				m_iconBitmap.bitmapData = mBitmap.bitmapData.clone();
				m_originalSymbolBitmap = new Bitmap(mBitmap.bitmapData.clone());
				updateContent();
			}
		}
		
		/**
		 * 
		 */
		public function onIcon2Loaded(mBitmap: Bitmap): void
		{
			if (mBitmap){
				m_icon2Bitmap.bitmapData = mBitmap.bitmapData.clone();
				m_originalSymbol2Bitmap = new Bitmap(mBitmap.bitmapData.clone());
			}
		}
		
		public override function updateContent(): void
		{
			super.updateContent();
			
			if (m_turbulenceFeature){
				// FILL BASE DATA
				var base: String = formatLevelString(m_turbulenceFeature.verticalExtentBase);
				var top: String = formatLevelString(m_turbulenceFeature.verticalExtentTop);
				
				//if ((m_icingFeature.verticalExtentBase > 0) || (m_icingFeature.verticalExtentTop > 0)){
					m_TopLabel.htmlText = '<P align="center">' + top + '</P>';
					m_BaseLabel.htmlText = '<P align="center">' + base + '</P>';
				//}
				
				var usingDegree: Boolean = false;
				if (m_turbulenceFeature.degree == 'Moderate ISOL Severe'){
					// USING SPECIAL DEGREE
					m_DegreeLabel.htmlText = '<P align="center">ISOL</P>';
					usingDegree = true;
				} else if (m_turbulenceFeature.degree == 'Moderate OCNL Severe'){
					// USING SPECIAL DEGREE
					m_DegreeLabel.htmlText = '<P align="center">OCNL</P>';
					usingDegree = true;
				} else if (m_turbulenceFeature.degree == 'Moderate FRQ Severe'){
					// USING SPECIAL DEGREE
					m_DegreeLabel.htmlText = '<P align="center">FRQ</P>';
					usingDegree = true;
				} else {
					m_DegreeLabel.htmlText = '';
					usingDegree = false;	
				}
				
				m_DegreeLabel.visible = usingDegree;
				m_icon2Bitmap.visible = usingDegree;
				
				// ---------
				m_TopLabel.x = 2;
				m_TopLabel.y = 2;
				m_TopLabel.width = measuredWidth - 4;
				//m_TopLabel.height = measuredHeight - 4;
				
				m_BaseLabel.x = 2;
				m_BaseLabel.width = measuredWidth - 4;
				
				m_iconBitmap.x = int((measuredWidth - m_iconBitmap.width) / 2);
				m_iconBitmap.y = m_TopLabel.y + m_TopLabel.height - 4;
				
				m_DegreeLabel.x = 2;
				m_DegreeLabel.y = m_iconBitmap.y + mn_iconsWidth - 4;
				m_DegreeLabel.width = measuredWidth - 4;
				
				m_icon2Bitmap.x = int((measuredWidth - m_iconBitmap.width) / 2);
				m_icon2Bitmap.y = m_DegreeLabel.y + m_DegreeLabel.height - 4;
				
				ColorUtils.updateSymbolColor(color, m_iconBitmap, m_originalSymbolBitmap);
				ColorUtils.updateSymbolColor(color, m_icon2Bitmap, m_originalSymbol2Bitmap);
				
				if (usingDegree){
					//m_DegreeLabel.x = 2;
					//m_DegreeLabel.y = m_iconBitmap.y + mn_iconsWidth;
					//m_DegreeLabel.width = measuredWidth - 4;
					
					//m_icon2Bitmap.x = int((measuredWidth - m_iconBitmap.width) / 2);
					//m_icon2Bitmap.y = m_DegreeLabel.y + m_DegreeLabel.height - 4;
					
					var nIcon2: String = 'severe_turbulence';
					
					if (nIcon2 != ms_actIcon2Loaded){
						ms_actIcon2Loaded = nIcon2;
						WFSIconLoader.getInstance().getIcon(nIcon2, this, onIcon2Loaded);
					}
					
					m_BaseLabel.y = m_icon2Bitmap.y + mn_iconsWidth - 4;
				} else {
					m_BaseLabel.y = m_iconBitmap.y + mn_iconsWidth - 4;
				}
				
				var nIcon: String = resolveIconName();
				
				if (nIcon != ms_actIconLoaded){
					ms_actIconLoaded = nIcon;
					WFSIconLoader.getInstance().getIcon(resolveIconName(), this, onIconLoaded);
					
				}
				
				updateLabelColor(m_BaseLabel, color);
				updateLabelColor(m_DegreeLabel, color);
				updateLabelColor(m_TopLabel, color);
			}
		}
		
		public override function measureContent(): void
		{
			m_TopLabel.width = m_TopLabel.textWidth;
			m_TopLabel.height = m_TopLabel.textHeight;
			
			m_BaseLabel.width = m_BaseLabel.textWidth;
			m_BaseLabel.height = m_BaseLabel.textHeight;
			
			m_DegreeLabel.width = m_DegreeLabel.textWidth;
			m_DegreeLabel.height = m_DegreeLabel.textHeight;
			
			if ((m_turbulenceFeature != null)
				&& ((m_turbulenceFeature.degree == 'Moderate ISOL Severe')
				|| (m_turbulenceFeature.degree == 'Moderate OCNL Severe')
				|| (m_turbulenceFeature.degree == 'Moderate FRQ Severe'))){
					// USING SPECIAL DEGREE
					
				measuredWidth = Math.max(m_TopLabel.textWidth + 4, m_BaseLabel.textWidth + 4, mn_iconsWidth + 4, m_DegreeLabel.textWidth + 4);
				measuredHeight = m_TopLabel.textHeight + mn_iconsWidth + m_DegreeLabel.textHeight + mn_iconsWidth + m_BaseLabel.textHeight;
			} else {
				measuredWidth = Math.max(m_TopLabel.textWidth + 4, m_BaseLabel.textWidth + 4, mn_iconsWidth + 4);
				measuredHeight = m_TopLabel.textHeight + 4 + m_BaseLabel.textHeight + 4 + mn_iconsWidth - 4;
			}
			 
			updateLabelColor(m_BaseLabel, color);
			updateLabelColor(m_DegreeLabel, color);
			updateLabelColor(m_TopLabel, color);
		}
		
		/**
		 * 
		 */
		protected function formatLevelString(levelValue: Number, zeroString: String = 'SFC'): String
		{
			var ret: String = (levelValue > 0) ? String(levelValue) : zeroString;
			
			while(ret.length < 3){
				ret = '0' + ret;
			}
			
			return(ret);
		}
		
		/**
		 * 
		 */
		internal function resolveIconName(): String
		{ 
			//var fDegree: String = m_turbulenceFeature.degree.toLowerCase(); 
			
			//var retIconName: String = 'icing_' + fDegree + '_' + fType;
			
			var retIconName: String = 'severe_turbulence';
			
			if (m_turbulenceFeature.degree == TYPE_MODERATE_IN_CLEAR_AIR){
				retIconName = 'moderate_turbulence';
			} else if (m_turbulenceFeature.degree == TYPE_SEVERE_IN_CLEAR_AIR){
				retIconName = 'severe_turbulence';
			} else if (m_turbulenceFeature.degree == TYPE_MODERATE_ISOL_SEVERE){
				retIconName = 'moderate_turbulence';
			} else if (m_turbulenceFeature.degree == TYPE_MODERATE_OCNL_SEVERE){
				retIconName = 'moderate_turbulence';
			} else if (m_turbulenceFeature.degree == TYPE_MODERATE_FRQ_SEVERE){
				retIconName = 'moderate_turbulence';
			}
			
			return( retIconName);
		}
		
		public function set turbulenceAreaData(val: WFSFeatureEditableTurbulenceArea): void
		{
			m_turbulenceFeature = val;
			
			updateContent();
		}
		
		public function get turbulenceAreaData(): WFSFeatureEditableTurbulenceArea
		{ return m_turbulenceFeature; }
	}
}