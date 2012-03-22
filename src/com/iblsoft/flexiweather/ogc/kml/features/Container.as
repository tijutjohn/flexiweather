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
	public class Container extends KMLFeature
	{
//		private var atom:Namespace = Namespaces.ATOM_NS;
//		private var georss:Namespace = Namespaces.GEORSS_NS;

		private var _features:Array;
		
		/**
		*	Constructor for class.
		* 
		*	@param x An XML document that contains an individual Entry element from 
		*	an Aton XML feed.
		*
		* 	@langversion ActionScript 3.0
		*	@playerversion Flash 8.5
		*	@tiptext
		*/	
		public function Container(kml: KML, s_namespace: String, x:XMLList)
		{
			super(kml, s_namespace, x);
			
			var kmlns:Namespace = new Namespace(s_namespace);

			// Features are: Placemark, GroundOverlay, ScreenOverlay, PhotoOverlay, NetworkLink, Folder, Document
			// We'll only support Placemark, GroundOverlay, Folder, and Document
			
			this._features = new Array();
		 	
			var i:XML;
			var folder: Folder;
			var document: Document;
			
			for each (i in this.xml.kmlns::Placemark) {
				var placemark: Placemark = new Placemark(kml, s_namespace, XMLList(i)) 
				addFeature(placemark);
			}
			for each (i in this.xml.kmlns::GroundOverlay) {
				var groundOverlay: GroundOverlay = new GroundOverlay(kml, s_namespace, XMLList(i))
				addFeature(groundOverlay);
			}
			for each (i in this.xml.kmlns::ScreenOverlay) {
				var screenOverlay: ScreenOverlay = new ScreenOverlay(kml, s_namespace, XMLList(i))
				addFeature(screenOverlay);
			}
			for each (i in this.xml.kmlns::Folder) {
				folder = new Folder(kml, s_namespace, XMLList(i));
				addFeature(folder);
			}
			for each (i in this.xml.kmlns::Document) {
				trace("\n\n Document node: " + i.toXMLString() + "\n\n");
//				folder = new Folder(XMLList(i));
				document = new Document(kml, s_namespace, XMLList(i));
				addFeature(document);
			}
		}

		override public function set parentDocument(value: Document): void
		{
			super.parentDocument = value;
			
			for each (var childFeature: KMLFeature in features)
			{
				childFeature.parentDocument = value;
			}
		}
		
		/**
		 * Add feature to feature container
		 *  
		 * @param feature
		 * 
		 */		
		public function addFeature(feature: KMLFeature): void
		{
			if (feature)
				feature.parentFeature = this;
			
			if (this is Document) {
				feature.parentDocument = this as Document;
				//FIXME check all children features if parent are set
//				var document: Document = feature as Document;
//				for each (var childFeature: KMLFeature in document)
//				{
//					childFeature.parentDocument = document;
//				}
			} else {
				if (parentDocument)
				{
					//if this container has already set parentDocument, set it to new child feature as well
					feature.parentDocument = parentDocument;
				}
			}
			
			_features.push(feature);
		}
		
		/**
		*	A String that contains the title for the entry.
		*
		* 	@langversion ActionScript 3.0
		*	@playerversion Flash 8.5
		*	@tiptext
		*/	
		public function get features():Array
		{
			return this._features;
		}
		
		public override function toString():String {
			var str:String = "";
			var i: KMLFeature;
			for each (i in this._features) {
				str += this._features + "\n";
			}
			return "Container: " + str;
		}
	}
}
