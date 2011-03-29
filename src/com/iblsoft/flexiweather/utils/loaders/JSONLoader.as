package com.iblsoft.flexiweather.utils.loaders
{
	import com.iblsoft.flexiweather.utils.UniURLLoader;
	
	import flash.utils.ByteArray;
	
	public class JSONLoader extends UniURLLoader
	{
		public function JSONLoader()
		{
			super();
			allowedFormats = [UniURLLoader.JSON_FORMAT];
		}
		
		override protected function isResultContentCorrect(s_format: String, data: Object): Boolean
		{
			return true;
		}
	}
}