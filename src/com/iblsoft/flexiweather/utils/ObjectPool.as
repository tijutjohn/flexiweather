package com.iblsoft.flexiweather.utils
{
	import flash.display.DisplayObject;
	import mx.core.ClassFactory;

	public class ObjectPool
	{
		public var maximumPooledObject: int = 20;
		public var tracingEnabled: Boolean;
		public var reuseObjects: Boolean = false;
		private var _pool: Array;
		public var name: String;
		public var itemRenderer: Class;
		private var _cntAdd: int = 0;
		private var _cntGet: int = 0;

		public function get length(): int
		{
			return _pool.length;
		}

		public function ObjectPool()
		{
			_pool = [];
		}

		public function addObject(object: Object): void
		{
			if (_pool.length >= maximumPooledObject)
			{
				//do not pool object, pool is full
				object = null;
				return;
			}
			var id: int = _pool.indexOf(object);
			if (id >= 0)
			{
				return;
			}
			_cntAdd++;
			_pool.push(object);
		}

		public function freeObject(object: Object): void
		{
//			var id: int = _pool.indexOf(object);
//			if (id >= 0)
//			{
//				_pool.splice(id, 1);
//			}
		}

		public function getObject(): Object
		{
			_cntGet++;
			var obj: Object;
			if (reuseObjects && _pool.length > 0)
			{
				obj = _pool.shift();
				if (obj is DisplayObject)
				{
					if ((obj as DisplayObject).parent)
					{
						addObject(obj);
						return null;
					}
				}
				else
				{
					if (obj is IObjectPoolObject)
					{
						if ((obj as IObjectPoolObject).isFree())
							return obj;
						else
							return null;
					}
				}
				return obj;
			}
			else
			{
				if (itemRenderer)
				{
					var newClass: ClassFactory = new ClassFactory(itemRenderer);
					var object: Object = newClass.newInstance();
					return object;
				}
			}
			return null;
		}
	}
}
