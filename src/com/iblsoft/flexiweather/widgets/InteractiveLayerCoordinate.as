package com.iblsoft.flexiweather.widgets
{
	import com.iblsoft.flexiweather.proj.Coord;
	
	import flash.events.MouseEvent;
	
	import mx.controls.Text;
	
	public class InteractiveLayerCoordinate extends InteractiveLayer
	{
		internal var m_textLabel: Text;
		
		public function InteractiveLayerCoordinate(container: InteractiveWidget, textLabel: Text)
		{
			super(container);
			m_textLabel = textLabel;
		}
		
		override public function onMouseMove(event: MouseEvent): Boolean
		{
			var c: Coord = container.pointToCoord(event.localX, event.localY).toLaLoCoord();
			if(m_textLabel != null)
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