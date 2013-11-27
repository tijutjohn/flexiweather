package com.iblsoft.flexiweather.symbology
{
	import com.iblsoft.flexiweather.utils.CubicBezier;
	import com.iblsoft.flexiweather.utils.DistanceMarkingCurveRenderer;
	
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.CapsStyle;
	import flash.display.Graphics;
	import flash.display.LineScaleMode;
	import flash.geom.Point;
	import flash.geom.Rectangle;

	public class StyledLineCurveRenderer extends DistanceMarkingCurveRenderer
	{
		public static const STYLE_NONE: String = "None";
		public static const STYLE_SOLID: String = "Solid";
		public static const STYLE_DASHED: String = "Dashed";
		public static const STYLE_DOTTED: String = "Dotted";
		public static const STYLE_DASHDOT: String = "DashDot";
		public static const STYLE_DASHDOTDOT: String = "DashDotDot";
		public static const STYLE_ICING_STYLE: String = "IcingStyle";
		public static const FILL_STYLE_NONE: String = 'None';
		public static const FILL_STYLE_SOLID: String = 'Solid';
		public static const FILL_STYLE_HORIZONTAL_LINES: String = 'HorizontalLines';
		public static const FILL_STYLE_VERTICAL_LINES: String = 'VerticalLines';
		public static const FILL_STYLE_CROSING_LINES: String = 'CrossingLines';
		public static const FILL_STYLE_BACKWARD_DIAGONAL_LINES: String = 'BackwardDiagonalLines';
		public static const FILL_STYLE_FORWARD_DIAGONAL_LINES: String = 'ForwardDiagonalLines';
		public static const FILL_STYLE_CROSSING_DIAGONAL_LINES: String = 'CrossingDiagonalLines';
		// style variables
		protected var mf_thickness: Number;
		protected var mi_color: uint;
		protected var mf_alpha: Number;
		protected var ms_style: String;
		protected var ms_fillStyle: String;
		protected var mi_fillColor: uint;
		// runtime variables
		//protected var mf_currentDistance: Number = 0; 
		//protected var mf_lastMarkDistance: Number = -1000; 
		protected var mf_markStep: Number = 6;
		protected var mf_paternStep: Number = 6;
		protected var mi_lastPaternStep: int = 0;
		protected var mi_counter: int = 0;
		protected var mf_actPaternDistance: Number = 0;
		protected var ma_paternDef: Array;
		protected var mp_lastMarkPoint: Point;
		protected var mp_actMarkPoint: Point;
		protected var mb_markChanged: Boolean = false;
		protected var ma_markParts: Array = new Array();
		protected var mf_lastPaternRatio: Number = 0;
		protected var mp_fIcingPoint: Point;

		public function get color(): uint
		{
			return mi_color;
		}
		
		public function set color(value: uint): void
		{
			if (value != mi_color) 
			{
				mi_color = value;
			}
		}
		
		public function get fillColor(): uint
		{
			return mi_fillColor;
		}
		
		public function set fillColor(value: uint): void
		{
			if (value != mi_fillColor) 
			{
				mi_fillColor = value;
			}
		}
		
		public function set thickness(value: Number): void
		{
			mf_thickness = value;
		}

		public function get thickness(): Number
		{
			return (mf_thickness);
		}

		function StyledLineCurveRenderer(g: Graphics,
				f_thickness: Number, i_color: uint, f_alpha: Number,
				s_style: String, s_fillStyle: String = 'None', i_fillColor: uint = 0x000000)
		{
			super(g);
			mi_color = i_color;
			mf_alpha = f_alpha;
			ms_style = s_style;
			ms_fillStyle = s_fillStyle;
			mi_fillColor = i_fillColor;
			thickness = f_thickness;
			switch (ms_style)
			{
				case StyledLineCurveRenderer.STYLE_DASHED:
				{
					mf_markStep = mf_thickness * 2;
					mf_paternStep = mf_thickness * 2;
					ma_paternDef = new Array(1, 1, 1, 1, 1, 0, 0, 0, 0, 0);
					break;
				}
				case StyledLineCurveRenderer.STYLE_ICING_STYLE:
				{
					mf_markStep = mf_thickness * 2;
					mf_paternStep = mf_thickness * 2;
					ma_paternDef = new Array(1, 1, 1, 1, 1, 0, 0, 0, 0, 0);
					break;
				}
				case StyledLineCurveRenderer.STYLE_DOTTED:
				{
					mf_markStep = mf_thickness * 2;
					mf_paternStep = mf_thickness * 2;
					ma_paternDef = new Array(1, 1, 0, 0);
					break;
				}
				case StyledLineCurveRenderer.STYLE_DASHDOT:
				{
					mf_markStep = mf_thickness * 1;
					mf_paternStep = mf_thickness * 1;
					ma_paternDef = new Array(1, 1, 1, 1, 1, 0, 0, 1, 1, 0, 0);
					break;
				}
				case StyledLineCurveRenderer.STYLE_DASHDOTDOT:
				{
					mf_markStep = mf_thickness * 2;
					mf_paternStep = mf_thickness * 2;
					ma_paternDef = new Array(1, 1, 1, 1, 1, 0, 0, 1, 1, 0, 0, 1, 1, 0, 0);
					break;
				}
				default:
				{
					mf_markStep = mf_thickness * 6;
					break;
				}
			}
		}

		override public function started(x: Number, y: Number): void
		{
			setDefaultLineStyle();
			
			beginFill(mi_fillColor);
			
			m_graphics.moveTo(x, y);
			mp_actMarkPoint = null;
			mp_lastMarkPoint = null;
			mf_actPaternDistance = 0;
			mi_lastPaternStep = 0;
			mi_counter = -1;
			mark(x, y);
			
		}

		override public function finished(x: Number, y: Number): void
		{
			endFill();
			m_graphics.moveTo(x, y);
		}

		override public function moveTo(x: Number, y: Number): void
		{
			m_lastX = x;
			m_lastY = y;
		}

		/**
		 *
		 */
		override public function curveTo(controlX: Number, controlY: Number, anchorX: Number, anchorY: Number): void
		{
			CubicBezier.drawCurve(this,
					new Point(m_lastX, m_lastY),
					new Point(controlX, controlY),
					new Point(controlX, controlY),
					new Point(anchorX, anchorY));
		}

		/**
		 * Default implemetation which creates a mark each 10 pixels.
		 * Reimplement this method, it's not necessary to call this one.
		 **/
		override protected function mark(x: Number, y: Number): void
		{
			nextMarkDistance += mf_markStep;
			if (mp_actMarkPoint == null)
				mp_lastMarkPoint = new Point(x, y);
			else
				mp_lastMarkPoint = mp_actMarkPoint.clone();
			mp_actMarkPoint = new Point(x, y);
			mb_markChanged = true;
			++mi_counter;
		}

		/**
		 *
		 */
		protected function setDefaultLineStyle(useAlpha: Boolean = true): void
		{
			if (useAlpha)
				m_graphics.lineStyle(mf_thickness, mi_color, mf_alpha, false, LineScaleMode.NONE, CapsStyle.SQUARE);
			else
				m_graphics.lineStyle(mf_thickness, mi_color, 0, false, LineScaleMode.NONE, CapsStyle.SQUARE);
		}

		/**
		 *
		 */
		protected function _lineTo(f_x: Number, f_y: Number): void
		{
			var dashDotOffset: int;
			switch (ms_style)
			{
				case StyledLineCurveRenderer.STYLE_SOLID:
				default:
				{
					m_graphics.lineTo(f_x, f_y);
					break;
				}
				case StyledLineCurveRenderer.STYLE_DOTTED:
				{
					if (mi_counter % 2 == 0)
					{
						setDefaultLineStyle();
						m_graphics.lineTo(f_x, f_y);
					}
					else
					{
						setDefaultLineStyle(false);
						m_graphics.lineTo(f_x, f_y);
					}
					break;
				}
				case StyledLineCurveRenderer.STYLE_DASHED:
				{
					if (mi_counter % 4 == 0)
					{
						setDefaultLineStyle();
						m_graphics.lineTo(f_x, f_y);
					}
					else
					{
						setDefaultLineStyle(false);
						m_graphics.lineTo(f_x, f_y);
					}
					break;
				}
				case StyledLineCurveRenderer.STYLE_ICING_STYLE:
				{
					if (mi_counter % 6 < 4)
					{
						setDefaultLineStyle();
						m_graphics.lineTo(f_x, f_y);
					}
					else
					{
						setDefaultLineStyle(false);
						m_graphics.lineTo(f_x, f_y);
					}
					if ((mi_counter % 6) == 2)
						mp_fIcingPoint = new Point(f_x, f_y);
					else if ((mi_counter % 6) == 3)
					{
						// CREATE NORMAL LINE
						var ePoint: Point = new Point(f_x, f_y);
						var vect: Point = ePoint.subtract(mp_fIcingPoint);
						var cPoint: Point = mp_fIcingPoint.clone();
						cPoint.x = cPoint.x + (vect.x / 2);
						cPoint.y = cPoint.y + (vect.y / 2);
						vect.normalize(1);
						vect = normalVector(vect);
						m_graphics.moveTo(cPoint.x, cPoint.y);
						m_graphics.lineTo(cPoint.x + (vect.x * 2), cPoint.y + (vect.y * 2));
						m_graphics.moveTo(f_x, f_y);
					}
					break;
				}
				/*case StyledLineCurveRenderer.STYLE_DOTTED:
				case StyledLineCurveRenderer.STYLE_DASHED:
					if(mi_counter % 2 == 0) {
						setDefaultLineStyle();
						m_graphics.lineTo(f_x, f_y);
					}
					else {
						setDefaultLineStyle(false);
						m_graphics.lineTo(f_x, f_y);
						//m_graphics.moveTo(f_x, f_y);
					}
					break;

				case StyledLineCurveRenderer.STYLE_DASHDOT:
					if (mi_counter == 0){
						setDefaultLineStyle(false);
						m_graphics.lineTo(f_x, f_y);
						//m_graphics.moveTo(f_x, f_y);
					} else if ((mi_counter > 0) && (mi_counter <= 3)){
						setDefaultLineStyle();
						m_graphics.lineTo(f_x, f_y);
					} else if (mi_counter == 4){
						setDefaultLineStyle(false);
						m_graphics.lineTo(f_x, f_y);
						//m_graphics.moveTo(f_x, f_y);
					} else if (mi_counter == 5){
						setDefaultLineStyle();
						m_graphics.lineTo(f_x, f_y);
						mi_counter = -1;
					}

					break;
				*/
				case StyledLineCurveRenderer.STYLE_DASHDOT:
				{
					dashDotOffset = mi_counter % 8;
					if (dashDotOffset < 3)
					{
						setDefaultLineStyle();
						m_graphics.lineTo(f_x, f_y);
					}
					else if ((dashDotOffset >= 3) && (dashDotOffset < 5))
					{
						setDefaultLineStyle(false);
						m_graphics.lineTo(f_x, f_y);
					}
					else if ((dashDotOffset >= 5) && (dashDotOffset < 6))
					{
						setDefaultLineStyle();
						m_graphics.lineTo(f_x, f_y);
					}
					else
					{
						setDefaultLineStyle(false);
						m_graphics.lineTo(f_x, f_y);
					}
					break;
				}
				case StyledLineCurveRenderer.STYLE_DASHDOTDOT:
				{
					dashDotOffset = mi_counter % 11;
					if (dashDotOffset < 3)
					{
						setDefaultLineStyle();
						m_graphics.lineTo(f_x, f_y);
					}
					else if ((dashDotOffset >= 3) && (dashDotOffset < 5))
					{
						setDefaultLineStyle(false);
						m_graphics.lineTo(f_x, f_y);
					}
					else if ((dashDotOffset >= 5) && (dashDotOffset < 6))
					{
						setDefaultLineStyle();
						m_graphics.lineTo(f_x, f_y);
					}
					else if ((dashDotOffset >= 6) && (dashDotOffset < 8))
					{
						setDefaultLineStyle(false);
						m_graphics.lineTo(f_x, f_y);
					}
					else if ((dashDotOffset >= 8) && (dashDotOffset < 9))
					{
						setDefaultLineStyle();
						m_graphics.lineTo(f_x, f_y);
					}
					else
					{
						setDefaultLineStyle(false);
						m_graphics.lineTo(f_x, f_y);
					}
					break;
				}
			}
			m_lastX = f_x;
			m_lastY = f_y;
		}

		
		protected function beginFill(i_fillColor: uint): void
		{
//			if (isCurveClosed() && (ms_fillStyle != StyledLineCurveRenderer.FILL_STYLE_NONE)){
			if (ms_fillStyle != StyledLineCurveRenderer.FILL_STYLE_NONE)
			{
				m_graphics.beginBitmapFill(createFillBitmap(i_fillColor), null, true, false);
			}
		}
		
		/**
		 * 
		 */
		protected function endFill(): void
		{
			if (ms_fillStyle != StyledLineCurveRenderer.FILL_STYLE_NONE)
			{
				m_graphics.endFill();
			}
		}
		
		/**
		 * 
		 */
		protected function createFillBitmap(i_fillColor: uint): BitmapData
		{
			var fillBitmapData: BitmapData = new BitmapData(16, 16, true, 0x00FFFFFF);//, 0x00000000);
			var ix: uint;
			var iy: uint;
			
			var nBitmap: Bitmap = new Bitmap(fillBitmapData);
			
			i_fillColor = getHexARGB(i_fillColor);
			
			switch (ms_fillStyle){
				case StyledLineCurveRenderer.FILL_STYLE_SOLID:
					fillBitmapData.fillRect(new Rectangle(0, 0, 16, 16), i_fillColor); //mi_fillColor);
					break;
				case StyledLineCurveRenderer.FILL_STYLE_HORIZONTAL_LINES:
					for (ix = 0; ix < 16; ix++){
						for (iy = 0; iy < 16; iy = iy + 8){
							fillBitmapData.setPixel32(ix, iy, i_fillColor); //mi_fillColor);
							//fillBitmapData.setPixel(ix, iy, mi_fillColor);
						}
					}
					break;
				
				case StyledLineCurveRenderer.FILL_STYLE_VERTICAL_LINES:
					for (ix = 0; ix < 16; ix = ix + 8){
						for (iy = 0; iy < 16; iy++){
							fillBitmapData.setPixel32(ix, iy, i_fillColor);
						}
					}
					break;
				
				case StyledLineCurveRenderer.FILL_STYLE_CROSING_LINES:
					for (ix = 0; ix < 16; ix++){
						for (iy = 0; iy < 16; iy = iy + 8){
							fillBitmapData.setPixel32(ix, iy, i_fillColor);
						}
					}
					for (ix = 0; ix < 16; ix = ix + 8){
						for (iy = 0; iy < 16; iy++){
							fillBitmapData.setPixel32(ix, iy,i_fillColor);
						}
					}
					break;
			}
			
			return(nBitmap.bitmapData);
		}
		
		/**
		 * 
		 */
		protected function getHexARGB(color: uint, n_alpha: Number = 255): uint
		{
			var r: uint = ((color & 0xFF0000) >> 16);
			var g: uint = ((color & 0x00FF00) >> 8);
			var b: uint = ((color & 0x0000FF));
			
			var ret: uint = n_alpha << 24;
			ret += (r << 16);
			ret += (g << 8);
			ret += (b);
			
			return(ret);
		}
		
		
		/**
		 *
		 */
		protected function drawPatern(x: Number, y: Number, paternRatioFrom: Number, paternRatioTo: Number): void
		{
			var nPoint: Point = new Point(x - m_lastX, y - m_lastY);
			var unitPoint: Point = unitVector(nPoint);
			var paternDef: Array = ma_paternDef;
			var paternRatioDef: Array = new Array();
			var mStep: Number = (1 / (paternDef.length - 1)) * mf_paternStep;
			var actPaternStart: Number = mf_actPaternDistance;
			var actPaternStartP: Number = actPaternStart / mf_paternStep;
			var actPaternEnd: Number = mf_actPaternDistance + nPoint.length;
			var actPaternEndP: Number = actPaternStartP + (nPoint.length / mf_paternStep);
			var tmpPaternStep: Number = mi_lastPaternStep; //Math.floor(mf_actPaternDistance % mf_paternStep) % paternDef.length;
			var actX: Number = m_lastX + (unitPoint.x * mStep);
			var actY: Number = m_lastY + (unitPoint.y * mStep);
			var tmpActDistance: Number = actPaternStart + mStep;
			tmpPaternStep = (tmpPaternStep + 1) % paternDef.length;
			// GO THRUE PATERN STEPS
			while (tmpActDistance <= actPaternEnd)
			{
				mi_lastPaternStep = tmpPaternStep;
				actX = actX + (unitPoint.x * mStep);
				actY = actY + (unitPoint.y * mStep);
				if (paternDef[tmpPaternStep] == 1)
				{
					setDefaultLineStyle();
					m_graphics.lineTo(actX, actY);
				}
				else
				{
					setDefaultLineStyle(false);
					m_graphics.lineTo(actX, actY);
				}
				tmpActDistance = tmpActDistance + mStep;
				tmpPaternStep = (tmpPaternStep + 1) % paternDef.length;
			}
			mf_actPaternDistance = actPaternEnd;
		}

		/**
		 * Default implemnetation which just draw a line.
		 * Reimplement this method, it's not necessary to call this one.
		 **/
		override protected function betweenMarkLineTo(x: Number, y: Number): void
		{
			_lineTo(x, y);
		}

		/**
		 *
		 */
		protected function getPointOnSegment(s_x: Number, s_y: Number, e_x: Number, e_y: Number, factor: Number): Point
		{
			return (new Point(s_x + ((e_x - s_x) * factor), s_y + ((e_y - s_y) * factor)));
		}

		/**
		 *
		 */
		protected function normalVector(tPoint: Point, left: Boolean = true): Point
		{
			var unitVector: Point = unitVector(tPoint);
			if (left)
				return (new Point(-unitVector.y, unitVector.x));
			else
				return (new Point(unitVector.y, -unitVector.x));
		}

		/**
		 *
		 */
		protected function unitVector(tPoint: Point): Point
		{
			var mag: Number = magnitudeVector(tPoint);
			if (mag > 0)
				return (new Point(tPoint.x / mag, tPoint.y / mag));
			else
				return (new Point(0, 0));
		}

		/**
		 *
		 */
		protected function magnitudeVector(tPoint: Point): Number
		{
			return (Math.sqrt((tPoint.x * tPoint.x) + (tPoint.y * tPoint.y)));
		}
	}
}
