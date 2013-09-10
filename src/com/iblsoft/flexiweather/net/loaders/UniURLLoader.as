package com.iblsoft.flexiweather.net.loaders
{
	import com.iblsoft.flexiweather.net.UniURLLoaderFormat;
	import com.iblsoft.flexiweather.net.events.UniURLLoaderErrorEvent;
	import com.iblsoft.flexiweather.utils.HTMLUtils;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.net.URLRequest;
	import flash.utils.ByteArray;
	import flash.utils.Dictionary;
	import mx.rpc.events.XMLLoadEvent;
	import mx.utils.ObjectUtil;

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
	public class UniURLLoader extends ImageLoader
	{
		public static var INVALID_FORMAT: int = 1;
		public static var MORE_FORMATS_ALLOWED: int = 2;

		/**
		 * Array of allowed formats which will be loaded into loader. If there will be loaded format, which will not be included in allowedFormats array
		 * there will be FAIL dispatched.
		 * Please note, that it depends on order of formats in array. If TEXT will be included before XML, it will be checked if result is in TEXT format
		 * and it will be dispatch as TEXT object. If you want to check XML first, please add XML format before TEXT format.
		 * Supported formats are just formats which are defined in this class (see above) BINARY, IMAGE, JSON, TEXT, XML
		 */
		public var allowedFormats: Array;

		public function UniURLLoader()
		{
			allowedFormats = [UniURLLoaderFormat.XML_FORMAT, UniURLLoaderFormat.IMAGE_FORMAT, UniURLLoaderFormat.JSON_FORMAT];
		}

		override public function destroy(): void
		{
			super.destroy();
			allowedFormats = null;
		}

		override protected function decodeResult(rawData: ByteArray, urlLoader: URLLoaderWithAssociatedData, urlRequest: URLRequest, resultCallback: Function, errorCallback: Function): void
		{
			debug("decodeResult");
			var test: ByteArray = ObjectUtil.copy(rawData) as ByteArray;
			var s_data: String = test.readUTFBytes(test.length);
			
			test.clear();
			
			//we need to autodect correct format
			var isValidDictionary: Dictionary = new Dictionary();
			var currFormat: String;
			var validFormats: int = 0;
			for each (currFormat in allowedFormats)
			{
				switch (currFormat)
				{
					case UniURLLoaderFormat.BINARY_FORMAT:
					{
						//binary format is always valid
						isValidDictionary[UniURLLoaderFormat.BINARY_FORMAT] = true;
						//do not increment validFormats, BINARY FORMAT is always valid
						break;
					}
					case UniURLLoaderFormat.IMAGE_FORMAT:
					{
						isValidDictionary[UniURLLoaderFormat.IMAGE_FORMAT] = ImageLoader.isValidImage(rawData);
						if (isValidDictionary[UniURLLoaderFormat.IMAGE_FORMAT])
							validFormats++;
						break;
					}
					case UniURLLoaderFormat.JSON_FORMAT:
					{
						isValidDictionary[UniURLLoaderFormat.JSON_FORMAT] = JSONLoader.isValidJSON(rawData);
						if (isValidDictionary[UniURLLoaderFormat.JSON_FORMAT])
							validFormats++;
						break;
					}
					case UniURLLoaderFormat.XML_FORMAT:
					{
						isValidDictionary[UniURLLoaderFormat.XML_FORMAT] = XMLLoader.isValidXML(rawData);
						if (isValidDictionary[UniURLLoaderFormat.XML_FORMAT])
							validFormats++;
						break;
					}
					case UniURLLoaderFormat.HTML_FORMAT:
					{
						isValidDictionary[UniURLLoaderFormat.HTML_FORMAT] = HTMLLoader.isValidHTML(rawData);
						if (isValidDictionary[UniURLLoaderFormat.HTML_FORMAT])
							validFormats++;
						break;
					}
					case UniURLLoaderFormat.TEXT_FORMAT:
					{
						//always valid
						isValidDictionary[UniURLLoaderFormat.TEXT_FORMAT] = true;
						//do not increment validFormats, TEXT_FORMAT is always valid
						break;
					}
				}
			}
			debug("decodeResult validFormats: " + validFormats);
			//check how many valid formats were detected except BINARY and TEXT (they are always valid)
			if (validFormats == 0)
			{
				//check if allowFormats contains BINARY or TEXT
				if (isValidFormats(UniURLLoaderFormat.TEXT_FORMAT) || isValidFormats(UniURLLoaderFormat.BINARY_FORMAT))
				{
					//TODO: should we dispatch binary data or text data?
					dispatchResult(rawData, urlRequest, urlLoader.associatedData);
				}
				else
					dispatchFault('UniURLLoader: Invalid content. Any of allowed formats was found.', INVALID_FORMAT, rawData, urlRequest, urlLoader.associatedData);
			}
			else
			{
				if (validFormats == 1)
				{
					var htmlSource: String;
					//there is just one allowed formats, dispatch correct result
					for each (currFormat in allowedFormats)
					{
						switch (currFormat)
						{
							case UniURLLoaderFormat.IMAGE_FORMAT:
							{
								if (isValidDictionary[UniURLLoaderFormat.IMAGE_FORMAT])
								{
									dispatchImage(rawData, urlLoader, urlRequest, resultCallback, errorCallback);
									return;
								}
								break;
							}
							case UniURLLoaderFormat.JSON_FORMAT:
							{
								if (isValidDictionary[UniURLLoaderFormat.JSON_FORMAT])
								{
									dispatchResult(JSONLoader.getJSON(rawData), urlRequest, urlLoader.associatedData);
									return;
								}
								break;
							}
							case UniURLLoaderFormat.XML_FORMAT:
							{
								if (isValidDictionary[UniURLLoaderFormat.XML_FORMAT])
								{
									htmlSource = HTMLLoader.getHTMLSource(rawData);
									//FAST check 401 - Unauthorized
									if (HTMLUtils.isHTMLFormat(htmlSource) && HTMLUtils.isHTML401Unauthorized(htmlSource))
									{
										//do not do anything it's 401 unathorized html page, should handle this with HTTPStatusEvent
										return;
									}
									var xml: XML = XMLLoader.getXML(rawData);
									dispatchResult(xml, urlRequest, urlLoader.associatedData);
									return;
								}
								break;
							}
							case UniURLLoaderFormat.HTML_FORMAT:
							{
								if (isValidDictionary[UniURLLoaderFormat.HTML_FORMAT])
								{
									htmlSource = HTMLLoader.getHTMLSource(rawData);
									dispatchResult(htmlSource, urlRequest, urlLoader.associatedData);
									return;
								}
								break;
							}
						}
					}
				}
				else
				{
					//there are more allowed formats detected, what it should be done now?
					//only case valid for this, is received HTML, which can be also valid XML, so check this case
					if (isValidFormats(UniURLLoaderFormat.XML_FORMAT) || isValidFormats(UniURLLoaderFormat.HTML_FORMAT))
					{
						//dispatch html as xml
						dispatchResult(XMLLoader.getXML(rawData), urlRequest, urlLoader.associatedData);
						return;
					}
					else
					{
						var formatsList: String = '';
						for (var format: String in isValidDictionary)
						{
							formatsList += format + ", ";
						}
						//TODO for now Fault will be dispatch to let user or developer know, that there are more allowed formats detected
						dispatchFault('UniURLLoader: More allowed formats detected. [' + formatsList + ']', MORE_FORMATS_ALLOWED, rawData, urlRequest, urlLoader.associatedData);
						return;
					}
				}
			}
			
			isValidDictionary = null;
			
			debug("decodeResult Invalid content: " + validFormats);
			//			
			//dispatch fault, if any other format has not dispatched result
			dispatchFault('UniURLLoader: Invalid content. Any of allowed formats was found.', INVALID_FORMAT, rawData, urlRequest, urlLoader.associatedData);
		}

		/**
		 * Helper function to dispatch image. Image needs to be loaded for binary loaded, which was received
		 *
		 */
		private function dispatchImage(rawData: ByteArray, urlLoader: URLLoaderWithAssociatedData, urlRequest: URLRequest, resultCallback: Function, errorCallback: Function): void
		{
			loadImage(rawData, urlLoader, urlRequest, resultCallback, errorCallback);
		}

		private function isValidFormats(format: String): Boolean
		{
			for each (var currFormat: String in allowedFormats)
			{
				if (currFormat == format)
					return true;
			}
			return false;
		}

		override public function toString(): String
		{
			return "UniURLLoader";
		}
	}
}
