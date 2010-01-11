package com.iblsoft.flexiweather.ogc
{
	import mx.collections.ArrayCollection;
	
	public class WMSLayer extends WMSLayerBase
	{
		internal var mb_queryable: Boolean = false;
		internal var ma_dimensions: ArrayCollection = new ArrayCollection();
		internal var ma_styles: ArrayCollection = new ArrayCollection();

		public function WMSLayer(parent: WMSLayerGroup, xml: XML, wms: Namespace, version: Version)
		{
			super(parent, xml, wms, version);
			mb_queryable = int(xml.@queryable) != 0
			for each(var elemDim: XML in xml.wms::Dimension) {
				var dim: WMSDimension = new WMSDimension(elemDim, wms, version);
				// in WMS < 1.3.0, dimension values are inside of <Extent> element
				// having the same @name as the <Dimension> element
				if(version.isLessThan(1, 3, 0)) {
					for each(var elemExtent: XML in xml.wms::Extent) {
						if(elemExtent.@name == dim.name) {
							dim.loadExtent(elemExtent, wms, version);
							break;
						}
					}
				}
				ma_dimensions.addItem(dim);
			}
			for each(var elemStyle: XML in xml.wms::Style) {
				ma_styles.addItem({
					name: String(elemStyle.wms::Name),
					title: String(elemStyle.wms::Title)
				});
			}
		}
		
		override public function equals(other: WMSLayer): Boolean
		{
			if(!super.equals(other))
				return false;
			if(mb_queryable != other.mb_queryable)
				return false;
			if(ma_styles.length != other.ma_styles.length)
				return false;
			for(var i: int = 0; i < ma_styles.length; ++i) {
				if(ma_styles[i] != other.ma_styles[i])
					return false;
			}
			if(ma_dimensions.length != other.ma_dimensions.length)
				return false;
			for(i = 0; i < ma_dimensions.length; ++i) {
				if(!ma_dimensions[i].equals(other.ma_dimensions[i]))
					return false;
			}
			return true;
		}
		
		public function get queryable(): Boolean
		{ return mb_queryable;	}

		public function get dimensions(): ArrayCollection
		{ return ma_dimensions;	}

		public function get styles(): ArrayCollection
		{ return ma_styles;	}
	}
}