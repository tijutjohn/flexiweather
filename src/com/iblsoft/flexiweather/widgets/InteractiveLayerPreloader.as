package com.iblsoft.flexiweather.widgets
{
	import mx.controls.ProgressBar;
	import mx.controls.ProgressBarLabelPlacement;
	import mx.controls.ProgressBarMode;
	
	import spark.effects.Fade;

	public class InteractiveLayerPreloader extends InteractiveLayer
	{
		private var _preloader: ProgressBar;
		private var _value: Number;
		private var _total: Number;
		private var _label: String;
		
		private var _fadeIn: Fade;
		private var _fadeOut: Fade;
		
		override public function set visible(b_visible:Boolean):void
		{
			if (super.visible != b_visible)
			{
				super.visible = b_visible;
				if (_fadeIn)
				{
					if (b_visible)
					{
						_fadeIn.play([_preloader]);
					} else {
						_fadeOut.play([_preloader]);
					}
				}
			}
		}
		public function InteractiveLayerPreloader(container:InteractiveWidget=null)
		{
			super(container);
		}
		
		private function createEffects(): void
		{
			_fadeIn = new Fade();
			_fadeIn.alphaFrom = 0;
			_fadeIn.alphaTo = 1;
			_fadeIn.duration = 1000;
			_fadeIn.target = _preloader;
			
			_fadeOut = new Fade();
			_fadeOut.alphaFrom = 1;
			_fadeOut.alphaTo = 0;
			_fadeOut.duration = 1000;
			_fadeOut.target = _preloader;
		}
			
		override protected function createChildren():void
		{
			super.createChildren();
			
			_preloader = new ProgressBar();
			_preloader.labelPlacement = ProgressBarLabelPlacement.CENTER;
			_preloader.indeterminate = true;
			_preloader.mode = ProgressBarMode.MANUAL;
			_preloader.setStyle('color',0xffffff);
			_preloader.setStyle('fontSize',14);
			
			createEffects();
			_preloader.setStyle('addedEffect', _fadeIn);
			_preloader.setStyle('showEffect', _fadeIn);
			_preloader.setStyle('hideEffect', _fadeOut);
			_preloader.setStyle('removedEffect', _fadeOut);
			
			
		}
		
		override protected function childrenCreated():void
		{
			super.childrenCreated();
			
			addChild(_preloader);
			
			if (_total > 0)
			{
				_preloader.setProgress(_value, _total);
				_preloader.label = _label;
			}
		}
		
		public function setLabel(label: String): void
		{
			if (_preloader)
			{
				_preloader.label = label;
				_preloader.validateNow();
			}
			_label = label;
		}
		public function setProgress(value: Number, total: Number): void
		{
			if (_preloader)
			{
				_preloader.indeterminate = false;
				_preloader.minimum = 0;
				_preloader.maximum = total;
				_preloader.mode = ProgressBarMode.MANUAL;
				_preloader.setProgress(value, total);
			}
			_value = value;
			_total = total;
		}
		
		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void
		{
			super.updateDisplayList(unscaledWidth, unscaledHeight);
			
			_preloader.setActualSize(unscaledWidth, 30);
		}
	}
}