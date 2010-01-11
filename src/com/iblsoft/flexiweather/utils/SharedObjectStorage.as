package com.iblsoft.flexiweather.utils
{
	import flash.net.SharedObject;
	
	public class SharedObjectStorage extends Storage
	{
		internal var m_sharedObject: SharedObject;
		internal var m_current: Object;
		 
		public function SharedObjectStorage(b_mode: Boolean, sharedObject: SharedObject)
		{
			super(b_mode);
			m_sharedObject = sharedObject;
			m_current = m_sharedObject.data;
			if(b_mode == Storage.STORING)
				for(var o: Object in m_current) {
					delete m_current[o];
				}
		}

		override public function hasKey(s_key: String): Boolean
		{
			return s_key in m_current;
		}	

		override public function serializeString(s_key: String, s: String, s_default: String = null): String
		{
			if(isLoading()) {
				var o: Object = m_current[s_key];
				if(o == null)
					return s_default; 
				return String(o);
			}
			else {
				m_current[s_key] = s;
				return s;
			}
		}
		
		override public function serializeInt(s_key: String, i: int, i_default: int = 0): int
		{
			if(isLoading()) {
				var o: Object = m_current[s_key];
				if(o == null)
					return i_default; 
				return int(o);
			}
			else {
				m_current[s_key] = i;
				return i;
			}
		}

		override public function serializeUInt(s_key: String, i: uint, i_default: uint = 0): uint
		{
			if(isLoading()) {
				var o: Object = m_current[s_key];
				if(o == null)
					return i_default; 
				return uint(o);
			}
			else {
				m_current[s_key] = i;
				return i;
			}
		}

		override public function serializeBool(s_key: String, b: Boolean, b_default: Boolean = false): Boolean
		{
			if(isLoading()) {
				var o: Object = m_current[s_key];
				if(o == null)
					return b_default; 
				return Boolean(o);
			}
			else {
				m_current[s_key] = b;
				return b;
			}
		}

		override public function serializeNumber(s_key: String, f: Number, f_default: Number = NaN): Number
		{
			if(isLoading()) {
				var o: Object = m_current[s_key];
				if(o == null)
					return f_default; 
				return Number(o);
			}
			else {
				m_current[s_key] = f;
				return f;
			}
		}
		
		override public function commit(): void
		{
			m_sharedObject.flush();
		}

		override protected function downLevel(s_key: String): Object
		{
			if(mb_mode == STORING)
				m_current[s_key] = new Object();
			var currentBackup: Object = m_current;
			m_current = m_current[s_key];
			return currentBackup;
		}

		override protected function upLevel(restorePoint: Object): void
		{
			m_current = restorePoint; 
		}
	}
}