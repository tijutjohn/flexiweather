package com.iblsoft.flexiweather.widgets.containers
{
	import flash.display.Graphics;
	
	import mx.containers.Box;
	import mx.containers.Canvas;
	import mx.containers.VBox;
	import mx.controls.Label;

	public class GroupBox extends VBox
	{
		public var container:Box;
		
		public var defaultPadding: int = 10;
		private var _cnv: Canvas;
		private var _label: Label;
		
		private var _cornerRadius: int = 10;
		[Bindable]
		public function get cornerRadius(): int
		{
			return _cornerRadius;
		}
		public function set cornerRadius(value: int): void
		{
			_cornerRadius = value;
			invalidateDisplayList();	
		}
		
		private var _captionGap: int = 5;
		[Bindable]
		public function get captionGap(): int
		{
			return _captionGap;
		}
		public function set captionGap(value: int): void
		{
			_captionGap = value;
			invalidateDisplayList();	
		}
		
		private var _caption: String = '';
		
		[Bindable]
		public function get caption(): String
		{
			return _caption;
		}
		public function set caption(value: String): void
		{
			_caption = value;
			invalidateDisplayList();
		}
		
		public function GroupBox()
		{
			super();
		}
		
		override protected function createChildren():void
		{
			super.createChildren();
			
			_cnv = new Canvas();
			_label = new Label();
			
			container = new Box();
			
		}
		
		override protected function childrenCreated():void
		{
			super.childrenCreated();
			
			setStyle('verticalGap',0);
			
			_cnv.addChild(_label);
			addChildAt(_cnv, 0);
			_cnv.percentWidth = 100;
			
			addChild(container);
			container.percentWidth = 100;
			container.percentHeight = 100;
			
			container.setStyle('paddingBottom',defaultPadding);
			container.setStyle('paddingTop',defaultPadding);
			container.setStyle('paddingLeft',defaultPadding);
			container.setStyle('paddingRight',defaultPadding);
			
		}
		override public function setStyle(styleProp:String, newValue:*):void
		{
			if (styleProp.indexOf('padding') == 0)
			{
				if (container)
				{
					container.setStyle(styleProp, newValue);
				} else {
					callLater(setStyle, [styleProp, newValue]);
				}
				return;
			}	
			super.setStyle(styleProp, newValue);
		}
		
		override protected function commitProperties():void
		{
			super.commitProperties();
			
			_label.text = _caption;
		}
		
		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void
		{
			super.updateDisplayList(unscaledWidth, unscaledHeight);
			
			var cGap: int = _captionGap;
			
			if (caption == '')
			{
				_cnv.includeInLayout = false;
				_cnv.visible = false;
				cGap = 0;
			} else {
				_cnv.includeInLayout = true;
				_cnv.visible = true;
			}
			
			var gr: Graphics = graphics;
			gr.clear();
			gr.lineStyle(getStyle('borderThickness'),getStyle('borderColor'),1);
			
			_label.text = _caption;
			_label.x = _cornerRadius + cGap;
			_label.validateNow();
			
			var topLineYpos: int = _label.textHeight / 2;
			gr.moveTo(_cornerRadius + cGap + _label.textWidth + cGap, topLineYpos);
			gr.lineTo(unscaledWidth - _cornerRadius, topLineYpos);
			
			gr.curveTo( unscaledWidth, topLineYpos, unscaledWidth, _cornerRadius + topLineYpos);
			
			gr.lineTo(unscaledWidth, unscaledHeight - _cornerRadius);
			gr.curveTo( unscaledWidth, unscaledHeight, unscaledWidth - _cornerRadius, unscaledHeight);
			gr.lineTo(_cornerRadius, unscaledHeight);
			gr.curveTo( 0, unscaledHeight, 0, unscaledHeight - _cornerRadius);
			gr.lineTo(0, _cornerRadius + topLineYpos);
			gr.curveTo( 0, topLineYpos, _cornerRadius, topLineYpos );
		}
		
		override protected function createBorder():void
		{
			
		}
	}
}