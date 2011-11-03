package com.iblsoft.flexiweather.utils
{
	import com.iblsoft.flexiweather.net.data.UniURLLoaderData;
	import com.iblsoft.flexiweather.net.interfaces.IURLLoaderBasicAuth;
	import com.iblsoft.flexiweather.net.interfaces.IURLLoaderBasicAuthListener;
	import com.iblsoft.flexiweather.net.managers.UniURLLoaderBasicAuthManager;
	import com.iblsoft.flexiweather.net.managers.UniURLLoaderManager;
	import com.iblsoft.flexiweather.plugins.IConsole;
	import com.iblsoft.flexiweather.proj.Coord;
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
	import flash.events.SecurityErrorEvent;
	import flash.net.URLLoader;
	import flash.net.URLLoaderDataFormat;
	import flash.net.URLRequest;
	import flash.net.URLRequestHeader;
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
	import mx.utils.URLUtil;
	
	import spark.components.TitleWindow;
	
	/**
	 * Replacement of flash.net.URLLoader and flash.display.Loader classes
	 * which unites abilities of both and provides automatic detection of received data format.
	 * Recognised formats are:
	 * - PNG images
	 * - XML data
	 * - other binary/text data
	 * This class is designed to handle parallel HTTP requests fired by the load() method.
	 * Each request may have associated data, which are then dispatched to UniURLLoader user
	 * together with UniURLLoaderEvent.
	 * Each call to load() method instanties internal a new URLLoader instance.
	 * 
	 * There are only 2 types of event (DATA_LOADED, DATA_LOAD_FAILED) dispatched out of this class,
	 * so that the class can be used simplier.
	*/
	public class UniURLLoader extends EventDispatcher implements IURLLoaderBasicAuth
	{
		public static const BINARY_FORMAT: String = 'binary';
		public static const IMAGE_FORMAT: String = 'image';
		public static const JSON_FORMAT: String = 'json';
		public static const TEXT_FORMAT: String = 'text';
		public static const XML_FORMAT: String = 'xml';
		
		public static var debugConsole: IConsole;
		
		/**
		 *  basicAuthURLLoaderClass must be of Class which implement IURLLoaderBasicAuthListener
		 * it server for listening to HTTPStatusEvent.HTTP_RESPONSE_STATUS which is available only in AIR projects and consists of response headers with BasicAuth information (e.g. REALM)
		 */		
		public static var basicAuthURLLoaderClass: Class;
		private var _baLoader: IURLLoaderBasicAuthListener;
		
		public static var basicAuthCredentialsPopupClass: IBasicAuthCredentialsPopup;
		
		/**
		 * Array of allowed formats which will be loaded into loader. If there will be loaded format, which will not be included in allowedFormats array
		 * there will be FAIL dispatched.
		 * Please note, that it depends on order of formats in array. If TEXT will be included before XML, it will be checked if result is in TEXT format
		 * and it will be dispatch as TEXT object. If you want to check XML first, please add XML format before TEXT format.
		 * Supported formats are just formats which are defined in this class (see above) BINARY, IMAGE, JSON, TEXT, XML
		 */		
		public var allowedFormats: Array;
		
		// FIXME: We should have multiple Loader's for images!
		protected var md_imageLoaderToRequestMap: Dictionary = new Dictionary();
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
		
		[Event(name = AUTHORIZATION_FAILED, type = "com.iblsoft.flexiweather.utils.UniURLLoaderEvent")]
		public static const AUTHORIZATION_FAILED: String = "authorizationFailed";
		public static const RUN_STOPPED_REQUEST: String = "runStoppedRequest";
		public static const STOP_REQUEST: String = "stopRequest";
		
		public static const LOAD_STARTED: String = "loadStarted";
		
		public static const DATA_LOADED: String = "dataLoaded";
		public static const DATA_LOAD_FAILED: String = "dataLoadFailed";

		[Event(name = DATA_LOADED, type = "com.iblsoft.flexiweather.utils.UniURLLoaderEvent")]
		[Event(name = DATA_LOAD_FAILED, type = "com.iblsoft.flexiweather.utils.UniURLLoaderEvent")]
		
		public static const ERROR_BAD_IMAGE: String = "errorBadImage";
		public static const ERROR_IO: String = "errorIO";
		
		/**
		 * result is received but format is not included in allowedFormats array
		 */ 
		public static const ERROR_UNEXPECTED_FORMAT: String = "errorUnexpectedFormat";
		/**
		 * result is received, and format is allowed, but content is invalid (not as expected)
		 */
		public static const ERROR_INVALID_CONTENT: String = "errorInvalidConter";
		public static const ERROR_SECURITY: String = "errorSecurity";
		public static const ERROR_CANCELLED: String = "errorCancelled";
		
		/** Deprecated - associated data. Use load(request, associatedData) instead. */
		public var data: Object;
		
		public function UniURLLoader()
		{
			allowedFormats = [XML_FORMAT, IMAGE_FORMAT, JSON_FORMAT];
			
		}
		
		public static function navigateToURL(request: URLRequest): void
		{
			flash.net.navigateToURL(new URLRequest(UniURLLoader.fromBaseURL(request.url)));
		}

		public static function fromBaseURL(s_url: String, s_customBaseUrl: String = null): String
		{
			var s_baseUrl: String = baseURL;
			if (s_customBaseUrl && s_customBaseUrl.length > 0)
			{
				s_baseUrl = s_customBaseUrl;
			}
			
			if(s_url.indexOf("${BASE_URL}") >= 0)
			{
				var regExp: RegExp = /\$\{BASE_URL\}/ig;
				while(regExp.exec(s_url) != null)
				{
					s_url = s_url.replace(regExp, s_baseUrl);
//					trace("replace url: " + urlRequest.url + " baseURL: " + baseURL);
				}
			}	
			return s_url;
		}
		
		private function checkRequestBaseURL(urlRequest: URLRequest): void
		{
			urlRequest.url = convertBaseURL(urlRequest.url);
		}
		
		public function convertBaseURL(url: String): String
		{
			return UniURLLoader.fromBaseURL(url);
		}
		
		
		/**
		 * 
		 * @param urlRequest
		 * 
		 */		
		private function checkRequestData(urlRequest: URLRequest): void
		{
			var url: String = decodeURIComponent(urlRequest.url);
			var urlArr: Array = url.split('?');
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
							trace("variable already exists in request variables ["+varName+"]: oldValue " + urlRequest[varName] + " newValue: " + varValue); 
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
		private function addBasicAuthToURLRequest(urlRequest: URLRequest, 
												  associatedData: Object = null,
												  s_backgroundJobName: String = null,
												  basicAuthAccount: BasicAuthAccount = null): Boolean
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
				
			} else {
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
			var basicAuthCredentialsReady: Boolean = ( username && password);
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
//				basicAuthManager.addEventListener(UniURLLoader.RUN_STOPPED_REQUEST, onRunStoppedRequest);
				var ae: UniURLLoaderEvent = new UniURLLoaderEvent(UniURLLoader.STOP_REQUEST, null, urlRequest, associatedData);
				dispatchEvent(ae);
				return true;
			}
			if (!already_authenticated)
			{
				if (!associatedData)
				{
					associatedData = {};
				}
				var associatedBasicAuth: BasicAuthAccount = associatedData.uniURLLoaderBasicAuthAccount as BasicAuthAccount;
				if (!associatedBasicAuth)
				{
					associatedBasicAuth = new BasicAuthAccount();
				}
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
				encoder.encode(username + ":"+password);
				var credsHeader: URLRequestHeader = new URLRequestHeader("Authorization", "Basic " + encoder.toString())
				urlRequest.requestHeaders.push(credsHeader);
			} else {
				trace("im already authenticated, do not add authentication again");
			}
			
			//				trace("send headers: " + rhArray[0]);
			
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
		public function load(
				urlRequest: URLRequest,
				associatedData: Object = null,
				s_backgroundJobName: String = null,
				useBasicAuthInRequest: Boolean = false,
				basicAuthAccount: BasicAuthAccount = null,
				basicAuthRequestData: UniURLLoaderData = null): void
		{
			checkRequestData(urlRequest);
			checkRequestBaseURL(urlRequest);
			
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
			} else {
				uniURLLoaderData = basicAuthManager.createRequest(urlRequest, this, associatedData, s_backgroundJobName);
			}
				
//			trace("UNIURLLoader load " + urlRequest.url + " " + urlRequest.data);
			var urlLoader: URLLoaderWithAssociatedData = new URLLoaderWithAssociatedData();
			urlLoader.associatedData = associatedData;
			urlLoader.dataFormat = URLLoaderDataFormat.BINARY;
			urlLoader.addEventListener(Event.COMPLETE, onDataComplete);
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
			
			UniURLLoaderManager.instance.addLoaderRequest( urlRequest);
			
//			Log.getLogger('UniURLLoader').info("load " + urlRequest.url + " data:" + urlRequest.data);
			urlLoader.load(urlRequest);
			
			if (debugConsole)
			{
				debugConsole.print("Load URL: " + urlRequest.url, 'Info', 'UniURLLoader');
			}
			var backgroundJob: BackgroundJob = null;
			if(s_backgroundJobName != null)
				backgroundJob = BackgroundJobManager.getInstance().startJob(s_backgroundJobName);
			md_urlLoaderToRequestMap[urlLoader] = {
				request: urlRequest,
				loader: urlLoader,
				backgroundJob: backgroundJob
			};
			
			
			var e: UniURLLoaderEvent = new UniURLLoaderEvent(LOAD_STARTED, null, urlRequest, associatedData);
			dispatchEvent(e);
		}
		
		public function setResponseHeaders(headers: Array, responseURL: String, status: int, loader: Object): void
		{
			trace("UniURLLoader onHttpResponseStatus: status: " + status + " url: " + responseURL);
			var realm: String;
			var basicAuthAccount: BasicAuthAccount;
			
			for each( var header: URLRequestHeader in headers )  {
				trace( "name: " + header.name + "\nvalue: " + header.value + "\n" );
				if (header.name == 'WWW-Authenticate')
				{
					realm = header.value;
					var pos: int = realm.indexOf('"');
					if (pos > -1)
					{
						var pos2: int = realm.indexOf('"', pos+1);
						var correctBasicRealm: String = realm.substring(pos + 1, pos2);
						trace("REALM header: " + realm);
						trace("REALM: " + correctBasicRealm);
						
						if (loader.associatedData)
						{
							if (loader.associatedData.uniURLLoaderBasicAuthAccount)
							{
								basicAuthAccount = loader.associatedData.uniURLLoaderBasicAuthAccount as BasicAuthAccount;
								basicAuthAccount.realm = correctBasicRealm;
							} else {
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
						
						if (loader.associatedData) {
							basicAuthAccount = loader.associatedData.uniURLLoaderBasicAuthAccount as BasicAuthAccount;
						} else {
							loader.associatedData = new Object();
							loader.associatedData.uniURLLoaderBasicAuthAccount = new BasicAuthAccount();
							basicAuthAccount = loader.associatedData.uniURLLoaderBasicAuthAccount as BasicAuthAccount;
						}
						
//						if (!urlLoader.associatedData)
//						{
//							urlRequest.
//						}
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
						{
							requestObject = _baLoader.getData();
							trace("setResponseHeaders: " + requestObject);
						}
						
						openBasicAuthDialog(urlRequest, realm, requestObject, true);
						
						var e: UniURLLoaderEvent = new UniURLLoaderEvent(UniURLLoader.AUTHORIZATION_FAILED, null, urlRequest, loader.associatedData);
						dispatchEvent(e);
					}
				}
			}
		}
		
		private function showBasicAuthPopup(domain: String, realm: String, data: UniURLLoaderData): void
		{
			trace("showBasicAuthPopup: " + data)
			var popup: BasicAuthCredentialsPopup;
			/*
			if (basicAuthCredentialsPopupClass)
			{
			popup = basicAuthCredentialsPopupClass.getPopup();
			} else {
			popup = new BasicAuthCredentialsPopup();
			}
			*/
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
			
			trace("openBasicAuthDialog: " + requestObject);
			
			var domain: String = getDomain(urlRequest);
			var showBasicAuthPopup: Boolean = (basicAuthManager.waitingForCredentials(domain, realm) == false);
			if (!showBasicAuthPopup && forceOpening)
			{
				showBasicAuthPopup = true;
			}
			if (showBasicAuthPopup && requestObject)
			{
//				var requestObject: UniURLLoaderData = basicAuthManager.getRequestByURLWithRealm(urlRequest, realm);
				
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
		
		public function cancel(urlRequest: URLRequest): Boolean
		{
			var key: Object;
			for(key in md_urlLoaderToRequestMap) {
				if(md_urlLoaderToRequestMap[key].request === urlRequest) {
					md_urlLoaderToRequestMap[key].loader.close();
					disconnectURLLoader(URLLoaderWithAssociatedData(md_urlLoaderToRequestMap[key].loader)); 
					delete md_urlLoaderToRequestMap[key];
					return true;
				}
			}
			for(key in md_imageLoaderToRequestMap) {
				var test: * = md_imageLoaderToRequestMap[key];
				if(test && test.hasOwnProperty('request') && test.request)
				{
					
					if(test.request == urlRequest) 
					{
						test.loader.close();
						disconnectImageLoader(LoaderWithAssociatedData(md_imageLoaderToRequestMap[key].loader)); // as LoaderWithAssociatedData);
						delete md_imageLoaderToRequestMap[key];
						return true;
					}
				} else {
					trace("UniURLLoader cancel Loade exists, but it has no request property");
				}
			}
			return false;
		}
		
		protected function isResultContentCorrect(s_format: String, data: Object): Boolean
		{
			return true;
		}
		
		protected function test(event: Event): void
		{
			var urlLoader: URLLoaderWithAssociatedData = URLLoaderWithAssociatedData(event.target);
			var urlRequest: URLRequest;
			
			// Try to use cross-domain 	 if received "Error #2048: Security sandbox violation:" 
				
				var s_proxyURL: String = fromBaseURL(crossDomainProxyURLPattern, proxyBaseURL);
				
				urlRequest = md_urlLoaderToRequestMap[urlLoader].request;
				
				checkRequestData(urlRequest);
				
				var s_url: String = urlRequest.url;
				
//				if (s_url.indexOf('ecmwf') >= 0)
//				{
//					s_url = 'http://wrep.ecmwf.int/wms/?token=MetOceanIE';
//					if (s_url.indexOf('GetCapabilities') >= 0)
//						trace("Stop GetCapabilities");
//					
//						trace("Stop ECMWF");
//				}
//				if (s_url.indexOf('?') >= 0)
//				{
//					s_url = (s_url.split('?') as Array)[0] as String;
//				}
				Log.getLogger('SecurityError').info('s_url: ' + s_url);
				Log.getLogger('SecurityError').info('s_url.indexOf("?"): ' + (s_url.indexOf("?")));
				/*
				if(urlRequest.data) {
					if(s_url.indexOf("?") >= 0)
					{
						if (s_url.indexOf("?") != (s_url.length - 1))
							s_url += "&";
					} else
						s_url += "?";
					
					Log.getLogger('SecurityError').info('STEP 1 s_url: ' + s_url);
					
					if (urlRequest.data is URLVariables)
					{
						s_url += urlRequest.data;
					} else {
						if (urlRequest.data is Object)
						{
							for (var dataItemName: String in urlRequest.data)
							{
								s_url += dataItemName + "=" + urlRequest.data[dataItemName];
							}
						}
					}
					Log.getLogger('SecurityError').info('STEP 2 s_url: ' + s_url);
				
					urlRequest.data = null
				}*/
				s_proxyURL = s_proxyURL.replace("${URL}", encodeURIComponent(s_url));
				Log.getLogger('SecurityError').info('s_proxyURL: ' + s_proxyURL);
				//Alert.show("Got error:\n" + event.text + "\n"
				//		+ "Retrying:\n" + s_proxyURL + "\n",
				//		"SecurityErrorEvent received");
				urlRequest.url = s_proxyURL;
				checkRequestData(urlRequest);
				
				urlLoader.b_crossDomainProxyRequest = true;
				urlLoader.load(urlRequest);
				return;
			
//			urlRequest = disconnectURLLoader(urlLoader);
//			if(urlRequest == null)
//				return;
//			
//			Log.getLogger("UniURLLoader").info("Security error: " + event.text);
//			dispatchFault(urlRequest, urlLoader.associatedData, ERROR_SECURITY, event.text);
		}
		
		/*
		private function onRunStoppedRequest(event: UniURLLoaderEvent): void
		{
			var basicAuthManager: UniURLLoaderBasicAuthManager = UniURLLoaderBasicAuthManager.instance;
			basicAuthManager.removeEventListener(UniURLLoader.RUN_STOPPED_REQUEST, onRunStoppedRequest);
			
			dispatchEvent(event);
		}
		*/
		
		protected function onDataComplete(event: Event): void
		{
			var basicAuthManager: UniURLLoaderBasicAuthManager = UniURLLoaderBasicAuthManager.instance;
			
			
			var urlLoader: URLLoaderWithAssociatedData = URLLoaderWithAssociatedData(event.target);
			var urlRequest: URLRequest = disconnectURLLoader(urlLoader);
			if(urlRequest == null)
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
			//Log.getLogger("UniURLLoader").info("Received " + rawData.length + "B");

			var b0: int = rawData.length > 0 ? rawData.readUnsignedByte() : -1;
			var b1: int = rawData.length > 1 ? rawData.readUnsignedByte() : -1;
			var b2: int = rawData.length > 2 ? rawData.readUnsignedByte() : -1;
			var b3: int = rawData.length > 3 ? rawData.readUnsignedByte() : -1;
			
			rawData.position = 0;
			
			var s_data: String;
			
			for each (var currFormat: String in allowedFormats)
			{
				switch (currFormat)
				{
					case BINARY_FORMAT:
						if(isResultContentCorrect(BINARY_FORMAT, rawData))
							dispatchResult(rawData, urlRequest, urlLoader.associatedData);
//						else
//							dispatchFault(urlRequest, urlLoader.associatedData);
						return;
						break;
					case IMAGE_FORMAT:
						var isPNG: Boolean = b0 == 0x89 && b1 == 0x50 && b2 == 0x4E && b3 == 0x47;
						var isJPG: Boolean = b0 == 0xff && b1 == 0xd8 && b2 == 0xff && b3 == 0xe0;
						 
						// 0x89 P N G
						if(isPNG || isJPG) {
							var imageLoader: LoaderWithAssociatedData = new LoaderWithAssociatedData();
							imageLoader.associatedData = urlLoader.associatedData;
							md_imageLoaderToRequestMap[imageLoader] = urlRequest;
							imageLoader.contentLoaderInfo.addEventListener(Event.COMPLETE, onImageLoaded);
				            imageLoader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, onImageLoadingIOError);
							imageLoader.loadBytes(rawData);
							return;
						}
						break;
						
					case JSON_FORMAT:
						dispatchResult(rawData, urlRequest, urlLoader.associatedData);
						return;
						break;
					case XML_FORMAT:
						// < - this is quite a weak heuristics
						if(b0 == 0x3C) {
							s_data = rawData.readUTFBytes(rawData.length);
							try {
								var x: XML = new XML(s_data);
								
								//FAST check 401 - Unauthorized
								if (HTMLUtils.isHTMLFormat(s_data) && HTMLUtils.isHTML401Unauthorized(s_data))
								{
									//do not do anything it's 401 unathorized html page, should handle this with HTTPStatusEvent
									return;
								}
								
								if(isResultContentCorrect(XML_FORMAT, x))
									dispatchResult(x, urlRequest, urlLoader.associatedData);
								else
									dispatchFault(urlRequest, urlLoader.associatedData, ERROR_INVALID_CONTENT, 'Invalid XML content');
								return;
							}
							catch(e: Error) {
								// if XML parsing fails, just continue with other formats
							}
						}
						break;
					case TEXT_FORMAT:
						// < - this is quite a weak heuristics
						s_data = rawData.readUTFBytes(rawData.length);
						if(isResultContentCorrect(TEXT_FORMAT, s_data))
							dispatchResult(x, urlRequest, urlLoader.associatedData);
						else
							dispatchFault(urlRequest, urlLoader.associatedData, ERROR_INVALID_CONTENT, 'Invalid TEXT content');
						return;
						break;
				}
			}
//			
				dispatchResult(rawData, urlRequest, urlLoader.associatedData);
		}

		protected function onDataIOError(event: IOErrorEvent): void
		{
			trace("onDataIOError");
			var urlLoader: URLLoaderWithAssociatedData = URLLoaderWithAssociatedData(event.target);
			var urlRequest: URLRequest = disconnectURLLoader(urlLoader);
			if(urlRequest == null)
				return;

			Log.getLogger("UniURLLoader").info("I/O error: " + event.text);
			dispatchFault(urlRequest, urlLoader.associatedData, ERROR_IO, event.text);
		}

		protected function onSecurityError(event: SecurityErrorEvent): void
		{
			var urlLoader: URLLoaderWithAssociatedData = URLLoaderWithAssociatedData(event.target);
			var urlRequest: URLRequest;
			
			// Try to use cross-domain 	 if received "Error #2048: Security sandbox violation:" 
			if(crossDomainProxyURLPattern != null
					&& event.text.match(/#2048/)
					&& !urlLoader.b_crossDomainProxyRequest) 
			{
				
				loadCrossDomainProxyURLPattern(urlLoader);
				return;
			}

			urlRequest = disconnectURLLoader(urlLoader);
			if(urlRequest == null)
				return;

			Log.getLogger("UniURLLoader").info("Security error: " + event.text);
			dispatchFault(urlRequest, urlLoader.associatedData, ERROR_SECURITY, event.text);
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
			if(urlRequest.data) {
				if(s_url.indexOf("?") >= 0)
				{
					if (s_url.indexOf("?") != (s_url.length - 1))
						s_url += "&";
				} else
					s_url += "?";
				
				Log.getLogger('SecurityError').info('STEP 1 s_url: ' + s_url);
				
				if (urlRequest.data is URLVariables)
				{
					s_url += urlRequest.data;
				} else {
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
			//Alert.show("Got error:\n" + event.text + "\n"
			//		+ "Retrying:\n" + s_proxyURL + "\n",
			//		"SecurityErrorEvent received");
			urlRequest.url = s_proxyURL;
			checkRequestData(urlRequest);
			urlLoader.b_crossDomainProxyRequest = true;
			urlLoader.load(urlRequest);
		}
		
		protected function onImageLoaded(event: Event): void
		{
			var imageLoader: LoaderWithAssociatedData = LoaderWithAssociatedData(event.target.loader);
			var urlRequest: URLRequest = disconnectImageLoader(imageLoader);
			if(urlRequest == null)
				return;

			dispatchResult(imageLoader.content, urlRequest, imageLoader.associatedData);
		}

		protected function onImageLoadingIOError(event: IOErrorEvent): void
		{
			var imageLoader: LoaderWithAssociatedData = LoaderWithAssociatedData(event.target.loader);
			var urlRequest: URLRequest = disconnectImageLoader(imageLoader);
			if(urlRequest == null)
				return;

			dispatchFault(urlRequest, imageLoader.associatedData, ERROR_BAD_IMAGE, event.text);
		}
		
		protected function dispatchResult(
				result: Object, urlRequest: URLRequest, associatedData: Object): void
		{
			var e: UniURLLoaderEvent = new UniURLLoaderEvent(
					DATA_LOADED, result, urlRequest, associatedData, false, true);
			dispatchEvent(e);  
		}

		protected function dispatchFault(
				urlRequest: URLRequest, associatedData: Object,
				faultCode: String,
				faultString: String,
				faultDetail: String = null): void
		{
			dispatchEvent(new UniURLLoaderEvent(
					DATA_LOAD_FAILED,
					new Fault(faultCode, faultString, faultDetail),
					urlRequest, associatedData,
					false, true));  
		}

		protected function disconnectURLLoader(urlLoader: URLLoaderWithAssociatedData): URLRequest
		{
			if (_baLoader)
			{
				_baLoader.removeBasicAuthListeners();
			}
			
			urlLoader.removeEventListener(Event.COMPLETE, onDataComplete);
			urlLoader.removeEventListener(IOErrorEvent.IO_ERROR, onDataIOError);
			urlLoader.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, onSecurityError);
			if(!urlLoader in md_urlLoaderToRequestMap)
				return null;

			// finish background job if it was started
			var backgroundJob: BackgroundJob = md_urlLoaderToRequestMap[urlLoader].backgroundJob;
			if(backgroundJob != null)
				BackgroundJobManager.getInstance().finishJob(backgroundJob);
			
			
			var urlRequest: URLRequest = md_urlLoaderToRequestMap[urlLoader].request; 
			
			UniURLLoaderManager.instance.removeLoaderRequest(urlRequest);
			
			delete md_urlLoaderToRequestMap[urlLoader];
			return urlRequest;
		}

		protected function disconnectImageLoader(imageLoader: LoaderWithAssociatedData): URLRequest
		{
			imageLoader.contentLoaderInfo.removeEventListener(Event.COMPLETE, onImageLoaded);
            imageLoader.contentLoaderInfo.removeEventListener(IOErrorEvent.IO_ERROR, onImageLoadingIOError);
			var urlRequest: URLRequest = md_imageLoaderToRequestMap[imageLoader]; 
			if(!imageLoader in md_imageLoaderToRequestMap)
				return null;
			delete md_imageLoaderToRequestMap[imageLoader];
			return urlRequest;
		}
		
		
		
		override public function toString(): String
		{
			return "UniURLLoader";
		}
		
	}
}

import flash.display.Loader;
import flash.net.URLLoader;

class URLLoaderWithAssociatedData extends URLLoader
{
	public var associatedData: Object;
	public var b_crossDomainProxyRequest: Boolean = false;
}

class LoaderWithAssociatedData extends Loader
{
	public var associatedData: Object;
}
