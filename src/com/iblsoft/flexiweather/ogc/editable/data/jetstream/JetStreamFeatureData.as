package com.iblsoft.flexiweather.ogc.editable.data.jetstream
{
	import com.iblsoft.flexiweather.ogc.editable.data.FeatureData;
	import com.iblsoft.flexiweather.ogc.editable.data.FeatureDataReflection;
	
	public class JetStreamFeatureData extends FeatureData
	{
		public function JetStreamFeatureData(name:String)
		{
			super(name);
		}
		
		override protected function createFeatureDataReflectionInstance(position: int): FeatureDataReflection
		{
			return new JetStreamFeatureDataReflection(position);
		}
	}
}