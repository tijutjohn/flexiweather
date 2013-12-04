package com.iblsoft.flexiweather.constants
{

	public class AnticollisionDisplayMode
	{
//		public static const DISPLACE_NOT_ALLOWED: String = 'notAllowed';
//		public static const DISPLACE_AUTOMATIC: String = 'automatic';
//		public static const DISPLACE_AUTOMATIC_SIMPLE: String = 'automaticSimple';
//		public static const DISPLACE_HIDE: String = 'hide';
		/** Place at desired location if possible, otherwise try do place around to a free space (inteligent labels which must be always displayed). */
		public static const DISPLACE_AROUND: String = 'displaceAround';
		/** Try do place around at desired location, if not free, hide it (KML labels). */
		public static const HIDE_IF_OCCUPIED: String = 'hideIfOccupied';
		/** Place at desired location even if it overlaps with something else. */
		public static const FIXED: String = 'fixed';

		public function AnticollisionDisplayMode()
		{
		}
	}
}
