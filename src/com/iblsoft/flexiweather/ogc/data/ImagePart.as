package com.iblsoft.flexiweather.ogc.data
{
	import com.iblsoft.flexiweather.ogc.BBox;
	import com.iblsoft.flexiweather.proj.Projection;
	
	import flash.display.Bitmap;

	public class ImagePart
	{
		public var mi_updateCycleAge: uint;
		public var m_image: Bitmap = null;
		public var mb_imageOK: Boolean = false;
		public var ms_imageCRS: String = null;
		public var m_imageBBox: BBox = null;
		
		public function intersectsOrHasDifferentCRS(other: ImagePart): Boolean
		{
			if(!Projection.equalCRSs(ms_imageCRS, other.ms_imageCRS))
				return true;
			var intersection: BBox = m_imageBBox.intersected(other.m_imageBBox);
			return intersection && intersection.width > 1e-6 && intersection.height > 1e-6;
		}
	}
}