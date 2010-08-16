package com.iblsoft.flexiweather.widgets
{
	import flash.filters.GlowFilter;
	
	import mx.controls.Text;

	public class GlowLabel extends Text
	{
		private var _glowColor: uint;
		private var _glowColorChanged: Boolean;
		public function get glowColor(): uint
		{
			return _glowColor;
		}
		public function set glowColor( value: uint): void
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
		public function set glowBlur( value: uint): void
		{
			if (_glowBlur != value)
			{
				_glowBlur = value;
				_glowBlurChanged = true;
				invalidateProperties();
				
			}
		}
		
		private var _glow:GlowFilter;
		public function GlowLabel()
		{
			super();
		}
		
		override protected function createChildren(): void
		{
			super.createChildren();
			
			_glow = new GlowFilter(0xffffff,1,3,3,3);
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
				} else {
					invalidateProperties();
				}
			}
			if (_glowBlurChanged)
			{
				if (_glow)
				{
					_glow.blurX = _glowBlur;
					_glow.blurY = _glowBlur;
					_glowBlurChanged = false
					
					filters = [_glow];
				} else {
					invalidateProperties();
				}
			}
		}
		
	}
}