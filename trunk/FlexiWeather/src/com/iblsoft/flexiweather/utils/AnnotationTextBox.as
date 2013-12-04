package com.iblsoft.flexiweather.utils
{
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;

	public class AnnotationTextBox extends AnnotationBox
	{
		private var m_label: TextField = new TextField();

		public function AnnotationTextBox()
		{
			super();
			addChild(m_label);
			m_label.multiline = true;
			m_label.selectable = false;
			m_label.autoSize = TextFieldAutoSize.CENTER;
		}

		public override function updateContent(): void
		{
			super.updateContent();
			m_label.x = 2;
			m_label.y = 2;
			m_label.width = measuredWidth - 4;
			m_label.height = measuredHeight - 4;
		}

		public override function measureContent(): void
		{
			m_label.width = m_label.textWidth;
			m_label.height = m_label.textHeight;
			measuredWidth = m_label.textWidth + 4;
			measuredHeight = m_label.textHeight + 4;
		}

		public function get label(): TextField
		{
			return m_label;
		}
	}
}
