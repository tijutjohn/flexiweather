package com.iblsoft.flexiweather.utils
{
	import flashx.textLayout.conversion.TextConverter;
	import flashx.textLayout.elements.TextFlow;

	public class HTMLUtils
	{
		public function HTMLUtils()
		{
		}

		public static function createHTMLTextFlow(txt: String): TextFlow
		{
			return TextConverter.importToFlow(txt, TextConverter.TEXT_FIELD_HTML_FORMAT);
		}

		public static function isHTMLFormat(s_data: String): Boolean
		{
			try
			{
				var x: XML = new XML(s_data);
			}
			catch (error: Error)
			{
				//it's not XML format, so it can not be HTML format
				return false;
			}
			var head: Boolean;
			var body: Boolean;
			for each (var node: XML in x.children())
			{
				if (node.name().localName == 'head')
					head = true;
				if (node.name().localName == 'body')
					body = true;
			}
			return head && body;
		}

		public static function isHTML401Unauthorized(s_data: String): Boolean
		{
			var isHTML: Boolean = isHTMLFormat(s_data);
			if (!isHTML)
			{
				//it's not HTML, so it can not be 401 HTML page
				return false
			}
			var x: XML = new XML(s_data);
			var head: Boolean;
			var body: Boolean;
			for each (var node: XML in x.children())
			{
				if (node.name().localName == 'head')
				{
					//check all head children() to find <title> tag
					if (node.children().length())
					{
						for each (var headChildNode: XML in node.children())
						{
							if (headChildNode.name().localName == 'title')
							{
								var titleString: String = headChildNode.text();
								var is401: Boolean = titleString.indexOf('401') >= 0;
								var isAuthorizationRelated: Boolean = titleString.toLocaleLowerCase().indexOf('authoriza') >= 0;
								var isUnauthorized: Boolean = titleString.toLocaleLowerCase().indexOf('unauthorized') >= 0;
								return is401 && (isUnauthorized || isAuthorizationRelated);
							}
						}
					}
				}
			}
			return false;
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
			s = s.substring(bodyTagClose, s.indexOf('</html>'));
			//remove body
			s = s.substring(0, s.indexOf('</body>'));
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
