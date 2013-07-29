package com.iblsoft.flexiweather.widgets
{
	import com.iblsoft.flexiweather.proj.Coord;
	
	import flash.events.MouseEvent;
	
	import spark.components.Label;

	public class InteractiveLayerCoordinate extends InteractiveLayer
	{
		private var m_textLabel: Label;

		public function InteractiveLayerCoordinate(container: InteractiveWidget = null)
		{
			super(container);
			m_textLabel = textLabel;
		}


		public function get textLabel():Label
		{
			return m_textLabel;
		}

		public function set textLabel(value:Label):void
		{
			m_textLabel = value;
		}

		override public function onMouseMove(event: MouseEvent): Boolean
		{
			var c: Coord = container.pointToCoord(event.localX, event.localY).toLaLoCoord();
			if (m_textLabel != null)
				m_textLabel.text = c.toNiceString();
			return false; // we don't want to discard the value	
		}

		override public function onMouseRollOut(event: MouseEvent): Boolean
		{
			m_textLabel.text = "";
			return false;
		}
	}
}
