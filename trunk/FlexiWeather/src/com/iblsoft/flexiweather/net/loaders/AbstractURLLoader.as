package com.iblsoft.flexiweather.net.loaders
{
	import com.iblsoft.flexiweather.net.UniURLLoaderFormat;
	import com.iblsoft.flexiweather.net.data.UniURLLoaderData;
	import com.iblsoft.flexiweather.net.events.UniURLLoaderAuthorizationEvent;
	import com.iblsoft.flexiweather.net.events.UniURLLoaderErrorEvent;
	import com.iblsoft.flexiweather.net.events.UniURLLoaderEvent;
	import com.iblsoft.flexiweather.net.interfaces.IURLLoaderBasicAuth;
	import com.iblsoft.flexiweather.net.interfaces.IURLLoaderBasicAuthListener;
	import com.iblsoft.flexiweather.net.managers.UniURLLoaderBasicAuthManager;
	import com.iblsoft.flexiweather.net.managers.UniURLLoaderManager;
	import com.iblsoft.flexiweather.plugins.IConsole;
	import com.iblsoft.flexiweather.proj.Coord;
	import com.iblsoft.flexiweather.utils.LoggingUtils;
	import com.iblsoft.flexiweather.utils.URLUtils;
	import com.iblsoft.flexiweather.widgets.BackgroundJob;
	import com.iblsoft.flexiweather.widgets.BackgroundJobManager;
	import com.iblsoft.flexiweather.widgets.basicauth.controls.BasicAuthCredentialsPopup;
	import com.iblsoft.flexiweather.widgets.basicauth.controls.IBasicAuthCredentialsPopup;
	import com.iblsoft.flexiweather.widgets.basicauth.data.BasicAuthAccount;
	import com.iblsoft.flexiweather.widgets.basicauth.events.BasicAuthEvent;
	
	import flash.display.DisplayObject;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.HTTPStatusEvent;
	import flash.events.IEventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.events.ProgressEvent;
	import flash.events.SecurityErrorEvent;
	import flash.net.URLLoader;
	import flash.net.URLLoaderDataFormat;
	import flash.net.URLRequest;
	import flash.net.URLRequestHeader;
	import flash.net.URLRequestMethod;
	import flash.net.URLVariables;
	import flash.utils.ByteArray;
	import flash.utils.Dictionary;
	
	import mx.controls.Alert;
	import mx.core.ClassFactory;
	import mx.core.FlexGlobals;
	import mx.core.IFlexDisplayObject;
	import mx.logging.Log;
	import mx.managers.PopUpManager;
	import mx.messaging.AbstractConsumer;
	import mx.rpc.Fault;
	import mx.utils.Base64Encoder;
	import mx.utils.ObjectUtil;
	import mx.utils.URLUtil;
	
	import spark.components.TitleWindow;

	public class AbstractURLLoader extends EventDispatcher implements IURLLoaderBasicAuth
	{
		public static var debugConsole: IConsole;
		/**
		 *  basicAuthURLLoaderClass must be of Class which implement IURLLoaderBasicAuthListener
		 * it server for listening to HTTPStatusEvent.HTTP_RESPONSE_STATUS which is available only in AIR projects and consists of response headers with BasicAuth information (e.g. REALM)
		 */
		public static var basicAuthURLLoaderClass: Class;
		private var _baLoader: IURLLoaderBasicAuthListener;
		public static var basicAuthCredentialsPopupClass: IBasicAuthCredentialsPopup;
		protected var md_urlLoaderToRequestMap: Dictionary = new Dictionary();
		private static var _baseURL: String = '';

		public static function get baseURL(): String
		{
			return _baseURL;
		}

		public static function set baseURL(value: String): void
		{
			_baseURL = value;
		}
		public static var proxyBaseURL: String = '';
		/**
		 * URL of the cross-domain script bridging script. The ${URL} pattern
		 * in this string is replaced with the actual URL required to be proxied.
		 * This string may use the ${BASE_URL} expansion.
		 *
		 * Example: "http://server.com/proxy?url=${URL}"
		 */
		public static var crossDomainProxyURLPattern: String = null;
		/** Deprecated - associated data. Use load(request, associatedData) instead. */
		public var data: Object;

		public function AbstractURLLoader(target: IEventDispatcher = null)
		{
			super(target);
		}

		public static function navigateToURL(request: URLRequest): void
		{
			if (request.data)
			{
				var s_params: String = "";
				for (var s_key: String in request.data)
				{
					if (s_params != "")
						s_params += "&";
					s_params += s_key;
					s_params += "=";
					s_params += encodeURIComponent(request.data[s_key]);
				}
				request.url += "?" + s_params;
			}
			flash.net.navigateToURL(new URLRequest(AbstractURLLoader.fromBaseURL(request.url)));
		}

		public static function fromBaseURL(s_url: String, s_customBaseUrl: String = null): String
		{
			var s_baseUrl: String = baseURL;
			if (s_customBaseUrl && s_customBaseUrl.length > 0)
				s_baseUrl = s_customBaseUrl;
			if (s_url.indexOf("${BASE_URL}") >= 0)
			{
				var regExp: RegExp = /\$\{BASE_URL\}/ig;
				while (regExp.exec(s_url) != null)
				{
					s_url = s_url.replace(regExp, s_baseUrl);
				}
			}
			s_url = URLUtils.urlSanityCheck(s_url);
			return s_url;
		}

		public function destroy(): void
		{
			var id: String;
			var obj: Object;
			if (md_urlLoaderToRequestMap)
			{
				for (id in md_urlLoaderToRequestMap)
				{
					obj = md_urlLoaderToRequestMap[id];
				}
			}
			
			data = null;
			if (_baLoader)
				_baLoader.destroy();
		}

		private function checkRequestBaseURL(urlRequest: URLRequest): void
		{
			urlRequest.url = convertBaseURL(urlRequest.url);
		}

		public function convertBaseURL(url: String): String
		{
			return AbstractURLLoader.fromBaseURL(url);
		}

		/**
		 * Function will check request data and will fix them if there is need for it. There are 4 different cases
		 *
		 * 1) all parameters are in URL
		 * 2) all parameters are in URLVariables
		 * 3) some parameters are in URL some in URLVariables
		 *
		 * Cases 1) and 2) will not touch request at all.
		 *
		 * Case 3) will modify request and add URLVariables after URL parameters in alphabetical order (URL parameters will not be changed)
		 * @param urlRequest
		 *
		 */
		public function checkRequestData(urlRequest: URLRequest): void
		{
			var url: String = decodeURIComponent(urlRequest.url);
			var urlArr: Array = url.split('?');
			//check if there are get parameters divide by "?" character
			var urlParamsExists: Boolean = (urlArr.length == 2);
			if (!urlParamsExists)
			{
				//don't do anything, there are not url params
				return;
			}
			if ((urlArr[1] as String).indexOf('&') == 0)
			{
				var paramsString: String = urlArr[1] as String;
				urlArr[1] = paramsString.substring(1, paramsString.length);
			}
			var urlVariablesParamsExists: Boolean = false;
			var vars: URLVariables;
			var urlParams: String = urlArr.join('?');
			if (urlRequest.data)
			{
				vars = urlRequest.data as URLVariables;
				if (vars)
					urlVariablesParamsExists = true;
			}
			if (vars && urlRequest.method == URLRequestMethod.GET)
			{
				if (!urlParamsExists)
					urlParams += "?";
				else
					urlParams += "&";
				var item: String;
				//now we have all datas in variables, move it to url
				//sort it alfabetically
				var test: Array = [];
				for (item in urlRequest.data)
				{
					test.push({item: item, value: urlRequest.data[item]});
				}
				test.sort(sortVariables);
				for each (var obj: Object in test)
				{
					urlParams += obj.item + "=" + obj.value + "&";
				}
				urlParams = urlParams.substr(0, urlParams.length - 1);
				urlRequest.data = null;
			}
			urlRequest.data = null;
			urlRequest.url = urlParams;
		}

		public function sortVariables(var1: Object, var2: Object): int
		{
			if (var1.item < var2.item)
				return -1;
			if (var1.item > var2.item)
				return 1;
			return 0;
		}

		/*
		private function checkRequestData(urlRequest: URLRequest): void
		{
			var url: String = decodeURIComponent(urlRequest.url);
			var urlArr: Array = url.split('?');
			//check if there are get parameters divide by "?" character
			if (urlArr.length == 2)
			{
				urlRequest.url = urlArr[0];

				var dataStr: String = urlArr[1];
				var dataArr: Array = dataStr.split('&');
				for each (var str: String in dataArr)
				{
					if (str && str.length > 0 && str.indexOf('=') > 0)
					{
						if (!urlRequest.data)
							urlRequest.data = new URLVariables();
						var valArr: Array = str.split('=');
						var varName: String = valArr.shift();
						var varValue: String = valArr.join('=');
						if (urlRequest.hasOwnProperty(varName))
						{
							debug("variable already exists in request variables ["+varName+"]: oldValue " + urlRequest[varName] + " newValue: " + varValue);
						} else {
							urlRequest.data[varName] = varValue;
						}
					}
				}
				if (urlRequest.data)
				{
					var vars: URLVariables = urlRequest.data as URLVariables;
					if (vars)
					{
						urlRequest.url += "?";
						//now we have all datas in variables, move it to url
						for (var item: String in urlRequest.data)
						{
							urlRequest.url += item + "=" + urlRequest.data[item] + "&";
						}
						urlRequest.url = urlRequest.url.substr(0, urlRequest.url.length-1);
						urlRequest.data = null;
					}
				}
				//				urlRequest.data = null;
			}
		}
		*/
		private function removeBasicAuthPopupListeners(popup: IBasicAuthCredentialsPopup): void
		{
			popup.removeEventListener(BasicAuthEvent.CREDENTIALS_READY, onBasicAuthCredentialsReady);
			popup.removeEventListener(BasicAuthEvent.AUTHENTICATION_CANCELLED, onBasicAuthCancelled);
		}

		private function onBasicAuthCancelled(event: BasicAuthEvent): void
		{
			var popup: TitleWindow = event.target as TitleWindow;
			removeBasicAuthPopupListeners(popup as IBasicAuthCredentialsPopup);
			PopUpManager.removePopUp(popup);
			//stop all requests for current realm and domain
			var domain: String = event.domain;
			var realm: String = event.realm;
			var basicAuthManager: UniURLLoaderBasicAuthManager = UniURLLoaderBasicAuthManager.instance;
			basicAuthManager.stopAllStoppedRequests(domain, realm);
		}

		private function onBasicAuthCredentialsReady(event: BasicAuthEvent): void
		{
			var popup: TitleWindow = event.target as TitleWindow;
			removeBasicAuthPopupListeners(popup as IBasicAuthCredentialsPopup);
			PopUpManager.removePopUp(popup);
			var basicAuthManager: UniURLLoaderBasicAuthManager = UniURLLoaderBasicAuthManager.instance;
			var requestData: UniURLLoaderData = event.requestData;
			var loader: UniURLLoader = requestData.loader as UniURLLoader;
			var request: URLRequest = requestData.request as URLRequest;
			var associatedData: Object = requestData.associatedData as Object;
			var s_backgroundJobName: String = requestData.backgroundJobName as String;
			var basicAccount: BasicAuthAccount = new BasicAuthAccount(event.username, event.password, event.domain, event.realm);
			loader.load(request, associatedData, s_backgroundJobName, true, basicAccount, requestData);
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

		/**
		 * Return object with properties "name" and "password". If BasicAuth credentails for "domain" do not exists, null is returned
		 *
		 * @param domain Domain name
		 * @return
		 *
		 */
		private function getBasicAuthCredentialsForDomain(domain: String, realm: String): BasicAuthAccount
		{
			var credentials: BasicAuthAccount = UniURLLoaderBasicAuthManager.instance.getAccountForDomain(domain, realm);
			return credentials;
		}

		/**
		 *
		 * @param urlRequest
		 * @param associatedData
		 * @param s_backgroundJobName
		 * @return true - request must be stopped (Basic URL popup opened), false - request can be loaded
		 *
		 */
		private function addBasicAuthToURLRequest(urlRequest: URLRequest, associatedData: Object = null, s_backgroundJobName: String = null, basicAuthAccount: BasicAuthAccount = null): Boolean
		{
			var domain: String = getDomain(urlRequest);
			var credentials: BasicAuthAccount;
			var username: String;
			var password: String;
			var realm: String;
			if (basicAuthAccount)
				realm = basicAuthAccount.realm;
			if (basicAuthAccount && basicAuthAccount.name && basicAuthAccount.password)
			{
				username = basicAuthAccount.name;
				password = basicAuthAccount.password;
			}
			else
			{
				credentials = getBasicAuthCredentialsForDomain(domain, realm);
				if (credentials)
				{
					username = credentials.name;
					password = credentials.password;
					realm = credentials.realm;
				}
			}
			var basicAuthManager: UniURLLoaderBasicAuthManager = UniURLLoaderBasicAuthManager.instance;
			//check if autentification is there already
			var basicAuthCredentialsReady: Boolean = (username && password);
			var waitForBasicAuthCredentials: Boolean = basicAuthManager.waitingForCredentials(domain, realm);
			if (waitForBasicAuthCredentials && associatedData.uniURLLoaderBasicAuthInfo == 'first message')
			{
				//this is message which will test correct Basic auth credentials, so let it be loaded
				waitForBasicAuthCredentials = false;
			}
			var already_authenticated: Boolean = false;
			if (!already_authenticated && waitForBasicAuthCredentials && !basicAuthCredentialsReady)
			{
				UniURLLoaderBasicAuthManager.instance.addRequest(urlRequest, this, associatedData, s_backgroundJobName);
				var ae: UniURLLoaderEvent = new UniURLLoaderEvent(UniURLLoaderEvent.STOP_REQUEST, null, urlRequest, associatedData);
				dispatchEvent(ae);
				return true;
			}
			if (!already_authenticated)
			{
				if (!associatedData)
					associatedData = {};
				var associatedBasicAuth: BasicAuthAccount = associatedData.uniURLLoaderBasicAuthAccount as BasicAuthAccount;
				if (!associatedBasicAuth)
					associatedBasicAuth = new BasicAuthAccount();
				associatedBasicAuth.domain = domain;
				associatedBasicAuth.name = username;
				associatedBasicAuth.password = password;
				associatedBasicAuth.realm = realm;
				associatedData.uniURLLoaderBasicAuthAccount = associatedBasicAuth;
				if (!basicAuthCredentialsReady)
				{
					associatedData.uniURLLoaderBasicAuthInfo = 'first message';
					var requestData: UniURLLoaderData = basicAuthManager.createRequest(urlRequest, this, associatedData, s_backgroundJobName);
					basicAuthManager.waitForCredentials(domain, realm);
					showBasicAuthPopup(domain, realm, requestData);
					return true;
				}
				var encoder: Base64Encoder = new Base64Encoder();
				encoder.insertNewLines = false;
				encoder.encode(username + ":" + password);
				var credsHeader: URLRequestHeader = new URLRequestHeader("Authorization", "Basic " + encoder.toString())
				urlRequest.requestHeaders.push(credsHeader);
			}
			else
			{
				// already authenticated, do not add authentication again
			}
			return false;
		}

		/**
		 * Main load function for loading request through UniURLLoader
		 *
		 * @param urlRequest
		 * @param associatedData
		 * @param s_backgroundJobName
		 *
		 */
		public function load(urlRequest: URLRequest, associatedData: Object = null, s_backgroundJobName: String = null, useBasicAuthInRequest: Boolean = false, basicAuthAccount: BasicAuthAccount = null, basicAuthRequestData: UniURLLoaderData = null): void
		{
			checkRequestData(urlRequest);
			checkRequestBaseURL(urlRequest);
			
//			trace(this + " load: " + urlRequest.url);
			// if there is no associatedDat, add empty one
			if (!associatedData)
			{
				associatedData = new Object();
				associatedData.uniURLLoaderBasicAuthAccount = new BasicAuthAccount();
			}
			var basicAuthManager: UniURLLoaderBasicAuthManager = UniURLLoaderBasicAuthManager.instance;
			//check if basicAut was used for this domain before
			var realm: String;
			var uniURLLoaderData: UniURLLoaderData;
			if (basicAuthAccount)
				realm = basicAuthAccount.realm;
			if (!useBasicAuthInRequest)
			{
				var usedBasicAuthBefore: Boolean = basicAuthManager.useBasicAuth(urlRequest, realm);
				if (usedBasicAuthBefore)
					useBasicAuthInRequest = true;
			}
			if (useBasicAuthInRequest)
			{
				var stopRequest: Boolean = addBasicAuthToURLRequest(urlRequest, associatedData, s_backgroundJobName, basicAuthAccount);
				uniURLLoaderData = basicAuthRequestData;
				if (stopRequest)
					return;
			}
			else
				uniURLLoaderData = basicAuthManager.createRequest(urlRequest, this, associatedData, s_backgroundJobName);
			var urlLoader: URLLoaderWithAssociatedData = new URLLoaderWithAssociatedData();
			urlLoader.associatedData = associatedData;
			urlLoader.dataFormat = URLLoaderDataFormat.BINARY;
			urlLoader.addEventListener(Event.COMPLETE, onDataComplete);
			urlLoader.addEventListener(ProgressEvent.PROGRESS, onDataProgress);
			urlLoader.addEventListener(IOErrorEvent.IO_ERROR, onDataIOError);
			urlLoader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, onSecurityError);
			//FIXME remove this. It's just for testing Proxy
			/*
			var backgroundJob: BackgroundJob = null;
			if(s_backgroundJobName != null)
			backgroundJob = BackgroundJobManager.getInstance().startJob(s_backgroundJobName);
			md_urlLoaderToRequestMap[urlLoader] = {
			request: urlRequest,
			loader: urlLoader,
			backgroundJob: backgroundJob
			};

			loadCrossDomainProxyURLPattern(urlLoader);
			return;
			*/
			//FIXME end of remove section.
			//implement listening for HTTP_RESPONSE_STATUS available only in AIR
			if (basicAuthURLLoaderClass)
			{
				var classFactory: ClassFactory = new ClassFactory(basicAuthURLLoaderClass);
				_baLoader = classFactory.newInstance() as IURLLoaderBasicAuthListener;
				_baLoader.addBasicAuthListeners(this, urlLoader, uniURLLoaderData);
			}
			UniURLLoaderManager.instance.addLoaderRequest(urlRequest);
			urlLoader.load(urlRequest);
//			debug("Load URL: " + urlRequest.url);
			var backgroundJob: BackgroundJob = null;
			if (s_backgroundJobName != null)
				backgroundJob = BackgroundJobManager.getInstance().startJob(s_backgroundJobName);
			md_urlLoaderToRequestMap[urlLoader] = {request: urlRequest, loader: urlLoader, backgroundJob: backgroundJob};
			var e: UniURLLoaderEvent = new UniURLLoaderEvent(UniURLLoaderEvent.LOAD_STARTED, null, urlRequest, associatedData);
			dispatchEvent(e);
		}

		public function setResponseHeaders(headers: Array, responseURL: String, status: int, loader: Object): void
		{
			var realm: String;
			var basicAuthAccount: BasicAuthAccount;
			for each (var header: URLRequestHeader in headers)
			{
				if (header.name == 'WWW-Authenticate')
				{
					realm = header.value;
					var pos: int = realm.indexOf('"');
					if (pos > -1)
					{
						var pos2: int = realm.indexOf('"', pos + 1);
						var correctBasicRealm: String = realm.substring(pos + 1, pos2);
						if (loader.associatedData)
						{
							if (loader.associatedData.uniURLLoaderBasicAuthAccount)
							{
								basicAuthAccount = loader.associatedData.uniURLLoaderBasicAuthAccount as BasicAuthAccount;
								basicAuthAccount.realm = correctBasicRealm;
							}
							else
							{
								basicAuthAccount = new BasicAuthAccount();
								basicAuthAccount.realm = correctBasicRealm;
							}
							loader.associatedData.uniURLLoaderBasicAuthAccount = basicAuthAccount;
						}
					}
					if (status == 401)
					{
						var basicAuthManager: UniURLLoaderBasicAuthManager = UniURLLoaderBasicAuthManager.instance;
						var urlLoader: URLLoaderWithAssociatedData = URLLoaderWithAssociatedData(loader);
						var urlRequest: URLRequest = md_urlLoaderToRequestMap[urlLoader].request;
						/**
						 * check if domain and realm was authenticated before.
						 * if yes - just load it again with correct basic auth crendentials
						 * if not - open basic auth popup
						 */
						if (loader.associatedData)
							basicAuthAccount = loader.associatedData.uniURLLoaderBasicAuthAccount as BasicAuthAccount;
						else
						{
							loader.associatedData = new Object();
							loader.associatedData.uniURLLoaderBasicAuthAccount = new BasicAuthAccount();
							basicAuthAccount = loader.associatedData.uniURLLoaderBasicAuthAccount as BasicAuthAccount;
						}
						realm = null;
						if (basicAuthAccount)
						{
							realm = basicAuthAccount.realm;
							//401 - authorization problem, reset name and password
							basicAuthAccount.name = null;
							basicAuthAccount.password = null;
						}
						if (realm)
						{
							var usedBasicAuthBefore: Boolean = basicAuthManager.useBasicAuth(urlRequest, realm);
							if (usedBasicAuthBefore)
							{
								//it was authenticated before
								load(urlRequest, loader.associatedData, null, true, basicAuthAccount);
								return;
							}
						}
						var requestObject: UniURLLoaderData;
						if (_baLoader)
							requestObject = _baLoader.getData();
						openBasicAuthDialog(urlRequest, realm, requestObject, true);
						var e: UniURLLoaderEvent = new UniURLLoaderEvent(UniURLLoaderAuthorizationEvent.AUTHORIZATION_FAILED, null, urlRequest, loader.associatedData);
						dispatchEvent(e);
					}
				}
			}
		}

		private function showBasicAuthPopup(domain: String, realm: String, data: UniURLLoaderData): void
		{
			var popup: BasicAuthCredentialsPopup;
			popup = new BasicAuthCredentialsPopup();
			popup.domain = domain;
			popup.realm = realm;
			popup.requestData = data;
			popup.addEventListener(BasicAuthEvent.CREDENTIALS_READY, onBasicAuthCredentialsReady);
			popup.addEventListener(BasicAuthEvent.AUTHENTICATION_CANCELLED, onBasicAuthCancelled);
			PopUpManager.addPopUp(popup, FlexGlobals.topLevelApplication as DisplayObject);
			PopUpManager.centerPopUp(popup);
		}

		private function openBasicAuthDialog(urlRequest: URLRequest, realm: String, requestObject: UniURLLoaderData, forceOpening: Boolean = false): void
		{
			//show basic auth popup
			var basicAuthManager: UniURLLoaderBasicAuthManager = UniURLLoaderBasicAuthManager.instance;
			var domain: String = getDomain(urlRequest);
			var showBasicAuthPopup: Boolean = (basicAuthManager.waitingForCredentials(domain, realm) == false);
			if (!showBasicAuthPopup && forceOpening)
				showBasicAuthPopup = true;
			if (showBasicAuthPopup && requestObject)
			{
				//reset waiting for credentials, because it is for the first time, or credentials was incorrect last time
				var basicAuthAccount: BasicAuthAccount = requestObject.associatedData.uniURLLoaderBasicAuthAccount as BasicAuthAccount;
				var realm: String;
				if (basicAuthAccount)
					realm = basicAuthAccount.realm;
				//basicAuthManager.doNotWaitForCredentials(domain, realm);
				//load it again with basic auth
				load(requestObject.request, requestObject.associatedData, requestObject.backgroundJobName, true, basicAuthAccount, requestObject);
			}
		}

		protected function test(event: Event): void
		{
			var urlLoader: URLLoaderWithAssociatedData = URLLoaderWithAssociatedData(event.target);
			var urlRequest: URLRequest;
			// Try to use cross-domain if received "Error #2048: Security sandbox violation:" 
			var s_proxyURL: String = fromBaseURL(crossDomainProxyURLPattern, proxyBaseURL);
			urlRequest = md_urlLoaderToRequestMap[urlLoader].request;
			checkRequestData(urlRequest);
			var s_url: String = urlRequest.url;
			Log.getLogger('SecurityError').info('s_url: ' + s_url);
			Log.getLogger('SecurityError').info('s_url.indexOf("?"): ' + (s_url.indexOf("?")));
			s_proxyURL = s_proxyURL.replace("${URL}", encodeURIComponent(s_url));
			Log.getLogger('SecurityError').info('s_proxyURL: ' + s_proxyURL);
			urlRequest.url = s_proxyURL;
			checkRequestData(urlRequest);
			urlLoader.b_crossDomainProxyRequest = true;
			urlLoader.load(urlRequest);
			return;
		}

		protected function onDataProgress(event: ProgressEvent): void
		{
			dispatchEvent(event);
		}

		protected function onDataComplete(event: Event): void
		{
			var basicAuthManager: UniURLLoaderBasicAuthManager = UniURLLoaderBasicAuthManager.instance;
			var urlLoader: URLLoaderWithAssociatedData = URLLoaderWithAssociatedData(event.target);
			var urlRequest: URLRequest = disconnectURLLoader(urlLoader);
			if (urlRequest == null)
				return;
			
			if (urlLoader.associatedData && urlLoader.associatedData.hasOwnProperty("uniURLLoaderBasicAuthInfo") && urlLoader.associatedData.uniURLLoaderBasicAuthInfo == 'first message')
			{
				var domain: String = getDomain(urlRequest);
				var basicAccount: BasicAuthAccount = urlLoader.associatedData.uniURLLoaderBasicAuthAccount as BasicAuthAccount;
				//check if there any queued basic auth request and call them
				if (basicAccount && basicAccount.name && basicAccount.password)
				{
					var realm: String = basicAccount.realm;
					var accountAdded: Boolean = basicAuthManager.addAccount(basicAccount.name, basicAccount.password, basicAccount.domain, realm);
					basicAuthManager.doNotWaitForCredentials(domain, realm);
					basicAuthManager.runAllStoppedRequests(urlRequest, basicAccount);
				}
			}
			var rawData: ByteArray = event.target.data as ByteArray;
			rawData.position = 0;
			var s_data: String;
			//decode result object. Each loader needs to implemented decodeResult function and call resultCallback or errorCallbac
			decodeResult(rawData, urlLoader, urlRequest, dispatchResult, dispatchFault);
		}

		/**
		 * Function will decode loaded result and dispatch result event or error event. AbstractURLLoader does not implement this method.
		 * Implement functionality in override method in your custom loaders.
		 *
		 * @param rawData
		 * @param urlLoader
		 * @param urlRequest
		 * @param resultCallback
		 * @param errorCallback
		 *
		 */
		protected function decodeResult(rawData: ByteArray, urlLoader: URLLoaderWithAssociatedData, urlRequest: URLRequest, resultCallback: Function, errorCallback: Function): void
		{
		}

		protected function onDataIOError(event: IOErrorEvent): void
		{
			debug("AbstractURLLoader.onDataIOError: " + event.text);
			var urlLoader: URLLoaderWithAssociatedData = URLLoaderWithAssociatedData(event.target);
			var urlRequest: URLRequest = disconnectURLLoader(urlLoader);
			if (urlRequest == null)
				return;
			Log.getLogger("UniURLLoader").info("I/O error: " + event.text);
			dispatchFault('UniURLLoader error: IO Error' + event.text, event.errorID, null, urlRequest, urlLoader.associatedData);
		}

		protected function onSecurityError(event: SecurityErrorEvent): void
		{
			debug("AbstractURLLoader.onSecurityError: " + event.text);
			var urlLoader: URLLoaderWithAssociatedData = URLLoaderWithAssociatedData(event.target);
			var urlRequest: URLRequest;
			// Try to use cross-domain if received "Error #2048: Security sandbox violation:" 
			if (crossDomainProxyURLPattern != null && event.text.match(/#2048/) && !urlLoader.b_crossDomainProxyRequest)
			{
				loadCrossDomainProxyURLPattern(urlLoader);
				return;
			}
			urlRequest = disconnectURLLoader(urlLoader);
			if (urlRequest == null)
				return;
			Log.getLogger("UniURLLoader").info("Security error: " + event.text);
			dispatchFault("UniURLLoader SecurityError: " + event.text, event.errorID, null, urlRequest, urlLoader.associatedData);
		}

		private function loadCrossDomainProxyURLPattern(urlLoader: URLLoaderWithAssociatedData): void
		{
			var urlRequest: URLRequest;
			var s_proxyURL: String = fromBaseURL(crossDomainProxyURLPattern, proxyBaseURL);
			urlRequest = md_urlLoaderToRequestMap[urlLoader].request;
			checkRequestData(urlRequest);
			var s_url: String = urlRequest.url;
			Log.getLogger('SecurityError').info('s_url: ' + s_url);
			Log.getLogger('SecurityError').info('s_url.indexOf("?"): ' + (s_url.indexOf("?")));
			if (urlRequest.data)
			{
				if (s_url.indexOf("?") >= 0)
				{
					if (s_url.indexOf("?") != (s_url.length - 1))
						s_url += "&";
				}
				else
					s_url += "?";
				Log.getLogger('SecurityError').info('STEP 1 s_url: ' + s_url);
				if (urlRequest.data is URLVariables)
					s_url += urlRequest.data;
				else
				{
					if (urlRequest.data is Object)
					{
						for (var dataItemName: String in urlRequest.data)
						{
							s_url += dataItemName + "=" + urlRequest.data[dataItemName];
						}
					}
				}
				urlRequest.data = null;
				Log.getLogger('SecurityError').info('STEP 2 s_url: ' + s_url);
			}
			s_proxyURL = s_proxyURL.replace("${URL}", encodeURIComponent(s_url));
			Log.getLogger('SecurityError').info('s_proxyURL: ' + s_proxyURL);
			urlRequest.url = s_proxyURL;
			checkRequestData(urlRequest);
			urlLoader.b_crossDomainProxyRequest = true;
			urlLoader.load(urlRequest);
		}

		protected function dispatchResult(result: Object, urlRequest: URLRequest, associatedData: Object): void
		{
			var e: UniURLLoaderEvent = new UniURLLoaderEvent(UniURLLoaderEvent.DATA_LOADED, result, urlRequest, associatedData, true, true);
			dispatchEvent(e);
		}

		protected function dispatchFault(errorString: String, errorID: int, rawData: Object, urlRequest: URLRequest, associatedData: Object): void
		{
			associatedData.errorResult = rawData;
			dispatchEvent(new UniURLLoaderErrorEvent(UniURLLoaderErrorEvent.DATA_LOAD_FAILED, rawData, urlRequest, associatedData, errorString, errorID, false, true));
		}

		protected function disconnectURLLoader(urlLoader: URLLoaderWithAssociatedData): URLRequest
		{
			if (_baLoader)
				_baLoader.removeBasicAuthListeners();
			urlLoader.removeEventListener(Event.COMPLETE, onDataComplete);
			urlLoader.removeEventListener(ProgressEvent.PROGRESS, onDataProgress);
			urlLoader.removeEventListener(IOErrorEvent.IO_ERROR, onDataIOError);
			urlLoader.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, onSecurityError);
			if (!urlLoader in md_urlLoaderToRequestMap)
				return null;
			// finish background job if it was started
			var backgroundJob: BackgroundJob = md_urlLoaderToRequestMap[urlLoader].backgroundJob;
			if (backgroundJob != null)
				BackgroundJobManager.getInstance().finishJob(backgroundJob);
			var urlRequest: URLRequest = md_urlLoaderToRequestMap[urlLoader].request;
			UniURLLoaderManager.instance.removeLoaderRequest(urlRequest);
			delete md_urlLoaderToRequestMap[urlLoader];
			return urlRequest;
		}

		public function cancel(urlRequest: URLRequest): Boolean
		{
			var key: Object;
			for (key in md_urlLoaderToRequestMap)
			{
				if (md_urlLoaderToRequestMap[key].request === urlRequest)
				{
					md_urlLoaderToRequestMap[key].loader.close();
					disconnectURLLoader(URLLoaderWithAssociatedData(md_urlLoaderToRequestMap[key].loader));
					delete md_urlLoaderToRequestMap[key];
					return true;
				}
			}
			return false;
		}

		protected function cloneByteArrayToString(ba: ByteArray): String
		{
			var str: String = ba.readUTFBytes(ba.length);
			ba.position = 0;
			
			return str;
		}

		protected function debug(txt: String): void
		{
			return;
			if (debugConsole)
				debugConsole.print(txt, 'Info', 'UniURLLoader');
		}

		override public function toString(): String
		{
			return "AbstractURLLoader";
		}
	}
}
