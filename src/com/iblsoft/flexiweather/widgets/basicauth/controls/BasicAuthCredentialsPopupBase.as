package com.iblsoft.flexiweather.widgets.basicauth.controls
{
	import com.iblsoft.flexiweather.net.data.UniURLLoaderData;
	import com.iblsoft.flexiweather.plugins.IPopupManager;
	import com.iblsoft.flexiweather.widgets.basicauth.events.BasicAuthEvent;
	import mx.core.IFlexDisplayObject;
	import spark.components.TitleWindow;

	public class BasicAuthCredentialsPopupBase extends TitleWindow implements IBasicAuthCredentialsPopup
	{
		private var popupManager: IPopupManager;
		[Bindable]
		public var domain: String;
		[Bindable]
		public var realm: String;
		public var requestData: UniURLLoaderData;

		public function BasicAuthCredentialsPopupBase()
		{
			super();
		}

		public function login(username: String, password: String, domain: String, realm: String, data: UniURLLoaderData): void
		{
			var bae: BasicAuthEvent = new BasicAuthEvent(BasicAuthEvent.CREDENTIALS_READY);
			bae.username = username;
			bae.password = password;
			bae.domain = domain;
			bae.realm = realm;
			bae.requestData = data;
			dispatchEvent(bae);
		}

		public function cancelAuthentication(domain: String, realm: String, data: UniURLLoaderData): void
		{
			var bae: BasicAuthEvent = new BasicAuthEvent(BasicAuthEvent.AUTHENTICATION_CANCELLED);
			bae.domain = domain;
			bae.realm = realm;
			bae.requestData = data;
			dispatchEvent(bae);
		}

		public function canBeClosed(): Boolean
		{
			return false;
		}

		public function getPopup(): IFlexDisplayObject
		{
			return this;
		}

		public function popupIsClosing(): void
		{
		}

		public function popupIsOpening(): void
		{
		}

		public function setPopupManager(popupManager: IPopupManager): void
		{
			this.popupManager = popupManager;
		}
	}
}
