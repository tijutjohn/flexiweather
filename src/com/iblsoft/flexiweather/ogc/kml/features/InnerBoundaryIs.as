package com.iblsoft.flexiweather.ogc.kml.features
{
	import com.iblsoft.flexiweather.syndication.Namespaces;


	/**
	*	Class that represents an Entry element within an Atom feed
	* 
	* 	@langversion ActionScript 3.0
	*	@playerversion Flash 8.5
	*	@tiptext
	* 
	* 	@see http://www.atomenabled.org/developers/syndication/atom-format-spec.php#rfc.section.4.1.2
	*/
	public class InnerBoundaryIs extends BoundaryCommon
	{
		
		/**
		*	Constructor for class.
		* 
		*	@param x An XML document that contains an individual Entry element from 
		*	an Aton XML feed.
		*
		*/	
		public function InnerBoundaryIs(s_namespace: String, x:XMLList)
		{
			super(s_namespace, x);
			
			var kml:Namespace = new Namespace(s_namespace);
		}
		
		public override function toString():String {
			return "InnerBoundaryIs: " + super.toString();
		}
	}
}
