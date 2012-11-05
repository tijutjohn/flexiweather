package com.iblsoft.flexiweather.widgets.basicauth.controls
{
	import com.iblsoft.flexiweather.net.data.UniURLLoaderData;
	import com.iblsoft.flexiweather.plugins.IPopup;

	public interface IBasicAuthCredentialsPopup extends IPopup
	{
		/**
		 * Needs to dispatch BasicAuthEvent.CREDENTIALS_READY with filled up username and password
		 *
		 * @param username
		 * @param password
		 * @param domain
		 * @param realm
		 * @param data UniURLLoaderData returned by UniURLLoaderBasicAuthManager.createRequest (or addRequest) before showing BasiAuth credentials popup
		 *
		 */
		function login(username: String, password: String, domain: String, realm: String, data: UniURLLoaderData): void;
		function cancelAuthentication(domain: String, realm: String, data: UniURLLoaderData): void;
	}
}
