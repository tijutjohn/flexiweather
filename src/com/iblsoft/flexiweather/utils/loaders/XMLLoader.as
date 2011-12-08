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
			if (s_format == 'xml')
			{
				return XMLLoader.isValidXML(data);
			}
			return false;
		}
		
		public static function isValidXML(data: Object): Boolean
		{
			if (data is XML)
				return true;
			
			if (data is String)
			{
				try {
					var xml: XML = new XML(data);
					if (xml)
						return true;
				} catch (error: Error) {
					return false;
				}
			}
			
			return false
		}
										  
	}
}