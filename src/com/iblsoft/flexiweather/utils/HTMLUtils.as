package com.iblsoft.flexiweather.utils
{
	public class HTMLUtils
	{
		public function HTMLUtils()
		{
		}
		
		public static function fixFeatureInfoHTML(s: String): String
		{
			var originalHTML: String = s;
			
			s = s.replace(/<table>/g, "<table><br/>");
			s = s.replace(/<\/table>/g, "</table><br/>");
			s = s.replace(/<tr>/g, "<tr><br/>");
			s = s.replace(/<td>/g, "<td>&nbsp;");
			
			s = s.replace(/<small>/g, "<p>");
			
			s = s.replace(/<\/small>/g, "</p>");
			
			//TODO this needs to be fixed on server
			s = s.replace(/<small\/>/g, "</p>");
			
			//remove <p></p>
			s = s.replace(/<p><\/p>/g, "");
			
			s = HTMLUtils.removeTag('<nobr>', s);
			s = HTMLUtils.removeTag('<\/nobr>', s);
			
			s = s.substring(s.indexOf('<body'), s.length);
			//find closest >, which close <body tag
			var bodyTagClose: int = s.indexOf('>') + 1;
			
			s = s.substring(bodyTagClose ,s.indexOf('</html>'));
			//remove body
			s = s.substring(0,s.indexOf('</body>'));
			
			trace("from: " + originalHTML);
			trace("to: " + s);
			
			return s;
		}
		
		public static function removeTag(tag: String, s: String): String
		{
			var reg: RegExp = new RegExp(tag, 'g');
			s = s.replace(reg, "");
			return s;
		}
	}
}