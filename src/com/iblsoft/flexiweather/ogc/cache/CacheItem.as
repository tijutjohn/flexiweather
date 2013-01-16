package com.iblsoft.flexiweather.ogc.cache
{
	import com.iblsoft.flexiweather.ogc.data.viewProperties.IViewProperties;
	import flash.display.Bitmap;
	import flash.display.DisplayObject;

	public class CacheItem
	{
		public static var CID: int = 0;
		private var _id: int;
		public var cacheKey: CacheKey;
		public var lastUsed: Date;
		public var viewProperties: IViewProperties;
		private var _image: DisplayObject;
		private var _displayed: Boolean;

		public function get image(): DisplayObject
		{
			return _image;
		}

		public function set image(value: DisplayObject): void
		{
			_image = value;
		}

		public function get displayed(): Boolean
		{
			return _displayed;
		}

		public function isImageOnDisplayList(): Boolean
		{
			if (image)
				return image.parent != null;
			return false;
		}

		public function set displayed(value: Boolean): void
		{
			_displayed = value;
		}

		public function CacheItem()
		{
			CID++;
			_id = CID;
		}

		public function toString(): String
		{
			return "CacheItem " + _id;
		}

		public function destroy(): void
		{
			cacheKey.destroy();
			cacheKey = null;
			lastUsed = null;
			viewProperties = null
			image = null;
		}
	}
}
