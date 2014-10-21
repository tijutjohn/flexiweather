package com.iblsoft.flexiweather.ogc
{

	public class FeatureUpdateContext
	{
		public static var FULL_UPDATE: int = 7;
		public static var CRS_CHANGED: int = 1;
		public static var VIEW_BBOX_MOVED: int = 2;
		public static var VIEW_BBOX_SIZE_CHANGED: int = 4;
		public static var PARTS_CHANGED: int = 8;
		public static var FEATURE_SCALE_CHANGED: int = 16;
		private var _flag: uint;

		public function get anyChange(): Boolean
		{
			return _flag != 0;
		}

		public function get noChange(): Boolean
		{
			return _flag == 0;
		}

		public function get fullUpdateNeeded(): Boolean
		{
			var test: int = (_flag & FULL_UPDATE);
			return test == FULL_UPDATE;
		}

		public function get significantlyChanged(): Boolean
		{
			return crsChanged || partsChanged;
		}

		public function get crsChanged(): Boolean
		{
			return (_flag & CRS_CHANGED) == CRS_CHANGED;
		}

		public function get viewBBoxSizeChanged(): Boolean
		{
			return (_flag & VIEW_BBOX_SIZE_CHANGED) == VIEW_BBOX_SIZE_CHANGED;
		}

		public function get viewBBoxMoved(): Boolean
		{
			return (_flag & VIEW_BBOX_MOVED) == VIEW_BBOX_MOVED;
		}

		public function get viewBBoxChanged(): Boolean
		{
			return viewBBoxSizeChanged || viewBBoxMoved;
		}

		public function get partsChanged(): Boolean
		{
			return (_flag & PARTS_CHANGED) == PARTS_CHANGED;
		}

		public function FeatureUpdateContext(statusFlag: uint)
		{
			_flag = statusFlag;
		}

		public static function fullUpdate(): FeatureUpdateContext
		{
			return new FeatureUpdateContext(FULL_UPDATE);
		}

		public function toString(): String
		{
			return "FeatureUpdateContext [" + _flag + "] crs: " + crsChanged + " viewbbox size: " + viewBBoxSizeChanged + " move: " + viewBBoxMoved;
		}
	}
}
