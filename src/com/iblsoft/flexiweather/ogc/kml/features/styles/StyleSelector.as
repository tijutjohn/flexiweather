package com.iblsoft.flexiweather.ogc.kml.features.styles
{
	import com.iblsoft.flexiweather.net.events.UniURLLoaderErrorEvent;
	import com.iblsoft.flexiweather.net.events.UniURLLoaderEvent;
	import com.iblsoft.flexiweather.net.loaders.UniURLLoader;
	import com.iblsoft.flexiweather.ogc.kml.controls.KMLBitmapLoader;
	import com.iblsoft.flexiweather.ogc.kml.events.KMLBitmapEvent;
	import com.iblsoft.flexiweather.ogc.kml.features.Document;
	import com.iblsoft.flexiweather.ogc.kml.features.KML;
	import com.iblsoft.flexiweather.syndication.Namespaces;
	import com.iblsoft.flexiweather.syndication.ParsingTools;
	import com.iblsoft.flexiweather.syndication.XmlElement;
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.net.URLRequest;
	import flash.utils.Dictionary;

	public class StyleSelector extends XmlElement
	{
		private var _id: String;
//		private var _iconCallbacks: Array;
//		private var _iconSucessfulCallbacks: Array;
//		private var _iconUnsucessfulCallback: Array;
		private var _document: Document;
//		private var _loader: KMLBitmapLoader;
		private var _href: String;
		private var _kml: KML

		public function get kml(): KML
		{
			return _kml;
		}

		public function StyleSelector(kml: KML, s_namespace: String, x: XMLList, document: Document)
		{
			super(s_namespace, x);
			_kml = kml;
			_document = document;
			this._id = ParsingTools.nullCheck(this.xml.@id);
		}

		override public function cleanupKML(): void
		{
			super.cleanupKML();
			_kml = null;
			_document = null;
		}

		/*
		public function getClonedBitmap(): Bitmap
		{
			if (_loader && _loader.bitmapData)
				return new Bitmap(_loader.bitmapData);

			return null;
		}

		public function get iconBitmapData(): BitmapData
		{
			if (_loader && _loader.bitmapData)
				return _loader.bitmapData;

			return null;
		}

		public function get isIconLoaded(): Boolean
		{
			if (_loader && _loader.bitmapData)
				return (_loader.bitmapData != null);

			return false;
		}*/
		public function href(): String
		{
			return _href;
		}

		/**
		 *	A String that contains the title for the entry.
		 */
		public function get id(): String
		{
			return this._id;
		}

		override public function toString(): String
		{
			return "StyleSelector with id: " + this._id;
		}
	}
}
