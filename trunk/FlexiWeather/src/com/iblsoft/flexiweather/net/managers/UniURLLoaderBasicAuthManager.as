package com.iblsoft.flexiweather.net.managers
{
	import com.iblsoft.flexiweather.net.data.UniURLLoaderData;
	import com.iblsoft.flexiweather.net.events.UniURLLoaderEvent;
	import com.iblsoft.flexiweather.net.loaders.AbstractURLLoader;
	import com.iblsoft.flexiweather.utils.SharedObjectStorage;
	import com.iblsoft.flexiweather.utils.Storage;
	import com.iblsoft.flexiweather.widgets.basicauth.data.BasicAuthAccount;
	import flash.events.EventDispatcher;
	import flash.net.SharedObject;
	import flash.net.URLRequest;
	import flash.utils.Dictionary;
	import mx.utils.URLUtil;

	/**
	 * Application needs valid applicationName to be set, to work correctly for different applications.  Name must consists of letters, numbers and _. Other characters are not allowed, bcause of SharedObject limitations.
	 * @author fkormanak
	 *
	 */
	public class UniURLLoaderBasicAuthManager extends EventDispatcher
	{
		private var _applicationName: String;
		private var _waitingForCredentials: Dictionary;
		private var _requests: Dictionary;
		private var _accounts: Array;
		public var authenticated: Boolean;
		private static var _instance: UniURLLoaderBasicAuthManager;

		public function get applicationName(): String
		{
			return _applicationName;
		}

		/**
		 * Name must consists of letters, numbers and _. Other characters are not allowed, bcause of SharedObject limitations
		 * @param value
		 *
		 */
		public function set applicationName(value: String): void
		{
			if (value)
			{
				//remove spaces, it shareObject can not have spaces in name
				value = value.split(' ').join('');
			}
			_applicationName = value;
			loadAccounts();
		}

		public static function get instance(): UniURLLoaderBasicAuthManager
		{
			if (!_instance)
				_instance = new UniURLLoaderBasicAuthManager();
			return _instance;
		}

		public function UniURLLoaderBasicAuthManager()
		{
			_accounts = [];
			_requests = new Dictionary();
			_waitingForCredentials = new Dictionary();
			applicationName = '';
//			loadAccounts();
		}

		/**
		 * Check if BasicAuth credentials already exists. Domain is extracted from request parameter
		 * @param request
		 * @param realm
		 * @return
		 *
		 */
		public function useBasicAuth(request: URLRequest, realm: String): Boolean
		{
			var domain: String = getDomain(request);
			return useBasicAuthForDomain(domain, realm);
		}

		/**
		 * Check if BasicAuth credentials already exists.
		 * @param request
		 * @param realm
		 * @return
		 *
		 */
		public function useBasicAuthForDomain(domain: String, realm: String): Boolean
		{
			var account: BasicAuthAccount = getAccountForDomain(domain, realm);
			return (account != null);
		}

		/**********************************************************************************************
		 *
		 * 	Accounts functionality
		 *
		 *********************************************************************************************/
		public function getAllAccounts(): Array
		{
			loadAccounts();
			return _accounts;
		}

		public function getAccountForDomain(domain: String, realm: String): BasicAuthAccount
		{
			for each (var account: BasicAuthAccount in _accounts)
			{
				if (account.domain == domain && account.realm == realm)
					return account;
			}
			return null;
		}

		public function resetAccounts(): void
		{
			_accounts = [];
			saveAccounts();
		}

		public function addAccount(name: String, password: String, domain: String, realm: String): Boolean
		{
			if (!name || !password)
			{
				return false;
			}
			//check if account does exists and add it if does not exists
			if (_accounts.length > 0)
			{
				for each (var account: BasicAuthAccount in _accounts)
				{
					if (account.name && account.password == password && account.domain == domain && account.realm == realm)
					{
						//account already exists, do not add it again
						return false;
					}
				}
			}
			_accounts.push(new BasicAuthAccount(name, password, domain, realm));
			saveAccounts();
			return true
		}

		private function loadAccounts(): void
		{
			var st: SharedObjectStorage = new SharedObjectStorage(Storage.LOADING, SharedObject.getLocal(applicationName + "_basic-auth-accounts"));
			if (st)
				st.serializeNonpersistentArray('accounts', _accounts, BasicAuthAccount);
		}

		private function saveAccounts(): void
		{
			var st: SharedObjectStorage = new SharedObjectStorage(Storage.STORING, SharedObject.getLocal(applicationName + "_basic-auth-accounts"));
			if (st)
				st.serializeNonpersistentArray('accounts', _accounts, BasicAuthAccount);
		}

		public function waitingForCredentials(domain: String, realm: String): Boolean
		{
			if (!_waitingForCredentials[domain + "_" + realm])
				return false;
			return _waitingForCredentials[domain + "_" + realm];
		}

		/**
		 * set flag "wait for credentials" for domain
		 * @param domain
		 *
		 */
		public function waitForCredentials(domain: String, realm: String): void
		{
			_waitingForCredentials[domain + "_" + realm] = true;
		}

		public function doNotWaitForCredentials(domain: String, realm: String): void
		{
			delete _waitingForCredentials[domain + "_" + realm];
		}

		/**********************************************************************************************
		 *
		 * 	Request functionality
		 *
		 *********************************************************************************************/
		public function getRequestByURLWithRealm(request: URLRequest, realm: String): UniURLLoaderData
		{
			var domain: String = getDomain(request);
			var domainRequests: Array = getRealmDomainRequestArray(domain);
			var data: UniURLLoaderData;
			var total: int = domainRequests.length;
			var found: int = -1;
			for (var i: int = 0; i < total; i++)
			{
				data = domainRequests[i] as UniURLLoaderData;
				if (data.request.url == request.url && data.associatedData && data.associatedData.uniURLLoaderBasicAuthAccount)
				{
					var basicAuthAccount: BasicAuthAccount = data.associatedData.uniURLLoaderBasicAuthAccount as BasicAuthAccount;
					if (basicAuthAccount && basicAuthAccount.realm == realm)
						found = i;
				}
			}
			if (found > -1)
			{
				var requests: Array = domainRequests.splice(found, 1);
				return requests[0] as UniURLLoaderData;
			}
			return null;
		}

		/**
		 * Get domain string from URL. It's needed for getting BasicAuth credentials saved in Shared objects (for mobile development)
		 * @param urlRequest
		 * @return
		 *
		 */
		private function getDomain(urlRequest: URLRequest): String
		{
			var url: String = urlRequest.url;
			var domain: String = URLUtil.getServerNameWithPort(url);
			return domain;
		}

		private function getRealmDomainRequestArray(domain: String): Array
		{
			if (!_requests[domain])
				_requests[domain] = new Array();
			return _requests[domain];
		}

		/**
		 * Just create request data and do not store them in request buffer
		 * @param request
		 * @param loader
		 * @param associatedData
		 * @param backgroundJobName
		 * @return
		 *
		 */
		public function createRequest(request: URLRequest,
				loader: AbstractURLLoader,
				associatedData: Object = null,
				backgroundJobName: String = null): UniURLLoaderData
		{
			var data: UniURLLoaderData = new UniURLLoaderData(request, loader, associatedData, backgroundJobName);
			return data;
		}

		/**
		 * Create request data and store them in buffer
		 * @param request
		 * @param loader
		 * @param associatedData
		 * @param backgroundJobName
		 * @return
		 *
		 */
		public function addRequest(request: URLRequest,
				loader: AbstractURLLoader,
				associatedData: Object = null,
				backgroundJobName: String = null): UniURLLoaderData
		{
			var domain: String = getDomain(request);
			var domainRequests: Array = getRealmDomainRequestArray(domain);
			var data: UniURLLoaderData = createRequest(request, loader, associatedData, backgroundJobName);
			domainRequests.push(data);
			return data;
		}

		public function setAuthenticated(value: Boolean): void
		{
			authenticated = value;
		}

		public function stopAllStoppedRequests(domain: String, realm: String): void
		{
			var domainRequests: Array = getRealmDomainRequestArray(domain);
			if (domainRequests.length > 0)
			{
				var pos: int = domainRequests.length - 1;
				while (pos > -1)
				{
					var requestObject: UniURLLoaderData = domainRequests[pos] as UniURLLoaderData;
					var loader: AbstractURLLoader = requestObject.loader;
					var request: URLRequest = requestObject.request;
					var associatedData: Object = requestObject.associatedData;
					var s_backgroundJobName: String = requestObject.backgroundJobName;
					//check realm, and if it is different, just add request back
					var basicAuthAccount: BasicAuthAccount = associatedData.uniURLLoaderBasicAuthAccount as BasicAuthAccount;
					if (basicAuthAccount)
					{
						var currRealm: String = basicAuthAccount.realm;
						if (currRealm && currRealm != realm)
							addRequest(request, loader, associatedData, s_backgroundJobName);
						else
							domainRequests.splice(pos, 1);
					}
					pos--;
				}
			}
		}

		public function runAllStoppedRequests(request: URLRequest, loggedBasicAccount: BasicAuthAccount): void
		{
			var domain: String = getDomain(request);
			var domainRequests: Array = getRealmDomainRequestArray(domain);
			if (domainRequests.length > 0)
			{
				var realm: String = loggedBasicAccount.realm;
				var pos: int = domainRequests.length - 1;
				while (pos > -1)
				{
					var requestObject: UniURLLoaderData = domainRequests[pos] as UniURLLoaderData;
					var loader: AbstractURLLoader = requestObject.loader;
					var request: URLRequest = requestObject.request;
					var s_backgroundJobName: String = requestObject.backgroundJobName;
					var associatedData: Object = requestObject.associatedData;
					if (associatedData && associatedData.uniURLLoaderBasicAuthAccount)
					{
						var basicAuthAccount: BasicAuthAccount = associatedData.uniURLLoaderBasicAuthAccount as BasicAuthAccount;
						if (basicAuthAccount && basicAuthAccount.realm == realm)
						{
							domainRequests.splice(pos, 1);
							var rn: UniURLLoaderEvent = new UniURLLoaderEvent(UniURLLoaderEvent.RUN_STOPPED_REQUEST, null, request, associatedData);
							loader.dispatchEvent(rn);
							loader.load(request, associatedData, s_backgroundJobName, true, loggedBasicAccount);
						}
					}
					else
					{
						domainRequests.splice(pos, 1);
						var rn2: UniURLLoaderEvent = new UniURLLoaderEvent(UniURLLoaderEvent.RUN_STOPPED_REQUEST, null, request, associatedData);
						loader.dispatchEvent(rn2);
						loader.load(request, associatedData, s_backgroundJobName, true, loggedBasicAccount);
					}
					pos--;
				}
			}
		}
	}
}
