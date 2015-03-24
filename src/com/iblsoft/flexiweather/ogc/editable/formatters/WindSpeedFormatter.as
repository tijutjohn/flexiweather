/***********************************************************************************************
 *
 *	Created:	24.03.2015
 *	Authors:	Franto Kormanak
 *
 *	Copyright (c) 2015, IBL Software Engineering spol. s r. o., <escrow@iblsoft.com>.
 *	All rights reserved. Unauthorised use, modification or redistribution is prohibited.
 *
 ***********************************************************************************************/

package com.iblsoft.flexiweather.ogc.editable.formatters
{
	import mx.formatters.Formatter;

	public class WindSpeedFormatter extends Formatter
	{
		public function WindSpeedFormatter()
		{
			super();
		}

		/**
		 *
		 */
		override public function format(value:Object):String
		{
			var ret: String = String(value);

			if (value is Number && value > 0)
				return(ret + ' kt');

			if (value == 0)
				return "STNR";

			return ret;
		}
	}
}