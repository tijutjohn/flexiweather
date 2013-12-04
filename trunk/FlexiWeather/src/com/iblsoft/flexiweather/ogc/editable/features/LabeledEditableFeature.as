package com.iblsoft.flexiweather.ogc.editable.features
{
	import com.iblsoft.flexiweather.ogc.FeatureUpdateContext;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextFormat;

	public class LabeledEditableFeature extends GenericEditableFeature
	{
		protected var textfield: TextField;
		private var _fontSize: uint;
		private var _bold: Boolean;
		private var _color: uint;
		private var _text: String;

		public function get fontSize(): uint
		{
			return _fontSize;
		}

		public function set fontSize(value: uint): void
		{
			_fontSize = value;
			updateText();
		}

		public function get bold(): Boolean
		{
			return _bold;
		}

		public function set bold(value: Boolean): void
		{
			_bold = value;
			updateText();
		}

		public function get color(): uint
		{
			return _color;
		}

		public function set color(value: uint): void
		{
			_color = value;
			updateText();
		}

		public function get text(): String
		{
			return _text;
		}

		public function set text(value: String): void
		{
			_text = value;
			updateText();
		}

		public function LabeledEditableFeature(s_namespace: String, s_typeName: String, s_featureId: String)
		{
			super(s_namespace, s_typeName, s_featureId);
			textfield = new TextField();
			addChild(textfield);
		}

		override public function update(changeFlag: FeatureUpdateContext): void
		{
			super.update(changeFlag);
		}

		protected function updateLabelPosition(x: Number, y: Number): void
		{
			textfield.x = x;
			textfield.y = y;
		}

		protected function updateText(): void
		{
			textfield.autoSize = TextFieldAutoSize.LEFT;
			textfield.text = _text;
			updateStyle(_color);
		}

		private function updateStyle(color: uint): void
		{
			var tf: TextFormat = textfield.getTextFormat();
			tf.color = color;
			tf.bold = _bold;
			tf.size = _fontSize;
			textfield.setTextFormat(tf);
		}
	}
}
