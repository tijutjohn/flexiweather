package com.iblsoft.flexiweather.ogc.editable.features.curves
{
	import com.iblsoft.flexiweather.ogc.editable.data.jetstream.WindBarb;
	
	import flash.events.IEventDispatcher;

	public interface IJetStreamEditorGUI extends IEventDispatcher
	{
		function updateJetStreamWindBard(windBard: WindBarb): void;	
	}
}