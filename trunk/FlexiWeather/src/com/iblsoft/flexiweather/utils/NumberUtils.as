package com.iblsoft.flexiweather.utils
{

	public class NumberUtils
	{
		private static const sms_hexTable: String = "0123456789abcdef";

		public static function decodeHTMLColor(s_color: String, i_default: uint): uint
		{
			var l_matches: Array = s_color.match("^#([A-Fa-f0-9]{6}).*");
			if (!l_matches)
				return i_default;
			return hexStringToUInt(l_matches[1]);
		}

		public static function encodeHTMLColor(i_color: uint): String
		{
			var s1: String = byteToHexString((i_color & 0x00ff0000) >> 16);
			var s2: String = byteToHexString((i_color & 0x0000ff00) >> 8);
			var s3: String = byteToHexString(i_color & 0x000000ff);
			return "#" + s1 + s2 + s3;
		}

		public static function encodeHTMLColorWithAlpha(i_color: uint, f_alpha: Number): String
		{
			var s1: String = byteToHexString((i_color & 0x00ff0000) >> 16);
			var s2: String = byteToHexString((i_color & 0x0000ff00) >> 8);
			var s3: String = byteToHexString(i_color & 0x000000ff);
			var s4: String = byteToHexString(uint(Math.round(f_alpha * 255)) & 0x000000ff);
			return "#" + s1 + s2 + s3 + s4;
		}

		public static function byteToHexString(i_byte: uint): String
		{
			return sms_hexTable.charAt((i_byte & 0xf0) >> 4) + sms_hexTable.charAt(i_byte & 0x0f);
		}

		public static function hexStringToUInt(s_hexString: String): uint
		{
			var i_acc: uint = 0;
			for (var i: uint = 0; i < s_hexString.length; ++i)
			{
				var i_chr: uint = s_hexString.charCodeAt(i);
				var i_value: uint = 0;
				if (i_chr >= 48 && i_chr <= 57)
					i_value = i_chr - 48;
				else if (i_chr >= 97 && i_chr <= 102)
					i_value = i_chr - 97 + 10;
				else if (i_chr >= 65 && i_chr <= 70)
					i_value = i_chr - 65 + 10;
				else
					throw new Error("Invalid hexadecimal value '" + s_hexString + "'")
				i_acc = i_acc * 16 + i_value;
			}
			return i_acc;
		}
	}
}
