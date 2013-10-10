package com.iblsoft.flexiweather.net.loaders
{
	import com.iblsoft.flexiweather.net.loaders.errors.URLLoaderError;
	import com.iblsoft.flexiweather.ogc.kml.data.KMLType;
	
	import flash.events.IEventDispatcher;
	import flash.net.URLRequest;
	import flash.utils.ByteArray;
	
	import mx.utils.ObjectUtil;

	/**
	 * Use this class to load KML or KMZ, when you do not know if result will be KML or KMZ. DecodeResult will try to find out if it is KML or KML 
	 * @author fkormanak
	 * 
	 */	
	public class KMLGenericLoader extends AbstractURLLoader
	{
		public function KMLGenericLoader(target: IEventDispatcher = null)
		{
			super(target);
		}

		override protected function decodeResult(rawData: ByteArray, urlLoader: URLLoaderWithAssociatedData, urlRequest: URLRequest, resultCallback: Function, errorCallback: Function): void
		{
			if (XMLLoader.isValidXML(rawData))
			{
				//response is XML so it's KML not KMZ
				var xml: XML = XMLLoader.getXML(rawData);
				resultCallback(xml, urlRequest, urlLoader.associatedData);
			} else {
				//if it's not KML, loader suppose it's KMZ.
				//TODO do we need to check if it's valid ZIP file in loaded
				dispatchResult(rawData, urlRequest, urlLoader.associatedData);
			}
		}
		
		/**
		 *  
		 * @param rawData
		 * @return 
		 * 
		 */		
		public static function getKMLType(rawData: ByteArray): String
		{
			if (XMLLoader.isValidXML(rawData))
			{
				return KMLType.KML;
			}
			
			if (KMZLoader.isValidKMZ(rawData))
				return KMLType.KMZ;
			
			return KMLType.UNKNOWN;
		}
		
		
	}
}
