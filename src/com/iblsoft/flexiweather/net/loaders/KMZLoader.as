package com.iblsoft.flexiweather.net.loaders
{
	import flash.utils.ByteArray;
	
	import mx.utils.ObjectUtil;

	public class KMZLoader extends BinaryLoader
	{
		public function KMZLoader()
		{
			super();
		}
		
		public static function isValidKMZ(data: Object): Boolean
		{
			if (data is ByteArray)
			{
				//we need to clone BYteArray, otherwise readded bytes will be removed from ByteArray
				var ba: ByteArray = data as ByteArray;
				
				var b0: int = ba.length > 0 ? ba.readUnsignedByte() : -1;
				var b1: int = ba.length > 1 ? ba.readUnsignedByte() : -1;
				
				ba.position = 0;			

				var isZIP: Boolean = b0 == 0x50 && b1 == 0x4B;
				if (isZIP)
					return true;
			}
			return false;
		}
	}
}
