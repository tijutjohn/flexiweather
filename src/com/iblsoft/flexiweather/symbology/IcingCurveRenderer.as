package com.iblsoft.flexiweather.symbology
{
	import com.iblsoft.flexiweather.utils.DistanceMarkingCurveRenderer;
	import flash.display.Graphics;
	import flash.geom.Point;

	public class IcingCurveRenderer extends DistanceMarkingCurveRenderer
	{
		public static const MARK_WARM: uint = 0;
		public static const MARK_COLD: uint = 1;
		public static const MARK_OCCLUDED: uint = 2;
		public static const MARK_STATIONARY: uint = 3;
		// style variables
		protected var mi_color: uint;
		protected var mi_colorSecondary: uint;
		protected var mi_markType: uint;
		// runtime variables
		protected var mf_markStep: Number = 20;
		protected var mf_markWidth: Number = 10;
		protected var mi_markCounter: uint = 0;
		protected var ml_markPoints: Array;
		protected var mf_lastDX: Number = 0;
		protected var mf_lastDY: Number = 0;

		function IcingCurveRenderer(g: Graphics, i_color: uint, i_colorSecondary: uint, i_markType: uint)
		{
			super(g);
			mi_color = i_color;
			mi_colorSecondary = i_colorSecondary;
			mi_markType = i_markType;
		}

		override public function started(x: Number, y: Number): void
		{
			mi_markCounter = 0;
			ml_markPoints = [];
			mf_lastDX = 0;
			mf_lastDY = 0;
			m_graphics.lineStyle(2, mi_color);
			switch (mi_markType)
			{
				case 2:
				{
					mf_markStep = 10;
					break;
				}
				case 3:
				{
					mf_markStep = 5;
					break;
				}
				default:
				{
					mf_markWidth = 10;
					mf_markStep = 15;
					break;
				}
			}
		}

		override public function finished(x: Number, y: Number): void
		{
			var i_markCounter: uint = 0;
			for each (var mark: Mark in ml_markPoints)
			{
				// skip marks which will exceed the curve size
				//if(mark.f_distance + mf_markWidth / 2 > mf_currentDistance)
				//	continue;
				if (mark.f_distance - mf_markWidth / 2 < 0)
					continue;
				switch (mi_markType)
				{
					case 0:
					{
						icingLine(mark.pt, mark.vDiff, mark.vNormal, mi_color);
						break;
					}
					case 1:
					{
						hemicircle(mark.pt, mark.vDiff, mark.vNormal, mi_color);
						break;
					}
					case 2:
					{
						switch (i_markCounter % 4)
						{
							case 0:
							{
								hemicircle(mark.pt, mark.vDiff, mark.vNormal, mi_color);
								break;
							}
							case 1:
								break;
							case 2:
							{
								triangle(mark.pt, mark.vDiff, mark.vNormal, mi_color);
								break;
							}
							case 3:
								break;
						}
						break;
					}
					case 3:
					{
						switch (i_markCounter % 8)
						{
							case 1:
							{
								hemicircle(mark.pt, mark.vDiff, mark.vNormal, mi_color);
								break;
							}
							case 5:
							{
								triangle(mark.pt, mark.vDiff, mark.vNormal, mi_colorSecondary - 1, -1);
								break;
							}
						}
					}
				}
				++i_markCounter;
			}
		}

		override protected function mark(x: Number, y: Number): void
		{
			nextMarkDistance += mf_markStep;
			var pt: Point = new Point(x, y);
			var vDiff: Point = new Point(mf_lastDX, mf_lastDY);
			vDiff.normalize(1);
			var vNormal: Point = new Point(vDiff.y, -vDiff.x);
			vNormal.normalize(1);
			ml_markPoints.push(new Mark(pt, vNormal, vDiff, mf_currentDistance));
			++mi_markCounter;
			if (mi_markType == 3)
			{
				switch (mi_markCounter % 8)
				{
					case 0:
					case 1:
					case 2:
					case 3:
					{
						m_graphics.lineStyle(2, mi_color);
						break;
					}
					case 4:
					case 5:
					case 6:
					case 7:
					{
						m_graphics.lineStyle(2, mi_colorSecondary);
						break;
					}
				}
			}
			else if (mi_markType == 0)
			{
				switch (mi_markCounter % 8)
				{
					case 0:
					case 1:
					case 2:
					case 3:
					case 4:
					case 5:
					{
						m_graphics.lineStyle(2, mi_color);
						break;
					}
					case 6:
					case 7:
					{
						m_graphics.lineStyle(2, mi_colorSecondary, 0);
						break;
					}
				}
			}
		}

		override protected function betweenMarkLineTo(x: Number, y: Number): void
		{
			if (x != m_lastX || y != m_lastY)
			{
				mf_lastDX = x - m_lastX;
				mf_lastDY = y - m_lastY;
			}
			//mark(x, y);
			//m_graphics.lineTo(x, y);
			super.moveTo(x, y);
		}

		protected function icingLine(pt: Point, vDiff: Point, vNormal: Point, i_color: uint, f_heightScale: Number = 1): void
		{
			var f_w: Number = mf_markWidth * 0.5;
			//var f_h: Number = (mf_markWidth - 1) * f_heightScale;
			var f_h: Number = (f_w * 0.8) * f_heightScale;
			var f_xR: Number = pt.x + vDiff.x * f_w;
			var f_yR: Number = pt.y + vDiff.y * f_w;
			var f_xC: Number = pt.x + vNormal.x * f_h;
			var f_yC: Number = pt.y + vNormal.y * f_h;
			var f_xL: Number = pt.x - vDiff.x * f_w;
			var f_yL: Number = pt.y - vDiff.y * f_w;
			m_graphics.lineStyle(2, i_color);
			//m_graphics.beginFill(i_color);
			//m_graphics.moveTo(f_xR, f_yR);
			m_graphics.moveTo(pt.x, pt.y);
			m_graphics.lineTo(f_xC, f_yC);
			m_graphics.moveTo(f_xR, f_yR);
			m_graphics.lineTo(f_xL, f_yL);
			//m_graphics.lineStyle(2, 0xFF0000);
			//m_graphics.lineTo(f_xL, f_yL);
			//m_graphics.lineTo(f_xR, f_yR);
			//m_graphics.lineStyle(2, i_color);
			//m_graphics.endFill();
		}

		protected function triangle(pt: Point, vDiff: Point, vNormal: Point, i_color: uint, f_heightScale: Number = 1): void
		{
			var f_w: Number = mf_markWidth / 2.0;
			var f_h: Number = (mf_markWidth - 1) * f_heightScale;
			var f_xR: Number = pt.x + vDiff.x * f_w;
			var f_yR: Number = pt.y + vDiff.y * f_w;
			var f_xC: Number = pt.x + vNormal.x * f_h;
			var f_yC: Number = pt.y + vNormal.y * f_h;
			var f_xL: Number = pt.x - vDiff.x * f_w;
			var f_yL: Number = pt.y - vDiff.y * f_w;
			m_graphics.lineStyle(2, i_color);
			//m_graphics.beginFill(i_color);
			m_graphics.moveTo(f_xR, f_yR);
			//m_graphics.lineTo(f_xC, f_yC);
			m_graphics.lineTo(f_xL, f_yL);
			//m_graphics.lineTo(f_xR, f_yR);
			//m_graphics.endFill();
		}

		protected function hemicircle(pt: Point, vDiff: Point, vNormal: Point, i_color: uint): void
		{
			var f_w: Number = mf_markWidth / 2.0;
			var f_h: Number = f_w * 1.2;
			var f_xR: Number = pt.x + vDiff.x * f_w;
			var f_yR: Number = pt.y + vDiff.y * f_w;
			var f_xC: Number = pt.x + vNormal.x * f_h;
			var f_yC: Number = pt.y + vNormal.y * f_h;
			var f_xL: Number = pt.x - vDiff.x * f_w;
			var f_yL: Number = pt.y - vDiff.y * f_w;
			m_graphics.lineStyle(1, i_color);
			m_graphics.beginFill(i_color);
			m_graphics.moveTo(f_xR, f_yR);
			m_graphics.curveTo(f_xR + vNormal.x * f_h, f_yR + vNormal.y * f_h, f_xC, f_yC);
			m_graphics.curveTo(f_xL + vNormal.x * f_h, f_yL + vNormal.y * f_h, f_xL, f_yL);
			m_graphics.lineTo(f_xR, f_yR);
			m_graphics.endFill();
		}
	}
}
import flash.display.Graphics;
import flash.geom.Point;
import com.iblsoft.flexiweather.utils.CubicBezier;

class Mark
{
	internal var pt: Point;
	internal var vNormal: Point;
	internal var vDiff: Point;
	internal var f_distance: Number;

	public function Mark(pt: Point, vNormal: Point, vDiff: Point, f_distance: Number)
	{
		this.pt = pt;
		this.vNormal = vNormal;
		this.vDiff = vDiff;
		this.f_distance = f_distance;
	}
}
;

class Line
{
	internal var x1: Number;
	internal var y1: Number;
	internal var x2: Number;
	internal var y2: Number;
	internal var afterMark: Mark;

	public function Line(x1: Number, y1: Number, x2: Number, y2: Number, afterMark: Mark)
	{
		this.x1 = x1;
		this.y1 = y1;
		this.x2 = x2;
		this.y2 = y2;
		this.afterMark = afterMark;
	}

	public function get length(): Number
	{
		return Math.sqrt(Math.pow(x1 - x2, 2) + Math.pow(y1 - y2, 2));
	}
}
;
