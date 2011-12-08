package com.iblsoft.flexiweather.utils.loaders
{
	import com.iblsoft.flexiweather.utils.HTMLUtils;
	import com.iblsoft.flexiweather.utils.UniURLLoader;
	
	public class WMSFeatureInfoLoader extends UniURLLoader
	{
		public function WMSFeatureInfoLoader()
		{
			super();
			allowedFormats = [UniURLLoader.XML_FORMAT, UniURLLoader.HTML_FORMAT];
		}
		
		override protected function isResultContentCorrect(s_format: String, data: Object): Boolean
		{
			trace("WMSFeatureInfoLoader: " + data);
			
			//for now WMS Feature Info Loader check just is data is valid XML
			var validXML: Boolean = XMLLoader.isValidXML(data); 
			
			if (validXML)
				return true; 
			
			if (s_format == UniURLLoader.HTML_FORMAT)
			{
				var validHTML: Boolean = HTMLUtils.isHTMLFormat(data as String); 
				if (validHTML)
					return true;
				else {
					//check some html tags, very weak check
					var str: String = data as String;
					var htmlPos: int = str.indexOf('<html');
					if (htmlPos >= 0)
					{
						var htmlEndPos: int = str.indexOf('</html', htmlPos + 6);
						if (htmlEndPos > htmlPos)
						{
							var bodyPos: int = str.indexOf('<body');
							if (bodyPos > htmlPos)
							{
								var bodyEndPos: int = str.indexOf('</body', bodyPos + 4);
								if (bodyEndPos > bodyPos)
									return true;
								
							}
						}
					}
				}
			}
			
			return false;
		}
	}
}