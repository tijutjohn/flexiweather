package com.iblsoft.flexiweather.utils
{
	import mx.collections.ArrayCollection;
	
	public class Storage
	{
		public static const LOADING: Boolean = false;
		public static const STORING: Boolean = true;
		
		internal var mb_mode: Boolean;
		
		public function Storage(b_mode: Boolean): void
		{
			mb_mode = b_mode;
		}
		
		public function serialize(s_key: String, o: Serializable): void
		{
			var restorePoint: Object = downLevel(s_key);
			try { 
				o.serialize(this);
			}
			finally {
				upLevel(restorePoint);
			} 
		}
		
		public function hasKey(s_key: String): Boolean
		{ return false; }	

		public function serializeString(s_key: String, s: String, s_default: String = null): String
		{ return s; }

		public function serializeInt(s_key: String, i: int, i_default: int = 0): int
		{ return i; }

		public function serializeUInt(s_key: String, i: uint, i_default: uint = 0): uint
		{ return i; }

		public function serializeBool(s_key: String, b: Boolean, b_default: Boolean = false): Boolean
		{ return b; }

		public function serializeNumber(s_key: String, f: Number, f_default: Number = NaN): Number
		{ return f; }

		public function serializeNonpersistentArrayCollection(
				s_key: String, a: ArrayCollection, c: Class): void
		{
			var i: int;
			var s: String;
			if(isLoading()) {
				a.removeAll();
				i = 0;
				while(true) {
					s = s_key + "." + i;
					if(!hasKey(s))
						break;
					a.addItem(__constructAndSerialize(s, c));
					++i; 
				}
			} else {
				for(i = 0; i < a.length; ++i) {
					s = s_key + "." + i;
					__serialize(s, a[i]);
				}
			}
		}

		public function serializeNonpersistentArray(
				s_key: String, a: Array, c: Class): void
		{
			var i: int;
			var s: String;
			if(isLoading()) {
				while(a.length > 0)
					a.pop();
				i = 0;
				while(true) {
					s = s_key + "." + i;
					if(!hasKey(s))
						break;
					a.push(__constructAndSerialize(s, c)); 
					++i; 
				}
			} else {
				for(i = 0; i < a.length; ++i) {
					s = s_key + "." + i;
					__serialize(s, a[i]);
				}
			}
		}
		
		public function serializeNonpersistentArrayMap(
				s_key: String, a: Array, cKey: Class, cValue: Class): void
		{
			var i: int;
			var s: String;
			var restorePointObject: Object;
			var key: Object;
			if(isLoading()) {
				while(a.length > 0)
					a.pop();
				i = 0;
				while(true) {
					s = s_key + "." + i;
					if(!hasKey(s))
						break;
					restorePointObject = downLevel(s);
					try {
						key = __constructAndSerialize("key", cKey); 
						var value: Object = __constructAndSerialize("value", cValue);
						a[key] = value;
					}
					finally { 
						upLevel(restorePointObject);
					}
					++i; 
				}
			} else {
				i = 0;
				for(key in a) {
					s = s_key + "." + i;
					restorePointObject = downLevel(s);
					try {
						__serialize("key", key);
						__serialize("value", a[key]);
					}
					finally { 
						upLevel(restorePointObject);
					}
					++i;
				}
			}
		}
		

		public function commit(): void
		{
		}
		
		protected function downLevel(s_key: String): Object
		{ return null; }

		protected function upLevel(restorePointObject: Object): void
		{}
		
		protected function __serialize(s_key: String, o: Object): void
		{
			if(o is Serializable)
				serialize(s_key, o as Serializable);
			else if(o is String)
				serializeString(s_key, o as String);
			else if(o is int)
				serializeInt(s_key, o as int);
			else if(o is uint)
				serializeUInt(s_key, o as uint);
			else if(o is Boolean)
				serializeBool(s_key, o as Boolean);
			else if(o is Number)
				serializeNumber(s_key, o as Number);
			else
				throw new Error("Unsupported serialization type '" + Class(o).toString() + "'");
			
		}

		protected function __constructAndSerialize(s_key: String, c: Class): Object
		{
			var o: Object;			
			if(c == String)
				o = serializeString(s_key, "");
			else if(c == int)
				o = serializeInt(s_key, 0);
			else if(c == uint)
				o = serializeUInt(s_key, 0);
			else if(c == Boolean)
				o = serializeBool(s_key, false);
			else if(c == Number)
				o = serializeNumber(s_key, 0.0);
			else {
				o = new c;
				if(o is Serializable)
					serialize(s_key, o as Serializable);
				else
					throw Error("Unsupported serialization type '" + c + "'");
			}
			return o;
		}
		
		public function isLoading(): Boolean
		{ return mb_mode == LOADING; }

		public function isStoring(): Boolean
		{ return mb_mode == STORING; }
	}
}