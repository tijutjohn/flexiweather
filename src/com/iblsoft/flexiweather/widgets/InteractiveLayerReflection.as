package com.iblsoft.flexiweather.widgets
{
	import com.iblsoft.flexiweather.ogc.BBox;
	import com.iblsoft.flexiweather.proj.Coord;
	import com.iblsoft.flexiweather.proj.Projection;
	
	import flash.display.BitmapData;
	import flash.display.Graphics;
	import flash.filters.GlowFilter;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextFormat;
	import flash.text.TextFormatAlign;

	public class InteractiveLayerReflection extends InteractiveLayer
	{
		private var _label: TextField;
		public var reflectionID: int;
		
		public function InteractiveLayerReflection(container:InteractiveWidget=null)
		{
			super(container);
			
			mouseChildren = false;
			mouseEnabled = false;
		}
		
		override protected function createChildren(): void
		{
			_label = new TextField();
		}
		
		override protected function childrenCreated(): void
		{
			addChild(_label);
		}
		
		override public function draw(graphics: Graphics): void
		{
			super.draw(graphics);
			var gr: Graphics = graphics;
			gr.clear();
			
			
			var projection: Projection = container.getCRSProjection();
			var extent: BBox = projection.extentBBox;
			
			var cLeft: Coord = new Coord(projection.crs, extent.xMin, extent.yMin);
			var cRight: Coord = new Coord(projection.crs, extent.xMax, extent.yMin);
			
			var newLeftPoint: Point = container.coordToPoint(cLeft);
			var newRightPoint: Point = container.coordToPoint(cRight);
			
			var w: int = newRightPoint.x - newLeftPoint.x;
			
			
			var deltas: Array = [0,1,-1,2,-2];
			var deltaColors: Array = [0x888888, 0xaaaaaa, 0x666666,0xcccccc, 0x444444];
			
			var crs: String = container.crs;
			var totalDeltas: int = deltas.length;
			for (var i: int = 0; i < totalDeltas; i++)
			{
				var delta: int = deltas[i];
				var clr: uint = deltaColors[i];
				
				var xx: int = newLeftPoint.x + delta * w;
				gr.beginFill(clr, 0.5);
				gr.lineStyle(1, 0xaaaaaa);
				gr.drawRect(xx, 0, w, height);
				gr.endFill();
				if (_label)
				{
					drawText("Reflection: " + delta, "test", gr, new Point(xx + w/2, height/2));
					
				}
			}
				
		}
		
		private var _tf: TextField = new TextField();
		private var _tf2: TextField = new TextField();
		private var _tfBD: BitmapData;
		
		private function drawText(txt: String, txt2: String,  gr: Graphics, pos: Point): void
		{
			if (!_tf.filters || !_tf.filters.length)
			{
				_tf.filters = [new GlowFilter(0xffffffff)];
			}
			if (!_tf2.filters || !_tf2.filters.length)
			{
				_tf2.filters = [new GlowFilter(0xffffffff)];
			}
			var tfWidth: int = 200;
			var tfHeight: int = 30;
			
			var format: TextFormat = _tf.getTextFormat();
			format.size = 24;
			format.align = TextFieldAutoSize.LEFT;
			
			var format2: TextFormat = _tf2.getTextFormat();
			format2.size = 20;
			format2.align = TextFieldAutoSize.LEFT;
			
			_tf.text = txt;
			_tf.setTextFormat(format);
			
			_tf2.text = txt2;
			_tf2.setTextFormat(format2);
			
			_tf.width = _tf.textWidth + 20;
			_tf2.width = _tf2.textWidth + 20;
			
			tfWidth = Math.max(_tf.textWidth + 20, _tf2.textWidth + 20);
			tfHeight = _tf.textHeight + _tf2.textHeight + 5;
			
			var mTf2: Matrix = new Matrix();
			mTf2.translate(0, _tf.textHeight + 3);
			
			_tfBD = new BitmapData(tfWidth, tfHeight, true, 0x88ffffff);
			_tfBD.draw(_tf);
			_tfBD.draw(_tf2, mTf2);
			
			var m: Matrix = new Matrix();
			m.translate(pos.x, pos.y)
			gr.lineStyle(0, 0, 0);
			gr.beginBitmapFill(_tfBD, m, false);
			gr.drawRect(pos.x, pos.y, tfWidth, tfHeight);
			gr.endFill();
		}
			
		
		private function updateLayerLabel(text: String): void
		{
			var id: String = container.id;
			//			_label.text = "["+id+"]"+text;
			_label.text = text;
			updateLabelStyles();
		} 
		private function updateLabelStyles(): void
		{
			_label.multiline = false;
			_label.border = false;
			_label.width = 200;
			var tf: TextFormat = _label.getTextFormat();
			tf.font = 'defaultFontMX';
			tf.color = 0xffffff;
			tf.size = 24;
			tf.align = TextFormatAlign.LEFT;
			_label.setTextFormat(tf);
		}
	}
}