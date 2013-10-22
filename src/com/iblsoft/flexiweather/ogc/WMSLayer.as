package com.iblsoft.flexiweather.ogc
{
	import com.iblsoft.flexiweather.ogc.configuration.services.WMSServiceParsingManager;

	public class WMSLayer extends WMSLayerBase
	{
		private var mb_queryable: Boolean = false;
		private var ma_styles: Array;

		public function WMSLayer(parent: WMSLayerGroup, xml: XML, wms: Namespace, version: Version)
		{
			super(parent, xml, wms, version);
			mb_queryable = int(xml.@queryable) != 0;
		}
		
		override public function initialize(parsingManager: WMSServiceParsingManager = null): void
		{
			super.initialize(parsingManager);
			
			ma_styles =  new Array();
			var styleObject: Object;
			for each (var elemStyle: XML in m_itemXML.wms::Style)
			{
				styleObject = {
							name: String(elemStyle.wms::Name),
							title: String(elemStyle.wms::Title)
						};
				var legendXML: XML = elemStyle.wms::LegendURL[0] as XML;
				if (legendXML is XML)
				{
					var xlink: Namespace = new Namespace('http://www.w3.org/1999/xlink');
					var legendObj: Object = {url: String(legendXML.wms::OnlineResource.@xlink::href), width: Number(legendXML.@width), height: Number(legendXML.@height)};
					styleObject.legend = legendObj;
				}
				ma_styles.push(styleObject);
			}
		}

		override public function destroy(): void
		{
			super.destroy();
			if (ma_styles)
			{
				removeAllArrayItems(ma_styles);
			}
			ma_styles = null;
		}

		override public function equals(other: WMSLayer): Boolean
		{
			if (!super.equals(other))
				return false;
			if (mb_queryable != other.mb_queryable)
				return false;
			if (ma_styles.length != other.ma_styles.length)
				return false;
			for (var i: int = 0; i < ma_styles.length; ++i)
			{
				if (ma_styles[i] != other.ma_styles[i])
					return false;
			}
			return true;
		}

		public function isTileableForCRS(s_crs: String): Boolean
		{
			for each (var crsWithBBox: CRSWithBBox in crsWithBBoxes)
			{
				if (crsWithBBox.crs == s_crs)
					return crsWithBBox is CRSWithBBoxAndTilingInfo;
			}
			return false;
		}

		public function isCompatibleWithCRS(crs: String): Boolean
		{
			for each (var crsWithBBox: CRSWithBBox in crsWithBBoxes)
			{
				if (crsWithBBox.crs == crs)
					return true;
			}
			return false;
		}

		public function get queryable(): Boolean
		{
			return mb_queryable;
		}

		public function get styles(): Array
		{
			return ma_styles;
		}
	}
}
