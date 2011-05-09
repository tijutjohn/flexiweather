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
			return true;
		}
	}
}