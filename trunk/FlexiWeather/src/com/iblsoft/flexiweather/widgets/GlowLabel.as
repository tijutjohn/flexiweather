package com.iblsoft.flexiweather.widgets
{
	import flash.filters.GlowFilter;
	import flash.text.TextFormat;
	import spark.components.Label;

	public class GlowLabel extends Label
	{
		public var autoSize: Boolean;
		public var defaultText: String;
//		override public function set y(value:Number):void
//		{
//			super.y = value;
//		}
		private var _glowColor: uint;
		private var _glowColorChanged: Boolean;

		public function get glowColor(): uint
		{
			return _glowColor;
		}

		public function set glowColor(value: uint): void
		{
			if (_glowColor != value)
			{
				_glowColor = value;
				_glowColorChanged = true;
				invalidateProperties();
			}
		}
		private var _glowBlur: int = 3;
		private var _glowBlurChanged: Boolean;

		public function get glowBlur(): uint
		{
			return _glowBlur;
		}

		public function set glowBlur(value: uint): void
		{
			if (_glowBlur != value)
			{
				_glowBlur = value;
				_glowBlurChanged = true;
				invalidateProperties();
			}
		}
		private var _glow: GlowFilter;

		public function GlowLabel()
		{
			super();
		}

		override protected function createChildren(): void
		{
			super.createChildren();
			_glow = new GlowFilter(0xffffff, 1, 3, 3, 3);
		}

		override protected function childrenCreated(): void
		{
			super.childrenCreated();
			filters = [_glow];
		}

		override protected function commitProperties(): void
		{
			super.commitProperties();
			if (_glowColorChanged)
			{
				if (_glow)
				{
					_glow.color = _glowColor;
					_glowColorChanged = false
					filters = [_glow];
				}
				else
					invalidateProperties();
			}
			if (_glowBlurChanged)
			{
				if (_glow)
				{
					_glow.blurX = _glowBlur;
					_glow.blurY = _glowBlur;
					_glowBlurChanged = false
					filters = [_glow];
				}
				else
					invalidateProperties();
			}
		}
	/*
	override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void
	{
		super.updateDisplayList(unscaledWidth, unscaledHeight);

		if (autoSize)
		{
//				var size: int = findFontSize(textField.width);


			var currFontSize: int = getStyle('fontSize');
			if (currFontSize != size && size >= 8)
			{
				setStyle('fontSize',currFontSize);
				validateNow();
			}
		}

	}
	*/
	/*
	private function findFontSize(preferredWidth: int): int
	{
		if (preferredWidth == 0)
			return -1;
		var ok: Boolean = true;
		var size: int = 8;
		var cnt:int;
		while (ok)
		{
			var format: TextFormat = textField.getTextFormat();
			format.size = size;
			textField.setTextFormat(format);
			textField.text = text;

			if (textField.textWidth > preferredWidth || textField.textHeight > height)
			{
				ok = false;
				return size - 1;
			}

			if (size > 100)
			{
				ok = false;
				return 12;
			}
			size++;
		}
		return 8;
	}
	*/
	}
}
