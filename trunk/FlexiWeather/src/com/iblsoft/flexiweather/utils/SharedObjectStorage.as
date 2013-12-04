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
			if (b_mode == Storage.STORING)
			{
				for (var o: Object in m_current)
				{
					delete m_current[o];
				}
			}
		}

		override public function hasKey(s_key: String, i_index: uint /* = NONINDEXED*/): Boolean
		{
			s_key = fixKey(s_key, i_index);
			return s_key in m_current;
		}

		override protected function __serializeString(s_key: String, i_index: uint /* = NONINDEXED*/, s: String, s_default: String = null): String
		{
			s_key = fixKey(s_key, i_index);
			if (isLoading())
			{
				var o: Object = m_current[s_key];
				//TODO Jozef, please check if this is correct behaviour
				if (o == null || o == "")
					return s_default;
				return String(o);
			}
			else
			{
				m_current[s_key] = s;
				return s;
			}
		}

		override protected function __serializeInt(s_key: String, i_index: uint /* = NONINDEXED*/, i: int, i_default: int = 0): int
		{
			s_key = fixKey(s_key, i_index);
			if (isLoading())
			{
				var o: Object = m_current[s_key];
				if (o == null)
					return i_default;
				return int(o);
			}
			else
			{
				m_current[s_key] = i;
				return i;
			}
		}

		override protected function __serializeUInt(s_key: String, i_index: uint /* = NONINDEXED*/, i: uint, i_default: uint = 0): uint
		{
			s_key = fixKey(s_key, i_index);
			if (isLoading())
			{
				var o: Object = m_current[s_key];
				if (o == null)
					return i_default;
				return uint(o);
			}
			else
			{
				m_current[s_key] = i;
				return i;
			}
		}

		override protected function __serializeBool(s_key: String, i_index: uint /* = NONINDEXED*/, b: Boolean, b_default: Boolean = false): Boolean
		{
			s_key = fixKey(s_key, i_index);
			if (isLoading())
			{
				var o: Object = m_current[s_key];
				if (o == null)
					return b_default;
				return Boolean(o);
			}
			else
			{
				m_current[s_key] = b;
				return b;
			}
		}

		override protected function __serializeNumber(s_key: String, i_index: uint /* = NONINDEXED*/, f: Number, f_default: Number = NaN): Number
		{
			s_key = fixKey(s_key, i_index);
			if (isLoading())
			{
				var o: Object = m_current[s_key];
				if (o == null)
					return f_default;
				return Number(o);
			}
			else
			{
				m_current[s_key] = f;
				return f;
			}
		}

		override public function commit(): void
		{
			m_sharedObject.flush();
		}

		override protected function downLevel(s_key: String, i_index: uint /*= NONINDEXED*/): Object
		{
			s_key = fixKey(s_key, i_index);
			if (mb_mode == STORING && !(s_key in m_current))
				m_current[s_key] = new Object();
			var currentBackup: Object = m_current;
			m_current = m_current[s_key];
			return currentBackup;
		}

		override protected function upLevel(restorePoint: Object): void
		{
			m_current = restorePoint;
		}

		private function fixKey(s_key: String, i_index: uint): String
		{
			if (i_index != NONINDEXED)
				s_key += "." + String(i_index);
			return s_key;
		}
	}
}
