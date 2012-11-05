package com.iblsoft.flexiweather.ogc.editable.features
{
	import com.iblsoft.flexiweather.ogc.editable.WFSFeatureEditable;

	public class GenericEditableFeature extends WFSFeatureEditable
	{
		public function GenericEditableFeature(s_namespace: String, s_typeName: String, s_featureId: String)
		{
			super(s_namespace, s_typeName, s_featureId);
		}
	}
}
