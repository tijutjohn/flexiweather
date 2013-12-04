package com.iblsoft.flexiweather.ogc.wfs
{
	import com.iblsoft.flexiweather.proj.Coord;
	import com.iblsoft.flexiweather.widgets.InteractiveWidget;
	import flash.display.Sprite;
	import flash.geom.Point;
	import mx.collections.ArrayCollection;
	import com.iblsoft.flexiweather.ogc.FeatureBase;

	public class WFSFeatureBase extends FeatureBase
	{
		public function WFSFeatureBase(s_namespace: String, s_typeName: String, s_featureId: String)
		{
			super(s_namespace, s_typeName, s_featureId);
		}
	}
}
