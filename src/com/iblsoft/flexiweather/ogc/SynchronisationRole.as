package com.iblsoft.flexiweather.ogc
{

	public class SynchronisationRole
	{
		public static const PRIMARY: String = 'primary';
		public static const SUB_PRIMARY: String = 'subPrimary';
		public static const NONE: String = 'none';
		public var role: String;

		public function get isPrimary(): Boolean
		{
			return (role == PRIMARY);
		}

		public function SynchronisationRole(l_role: String = NONE)
		{
			setRole(l_role);
		}

		public function setRole(l_role: String): void
		{
			role = l_role;
		}
	}
}
