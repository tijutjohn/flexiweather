package com.iblsoft.flexiweather.ogc.kml.features
{
	import com.iblsoft.flexiweather.net.events.UniURLLoaderErrorEvent;
	import com.iblsoft.flexiweather.net.events.UniURLLoaderEvent;
	import com.iblsoft.flexiweather.net.loaders.UniURLLoader;
	import com.iblsoft.flexiweather.ogc.FeatureBase;
	import com.iblsoft.flexiweather.ogc.InteractiveLayerFeatureBase;
	import com.iblsoft.flexiweather.ogc.kml.events.KMLFeatureEvent;
	import com.iblsoft.flexiweather.ogc.kml.features.styles.Style;
	import com.iblsoft.flexiweather.ogc.kml.features.styles.StyleMap;
	import com.iblsoft.flexiweather.ogc.kml.features.styles.StyleSelector;
	import com.iblsoft.flexiweather.syndication.ParsingTools;
	import com.iblsoft.flexiweather.utils.AnticollisionLayout;
	import com.iblsoft.flexiweather.utils.AnticollisionLayoutObject;
	import com.iblsoft.flexiweather.widgets.InteractiveWidget;
	
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	import flash.net.URLRequest;
	
	import mx.states.OverrideBase;
	import mx.utils.object_proxy;
	
	/**
	 * Main class for KML feature
	 *  
	 * @author fkormanak
	 * 
	 */	
	public class KMLFeature extends FeatureBase
	{
		override public function set x(value:Number):void
		{
			super.x = value;
//			trace("feature: x: " + x);
			notifyPositionChange();
		}
		override public function set y(value:Number):void
		{
			super.y = value;
//			trace("feature: y: " + y);
			notifyPositionChange();
		}
		override public function set visible(value:Boolean):void
		{
			var oldValue: Boolean = super.visible;
			
			super.visible = value;
			if (value != oldValue)
			{
				notifyVisibilityChange();
			}
		}
		
		private var _xmlList:XMLList;
		
		public var _name:String;
		public var _id:String;
		//		public var _link: com.adobe.xml.syndication.atom.Link;
		public var _visibility:Boolean = true;
		public var _open:Boolean = false;
		//		public var _author:Author;
		public var _snippet:String;
		
		public var _styleUrl:String;
		public var _styleSelector: StyleSelector;
		
		public var _lookAt: LookAt;
		
		public var _description:String;
		
		private var _parentDocument: Document;
		private var _parentFeature: KMLFeature;
		
		private var _kmlIcon: KMLIcon;
		private var _kmlLabel: KMLLabel;
		
		public function get kmlIcon(): KMLIcon
		{
			return _kmlIcon;
		}
		public function get kmlLabel(): KMLLabel 
		{
			return _kmlLabel;
		}
		
		private var _kml: KML
		public function get kml(): KML
		{
			return _kml;
		}
		
		private var _kmlns: Namespace;
		public function get kmlns(): Namespace
		{
			if (!_kmlns)
				_kmlns = new Namespace(ms_namespace);
			
			return _kmlns;
		}
//		public function KMLFeature(s_xml: XMLList, s_namespace:String, s_typeName:String, s_featureId:String)
		public function KMLFeature(kml: KML, s_namespace: String, s_xml: XMLList)
		{
//			super(s_namespace, s_typeName, s_featureId);
			super(s_namespace, null, null);
		
			_kml = kml;
			
			_kmlns = new Namespace(s_namespace);
			
			createKMLLabel();
			
			_xmlList = s_xml;
			parse();
			
			mouseEnabled = true;
			mouseChildren = true;
			doubleClickEnabled = true;
			addEventListener(MouseEvent.CLICK, onKMLFeatureClick);
		}
		
		protected function createIcon(): void
		{
			_kmlIcon = new KMLIcon(this);
			addChild(_kmlIcon);
		}
		protected function createKMLLabel(): void
		{
			_kmlLabel = new KMLLabel();
//			addChild(_kmlLabel);
		}
		
		public override function cleanup(): void
		{
			master.container.labelLayout.removeObject(this);
			master.container.labelLayout.removeObject(_kmlLabel);
			
			master.container.objectLayout.removeObject(this);
			
			super.cleanup();
		}
		
		private function onKMLFeatureClick(event: MouseEvent): void
		{
			var kfe: KMLFeatureEvent = new KMLFeatureEvent(KMLFeatureEvent.KML_FEATURE_CLICK, true);
			kfe.kmlFeature = this;
			dispatchEvent(kfe);
		}
		protected function parse(): void
		{
			if (!_xmlList)
				return;
			
			this._id = ParsingTools.nullCheck(_xmlList.@id);
			this._name = ParsingTools.nullCheck(_xmlList.kmlns::name);
			
			this._description = ParsingTools.nullCheck(_xmlList.kmlns::description);
			this._snippet = ParsingTools.nullCheck(_xmlList.kmlns::Snippet);
			this._styleUrl = ParsingTools.nullCheck(_xmlList.kmlns::styleUrl);
			
			if (ParsingTools.nullCheck(this.xml.kmlns::Style)) {
				this._styleSelector = new Style(kml, ms_namespace, this.xml.kmlns::Style, parentDocument);
			}
			if (ParsingTools.nullCheck(this.xml.kmlns::StyleMap)) {
				this._styleSelector = new StyleMap(kml, ms_namespace, this.xml.kmlns::StyleMap, parentDocument);
			}
			if (ParsingTools.nullCheck(this.xml.kmlns::LookAt)) {
				this._lookAt = new LookAt(ms_namespace, this.xml.kmlns::LookAt);
			}
			
			trace("Feature name: " + _name + " ID: " + _id);
			trace("\t description: " + _description);
			trace("\t snippet: " + _snippet);
			
			dispatchEvent(new Event("nameChanged"));
			
			/*
			if (ParsingTools.nullCheck(_xmlList.atom::link) != null) {
			this._link = new com.adobe.xml.syndication.atom.Link::Link(_xmlList.atom::link);
			}
			
			if (ParsingTools.nullCheck(_xmlList.atom::author) != null) {
			this._author = new Author(_xmlList.atom::author);
			}
			*/
			
			var visibility:Number = ParsingTools.nanCheck(_xmlList.kmlns::visibility);
			if (visibility == 1) {
				this._visibility = true;
			} else if (visibility == 0) {
				this._visibility = false;
			}
			
			var open:Number = ParsingTools.nanCheck(_xmlList.kmlns::open);
			if (open == 1) {
				this._open = true;
			} else if (open == 0) {
				this._open = false;
			}
		}
		
		/** Called after the feature is added to master or after any change (e.g. area change). */
		override public function update(): void
		{
			super.update();
			if (m_points && m_points.length > 0)
			{
				if (m_points.length > 1)
				{
					trace("Attention: KML Feature has more than 1 point");
				}
				var pos: flash.geom.Point = m_points.getItemAt(0) as flash.geom.Point;
//				this.x = pos.x;
//				this.y = pos.y;
				
//				trace("change position to ["+this.x+","+this.y+"] for KML feature : " + this);
			}
		}
		
		private function getKMLVisibility(): Boolean
		{
			if (!visibility)
			{
				return false;
			} else {
				if (parentFeature)
					return parentFeature.visibility;
			}
			return true;
		}
		private function notifyVisibilityChange(): void
		{
			var kfe: KMLFeatureEvent = new KMLFeatureEvent(KMLFeatureEvent.KML_FEATURE_VISIBILITY_CHANGE, true);
			kfe.kmlFeature = this;
			dispatchEvent(kfe);
		}
		
		private function notifyPositionChange(): void
		{
			var kfe: KMLFeatureEvent = new KMLFeatureEvent(KMLFeatureEvent.KML_FEATURE_POSITION_CHANGE, true);
			kfe.kmlFeature = this;
			dispatchEvent(kfe);
		}
		/**
		 * @langversion ActionScript 3.0
		 * @playerversion Flash 8.5
		 * @tiptext
		 */
		public function get parentDocument(): Document
		{
			return _parentDocument;
		}
		public function set parentDocument(value: Document): void
		{
			_parentDocument = value;
		}
		
		public function get parentFeature(): KMLFeature
		{
			return _parentFeature;
		}
		public function set parentFeature(value: KMLFeature): void
		{
			_parentFeature = value;
		}
		/**
		 * Get the XML used to populate the NewsFeedElement.
		 *
		 * @langversion ActionScript 3.0
		 * @playerversion Flash 8.5
		 * @tiptext
		 */
		public function get xml():XMLList
		{
			return _xmlList;
		}
		
		/**
		 * Set the XML used to populate the NewsFeedElement.
		 *
		 * @param x The XML used to populate the NewsFeedElement.
		 * @langversion ActionScript 3.0
		 * @playerversion Flash 8.5
		 * @tiptext
		 */
		public function set xml(x:XMLList):void
		{
			_xmlList = x;
		}
		
		/**
		 *	The string in the name tag.
		 */	
		[Bindable (event="nameChanged")]
		public override function get name():String
		{
			return this._name;
		}
		
		public function get style(): StyleSelector
		{
			if (_styleUrl && _parentDocument)
			{
				var currStyle: StyleSelector = _parentDocument.getStyleSelectorByID(_styleUrl);
			}
			var hasStyle: Boolean = _styleSelector != null;
			var hasStyleURL: Boolean = (currStyle != null)
				
			//check current style first
			if (hasStyle && !hasStyleURL)
				return _styleSelector;
			if (!hasStyle && hasStyleURL)
				return currStyle;
			
			if (hasStyle && hasStyleURL)
			{
				//has both, check what to do
				
				//for now return style by styleURL
				return currStyle;
			}
			return null;
		}
		/**
		 *	An array containing one or more link objects relating to this entry.
		 */	
		/*
		public function get link(): com.adobe.xml.syndication.atom.Link::Link
		{	
		return this._link;
		}
		*/
		
		/**
		 *	A String that uniquely identifies the Entry.
		 *
		 *	This property conveys a permanent, universally unique identifier for
		 *	an entry or feed.
		 *
		 * 	@langversion ActionScript 3.0
		 *	@playerversion Flash 8.5
		 *	@tiptext
		 */	
		public function get visibility():Boolean
		{
			return this._visibility;
		}
		public function get kmlVisibility():Boolean
		{
			return getKMLVisibility();
		}
		
		/**
		 *	A String that uniquely identifies the Entry.
		 *
		 *	This property conveys a permanent, universally unique identifier for
		 *	an entry or feed.
		 *
		 * 	@langversion ActionScript 3.0
		 *	@playerversion Flash 8.5
		 *	@tiptext
		 */	
		public function get open():Boolean
		{
			return this._open;
		}
		
		
		/**
		 *	An Array of Author objects that represent the authors for the entry.
		 *
		 * 	@langversion ActionScript 3.0
		 *	@playerversion Flash 8.5
		 *	@tiptext
		 */	
		/*
		public function get author():Author
		{
		return this._author;
		}
		*/
		
		
		/**
		 *	A Content object that contains the content of the entry.
		 *
		 * 	@langversion ActionScript 3.0
		 *	@playerversion Flash 8.5
		 *	@tiptext
		 */	
		public function get description():String
		{
			return this._description;
		}
		
		/**
		 *	A Content object that contains the content of the entry.
		 *
		 * 	@langversion ActionScript 3.0
		 *	@playerversion Flash 8.5
		 *	@tiptext
		 */	
		public function get snippet():String
		{
			return this._snippet;
		}
		
		public override function toString():String {
			//			return super.toString() + "name: " + _name +
			//				   "id: " + _id +
			//				   "link: " + _link +
			//				   "visibility: " + _visibility +
			//				   "open: " + _open +
			//				   "author: " + _author +
			//				   "snippet: " + snippet +
			//				   "description: " + description +
			//				   "\n";
			return super.toString() + "name: " + _name +
				"id: " + _id +
				"visibility: " + _visibility +
				"open: " + _open +
				"snippet: " + snippet +
				"description: " + description +
				"\n";
		}
	}
}