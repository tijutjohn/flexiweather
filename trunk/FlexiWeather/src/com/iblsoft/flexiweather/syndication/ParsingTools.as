package com.iblsoft.flexiweather.syndication
{
	import mx.utils.StringUtil;

	/**
	 * Utility class with functions to help parse RSS and Atom feeds.
	 *
	 * @langversion ActionScript 3.0
	 * @playerversion Flash 8.5
	 * @tiptext
	 */
	public class ParsingTools
	{
		/**
		 * Checks to see if a piece of XML that should be a string is empty.
		 * If so, returns null.
		 *
		 * @param x The piece of XML to test.
		 * @return null if the string is emply, otherwise the value of the XML
		 *         node.
		 *
		 * @langversion ActionScript 3.0
		 * @playerversion Flash 8.5
		 * @tiptext
		 */
		public static function nullCheck(x: XMLList): String
		{
			var s: String = String(x);
			if (s == "" || StringUtil.trim(s).length == 0)
				return null;
			return s;
		}

		/**
		 * Checks to see if a piece of XML that should be a number is empty.
		 * If so, returns NaN.
		 *
		 * @param x The piece of XML to test.
		 * @return null if the number is emply, otherwise the value of the XML
		 *         node.
		 *
		 * @langversion ActionScript 3.0
		 * @playerversion Flash 8.5
		 * @tiptext
		 */
		public static function nanCheck(x: XMLList): Number
		{
			var s: String = String(x);
			if (ParsingTools.nullCheck(x) == null || s.search(/\d/) == -1)
				return NaN;
			return Number(s);
		}

		/**
		 * Checks to see if a piece of XML that should be a date is empty.
		 * If so, returns null. If not, parses the string into a date using
		 * the specifid date parsing function.
		 *
		 * @param x The piece of XML to test.
		 * @param f The date parsing function to use to parse the string if
		 *          it's not null.
		 * @return null if the date is emply, otherwise a date object created
		 *         using the specified date-parsing function.
		 *
		 * @langversion ActionScript 3.0
		 * @playerversion Flash 8.5
		 * @tiptext
		 */
		public static function dateCheck(x: XMLList, f: Function): Date
		{
			var s: String = String(x);
			if (ParsingTools.nullCheck(x) == null)
				return null;
			return f(s);
		}
	/**
	 * Checks to see if a piece of XML that should be a string represents
	 * categories. If it's empty, return null. If not, parse the string
	 * into an array of category objects.
	 *
	 * @param x The piece of XML to test.
	 * @return null if the string is empty, otherwise an array of Category
	 *         objects.
	 *
	 * @langversion ActionScript 3.0
	 * @playerversion Flash 8.5
	 * @tiptext
	 */
	/*
	public static function xmlToCategories(x:XMLList):Array
	{
		if (ParsingTools.nullCheck(x) == null)
		{
			return null;
		}
		var categories:Array = new Array();
		var c:XML;
		for each (c in x)
		{
			var cat:Category = new Category();
			var domain:String = String(c.@domain);
			if (StringUtil.trim(domain).length != 0)
			{
				cat.domain = domain;
			}
			cat.addPaths(String(c).split("/"));
			categories.push(cat);
		}
		return categories;
	}

	public static function xmlToGeo(x:XMLList):Geo
	{
		  if (ParsingTools.nullCheck(x) == null)
		  {
			  return null;
		  }
		  var geo:Geo = new Geo();
				  var point:String = String(x);
				  var pointSplit:Array = point.split(" ");
				  var latitude:Number = new Number(pointSplit[0]);
				  var longitude:Number = new Number(pointSplit[1]);
				  geo.point = new LatLng();
				  geo.point.latitude = latitude;
				  geo.point.longitude = longitude;
				  return geo;
	}
	  */
	}
}
