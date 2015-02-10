package com.iblsoft.flexiweather.ogc.editable.features
{
	import com.iblsoft.flexiweather.ogc.FeatureUpdateContext;
	import com.iblsoft.flexiweather.ogc.wfs.WFSFeatureEditableSprite;

	import flash.display.Bitmap;
	import flash.geom.Point;

	public class IconLabeledEditableFeature extends LabeledEditableFeature
	{
		private var _bitmap: Bitmap;

		public function get bitmap(): Bitmap
		{
			return _bitmap;
		}

		public function set bitmap(value: Bitmap): void
		{
			_bitmap = value;
			bitmapAdded();
		}

		public function IconLabeledEditableFeature(s_namespace: String, s_typeName: String, s_featureId: String)
		{
			super(s_namespace, s_typeName, s_featureId);
		}

		private function bitmapAdded(): void
		{
			if (_bitmap.parent != this)
				addChild(_bitmap);
		}

		override public function getDisplaySpriteForReflection(id:int):WFSFeatureEditableSprite
		{
			return new IconSprite(this);
		}

		override public function update(changeFlag: FeatureUpdateContext): void
		{
			super.update(changeFlag);
			var a_points: Array = getPoints();
			if (a_points.length > 0)
			{
				var pt: Point = a_points[0] as Point;
				var gap: int = 5;
				updateIconPosition(pt.x - _bitmap.width / 2, pt.y - _bitmap.height / 2);
				updateLabelPosition(_bitmap.x + _bitmap.width + gap, _bitmap.y + _bitmap.height / 2 - textfield.textHeight / 2);

				updateEditablePoints(changeFlag);
			}

		}

		protected function updateIconPosition(x: Number, y: Number): void
		{
			_bitmap.x = x;
			_bitmap.y = y;
		}
	}
}
import com.iblsoft.flexiweather.ogc.editable.WFSFeatureEditable;
import com.iblsoft.flexiweather.ogc.wfs.IWFSIconSprite;
import com.iblsoft.flexiweather.ogc.wfs.WFSFeatureEditableSprite;
import com.iblsoft.flexiweather.utils.ColorUtils;

import flash.display.Bitmap;
import flash.display.BitmapData;
import flash.geom.Point;

class IconSprite extends WFSFeatureEditableSprite implements IWFSIconSprite
{
	private var mn_iconsWidth: Number = 24;
	private var m_iconBitmap: Bitmap = new Bitmap();
	private var m_iconBitmapOrig: Bitmap = new Bitmap();

	override public function set visible(value:Boolean):void
	{
		if (super.visible != value)
		{
			super.visible = value;

			if (!value)
			{
				trace("IconSprite hiding");
			} else {
				trace("IconSprite showing");
			}
		}
	}

	public function IconSprite(feature: WFSFeatureEditable)
	{
		super(feature)

		var baseBitmapData: BitmapData = new BitmapData(mn_iconsWidth, mn_iconsWidth, true, 0xFFFFFF);
		m_iconBitmap.bitmapData = baseBitmapData;

		addChild(m_iconBitmap);

	}

	public function setBitmap(nBitmapData: BitmapData, pt: Point, blackColor: uint = 0): void
	{
		mb_bitmapLoaded = true;
		var nBitmapData: BitmapData = nBitmapData.clone();
		m_iconBitmapOrig = new Bitmap(nBitmapData.clone());

		m_iconBitmap.bitmapData = nBitmapData;

		update(blackColor, pt);


	}
	public function update(blackColor: uint, pt: Point): void
	{
		if (m_iconBitmap)
		{
			m_iconBitmap.x = pt.x - m_iconBitmap.width / 2;
			m_iconBitmap.y = pt.y - m_iconBitmap.height / 2;
			ColorUtils.updateSymbolColor(blackColor, m_iconBitmap, m_iconBitmapOrig);
		}
	}
}
