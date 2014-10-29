package com.iblsoft.flexiweather.ogc.editable.annotations
{
	import com.iblsoft.flexiweather.ogc.editable.features.curves.withAnnotation.WFSFeatureEditableCloud;
	import com.iblsoft.flexiweather.ogc.net.loaders.WFSIconLoader;
	import com.iblsoft.flexiweather.utils.AnnotationBox;
	import com.iblsoft.flexiweather.utils.ColorUtils;

	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextFormat;

	public class CloudAnnotation extends AnnotationBox
	{
		//Turbulence Degree constants
		public static const NAME_CLOUD_MODERATE: String = 'Moderate in cloud';
		public static const NAME_CLOUD_SEVERE: String = 'Severe in cloud';

		public static const TYPE_CLOUD_MODERATE: String = 'CloudModerate';
		public static const TYPE_CLOUD_SEVERE: String = 'CloudSevere';

		//Icing Degree constants
		public static const NAME_MODERATE_CLOUD: String = 'Moderate (cloud)';
		public static const NAME_SEVERE_CLOUD: String = 'Severe (cloud)';

		public static const TYPE_MODERATE_CLOUD: String = 'ModerateCloud';
		public static const TYPE_SEVERE_CLOUD: String = 'SevereCloud';

		private var m_label: TextField = new TextField();
		private var m_turbulenceLabel: TextField = new TextField();
		private var m_turbulenceBaseLabel: TextField = new TextField();
		private var m_icingLabel: TextField = new TextField();
		private var m_icingBaseLabel: TextField = new TextField();

		private var m_cloudData: WFSFeatureEditableCloud;

		private var m_iconTurbulenceBitmap: Bitmap = new Bitmap();
		private var m_iconIcingBitmap: Bitmap = new Bitmap();

		private var m_iconTurbulenceBitmapOrig: Bitmap;
		private var m_iconIcingBitmapOrig: Bitmap;

		private var m_actTurbulenceIconName: String = '';
		private var m_actIcingIconName: String = '';

		override public function set visible(value:Boolean):void
		{
			if (super.visible != value)
			{
				super.visible = value;
				trace("CloudAnnotation visible: " + value);
				if (!value)
				{
					trace("Hide CloudAnnotation");
				} else {
					trace("Show CloudAnnotation");
				}
			}
		}

		public function CloudAnnotation()
		{
			super();

			var baseBitmapData: BitmapData = new BitmapData(24, 24, true, 0xFFFFFF);

			m_iconIcingBitmap.bitmapData = baseBitmapData;
			m_iconTurbulenceBitmap.bitmapData = baseBitmapData;

			addChild(m_label);

			addChild(m_turbulenceLabel);
			addChild(m_iconTurbulenceBitmap);
			//addChild(m_turbulenceBaseLabel);

			addChild(m_icingLabel);
			addChild(m_iconIcingBitmap);
			//addChild(m_icingBaseLabel);

			var nFormat: TextFormat = new TextFormat('_sans', 11);

			/*m_label.border = true;
			m_turbulenceLabel.border = true;
			m_turbulenceBaseLabel.border = true;
			m_icingLabel.border = true;
			m_icingBaseLabel.border = true;*/

			m_label.defaultTextFormat = nFormat;
			m_turbulenceLabel.defaultTextFormat = nFormat;
			//m_turbulenceBaseLabel.defaultTextFormat = nFormat;
			m_icingLabel.defaultTextFormat = nFormat;
			//m_icingBaseLabel.defaultTextFormat = nFormat;

			m_label.setTextFormat(nFormat);
			m_turbulenceLabel.setTextFormat(nFormat);
			//m_turbulenceBaseLabel.setTextFormat(nFormat);
			m_icingLabel.setTextFormat(nFormat);
			//m_icingBaseLabel.setTextFormat(nFormat);

			m_label.multiline = true;
			m_turbulenceLabel.multiline = true;
			//m_turbulenceBaseLabel.multiline = true;
			m_icingLabel.multiline = true;
			//m_icingBaseLabel.multiline = true;

			m_label.selectable = false;
			m_turbulenceLabel.selectable = false;
			//m_turbulenceBaseLabel.selectable = false;
			m_icingLabel.selectable = false;
			//m_icingBaseLabel.selectable = false;

			m_label.autoSize = TextFieldAutoSize.CENTER;
			m_turbulenceLabel.autoSize = TextFieldAutoSize.CENTER;
			//m_turbulenceBaseLabel.autoSize = TextFieldAutoSize.CENTER;
			m_icingLabel.autoSize = TextFieldAutoSize.CENTER;
			//m_icingBaseLabel.autoSize = TextFieldAutoSize.CENTER;
		}

		public override function updateContent(): void
		{
			super.updateContent();

			var isCB: Boolean = true;
			var isDUC: Boolean = true;

			if (m_cloudData){
				// FILL BASE DATA
				var base: String = formatLevelString(m_cloudData.verticalExtentBase, 'SFC');
				var top: String = formatLevelString(m_cloudData.verticalExtentTop);

				isCB = (m_cloudData.type.toLowerCase() == 'cb') ? true : false;
				isDUC = (m_cloudData.type.toLowerCase() == 'duc') ? true : false;

				var distribution: String =  m_cloudData.distribution;
				var type: String =  m_cloudData.type;

				if (distribution.toLowerCase() == 'no distribution')
				{
					distribution = '';
				}
				if (type.toLowerCase() == 'no type')
				{
					type = '';
				}
				var mData: String = '<P align="center">';
				if (distribution.length > 0)
				{
				 	mData += distribution + '\n';
				}

				if (type.length > 0)
				{
					mData += type;
				}


				if (isCB || isDUC)
				{ // Add base and top parameters ONLY for CB and DUC cloud types
					//if ((m_cloudData.verticalExtentBase > 0) || (m_cloudData.verticalExtentTop > 0)){
						mData += '\n' + top;
						mData += '\n' + base;
					//}
				}

				mData += '</P>';

				if (distribution.length == 0 && type.length == 0)
				{
					m_label.htmlText = '';
				} else {
					m_label.htmlText = mData;
				}

				// Use turbulence and icing ONLY on types not equal to CB type
				if (!isCB){
					// FILL TURBULENCE IF NEEDED
					if (m_cloudData.useTurbulence){
						m_turbulenceLabel.htmlText = '<P align="center">' + formatLevelString(m_cloudData.turbulenceTop, 'SFC') + '\n' + formatLevelString(m_cloudData.turbulenceBase, 'SFC') + '</P>';

						var turbulenceIconName: String = '';

						if (m_cloudData.turbulenceDegree == 'Moderate in cloud'){
							//m_turbulenceBaseLabel.htmlText = '<P align="center">TURB (MOD)</P>';
							turbulenceIconName = 'moderate_turbulence';
						} else {
							//m_turbulenceBaseLabel.htmlText = '<P align="center">TURB (SVR)</P>';
							turbulenceIconName = 'severe_turbulence';
						}

						if (m_actTurbulenceIconName != turbulenceIconName){
							m_actTurbulenceIconName = turbulenceIconName;
							WFSIconLoader.getInstance().getIcon(turbulenceIconName, this, onTurbulenceIconLoaded);
						}

						//m_turbulenceBaseLabel.visible = true;
						m_turbulenceLabel.visible = true;

						m_iconTurbulenceBitmap.visible = true;
					} else {
						m_turbulenceLabel.htmlText = '';
						//m_turbulenceBaseLabel.htmlText = '';
						//m_turbulenceBaseLabel.visible = false;
						m_turbulenceLabel.visible = false;

						m_iconTurbulenceBitmap.visible = false;
					}

					// FILL ICING IF NEEDED
					if (m_cloudData.useIcing){
						m_icingLabel.htmlText = '<P align="center">' + formatLevelString(m_cloudData.icingTop, 'SFC') + '\n' + formatLevelString(m_cloudData.icingBase, 'SFC') + '</P>';

						var icingIconName: String = '';

						if (m_cloudData.icingDegree == 'Moderate (cloud)'){
							//m_icingBaseLabel.htmlText = '<P align="center">IC (MOD)</P>';
							icingIconName = 'moderate_aircraft_icing';
						} else {
							//m_icingBaseLabel.htmlText = '<P align="center">IC (SVR)</P>';
							icingIconName = 'severe_aircraft_icing';
						}

						if (m_actIcingIconName != icingIconName){
							m_actIcingIconName = icingIconName;
							WFSIconLoader.getInstance().getIcon(icingIconName, this, onIcingIconLoaded);
						}

						//m_icingBaseLabel.visible = true;
						m_icingLabel.visible = true;

						m_iconIcingBitmap.visible = true;
					} else {
						m_icingLabel.htmlText = '';
						//m_icingBaseLabel.htmlText = '';
						//m_icingBaseLabel.visible = false;
						m_icingLabel.visible = false;

						m_iconIcingBitmap.visible = false;
					}
				} else { // Do not show icing and turbulence for CB type clouds
					m_turbulenceLabel.htmlText = '';
					//m_turbulenceBaseLabel.htmlText = '';
					//m_turbulenceBaseLabel.visible = false;
					m_turbulenceLabel.visible = false;

					m_iconTurbulenceBitmap.visible = false;

					m_icingLabel.htmlText = '';
					//m_icingBaseLabel.htmlText = '';
					//m_icingBaseLabel.visible = false;
					m_icingLabel.visible = false;

					m_iconIcingBitmap.visible = false;
				}
			}



			m_label.x = 2;
			m_label.y = 2;
			m_label.width = measuredWidth - 4;
			m_label.height = measuredHeight - 4;

			var nextY: Number = 2 + m_label.height;

			if (m_cloudData.useTurbulence && !isCB){
				m_turbulenceLabel.width = m_turbulenceLabel.textWidth;
				m_turbulenceLabel.height = m_turbulenceLabel.textHeight;

				var turbMaxHeight: Number = Math.max(m_turbulenceLabel.height, m_iconTurbulenceBitmap.height);

				m_turbulenceLabel.x = measuredWidth - 2 - m_turbulenceLabel.width;
				m_turbulenceLabel.y = nextY + int((turbMaxHeight - m_turbulenceLabel.height) / 2);

				//m_turbulenceBaseLabel.x = 2;
				//m_turbulenceBaseLabel.y = m_turbulenceLabel.y + ((m_turbulenceLabel.height - m_turbulenceBaseLabel.height) / 2);

				m_iconTurbulenceBitmap.x = int((m_turbulenceLabel.x - m_iconTurbulenceBitmap.width) / 2);
				m_iconTurbulenceBitmap.y = nextY + int((turbMaxHeight - m_iconTurbulenceBitmap.height) / 2);

				nextY += turbMaxHeight;
			} else {
				m_turbulenceLabel.x = 0;
				m_turbulenceLabel.y = 0;

				//m_turbulenceBaseLabel.x = 0;
				//m_turbulenceBaseLabel.y = 0;

				m_iconTurbulenceBitmap.x = 0;
				m_iconTurbulenceBitmap.y = 0;
			}

			if (m_cloudData.useIcing && !isCB){
				m_icingLabel.width = m_icingLabel.textWidth;
				m_icingLabel.height = m_icingLabel.textHeight;

				var icingMaxHeight: Number = Math.max(m_icingLabel.height, m_iconIcingBitmap.height);

				m_icingLabel.x = measuredWidth - 2 - m_icingLabel.width;
				m_icingLabel.y = nextY + int((icingMaxHeight - m_icingLabel.height) / 2);

				//m_icingBaseLabel.x = 2;
				//m_icingBaseLabel.y = m_icingLabel.y + ((m_icingLabel.height - m_icingBaseLabel.height) / 2);

				m_iconIcingBitmap.x = int((m_icingLabel.x - m_iconIcingBitmap.width) / 2);
				m_iconIcingBitmap.y = nextY + int((icingMaxHeight - m_iconIcingBitmap.height) / 2);
			} else {
				m_icingLabel.x = 0;
				m_icingLabel.y = 0;

				//m_icingBaseLabel.x = 0;
				//m_icingBaseLabel.y = 0;

				m_iconIcingBitmap.x = 0;
				m_iconIcingBitmap.y = 0;
			}

			if (m_iconIcingBitmap)
				ColorUtils.updateSymbolColor(color, m_iconIcingBitmap, m_iconIcingBitmapOrig);
			if (m_iconTurbulenceBitmap)
				ColorUtils.updateSymbolColor(color, m_iconTurbulenceBitmap, m_iconTurbulenceBitmapOrig);

			updateLabelColor(m_label, color);
			updateLabelColor(m_icingBaseLabel, color);
			updateLabelColor(m_icingLabel, color);
			updateLabelColor(m_turbulenceBaseLabel, color);
			updateLabelColor(m_turbulenceLabel, color);
		}

		public override function measureContent(): void
		{
			var isCB: Boolean = true;

			if (m_cloudData){
				isCB = (m_cloudData.type.toLowerCase() == 'cb') ? true : false;
			}


			m_label.width = m_label.textWidth;
			m_label.height = m_label.textHeight;

			m_turbulenceLabel.width = m_turbulenceLabel.textWidth;
			m_turbulenceLabel.height = m_turbulenceLabel.textHeight;
			//m_turbulenceBaseLabel.width = m_turbulenceBaseLabel.textWidth;
			//m_turbulenceBaseLabel.height = m_turbulenceBaseLabel.textHeight;

			m_icingLabel.width = m_icingLabel.textWidth;
			m_icingLabel.height = m_icingLabel.textHeight;
			//m_icingBaseLabel.width = m_icingBaseLabel.textWidth;
			//m_icingBaseLabel.height = m_icingBaseLabel.textHeight;

			measuredWidth = Math.max(m_label.textWidth + 4,
					//(m_cloudData.useTurbulence && !isCB) ? (m_turbulenceBaseLabel.width + m_turbulenceLabel.width + 4) : 0,
					(m_cloudData.useTurbulence && !isCB) ? (m_turbulenceLabel.width + 4 + m_iconTurbulenceBitmap.width + 4) : 0,
					//(m_cloudData.useIcing && !isCB) ? (m_icingBaseLabel.width + m_icingLabel.width + 4) : 0);
					(m_cloudData.useIcing && !isCB) ? (m_icingLabel.width + 4 + m_iconIcingBitmap.width + 4) : 0);

			var nHeight: Number = m_label.textHeight + 4;
			if (m_cloudData.useTurbulence && !isCB){
				nHeight += Math.max(m_turbulenceLabel.textHeight + 4, m_iconTurbulenceBitmap.height);
			}
			if (m_cloudData.useIcing && !isCB){
				nHeight += Math.max(m_icingLabel.textHeight + 4, m_iconIcingBitmap.height);
			}

			measuredHeight = nHeight;
		}

		/**
		 *
		 */
		public function onTurbulenceIconLoaded(nBitmap: Bitmap): void
		{
			if (nBitmap){
				m_iconTurbulenceBitmap.bitmapData = nBitmap.bitmapData.clone();
				m_iconTurbulenceBitmapOrig = new Bitmap(nBitmap.bitmapData.clone());
				updateContent();
			}

		}

		/**
		 *
		 */
		public function onIcingIconLoaded(nBitmap: Bitmap): void
		{
			if (nBitmap){
				m_iconIcingBitmap.bitmapData = nBitmap.bitmapData.clone();
				m_iconIcingBitmapOrig = new Bitmap(nBitmap.bitmapData.clone());
				updateContent();
			}

			//m_cloudData.update();
		}

		/**
		 *
		 */
		protected function formatLevelString(levelValue: Number, zeroString: String = 'XXX'): String
		{
			var ret: String = (levelValue > 0) ? String(levelValue) : zeroString;

			while(ret.length < 3){
				ret = '0' + ret;
			}

			return(ret);
		}

		public function get label(): TextField
		{ return m_label; }

		public function set cloudData(val: WFSFeatureEditableCloud): void
		{
			m_cloudData = val;

			updateContent();
		}

		public function get cloudData(): WFSFeatureEditableCloud
		{ return m_cloudData; }
	}
}