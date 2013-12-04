package com.iblsoft.utils
{

	public class ColorGradient
	{
		protected var ma_values: Array = null;
		protected var ma_colors: Array = null;

		public function ColorGradient(a_values: Array, a_colors: Array)
		{
			ma_values = a_values;
			ma_colors = a_colors;
		}

		private function getInterpolatedColorForValue(f_value: Number, a_values: Array, a_colors: Array): uint
		{
			var i_rangeIndex: int = 0;
			for (var s_i: String in a_values)
			{
				var i: int = int(s_i);
				if (f_value < a_values[i])
					break;
				i_rangeIndex = i + 1;
			}
			if (i_rangeIndex == 0)
				return a_colors[0];
			if (i_rangeIndex == a_values.length)
				return a_colors[a_values.length - 1];
			var f_min: Number = a_values[i_rangeIndex - 1];
			var f_max: Number = a_values[i_rangeIndex];
			var colorMin: uint = a_colors[i_rangeIndex - 1];
			var colorMax: uint = a_colors[i_rangeIndex];
			var f_factor: Number = (f_value - f_min) / (f_max - f_min);
			var aMin: uint = colorMin >>> 24;
			var rMin: uint = (colorMin << 8) >>> 24;
			var gMin: uint = (colorMin << 16) >>> 24;
			var bMin: uint = (colorMin << 24) >>> 24;
			var aMax: uint = colorMax >> 24;
			var rMax: uint = (colorMax << 8) >>> 24;
			var gMax: uint = (colorMax << 16) >>> 24;
			var bMax: uint = (colorMax << 24) >>> 24;
			var a: uint = f_factor * (aMax - aMin) + aMin;
			var r: uint = f_factor * (rMax - rMin) + rMin;
			var g: uint = f_factor * (gMax - gMin) + gMin;
			var b: uint = f_factor * (bMax - bMin) + bMin;
			return b + (g << 8) + (r << 16) + (a << 24);
		}

		public function getColorForValue(f_value: Number): uint
		{
			var i_rangeIndex: int = 0;
			for (var s_i: String in ma_values)
			{
				var i: int = int(s_i);
				if (f_value < ma_values[i])
					break;
				i_rangeIndex = i + 1;
			}
			if (i_rangeIndex == 0)
				return ma_colors[0];
			if (i_rangeIndex == ma_values.length)
				return ma_colors[ma_values.length - 1];
			var f_min: Number = ma_values[i_rangeIndex - 1];
			var f_max: Number = ma_values[i_rangeIndex];
			var colorMin: uint = ma_colors[i_rangeIndex - 1];
			var colorMax: uint = ma_colors[i_rangeIndex];
			var f_factor: Number = (f_value - f_min) / (f_max - f_min);
			var aMin: uint = colorMin >>> 24;
			var rMin: uint = (colorMin << 8) >>> 24;
			var gMin: uint = (colorMin << 16) >>> 24;
			var bMin: uint = (colorMin << 24) >>> 24;
			var aMax: uint = colorMax >> 24;
			var rMax: uint = (colorMax << 8) >>> 24;
			var gMax: uint = (colorMax << 16) >>> 24;
			var bMax: uint = (colorMax << 24) >>> 24;
			var a: uint = f_factor * (aMax - aMin) + aMin;
			var r: uint = f_factor * (rMax - rMin) + rMin;
			var g: uint = f_factor * (gMax - gMin) + gMin;
			var b: uint = f_factor * (bMax - bMin) + bMin;
			return b + (g << 8) + (r << 16) + (a << 24);
		}

		public function get minimumValue(): Number
		{
			return ma_values[0];
		}

		public function get maximumValue(): Number
		{
			return ma_values[ma_values.length - 1];
		}
	}
}
