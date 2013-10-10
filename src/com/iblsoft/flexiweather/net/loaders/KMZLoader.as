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
				data = ObjectUtil.clone(data) as ByteArray;
				var b0: int = data.length > 0 ? data.readUnsignedByte() : -1;
				var b1: int = data.length > 1 ? data.readUnsignedByte() : -1;
				var isZIP: Boolean = b0 == 0x50 && b1 == 0x4B;
				if (isZIP)
					return true;
			}
			return false;
		}
	}
}
