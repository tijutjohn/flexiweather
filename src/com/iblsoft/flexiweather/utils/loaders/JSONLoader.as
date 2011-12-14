package com.iblsoft.flexiweather.utils.loaders
{
	import com.iblsoft.flexiweather.utils.UniURLLoader;
	
	import flash.utils.ByteArray;
	
	import json.JParser;
	
	public class JSONLoader extends UniURLLoader
	{
		public function JSONLoader()
		{
			super();
			allowedFormats = [UniURLLoader.JSON_FORMAT];
		}
		
		override protected function isResultContentCorrect(s_format: String, data: Object): Boolean
		{
			return JSONLoader.isValidJSon(data);
		}
		
		static public function isValidJSon(data: Object): Boolean
		{
			if (data is String)
			{
				if (data == "")
					return true;
				try {
					var json: Object = JParser.decode(data as String);
					if (json)
						return true;
				} catch (error: Error) {
					return false;
				}
					
			}
			return false;
		}
	}
}