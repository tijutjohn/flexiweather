package com.iblsoft.flexiweather.ogc.multiview.data
{
	import com.iblsoft.flexiweather.ogc.data.GlobalVariableValue;
	import com.iblsoft.flexiweather.utils.Serializable;
	import com.iblsoft.flexiweather.utils.Storage;
	
	public class MultiViewDataProviderItem implements Serializable
	{
		public var enabled: Boolean;
		public var label: String;
		public var level: GlobalVariableValue;
		public var run: GlobalVariableValue;
		public var fullPath: String;
		public var name: String;
		
		public function MultiViewDataProviderItem()
		{
		}
		
		public function serialize(storage:Storage):void
		{
			label = storage.serializeString('label', label);
			enabled = storage.serializeBool('enabled', enabled);
			if (storage.isStoring())
			{
				if (level)
					storage.serialize('level', level);
				if (run)
					storage.serialize('run', run);
				
				if (name)
					storage.serializeString('name', name);
				if (fullPath)
					storage.serializeString('full-path', fullPath);
					
			} else {
				
					name = storage.serializeString('name', null);
					fullPath = storage.serializeString('full-path', null);
				try {
					level = new GlobalVariableValue();
					storage.serialize('level', level);
				} catch (e: Error) {
					level = null;
					trace("MultiViewDataProviderItem can not restore 'level'");
				}
				try {
					run = new GlobalVariableValue();
					storage.serialize('run', run);
				} catch (e: Error) {
					trace("MultiViewDataProviderItem can not restore 'run'");
				}
					
			}
		}
	}
}