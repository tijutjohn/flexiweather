package com.iblsoft.flexiweather.utils.loaders
{
	import com.iblsoft.flexiweather.utils.UniURLLoader;

	import flash.utils.ByteArray;
	
	public class XMLLoader extends UniURLLoader
	{
		public function XMLLoader()
		{
			super();
			allowedFormats = [UniURLLoader.XML_FORMAT];
		}
		
		override protected function isResultContentCorrect(s_format: String, data: Object): Boolean
		{
			return true;
		}
	}
}