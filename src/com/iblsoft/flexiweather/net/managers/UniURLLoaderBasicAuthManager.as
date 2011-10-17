package com.iblsoft.flexiweather.net.managers
{
	import com.iblsoft.flexiweather.net.data.UniURLLoaderData;
	import com.iblsoft.flexiweather.utils.SharedObjectStorage;
	import com.iblsoft.flexiweather.utils.Storage;
	import com.iblsoft.flexiweather.utils.UniURLLoader;
	import com.iblsoft.flexiweather.widgets.basicauth.data.BasicAuthAccount;
	
	import flash.net.SharedObject;
	import flash.net.URLRequest;
	import flash.utils.Dictionary;
	
	import mx.utils.URLUtil;

	public class UniURLLoaderBasicAuthManager
	{
		private var _waitingForCredentials: Dictionary;
		private var _requests: Dictionary;
		private var _accounts: Array;
		
		public var authenticated: Boolean;
		
		private static var _instance: UniURLLoaderBasicAuthManager;
		
		public static function get instance(): UniURLLoaderBasicAuthManager
		{
			if (!_instance)
			{
				_instance = new UniURLLoaderBasicAuthManager();
			}
			return _instance;
		}
		
		public function UniURLLoaderBasicAuthManager()
		{
			_accounts = [];
			_requests = new Dictionary();
			_waitingForCredentials = new Dictionary();
			loadAccounts();
		}
		
		public function useBasicAuth(request: URLRequest, realm: String): Boolean
		{
			var domain: String = getDomain(request);
			return useBasicAuthForDomain(domain, realm);
		}
		
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
				{
					return account;
				}
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
				trace("problem adding account");
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
			var st : SharedObjectStorage=new SharedObjectStorage( Storage.LOADING, SharedObject.getLocal( "basic-auth-accounts" ));
			st.serializeNonpersistentArray('accounts', _accounts, BasicAuthAccount);
			
		}
		private function saveAccounts(): void
		{
			var st : SharedObjectStorage=new SharedObjectStorage( Storage.STORING, SharedObject.getLocal( "basic-auth-accounts" ));
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
		
		public function getFirstRequestByDomain(domain: String): UniURLLoaderData
		{
			var domainRequests: Array = getDomainRequestArray(domain);
			trace("getFirstRequestByDomain: ["+domain+"]:" + domainRequests); 
			if (domainRequests.length > 0)
				return domainRequests.shift();
			
			return null;
			
		}
		public function getFirstRequestByRequest(request: URLRequest): UniURLLoaderData
		{
			var domain: String = getDomain(request);
			var domainRequests: Array = getDomainRequestArray(domain);
			trace("getFirstRequestByRequest: ["+domain+"]:" + domainRequests); 
			if (domainRequests.length > 0)
				return domainRequests.shift();
			
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
		private function getDomainRequestArray(domain: String): Array
		{
			if (!_requests[domain])
				_requests[domain] = new Array();
			
			return _requests[domain];
			
		}
		public function addRequest(request: URLRequest, 
										  loader: UniURLLoader, 
										  associatedData: Object = null,
										  backgroundJobName: String = null): void
		{
			var domain: String = getDomain(request);
			var domainRequests: Array = getDomainRequestArray(domain);
			
			domainRequests.push(new UniURLLoaderData(request, loader, associatedData, backgroundJobName));
		}
		
		public function setAuthenticated(value: Boolean): void
		{
			authenticated = value;
		}
		
		public function stopAllStoppedRequests(domain: String, realm: String): void
		{
			var domainRequests: Array = getDomainRequestArray(domain);
			
			trace("runAllStoppedRequests for ["+domainRequests+"] " + domainRequests.length);
			while (domainRequests.length > 0)
			{
				var requestObject: UniURLLoaderData = domainRequests.shift();
				
				var loader: UniURLLoader = requestObject.loader;
				var request: URLRequest = requestObject.request;
				var associatedData: Object = requestObject.associatedData;
				var s_backgroundJobName: String = requestObject.backgroundJobName;
				
				//check realm, and if it is different, just add request back
				var basicAuthAccount: BasicAuthAccount = associatedData.uniURLLoaderBasicAuthAccount as BasicAuthAccount;
				if (basicAuthAccount)
				{
					var currRealm: String = basicAuthAccount.realm;
					if (currRealm && currRealm != realm)
					{
						addRequest(request, loader, associatedData, s_backgroundJobName);
					}
				}
			}
			
		}
		public function runAllStoppedRequests(request: URLRequest): void
		{
			var domain: String = getDomain(request);
			var domainRequests: Array = getDomainRequestArray(domain);
			
			trace("runAllStoppedRequests for ["+domainRequests+"] " + domainRequests.length);
			while (domainRequests.length > 0)
			{
				var requestObject: UniURLLoaderData = domainRequests.shift();
				
				var loader: UniURLLoader = requestObject.loader;
				var request: URLRequest = requestObject.request;
				var associatedData: Object = requestObject.associatedData;
				var s_backgroundJobName: String = requestObject.backgroundJobName;
				
				loader.load(request, associatedData, s_backgroundJobName, true);
			}
		}
	}
}
