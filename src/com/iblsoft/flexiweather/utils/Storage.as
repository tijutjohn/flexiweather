package com.iblsoft.flexiweather.utils
{
	import flash.utils.getDefinitionByName;
	import flash.utils.getQualifiedClassName;
	
	import mx.collections.ArrayCollection;
	
	public class Storage
	{
		public static const LOADING: Boolean = false;
		public static const STORING: Boolean = true;
		public static const NONINDEXED: uint = 0xFFFFFFFF;
		
		internal var mb_mode: Boolean;
		
		public function Storage(b_mode: Boolean): void
		{
			mb_mode = b_mode;
		}
		
		public function serialize(s_key: String, o: Serializable): void
		{ __serialize(s_key, NONINDEXED, o); }

		public final function serializeString(s_key: String, s: String, s_default: String = null): String
		{ return __serializeString(s_key, NONINDEXED, s, s_default); }

		public final function serializeInt(s_key: String, i: int, i_default: int = 0): int
		{ return __serializeInt(s_key, NONINDEXED, i, i_default); }

		public final function serializeUInt(s_key: String, i: uint, i_default: uint = 0): uint
		{ return __serializeUInt(s_key, NONINDEXED, i, i_default); }

		public final function serializeBool(s_key: String, b: Boolean, b_default: Boolean = false): Boolean
		{ return __serializeBool(s_key, NONINDEXED, b, b_default); }

		public final function serializeNumber(s_key: String, f: Number, f_default: Number = NaN): Number
		{ return __serializeNumber(s_key, NONINDEXED, f, f_default); }

		public final function serializePersistentArrayCollection(
			s_key: String, a: ArrayCollection, c: Class): void
		{
			serializePersistentArray(s_key, a.toArray(), c);
		}
		
		public final function serializePersistentArray(
			s_key: String, a: Array, baseClass: Class): void
		{
			var i: int;
			var s: String;
			var s_class: String;
			var restorePointObject: Object;
			if(isLoading()) {
				while(a.length > 0)
					a.pop();
				i = 0;
				while(true) {
					if(!hasKey(s_key, i))
						break;
					restorePointObject = downLevel(s_key, i);
					var c: Class = null; 
					try {
						s_class = __serializeString("class", NONINDEXED, null);
						try {
							c = Class(getDefinitionByName(s_class));
						}
						catch(e: ReferenceError) {
							throw StorageException("Unknown persistent class '" + s_class + "': " + e.message);
						}
					}
					finally { 
						upLevel(restorePointObject);
					}
					if(c as baseClass == null) {
						throw StorageException("Unable to retype class '" + s_class + "' to '" + String(baseClass) + "'");
					}
					a.push(__constructAndSerialize(s_key, i, c)); 
					++i; 
				}
			} else {
				for(i = 0; i < a.length; ++i) {
					restorePointObject = downLevel(s_key, i);
					try {
						s_class = getQualifiedClassName(a[i]);
						__serializeString("class", NONINDEXED, s_class);
					}
					finally { 
						upLevel(restorePointObject);
					}
					__serialize(s_key, i, a[i]);
				}
			}
		}

		public final function serializeNonpersistentArrayCollection(
				s_key: String, a: ArrayCollection, c: Class): void
		{
			serializeNonpersistentArray(s_key, a.toArray(), c);
		}

		public final function serializeNonpersistentArray(
				s_key: String, a: Array, c: Class): void
		{
			var i: int;
			var s: String;
			if(isLoading()) {
				while(a.length > 0)
					a.pop();
				i = 0;
				while(true) {
					if(!hasKey(s_key, i))
						break;
					a.push(__constructAndSerialize(s_key, i, c)); 
					++i; 
				}
			} else {
				for(i = 0; i < a.length; ++i) {
					__serialize(s_key, i, a[i]);
				}
			}
		}
		
		public final function serializeNonpersistentArrayMap(
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
					if(!hasKey(s_key, i))
						break;
					restorePointObject = downLevel(s_key, i);
					try {
						key = __constructAndSerialize("key", NONINDEXED, cKey); 
						var value: Object = __constructAndSerialize("value", NONINDEXED, cValue);
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
					restorePointObject = downLevel(s_key, i);
					try {
						__serialize("key", NONINDEXED, key);
						__serialize("value", NONINDEXED, a[key]);
					}
					finally { 
						upLevel(restorePointObject);
					}
					++i;
				}
			}
		}

		public function serializeWithCustomFunction(s_key: String, serializeFunction: Function): void
		{
			var restorePoint: Object = downLevel(s_key, NONINDEXED);
			if(restorePoint == null)
				throw StorageException("Failed to access storage node '" + s_key + "'");
			try { 
				serializeFunction(this);
			}
			finally {
				upLevel(restorePoint);
			}
		}
		
		public function commit(): void
		{
		}
		
		protected function downLevel(s_key: String, i_index: uint/* = NONINDEXED*/): Object
		{ return null; }

		protected function upLevel(restorePointObject: Object): void
		{}
		
		public function hasKey(s_key: String, i_index: uint/* = NONINDEXED*/): Boolean
		{ return false; }	

		protected function __serialize(s_key: String, i_index: uint/* = NONINDEXED*/, o: Object): Object
		{
			if(o is Serializable) {
				var restorePoint: Object = downLevel(s_key, i_index);
				if(restorePoint == null)
					throw StorageException("Failed to access storage node '" + s_key + "'");
				try { 
					o.serialize(this);
				}
				finally {
					upLevel(restorePoint);
				}
			}
			else if(o is String)
				__serializeString(s_key, i_index, o as String);
			else if(o is int)
				__serializeInt(s_key, i_index, o as int);
			else if(o is uint)
				__serializeUInt(s_key, i_index, o as uint);
			else if(o is Boolean)
				__serializeBool(s_key, i_index, o as Boolean);
			else if(o is Number)
				__serializeNumber(s_key, i_index, o as Number);
			else
				throw new Error("Unsupported serialization type '" + Class(o).toString() + "'");
			return o; 
		}

		protected function __serializeString(s_key: String, i_index: uint/* = NONINDEXED*/, s: String, s_default: String = null): String
		{ return s; }

		protected function __serializeInt(s_key: String, i_index: uint/* = NONINDEXED*/, i: int, i_default: int = 0): int
		{ return i; }

		protected function __serializeUInt(s_key: String, i_index: uint/* = NONINDEXED*/, i: uint, i_default: uint = 0): uint
		{ return i; }

		protected function __serializeBool(s_key: String, i_index: uint/* = NONINDEXED*/, b: Boolean, b_default: Boolean = false): Boolean
		{ return b; }

		protected function __serializeNumber(s_key: String, i_index: uint/* = NONINDEXED*/, f: Number, f_default: Number = NaN): Number
		{ return f; }

		protected function __constructAndSerialize(s_key: String, i_index: uint/* = NONINDEXED*/, c: Class): Object
		{
			var o: Object;			
			if(c == String)
				o = __serializeString(s_key, i_index, "");
			else if(c == int)
				o = __serializeInt(s_key, i_index, 0);
			else if(c == uint)
				o = __serializeUInt(s_key, i_index, 0);
			else if(c == Boolean)
				o = __serializeBool(s_key, i_index, false);
			else if(c == Number)
				o = __serializeNumber(s_key, i_index, 0.0);
			else {
				o = new c;
				if(o is Serializable)
					__serialize(s_key, i_index, o as Serializable);
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