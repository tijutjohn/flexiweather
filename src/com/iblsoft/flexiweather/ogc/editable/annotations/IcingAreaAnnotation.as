package com.iblsoft.flexiweather.ogc.editable.annotations
{
	import com.iblsoft.flexiweather.net.loaders.UniURLLoader;
	import com.iblsoft.flexiweather.ogc.editable.features.curves.withAnnotation.WFSFeatureEditableIcingArea;
	import com.iblsoft.flexiweather.ogc.net.loaders.WFSIconLoader;
	import com.iblsoft.flexiweather.utils.AnnotationBox;
	import com.iblsoft.flexiweather.utils.ColorUtils;
	
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextFormat;

	public class IcingAreaAnnotation extends AnnotationBox
	{
		//private var m_label: TextField = new TextField();
		
		private var m_BaseLabel: TextField = new TextField();
		private var m_TopLabel: TextField = new TextField();
		
		private var m_icingFeature: WFSFeatureEditableIcingArea;
		
		private var mn_iconsWidth: Number = 24;
		
		private var m_loader: UniURLLoader = new UniURLLoader();
		
		private var ms_actIconLoaded: String = '';
		
		private var m_iconBitmap: Bitmap = new Bitmap();
		private var m_iconBitmapOrig: Bitmap;
		
		public function IcingAreaAnnotation()
		{
			super();
			
			var baseBitmapData: BitmapData = new BitmapData(24, 24, true, 0xFFFFFF);
			
			m_iconBitmap.bitmapData = baseBitmapData;
			
			//addChild(m_label);
			addChild(m_BaseLabel);
			addChild(m_iconBitmap);
			addChild(m_TopLabel);
			
			var nFormat: TextFormat = new TextFormat('_sans', 11);
			
			/*m_label.border = true;
			m_turbulenceLabel.border = true;
			m_turbulenceBaseLabel.border = true;
			m_icingLabel.border = true;
			m_icingBaseLabel.border = true;*/
			
			m_BaseLabel.defaultTextFormat = nFormat;
			m_TopLabel.defaultTextFormat = nFormat;
			
			m_BaseLabel.setTextFormat(nFormat);
			m_TopLabel.setTextFormat(nFormat);
			
			m_BaseLabel.multiline = true;
			m_TopLabel.multiline = true;
			
			m_BaseLabel.selectable = false;
			m_TopLabel.selectable = false;
			
			m_BaseLabel.autoSize = TextFieldAutoSize.CENTER;
			m_TopLabel.autoSize = TextFieldAutoSize.CENTER;
			
		}
		
		/**
		 * 
		 */
		public function onIconLoaded(mBitmap: Bitmap): void
		{
			if (mBitmap){
				m_iconBitmap.bitmapData = mBitmap.bitmapData.clone();
				m_iconBitmapOrig = new Bitmap(mBitmap.bitmapData.clone());
				updateContent();
			}
		}
		
		public override function updateContent(): void
		{
			super.updateContent();
			
			if (m_icingFeature){
				// FILL BASE DATA
				var base: String = formatLevelString(m_icingFeature.verticalExtentBase);
				var top: String = formatLevelString(m_icingFeature.verticalExtentTop);
				
				//if ((m_icingFeature.verticalExtentBase > 0) || (m_icingFeature.verticalExtentTop > 0)){
					m_TopLabel.htmlText = '<P align="center">' + top + '</P>';
					m_BaseLabel.htmlText = '<P align="center">' + base + '</P>';
				//}
			}
			
			m_TopLabel.x = 2;
			m_TopLabel.y = 2;
			m_TopLabel.width = measuredWidth - 4;
			//m_TopLabel.height = measuredHeight - 4;
			
			m_iconBitmap.x = int((measuredWidth - m_iconBitmap.width) / 2);
			m_iconBitmap.y = m_TopLabel.y + m_TopLabel.height;
			
			m_BaseLabel.x = 2;
			m_BaseLabel.y = m_TopLabel.y + m_TopLabel.height + mn_iconsWidth;
			m_BaseLabel.width = measuredWidth - 4;
			//m_BaseLabel.height = measuredHeight - 4;
			
			var nIcon: String = resolveIconName();
			
			if (nIcon != ms_actIconLoaded){
				ms_actIconLoaded = nIcon;
				WFSIconLoader.getInstance().getIcon(resolveIconName(), this, onIconLoaded);
				
			}
			if (m_iconBitmap)
				ColorUtils.updateSymbolColor(color, m_iconBitmap, m_iconBitmapOrig);
			
			updateLabelColor(m_BaseLabel, color);
			updateLabelColor(m_TopLabel, color);
		}
		
		public override function measureContent(): void
		{
			m_TopLabel.width = m_TopLabel.textWidth;
			m_TopLabel.height = m_TopLabel.textHeight;
			
			m_BaseLabel.width = m_BaseLabel.textWidth;
			m_BaseLabel.height = m_BaseLabel.textHeight;
			
			measuredWidth = Math.max(m_TopLabel.textWidth + 4, m_BaseLabel.textWidth + 4, m_iconBitmap.width + 4); 
			measuredHeight = m_TopLabel.textHeight + 4 + m_BaseLabel.textHeight + 4 + mn_iconsWidth;
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
		protected function resolveIconName(): String
		{
			var fType: String = m_icingFeature.type.toLowerCase(); 
			var fDegree: String = m_icingFeature.degree.toLowerCase(); 
			
			var retIconName: String = 'icing_' + fDegree + '_' + fType;
			
			return( retIconName);
		}
		
		public function set icingAreaData(val: WFSFeatureEditableIcingArea): void
		{
			m_icingFeature = val;
			
			updateContent();
		}
		
		public function get icingAreaData(): WFSFeatureEditableIcingArea
		{ return m_icingFeature; }
	}
}