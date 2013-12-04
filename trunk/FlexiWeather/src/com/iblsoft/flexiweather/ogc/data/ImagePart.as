package com.iblsoft.flexiweather.ogc.data
{
	import com.iblsoft.flexiweather.ogc.BBox;
	import com.iblsoft.flexiweather.proj.Projection;
	import flash.display.AVM1Movie;
	import flash.display.Bitmap;
	import flash.display.DisplayObject;

	public class ImagePart
	{
		public var ms_cacheKey: String;
		public var mi_updateCycleAge: uint;
		private var m_image: DisplayObject = null;
		public var mb_imageOK: Boolean = false;
		public var ms_imageCRS: String = null;
		public var m_imageBBox: BBox = null;

		public function get image():DisplayObject
		{
			return m_image;
		}

		public function set image(value:DisplayObject):void
		{
			m_image = value;
		}

		public function get isBitmap(): Boolean
		{
			return m_image is Bitmap;
		}

		public function get isFlash(): Boolean
		{
			return m_image is AVM1Movie;
		}

		public function intersectsOrHasDifferentCRS(other: ImagePart): Boolean
		{
			if (!Projection.equalCRSs(ms_imageCRS, other.ms_imageCRS))
				return true;
			var intersection: BBox = m_imageBBox.intersected(other.m_imageBBox);
			return intersection && intersection.width > 1e-6 && intersection.height > 1e-6;
		}

		public function destroy(): void
		{
			m_imageBBox = null;
			if (m_image)
			{
				if (m_image is Bitmap)
				{
					var bmp: Bitmap = m_image as Bitmap;
					if (bmp.bitmapData)
						bmp.bitmapData.dispose();
				}
				//FIXME how to unload AVM1Movie
				m_image = null;
			}
		}
	}
}
