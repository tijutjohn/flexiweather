package com.iblsoft.flexiweather.ogc.editable.annotations
{
	import com.iblsoft.flexiweather.ogc.editable.features.WFSFeatureEditableStorm;
	import com.iblsoft.flexiweather.utils.AnnotationBox;
	
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.geom.ColorTransform;
	import flash.geom.Rectangle;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextFormat;

	public class StormAnnotation extends AnnotationBox
	{
		public static const NAME_DEPRESSION: String = 'Depression';
		public static const NAME_TROPIC_DEPRESSION: String = 'Tropical depression';
		public static const NAME_TROPIC_STORM: String = 'Tropical storm';
		public static const NAME_SEVERE_STORM: String = 'Severe tropical storm';
		public static const NAME_TYPHOON: String = 'Typhoon';
		public static const NAME_DUST_SAND_STORM: String = 'Dust/Sand Storm';
		
		public static const TYPE_DEPRESSION: String = 'Depression';
		public static const TYPE_TROPIC_DEPRESSION: String = 'TropicalDepression';
		public static const TYPE_TROPIC_STORM: String = 'TropicalStorm';
		public static const TYPE_SEVERE_STORM: String = 'SevereTropicalStorm';
		public static const TYPE_TYPHOON: String = 'Typhoon';
		public static const TYPE_DUST_SAND_STORM: String = 'DustSandStorm';
		
		public static const INTENSITY_UNKNOWN: String = 'Unknown';
		public static const INTENSITY_NO_CHANGE: String = 'No change';
		public static const INTENSITY_WEAKENING: String = 'Weakening';
		public static const INTENSITY_INTENSIFYING: String = 'Intensifying';
		
		public static const UNIT_MM: String = 'mm';
		public static const UNIT_CM: String = 'cm';
		public static const UNIT_M: String = 'm';
		public static const UNIT_KM: String = 'km';
		public static const UNIT_IN: String = 'in';
		public static const UNIT_ML: String = 'ml';
		public static const UNIT_FL: String = 'FL';
		public static const UNIT_AT: String = 'AT';
		public static const UNIT_GPM: String = 'gpm';
		public static const UNIT_NM_US: String = 'NM(US)';
		public static const UNIT_NM_UK: String = 'NM(UK)';
		public static const UNIT_ML_STATUTE: String = 'ml statute';
		public static const UNIT_DM: String = 'dm';
		public static const UNIT_DKM: String = 'dkm';
		public static const UNIT_M2_S2: String = 'm2/s2';
		
		private var m_TextLabel: TextField = new TextField();
		
		private var m_stormFeature: WFSFeatureEditableStorm;
		
		override public function set visible(value:Boolean):void
		{
			if (super.visible != value)
			{
				super.visible = value;
				trace("StormAnnotation visible: " + value);
				if (!value)
				{
					trace("Hide StormAnnotation");
				} else {
					trace("Show StormAnnotation");
				}
			} 
		}
		
		public function StormAnnotation(color: uint)
		{
			super();
			
			addChild(m_TextLabel);
			
			var nFormat: TextFormat = new TextFormat('_sans', 11);
			nFormat.color = color;
			
			m_TextLabel.defaultTextFormat = nFormat;
			m_TextLabel.setTextFormat(nFormat);
			m_TextLabel.multiline = true;
			m_TextLabel.selectable = false;
			m_TextLabel.autoSize = TextFieldAutoSize.CENTER;
		}
		
		
		protected function formatLevelString(levelValue: Number, zeroString: String = 'SFC'): String
		{
			var ret: String = (levelValue > 0) ? String(levelValue) : zeroString;
			
			while(ret.length < 3){
				ret = '0' + ret;
			}
			
			return(ret);
		}
		
		public override function updateContent(): void
		{
			super.updateContent();
			
			if (m_stormFeature.label == null)
			{
				visible = false;
			}
			
			if (m_stormFeature){
				// FILL BASE DATA
//				m_TextLabel.htmlText = '<P align="center">' + m_stormFeature.label + ' MAX WIND ' + m_stormFeature.speed + 'kt ' + m_stormFeature.pressure + 'hPa' + '</P>';
				m_TextLabel.htmlText = '<P align="center">' + m_stormFeature.label + '</P>';
			}
			
			m_TextLabel.x = 2;
			m_TextLabel.y = 2;
			m_TextLabel.width = measuredWidth - 4;
			//m_TextLabel.height = measuredHeight - 4;
			
			updateLabelColor(m_TextLabel, color);
		}
		
		public override function measureContent(): void
		{
			m_TextLabel.width = m_TextLabel.textWidth;
			m_TextLabel.height = m_TextLabel.textHeight;
			
			measuredWidth = m_TextLabel.textWidth + 4;
			measuredHeight = m_TextLabel.textHeight + 4;
		}
		
		
		
		
		public function set stormData(val: WFSFeatureEditableStorm): void
		{
			m_stormFeature = val;
			
			updateContent();
		}
		
		public function get stormData(): WFSFeatureEditableStorm
		{ return m_stormFeature; }
		
	}
}