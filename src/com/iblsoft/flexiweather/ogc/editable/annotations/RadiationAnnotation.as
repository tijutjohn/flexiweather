package com.iblsoft.flexiweather.ogc.editable.annotations
{
	import com.iblsoft.flexiweather.ogc.editable.features.WFSFeatureEditableRadiation;
	import com.iblsoft.flexiweather.ogc.net.loaders.WFSIconLoader;
	import com.iblsoft.flexiweather.proj.Coord;
	import com.iblsoft.flexiweather.utils.AnnotationBox;
	import com.iblsoft.flexiweather.utils.ColorUtils;
	
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.geom.ColorTransform;
	import flash.geom.Rectangle;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextFormat;

	public class RadiationAnnotation extends AnnotationBox
	{
		public static const TYPE_REACTOR_ON_GROUND: String = 'ReactorOnGround';
		public static const TYPE_REACTOR_AT_SEA: String = 'ReactorAtSea';
		public static const TYPE_REACTOR_IN_SPACE: String = 'ReactorInSpace';
		public static const TYPE_NUCLEAR_FUEL: String = 'NuclearFuel';
		public static const TYPE_RADIOACTIVE_WASTE: String = 'RadioactiveWaste';
		public static const TYPE_TRANSPORT_OF_FUEL: String = 'TransportOfFuel';
		public static const TYPE_STORAGE_OF_FUEL: String = 'StorageOfFuel';
		public static const TYPE_MANUFACTURE_OF_RADIO_ISOTOPES: String = 'ManufactureOfRadioIsotopes';
		public static const TYPE_USE_OF_RADIO_ISOTOPES: String = 'Use OfRadioIsotopes';
		public static const TYPE_STORAGE_OF_RADIO_ISOTOPES: String = 'StorageOfRadioIsotopes';
		public static const TYPE_DISPOSAL_OF_RADIO_ISOTOPES: String = 'DisposalOfRadioIsotopes';
		public static const TYPE_TRANSPORT_OF_RADIO_ISOTOPES: String = 'TransportOfRadioIsotopes';
		public static const TYPE_USE_OF_RADIO_ISOTOPES_FOR_POWER: String = 'UseOfRadioIsotopesForPower';
		public static const TYPE_MISSING_VALUE: String = 'MissingValue';
		
		public static const NAME_REACTOR_ON_GROUND: String = 'Reactor on ground';
		public static const NAME_REACTOR_AT_SEA: String = 'Reactor at sea';
		public static const NAME_REACTOR_IN_SPACE: String = 'Reactor in space';
		public static const NAME_NUCLEAR_FUEL: String = 'Nuclear fuel';
		public static const NAME_RADIOACTIVE_WASTE: String = 'Radioactive waste';
		public static const NAME_TRANSPORT_OF_FUEL: String = 'Transport of fuel';
		public static const NAME_STORAGE_OF_FUEL: String = 'Storage of fuel';
		public static const NAME_MANUFACTURE_OF_RADIO_ISOTOPES: String = 'Manufacture of radio isotopes';
		public static const NAME_USE_OF_RADIO_ISOTOPES: String = 'Use of radio isotopes';
		public static const NAME_STORAGE_OF_RADIO_ISOTOPES: String = 'Storage of radio isotopes';
		public static const NAME_DISPOSAL_OF_RADIO_ISOTOPES: String = 'Disposal of radio isotopes';
		public static const NAME_TRANSPORT_OF_RADIO_ISOTOPES: String = 'Transport of radio isotopes';
		public static const NAME_USE_OF_RADIO_ISOTOPES_FOR_POWER: String = 'Use of radio isotopes for power';
		public static const NAME_MISSING_VALUE: String = 'Missing value';
		
		private var m_TopLabel: TextField = new TextField();
		private var m_BaseLabel: TextField = new TextField();
		
		private var m_radiationFeature: WFSFeatureEditableRadiation;
		
		private var mn_iconsWidth: Number = 24;
		
		private var ms_actIconLoaded: String = '';
		
		private var m_iconBitmap: Bitmap = new Bitmap();
		private var m_iconBitmapOrig: Bitmap;
		
		override public function set visible(value:Boolean):void
		{
			if (super.visible != value)
			{
				super.visible = value;
				trace("RadiationAnnotation visible: " + value);
				if (!value)
				{
					trace("Hide RadiationAnnotation");
				} else {
					trace("Show RadiationAnnotation");
				}
			} 
		}
		
		public function RadiationAnnotation(color: uint)
		{
			super();
			
			var baseBitmapData: BitmapData = new BitmapData(mn_iconsWidth, mn_iconsWidth, true, 0xFFFFFF);
			
			m_iconBitmap.bitmapData = baseBitmapData;
			
			addChild(m_BaseLabel);
			addChild(m_iconBitmap);
			addChild(m_TopLabel);
			
			var nFormat: TextFormat = new TextFormat('_sans', 11);
			nFormat.color = color;
			
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
				var nBitmapData: BitmapData = mBitmap.bitmapData.clone();
//				var cTransform: ColorTransform = new ColorTransform(1, 1, 1, 1, 255, 0, 0, 0);
//				nBitmapData.colorTransform(new Rectangle(0, 0, nBitmapData.width, nBitmapData.height), cTransform); 
				
				m_iconBitmap.bitmapData = nBitmapData; //mBitmap.bitmapData.clone();
				m_iconBitmapOrig = new Bitmap(mBitmap.bitmapData.clone());
				m_iconBitmap.x = 2;
				m_iconBitmap.y = 2;
				
				updateContent();
			
			}
		}
		
		public override function updateContent(): void
		{
			super.updateContent();
			
			if (m_radiationFeature){
				
				var coord: Coord;
				if (m_radiationFeature.coordinates && m_radiationFeature.coordinates.length > 0)
				{
					coord = m_radiationFeature.coordinates[0];
					m_BaseLabel.htmlText = '<P align="center">' + coord.toLaLoCoord().toNiceString() + '</P>';
				}

				m_TopLabel.htmlText = '<P align="center">' + m_radiationFeature.label + '</P>';
				
			}
			
			m_TopLabel.x = 2;
			m_TopLabel.y = 2;
			m_TopLabel.width = measuredWidth - 4;
			
			m_iconBitmap.x = int((measuredWidth - m_iconBitmap.width) / 2);
			m_iconBitmap.y = m_TopLabel.y + m_TopLabel.height;
			
			m_BaseLabel.x = 2;
			m_BaseLabel.y = m_TopLabel.y + m_TopLabel.height + mn_iconsWidth;
			m_BaseLabel.width = measuredWidth - 4;
			//m_BaseLabel.height = measuredHeight - 4;
			
			var nIcon: String = 'radioactive_materials';
		
			// http://wms.iblsoft.com/ria/helpers/gpaint-macro/render/SIGWX/tropical_storm?width=24&height=24
			if (nIcon != ms_actIconLoaded){
				ms_actIconLoaded = nIcon;
				WFSIconLoader.getInstance().getIcon(nIcon, this, onIconLoaded, 'SIGWX');
				
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
		private function resolveIconName(): String
		{
			var retIconName: String = 'radioactive_materials';
			
			return(retIconName);
		}
		
		public function set radiationData(val: WFSFeatureEditableRadiation): void
		{
			m_radiationFeature = val;
			
			updateContent();
		}
		
		public function get radiationData(): WFSFeatureEditableRadiation
		{ return m_radiationFeature; }
		
	}
}