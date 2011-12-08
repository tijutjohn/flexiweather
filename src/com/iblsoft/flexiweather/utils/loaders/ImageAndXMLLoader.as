package com.iblsoft.flexiweather.utils.loaders
{
	import com.iblsoft.flexiweather.utils.UniURLLoader;
	
	import mx.events.DynamicEvent;
	
	public class ImageAndXMLLoader extends UniURLLoader
	{
		public static var XML_RECEIVED: String = 'xmlReceived';
		
		public function ImageAndXMLLoader()
		{
			super();
			allowedFormats = [UniURLLoader.IMAGE_FORMAT, UniURLLoader.XML_FORMAT];
		}
		
		override protected function isResultContentCorrect(s_format: String, data: Object): Boolean
		{
			var validXML: Boolean = XMLLoader.isValidXML(data); 
			var validImage: Boolean = ImageLoader.isValidImage(data);
			
			if (validXML)
			{
				trace("stop, XML loaded in ImageAndXMLLoader");
				var de: DynamicEvent = new DynamicEvent(XML_RECEIVED);
				de['xml'] = data;
				dispatchEvent(de);
			}
			return validXML || validImage;
		}
	}
}