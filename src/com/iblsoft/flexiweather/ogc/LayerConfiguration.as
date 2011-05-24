package com.iblsoft.flexiweather.ogc
{
	import com.iblsoft.flexiweather.utils.Serializable;
	import com.iblsoft.flexiweather.utils.Storage;
	import com.iblsoft.flexiweather.widgets.InteractiveLayer;
	import com.iblsoft.flexiweather.widgets.InteractiveWidget;
	
	import flash.events.Event;
	import flash.events.EventDispatcher;
	
	public class LayerConfiguration extends EventDispatcher implements Serializable
	{
		protected var ms_label: String;
		protected var ms_previewURL: String = null;
		
		public function LayerConfiguration()
		{
		}

		public function serialize(storage: Storage): void
		{
			ms_label = storage.serializeString("label", ms_label);
		}
		
		[Bindable (event="labelChanged")]
		public function get label(): String
		{ return ms_label; }

		public function set label(s: String): void
		{ 
			ms_label = s;
			dispatchEvent(new Event('labelChanged')); 
		}
		
		public function createInteractiveLayer(iw: InteractiveWidget): InteractiveLayer
		{
			return null;
		}
		
		public function isCompatibleWithCRS(crs: String): Boolean
		{
			return false;
		}
		
		public function hasPreview(): Boolean
        { return false; }
        
		public function getPreviewURL(): String
		{
			return '';
		}
		public function renderPreview(f_width: Number, f_height: Number, iw: InteractiveWidget =  null): void
		{
			
		}
		
		public function set previewURL(s: String): void
		{ ms_previewURL = s; }

		public function get previewURL(): String
		{ 
			if (ms_previewURL)
				return ms_previewURL;
				
			return getPreviewURL();
		}
	}
}