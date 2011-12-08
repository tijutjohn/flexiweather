package com.iblsoft.flexiweather.utils.loaders
{
	import com.iblsoft.flexiweather.utils.UniURLLoader;
	
	import mx.events.DynamicEvent;
	
	public class WMSImageLoader extends UniURLLoader
	{
		public function WMSImageLoader()
		{
			super();
			allowedFormats = [UniURLLoader.IMAGE_FORMAT, UniURLLoader.XML_FORMAT];
		}
		
		override protected function isResultContentCorrect(s_format: String, data: Object): Boolean
		{
			var validXML: Boolean = XMLLoader.isValidXML(data); 
			var validImage: Boolean = ImageLoader.isValidImage(data);
			
			if (validXML)
				return false; 

			if (validImage)
				return true;
			
			return false
		}
		
		public static function isWMSServiceException(data: Object): Boolean
		{
			var xmlSource: String;
			var xml: XML
			if (data is String)
			{
				xmlSource = data as String;
			 	xml = new XML(xmlSource);
			}
			if (data is XML)
				xml = data as XML;
			
			var topName: String = xml.name().localName;
			var children: XMLList = xml.children();
			if (children)
			{
				var child: XML = children[0] as XML;
				var childName: String = (child.name() as QName).localName;
				if (child.hasOwnProperty('@code'))
				{
					var codeName: String = child.@code;
					
					if (topName == 'ServiceExceptionReport' && childName == 'ServiceException' && codeName == 'OperationNotSupported')
					{
						return true;
					}
				}
			}
			return false;
		}
	}
}