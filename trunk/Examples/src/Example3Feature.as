package
{
	import com.iblsoft.flexiweather.ogc.FeatureUpdateContext;
	import com.iblsoft.flexiweather.ogc.InteractiveLayerFeatureBase;
	import com.iblsoft.flexiweather.ogc.InteractiveLayerWFS;
	import com.iblsoft.flexiweather.ogc.editable.WFSFeatureEditableCurve;
	import com.iblsoft.flexiweather.utils.AnnotationTextBox;
	import com.iblsoft.flexiweather.utils.anticollision.AnticollisionLayout;
	import com.iblsoft.flexiweather.utils.geometry.ILineSegmentApproximableBounds;
	import com.iblsoft.flexiweather.utils.geometry.LineSegment;
	
	import flash.display.DisplayObject;
	import flash.geom.Point;

	public class Example3Feature extends WFSFeatureEditableCurve implements ILineSegmentApproximableBounds
	{
		private var m_label: AnnotationTextBox = new AnnotationTextBox();
		private var ms_type: String;

		public function Example3Feature(s_type: String)
		{
			super('http://www.iblsoft.com/wfs/test', 'Example3FeatureWithLabel', null);
			ms_type = s_type;
		}

		public override function setMaster(master: InteractiveLayerFeatureBase): void
		{
			super.setMaster(master);
			master.container.labelLayout.addObstacle(this, master);
			master.container.labelLayout.addObject(m_label, master, [this]);
		}

		public override function update(changeFlag: FeatureUpdateContext): void
		{
			super.update(changeFlag);
			graphics.clear();
			var ptAvg: Point = new Point(0, 0);
			var ptFirst: Point;
			graphics.lineStyle(3, 0xff8040, 1);
			if (/^filled-.*/.test(ms_type))
				graphics.beginFill(0x0080c0, 0.5);
			var ptPrev: Point = null;
			
			var points: Array = getPoints();
			var pointsLength: int = points.length;
			
			for each (var pt: Point in points)
			{
				ptAvg.x += pt.x;
				ptAvg.y += pt.y;
				if (ptPrev == null)
				{
					graphics.moveTo(pt.x, pt.y);
					ptFirst = pt;
				}
				else
					graphics.lineTo(pt.x, pt.y);
				ptPrev = pt;
			}
			ptAvg.x /= pointsLength;
			ptAvg.y /= pointsLength;
			if (/.*polygon$/.test(ms_type) && ptFirst != null)
				graphics.lineTo(ptFirst.x, ptFirst.y);
			if (/^filled-.*/.test(ms_type))
				graphics.endFill();
			m_label.label.text = "Hello!\nI am a label and I try not to\ncover any feature if possible.";
			m_label.update();
			m_label.x = ptAvg.x - m_label.width / 2.0;
			m_label.y = ptAvg.y - m_label.height / 2.0;
			master.container.labelLayout.updateObjectReferenceLocation(m_label);
		}

		public override function cleanup(): void
		{
			master.container.labelLayout.removeObject(this);
			master.container.labelLayout.removeObject(m_label);
			super.cleanup();
		}

		// ILineSegmentApproximableBounds implementation
		public function getLineSegmentApproximationOfBounds(): Array
		{
			var a: Array = [];
			var ptFirst: Point = null;
			var ptPrev: Point = null;
			for each (var pt: Point in getPoints())
			{
				if (ptPrev != null)
					a.push(new LineSegment(ptPrev.x, ptPrev.y, pt.x, pt.y));
				ptPrev = pt;
			}
			if (/.*polygon$/.test(ms_type) && ptFirst != null)
				a.push(new LineSegment(ptPrev.x, ptPrev.y, ptFirst.x, ptFirst.y));
			return a;
		}
	}
}
