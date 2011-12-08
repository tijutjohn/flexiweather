package com.iblsoft.flexiweather.utils.loaders
{
	import com.iblsoft.flexiweather.utils.UniURLLoader;
	
	import flash.utils.ByteArray;
	
	public class ImageLoader extends UniURLLoader
	{
		public function ImageLoader()
		{
			super();
			allowedFormats = [UniURLLoader.IMAGE_FORMAT];
		}
		
		override protected function isResultContentCorrect(s_format: String, data: Object): Boolean
		{
			return ImageLoader.isValidImage(data);
		}
		
		public static function isValidImage(data: Object): Boolean
		{
			if (data is ByteArray)
			{
				var b0: int = data.length > 0 ? data.readUnsignedByte() : -1;
				var b1: int = data.length > 1 ? data.readUnsignedByte() : -1;
				var b2: int = data.length > 2 ? data.readUnsignedByte() : -1;
				var b3: int = data.length > 3 ? data.readUnsignedByte() : -1;
				
				var isPNG: Boolean = b0 == 0x89 && b1 == 0x50 && b2 == 0x4E && b3 == 0x47;
				var isJPG: Boolean = b0 == 0xff && b1 == 0xd8 && b2 == 0xff && b3 == 0xe0;
				
				if (isPNG || isJPG)
					return true;
			}
			
			return false;
		}
	}
}