package com.iblsoft.flexiweather.ogc.data
{
	import com.iblsoft.flexiweather.ogc.BBox;
	import com.iblsoft.flexiweather.proj.Projection;

	import flash.display.AVM1Movie;
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.DisplayObject;

	public class ImagePart
	{
		public static var idCounter: int = 0;
		public var partID: int;

		public var ms_cacheKey: String;
		public var mi_updateCycleAge: uint;
		private var m_image: DisplayObject = null;
		private var _mb_imageOK: Boolean = false;
		public var ms_imageCRS: String = null;
		public var m_imageBBox: BBox = null;

		public function get mb_imageOK():Boolean
		{
			return _mb_imageOK;
		}

		public function set mb_imageOK(value:Boolean):void
		{
//			trace("ImagePart ["+partID+"]mb_imageOK = " + value);
			_mb_imageOK = value;
		}

		public function get imageBBox(): BBox
		{
			return m_imageBBox;
		}

		public function get image():DisplayObject
		{
			return m_image;
		}
/*
		public function set image(value:DisplayObject):void
		{
			m_image = value;
		}
*/

		public function set image(value:DisplayObject):void
		{
			if (value is Bitmap)
			{
				var bd: BitmapData = (value as Bitmap).bitmapData;
//				trace("ImagePart ["+partID+"] set bitmap ["+bd.width+","+bd.height+"]");
				m_image = new Bitmap((value as Bitmap).bitmapData);
			} else {
//				trace("ImagePart ["+partID+"] NOT set");
				m_image = value;
			}
		}

		public function get isBitmap(): Boolean
		{
			return m_image is Bitmap;
		}

		public function get isFlash(): Boolean
		{
			return m_image is AVM1Movie;
		}

		public function ImagePart()
		{
			partID = idCounter++;
		}
		public function intersectsOrHasDifferentCRS(other: ImagePart): Boolean
		{
			if (!Projection.equalCRSs(ms_imageCRS, other.ms_imageCRS))
				return true;
			var intersection: BBox = m_imageBBox.intersected(other.m_imageBBox);
			return intersection && intersection.width > 1e-6 && intersection.height > 1e-6;
		}

		public function areaEquals(other: ImagePart): Boolean
		{
			if (!Projection.equalCRSs(ms_imageCRS, other.ms_imageCRS))
				return false;

			return m_imageBBox.equals(other.imageBBox);
		}

		public function destroy(): void
		{
			m_imageBBox = null;
			if (m_image)
			{
				trace("ImagePart ["+partID+"] destroy");
				if (m_image is Bitmap)
				{
					var bmp: Bitmap = m_image as Bitmap;
					if (bmp.bitmapData)
						bmp.bitmapData.dispose();
				}
				//FIXME how to unload AVM1Movie
				m_image = null;
			} else {
				trace("ImagePart ["+partID+"] destroy, but there is no image");
			}
		}

		public function toString(): String
		{
			return "ImagePart ["+partID+"]";
		}
	}
}
