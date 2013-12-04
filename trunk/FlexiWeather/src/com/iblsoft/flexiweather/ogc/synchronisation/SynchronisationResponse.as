package com.iblsoft.flexiweather.ogc.synchronisation
{
	public class SynchronisationResponse
	{
		public static const SYNCHRONISED_EXACTLY: String = 'synchronisedExactly';
		public static const SYNCHRONISED_WITH_NEAREST_VALUE: String = 'synchronisedWithNearestValue';
		public static const ALREADY_SYNCHRONISED: String = 'alreadySynchronised';
		public static const SYNCHRONISATION_VALUE_NOT_FOUND: String = 'synchronisationValueNotFound';
		
		/**
		 * Returns is synchronisation was succesfully done or was not needed, because synchronised object has already set value to synchronised value
		 *  
		 * @param value
		 * @return 
		 * 
		 */		
		public static function wasSynchronised(value: String): Boolean
		{
			switch(value)
			{
				case SYNCHRONISED_EXACTLY:
				case SYNCHRONISED_WITH_NEAREST_VALUE:
				case ALREADY_SYNCHRONISED:
					return true;
			}
			
			return false;
		}
	}
}