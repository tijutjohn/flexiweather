package com.iblsoft.flexiweather.widgets.basicauth.data
{
	import com.iblsoft.flexiweather.utils.Serializable;
	import com.iblsoft.flexiweather.utils.Storage;

	public class BasicAuthAccount implements Serializable
	{
		public var name: String;
		public var password: String;
		public var domain: String;
		public var realm: String;

		public function BasicAuthAccount(name: String = null, password: String = null, domain: String = null, realm: String = null)
		{
			this.name = name;
			this.password = password;
			this.domain = domain;
			this.realm = realm;
		}

		public function serialize(storage: Storage): void
		{
			if (storage.isLoading())
			{
				name = storage.serializeString('name', name);
				password = storage.serializeString('password', password);
				domain = storage.serializeString('domain', domain);
				realm = storage.serializeString('realm', realm);
			}
			else
			{
				storage.serializeString('name', name);
				storage.serializeString('password', password);
				storage.serializeString('domain', domain);
				storage.serializeString('realm', realm);
			}
		}

		public function toString(): String
		{
			var str: String = "BasicAuthAccount: ";
			if (name)
				str += " name: " + name;
			if (password)
				str += " password: " + password;
			if (domain)
				str += " domain: " + domain;
			if (realm)
				str += " realm: " + realm;
			return str;
		}
	}
}
