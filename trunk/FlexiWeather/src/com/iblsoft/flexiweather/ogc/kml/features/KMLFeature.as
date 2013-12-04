package com.iblsoft.flexiweather.ogc.kml.features
{
	import com.iblsoft.flexiweather.net.events.UniURLLoaderErrorEvent;
	import com.iblsoft.flexiweather.net.events.UniURLLoaderEvent;
	import com.iblsoft.flexiweather.net.loaders.UniURLLoader;
	import com.iblsoft.flexiweather.ogc.BBox;
	import com.iblsoft.flexiweather.ogc.CRSWithBBox;
	import com.iblsoft.flexiweather.ogc.FeatureBase;
	import com.iblsoft.flexiweather.ogc.FeatureUpdateContext;
	import com.iblsoft.flexiweather.ogc.InteractiveLayerFeatureBase;
	import com.iblsoft.flexiweather.ogc.events.ReflectionEvent;
	import com.iblsoft.flexiweather.ogc.kml.controls.KMLLabel;
	import com.iblsoft.flexiweather.ogc.kml.controls.KMLSprite;
	import com.iblsoft.flexiweather.ogc.kml.data.KMLFeaturesReflectionDictionary;
	import com.iblsoft.flexiweather.ogc.kml.data.KMLReflectionData;
	import com.iblsoft.flexiweather.ogc.kml.data.KMLResourceKey;
	import com.iblsoft.flexiweather.ogc.kml.events.KMLFeatureEvent;
	import com.iblsoft.flexiweather.ogc.kml.events.KMLParsingStatusEvent;
	import com.iblsoft.flexiweather.ogc.kml.features.styles.Style;
	import com.iblsoft.flexiweather.ogc.kml.features.styles.StyleMap;
	import com.iblsoft.flexiweather.ogc.kml.features.styles.StyleSelector;
	import com.iblsoft.flexiweather.ogc.kml.managers.KMLParserManager;
	import com.iblsoft.flexiweather.ogc.kml.managers.KMLResourceManager;
	import com.iblsoft.flexiweather.ogc.kml.renderer.IKMLRenderer;
	import com.iblsoft.flexiweather.plugins.IConsole;
	import com.iblsoft.flexiweather.proj.Coord;
	import com.iblsoft.flexiweather.proj.Projection;
	import com.iblsoft.flexiweather.syndication.ParsingTools;
	import com.iblsoft.flexiweather.utils.ProfilerUtils;
	import com.iblsoft.flexiweather.utils.anticollision.AnticollisionLayout;
	import com.iblsoft.flexiweather.utils.anticollision.AnticollisionLayoutObject;
	import com.iblsoft.flexiweather.widgets.InteractiveWidget;
	
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	import flash.net.URLRequest;
	import flash.utils.Dictionary;
	import flash.utils.flash_proxy;
	import flash.utils.getTimer;
	import flash.utils.setTimeout;
	
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
		public static const VISIBILITY_CHANGE: String = 'visibilityChange';
		public static const ICON_TYPE_NORMAL: String = 'normal';
		public static const ICON_TYPE_HIGHLIGHTED: String = 'highlighted';
		private var _displaySprites: Array = [];
		public var featureScale: Number = 1;

		protected var ms_kmlFeatureParsingStatus: String;
		protected var mb_kmlFeatureParsingSupportedFeature: Boolean;
		
		public function removeDisplaySprite(sprite: Sprite): void
		{
			var total: int = _displaySprites.length;
			for (var i: int = 0; i < total; i++)
			{
				if (_displaySprites[i] == sprite)
				{
					_displaySprites.splice(i, 1);
					return;
				}
			}
		}

		protected function changeKMLFeatureParsingStatus(status: String): void
		{
			trace(this + " changeKMLFeatureParsingStatus 1: "+ status +" => "+ ms_kmlFeatureParsingStatus);
			
			if (ms_kmlFeatureParsingStatus == null)
			{
				ms_kmlFeatureParsingStatus = status;
			} else {
				switch (status)
				{
					case KMLParsingStatusEvent.FEATURE_PARSING_FAILED:
						if (ms_kmlFeatureParsingStatus != KMLParsingStatusEvent.FEATURE_PARSING_FAILED)
						{
							ms_kmlFeatureParsingStatus = KMLParsingStatusEvent.FEATURE_PARSING_PARTIALLY_SUCCESFULL;
						}
						break;
					
					case KMLParsingStatusEvent.FEATURE_PARSING_PARTIALLY_SUCCESFULL:
					case KMLParsingStatusEvent.FEATURE_PARSING_SUCCESFULL:
						
						if (ms_kmlFeatureParsingStatus == KMLParsingStatusEvent.FEATURE_PARSING_FAILED)
							ms_kmlFeatureParsingStatus = KMLParsingStatusEvent.FEATURE_PARSING_PARTIALLY_SUCCESFULL;
						break;
					
					default:
						trace("Unknowns KMLFeature parsing status" + status)
						break;
					
				}
			}
			
			trace(this + " changeKMLFeatureParsingStatus 2: "+ status +" => "+ ms_kmlFeatureParsingStatus);
			
		}
		protected function beforeKMLFeatureParsing(): void
		{
			ms_kmlFeatureParsingStatus = null;
		}
		
		protected function afterKMLFeatureParsing(): void
		{
			switch (ms_kmlFeatureParsingStatus)
			{
				case KMLParsingStatusEvent.FEATURE_PARSING_FAILED:
					notifyKMLFeatureParsingFailed();	
					break;
				
				case KMLParsingStatusEvent.FEATURE_PARSING_PARTIALLY_SUCCESFULL:
					notifyKMLFeatureParsingPartiallySuccesfull();		
					break;
				case KMLParsingStatusEvent.FEATURE_PARSING_SUCCESFULL:
					notifyKMLFeatureParsingSuccesfull();		
					break;
				default:
					notifyKMLFeatureParsingFailed();	
					break;
				
			}
		}
		
		protected function notifyKMLFeatureParsingSuccesfull(): void
		{
			dispatchEvent(new KMLParsingStatusEvent(KMLParsingStatusEvent.FEATURE_PARSING_SUCCESFULL));	
		}
		
		protected function notifyKMLFeatureParsingPartiallySuccesfull(): void
		{
			dispatchEvent(new KMLParsingStatusEvent(KMLParsingStatusEvent.FEATURE_PARSING_PARTIALLY_SUCCESFULL));	
		}
		
		protected function notifyKMLFeatureParsingFailed(): void
		{
			dispatchEvent(new KMLParsingStatusEvent(KMLParsingStatusEvent.FEATURE_PARSING_FAILED));	
		}
		
		public function get displaySpritesLength(): int
		{
			if (_displaySprites)
				return _displaySprites.length;
			return 0;
		}

		public function addDisplaySprite(sprite: Sprite): void
		{
			_displaySprites.push(sprite);
		}

		public function get visibleDisplaySprite(): Sprite
		{
			var containerWidth: int = master.container.width;
			for each (var sprite: Sprite in _displaySprites)
			{
				if (sprite.x > 0 && sprite.x < containerWidth)
					return sprite;
			}
			return null;
		}

		override public function set x(value: Number): void
		{
			super.x = value;
			notifyPositionChange();
		}

		override public function set y(value: Number): void
		{
			super.y = value;
			notifyPositionChange();
		}

		override public function set visible(value: Boolean): void
		{
			var oldValue: Boolean = super.visible;
			super.visible = value;
			
//			trace(this + " visible: " + value);
			
			if (value != oldValue)
				notifyVisibilityChange();
		}
		private var _xmlList: XMLList;
		public var _name: String;
		public var _id: String;
		//		public var _link: com.adobe.xml.syndication.atom.Link;
		public var _visibility: Boolean = true;
		public var _open: Boolean = false;
		//		public var _author:Author;
		public var _snippet: String;
		public var _styleUrl: String;
		public var _styleSelector: StyleSelector;
		public var _lookAt: LookAt;
		public var _description: String;
		private var _parentDocument: Document;
//		private var _kmlIcon: KMLIcon;
		private var _kmlLabel: KMLLabel;
		private var _region: Region;

//		public function get kmlIcon(): KMLIcon
//		{
//			return _kmlIcon;
//		}
		public function get kmlLabel(): KMLLabel
		{
			return _kmlLabel;
		}
		private var _kml: KML

		public function get kml(): KML
		{
			return _kml;
		}
		protected var _kmlReflectionDictionary: KMLFeaturesReflectionDictionary;

		public function get kmlReflectionDictionary(): KMLFeaturesReflectionDictionary
		{
			return _kmlReflectionDictionary
		}
		private var _kmlns: Namespace;

		public function get kmlns(): Namespace
		{
			if (!_kmlns)
				_kmlns = new Namespace(ms_namespace);
			return _kmlns;
		}

		public function KMLFeature(kml: KML, s_namespace: String, s_xml: XMLList)
		{
			super(s_namespace, null, null);
			_kml = kml;
			_xmlList = s_xml;
			addEventListener(Event.ENTER_FRAME, initializeOnNextFrame);
		}
		
		private function initializeOnNextFrame(event: Event): void
		{
			
			removeEventListener(Event.ENTER_FRAME, initializeOnNextFrame);
			init();
		}
		private var _iconState: String;

		private function set iconState(value: String): void
		{
			_iconState = value;
		}

		public function get state(): String
		{
			return _iconState;
		}

		public function get isHighlighted(): Boolean
		{
			return _iconState == ICON_TYPE_HIGHLIGHTED;
		}

		public function showNormal(): void
		{
			iconState = ICON_TYPE_NORMAL;
			update(FeatureUpdateContext.fullUpdate());
		}

		public function showHighlight(): void
		{
			iconState = ICON_TYPE_HIGHLIGHTED;
			update(FeatureUpdateContext.fullUpdate());
		}
		private var _normalStyle: StyleSelector;
		private var _highlightStyle: StyleSelector;

		public function get normalStyle(): StyleSelector
		{
			return _normalStyle;
		}

		public function set normalStyle(value: StyleSelector): void
		{
			_normalStyle = value;
			update(FeatureUpdateContext.fullUpdate());
		}

		public function get highlightStyle(): StyleSelector
		{
			return _highlightStyle;
		}

		public function set highlightStyle(value: StyleSelector): void
		{
			_highlightStyle = value;
		}
		private var _normalResourceKey: KMLResourceKey;
		private var _highlightResourceKey: KMLResourceKey;

		public function setNormalBitmapResourceKey(key: KMLResourceKey): void
		{
			_normalResourceKey = key;
		}

		public function setHighlightBitmapResourceKey(key: KMLResourceKey): void
		{
			_highlightResourceKey = key;
		}

		public function init(): void
		{
			showNormal();
			mouseEnabled = true;
			mouseChildren = true;
			doubleClickEnabled = true;
			addEventListener(MouseEvent.CLICK, onKMLFeatureClick);
		}

		override public function setMaster(master: InteractiveLayerFeatureBase): void
		{
			super.setMaster(master);
			_kmlReflectionDictionary = new KMLFeaturesReflectionDictionary(master.container);
			_kmlReflectionDictionary.addEventListener(ReflectionEvent.ADD_REFLECTION, onKMLAddReflection);
			_kmlReflectionDictionary.addEventListener(ReflectionEvent.REMOVE_REFLECTION, onKMLRemoveReflection);
		}

		protected function get currentCoordinates(): Array
		{
			return coordinates;
		}

		override public function getExtent(): CRSWithBBox
		{
			var a_coordinates: Array = currentCoordinates;
			if (a_coordinates && a_coordinates.length == 1)
			{
				//point has no bounding box
				return null;
			}
			return getExtentFromCoordinates(a_coordinates);
		}

		protected function addLabelToAnticollisionLayout(kmlLabel: KMLLabel): void
		{
		}

		protected function removeLabelFromAnticollisionLayout(kmlLabel: KMLLabel): void
		{
		}

		protected function removeReflection(reflection: KMLReflectionData): void
		{
			var kmlSprite: KMLSprite = reflection.displaySprite as KMLSprite;
			removeLabelFromAnticollisionLayout(kmlSprite.kmlLabel);
			removeChild(kmlSprite);
			removeDisplaySprite(kmlSprite);
			kmlSprite.kmlLabel = null;
			kmlLabel.cleanup();
		}

		protected function onKMLRemoveReflection(event: ReflectionEvent): void
		{
			//remove whole reflection
			var reflection: KMLReflectionData = event.reflection as KMLReflectionData;
			removeReflection(reflection);
		}

		protected function onKMLAddReflection(event: ReflectionEvent): void
		{
			addEventListener(Event.ENTER_FRAME, onKMLAddReflectionDelayed);
			//onKMLAddReflectionDelayed(event);
		}
		
		private function onKMLAddReflectionDelayed(event: Event): void
		{
			removeEventListener(Event.ENTER_FRAME, onKMLAddReflectionDelayed);
			update(FeatureUpdateContext.fullUpdate());
		}

		protected function updateCoordsReflections( bCheckCoordIsInside: Boolean = true): void
		{
			//FIXME need to chack correct coordinate e.g. for Placemark Polygon
			_kmlReflectionDictionary.cleanup();
			var reflectionIDs: Array = _kmlReflectionDictionary.reflectionIDs;
			var currCoordinates: Array = currentCoordinates;
			var total: int = currentCoordinates.length;
			var coordsPosition: Array = [];
			for (var i: int = 0; i < total; i++)
			{
				coordsPosition.push(i);
			}
			var invisibleCoordsPositions: Array = updateCoordsReflectionsForSpecifiedCoordinates(coordsPosition, bCheckCoordIsInside);
			if (invisibleCoordsPositions.length > 0 && invisibleCoordsPositions.length < total)
			{
				/**
				 * feature is partly visible, add all coordinates, otherwise there can be problem with rendering KML
				 * e.g. position of each KMLFeature is taken from first coordinates and if it is not present in returned points, KML feature will be renderer on wrong position
				 */
				invisibleCoordsPositions = updateCoordsReflectionsForSpecifiedCoordinates(invisibleCoordsPositions, false);
				if (invisibleCoordsPositions.length > 0)
					trace("invisibleCoordsPositions should be empty now");
			}
		}

		protected function mapCoordInCRSToViewReflections(p: flash.geom.Point): Array
		{
			var iw: InteractiveWidget = master.container;
			var pointReflections: Array = iw.mapCoordInCRSToViewReflections(p);
			return pointReflections;
		}
		
		protected function updateCoordsReflectionsForSpecifiedCoordinates(coords: Array, bCheckCoordIsInside: Boolean): Array
		{
			var iw: InteractiveWidget = master.container;
			var crs: String = iw.getCRS();
			var projection: Projection = iw.getCRSProjection();
			var viewBBox: BBox = iw.getViewBBox();
			var currCoordinates: Array = currentCoordinates;
//			var visibleCoords: int = 0;
			var invisibleCoords: Array = [];
			for each (var i: int in coords)
			{
				var coord: Coord = currCoordinates[i] as Coord;
				var coordPointForReflection: flash.geom.Point = new flash.geom.Point();
				if (coord.crs != crs)
				{
					//conver to InteractiveWidget CRS
					coordPointForReflection = coord.convertToProjection(projection);
				}
				else
					coordPointForReflection = new flash.geom.Point(coord.x, coord.y);
				
				var pointReflections: Array = mapCoordInCRSToViewReflections(coordPointForReflection);
				
				var reflectionsCount: int = pointReflections.length;
				for (var j: int = 0; j < reflectionsCount; j++)
				{
					var pointReflectedObject: Object = pointReflections[j];
					var pointReflected: flash.geom.Point = pointReflectedObject.point as flash.geom.Point;
					var coordReflected: Coord = new Coord(crs, pointReflected.x, pointReflected.y);
					if (bCheckCoordIsInside && !viewBBox.coordInside(coordReflected))
					{
						invisibleCoords.push(i);
						continue;
					}
//					visibleCoords++;
					_kmlReflectionDictionary.addReflectedCoordAt(coordReflected, i, j, pointReflectedObject.reflection);
				}
			}
			return invisibleCoords;
		}
		
		protected function getReflectedCoordinate(coord: Coord): Dictionary
		{
			
			//TODO optimalize getReflectedCoordinate method
			
			
			var iw: InteractiveWidget = master.container;
			var crs: String = iw.getCRS();
			var projection: Projection = iw.getCRSProjection();
			var coordPointForReflection: Coord;
			if (coord.crs != crs)
			{
				//conver to InteractiveWidget CRS
				coordPointForReflection = coord.convertToProjection(projection);
			}
			else
				coordPointForReflection = coord; //new flash.geom.Point(coord.x, coord.y);
			
			
			var pointReflections: Array;
			var reflections: Dictionary = new Dictionary();
			
			var bUseReflections: Boolean = false; //projection.wrapsHorizontally;
			var coordReflected: Coord;
			var p2: flash.geom.Point;
			if (bUseReflections)
			{
				pointReflections = iw.mapCoordInCRSToViewReflectionsForDeltas(coordPointForReflection, [0,1,-1,2,-2,3,-3]);
			
				var reflectionsCount: int = pointReflections.length;
			
				for (var j: int = 0; j < reflectionsCount; j++)
				{
					var pointReflectedObject: Object = pointReflections[j];
					
					var pointReflected: flash.geom.Point = pointReflectedObject.point as flash.geom.Point;
					coordReflected = new Coord(crs, pointReflected.x, pointReflected.y);
					
					p2 = iw.coordToPoint(coordReflected);
					
					reflections[pointReflectedObject.reflection] = {coord: coordReflected, point: p2, reflection: pointReflectedObject.reflection};
				}
			} else {
				
//				var pointReflected: flash.geom.Point = coordPointForReflection;
				coordReflected = coordPointForReflection; //new Coord(crs, pointReflected.x, pointReflected.y);
					
				p2 = iw.coordToPoint(coordReflected);
					
				reflections[0] = {coord: coordReflected, point: p2, reflection: 0};
			}
			return reflections;
		}

		/**
		 * Returns "active" flag for Feature. If there is no Region and LOD present, it will return always true. Otherwise it will return correct value dependent on size of
		 * @return
		 *
		 */
		public function isActive(w: int, h: int): Boolean
		{
			return true;
			if (!_region)
				return true;
			if (_region.lod)
			{
				var minLodPixels: Number = _region.lod.minLodPixels;
				var maxLodPixels: Number = _region.lod.maxLodPixels;
				if (w >= minLodPixels && w <= maxLodPixels && h >= minLodPixels && h <= maxLodPixels)
					return true;
				else
					return false;
			}
			return true;
		}

		protected function cleanupIcon(): void
		{
//			if (_kmlIcon)
//			{
//				removeChild(_kmlIcon);
//				_kmlIcon.cleanup();
//				
//				_kmlIcon = null;
//			}
			if (kml)
				var resourceManager: KMLResourceManager = kml.resourceManager;
			
			if (resourceManager)
			{
				resourceManager.disposeResource(_normalResourceKey);
				resourceManager.disposeResource(_highlightResourceKey);
			}
			
			_normalResourceKey = null;
			_highlightResourceKey = null;
		}

		protected function createIcon(): void
		{
//			_kmlIcon = new KMLIcon(this);
//			addChild(_kmlIcon);
		}

		protected function cleanupKMLLabel(): void
		{
			if (_kmlLabel)
			{
				if (_kmlLabel.parent)
					_kmlLabel.parent.removeChild(_kmlLabel);
				_kmlLabel.cleanup();
				_kmlLabel = null;
			}
		}

		protected function createKMLLabel(parent: Sprite): KMLLabel
		{
			//reuseleanup KMLLabels
			_kmlLabel = kml.resourceManager.getKMLLabel(this);
			_kmlLabel.visible = true;
			_kmlLabel.reflection = (parent as KMLSprite).reflection;
			return _kmlLabel;
		}

		/*
		private var _listenersArray: Dictionary = new Dictionary();

		public override function addEventListener(type:String, listener:Function, useCapture:Boolean=false, priority:int=0, useWeakReference:Boolean=false):void
		{
			super.addEventListener(type, listener, useCapture, priority, useWeakReference);

			if (!_listenersArray[type]) {
				_listenersArray[type] = 1;
			} else {
				_listenersArray[type] = int(_listenersArray[type]) + 1;
			}
		}

		public override function removeEventListener(type:String, listener:Function, useCapture:Boolean=false):void
		{
			super.removeEventListener(type, listener, useCapture);

			delete _listenersArray[type];
		}
		*/
		public override function cleanup(): void
		{
			removeEventListener(MouseEvent.CLICK, onKMLFeatureClick);
			if (master && master.container)
			{
				var kmlSprite: KMLSprite;
				var kmlLabel: KMLLabel;
				var reflection: KMLReflectionData;
				var totalReflections: int = kmlReflectionDictionary.totalReflections;
				for (var i: int = 0; i < totalReflections; i++)
				{
					reflection = kmlReflectionDictionary.getReflection(i) as KMLReflectionData;
					kmlSprite = reflection.displaySprite as KMLSprite;
					if (kmlSprite)
					{
						kmlLabel = kmlSprite.kmlLabel;
						master.container.labelLayout.removeObject(reflection.displaySprite);
						master.container.labelLayout.removeObject(kmlLabel);
						if (kmlSprite.parent)
							kmlSprite.parent.removeChild(kmlSprite);
					}
				}
//				master.container.labelLayout.removeObject(this);
//				master.container.labelLayout.removeObject(_kmlLabel);
				master.container.objectLayout.removeObject(this);
			}
			_itemRendererInstance = null;
			previous = null;
			next = null;
			cleanupIcon();
			cleanupKMLLabel();
			cleanupKML();
			super.cleanup();
		}

		private function onKMLFeatureClick(event: MouseEvent): void
		{
			var kfe: KMLFeatureEvent = new KMLFeatureEvent(KMLFeatureEvent.KML_FEATURE_CLICK, true);
			kfe.kmlFeature = this;
			dispatchEvent(kfe);
		}

		public function parse(s_namespace: String, kmlParserManager: KMLParserManager): void
		{
			beforeKMLFeatureParsing();
			
			parseKML(s_namespace, kmlParserManager);
			
			afterKMLFeatureParsing();
		}

		public function cleanupKML(): void
		{
			_kml = null;
			_xmlList = null;
			if (_styleSelector)
			{
				_styleSelector.cleanupKML();
				_styleSelector = null;
			}
			if (_lookAt)
			{
				_lookAt.cleanupKML();
				_lookAt = null;
			}
			if (_region)
			{
				_region.cleanupKML();
				_region = null;
			}
		}

		protected function parseKML(s_namespace: String, kmlParserManager: KMLParserManager): void
		{
			if (!_xmlList)
				return;
			_kmlns = new Namespace(s_namespace);
			this._id = ParsingTools.nullCheck(_xmlList.@id);
			this._name = ParsingTools.nullCheck(_xmlList.kmlns::name);
			this._description = ParsingTools.nullCheck(_xmlList.kmlns::description);
			this._snippet = ParsingTools.nullCheck(_xmlList.kmlns::Snippet);
			this._styleUrl = ParsingTools.nullCheck(_xmlList.kmlns::styleUrl);
			if (ParsingTools.nullCheck(this.xml.kmlns::Style))
				this._styleSelector = new Style(kml, ms_namespace, this.xml.kmlns::Style, parentDocument);
			if (ParsingTools.nullCheck(this.xml.kmlns::StyleMap))
				this._styleSelector = new StyleMap(kml, ms_namespace, this.xml.kmlns::StyleMap, parentDocument);
			if (ParsingTools.nullCheck(this.xml.kmlns::LookAt))
				this._lookAt = new LookAt(ms_namespace, this.xml.kmlns::LookAt);
			if (ParsingTools.nullCheck(this.xml.kmlns::Region))
				this._region = new Region(ms_namespace, this.xml.kmlns::Region);
			dispatchEvent(new Event("nameChanged"));
			/*
			if (ParsingTools.nullCheck(_xmlList.atom::link) != null) {
			this._link = new com.adobe.xml.syndication.atom.Link::Link(_xmlList.atom::link);
			}

			if (ParsingTools.nullCheck(_xmlList.atom::author) != null) {
			this._author = new Author(_xmlList.atom::author);
			}
			*/
			var visibility: Number = ParsingTools.nanCheck(_xmlList.kmlns::visibility);
			if (visibility == 1)
				this._visibility = true;
			else if (visibility == 0)
				this._visibility = false;
			var open: Number = ParsingTools.nanCheck(_xmlList.kmlns::open);
			if (open == 1)
				this._open = true;
			else if (open == 0)
				this._open = false;
		}
		private var _itemRendererInstance: IKMLRenderer;

		public function setItemRenderer(itemRendererInstance: IKMLRenderer): void
		{
			_itemRendererInstance = itemRendererInstance;
		}

		private function getKMLVisibility(): Boolean
		{
			if (!visibility)
				return false;
			else
			{
				if (parentFeature && parentFeature is KMLFeature)
					return (parentFeature as KMLFeature).visibility;
			}
			return true;
		}

		public function notifyVisibilityChange(): void
		{
			var kfe: KMLFeatureEvent = new KMLFeatureEvent(KMLFeatureEvent.KML_FEATURE_VISIBILITY_CHANGE, true);
			kfe.kmlFeature = this;
			dispatchEvent(kfe);
		}

		public function notifyPositionChange(): void
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

		/**
		 * Get the XML used to populate the NewsFeedElement.
		 *
		 * @langversion ActionScript 3.0
		 * @playerversion Flash 8.5
		 * @tiptext
		 */
		public function get xml(): XMLList
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
		public function set xml(x: XMLList): void
		{
			_xmlList = x;
		}

		/**
		 *	The string in the name tag.
		 */
		[Bindable(event = "nameChanged")]
		public override function get name(): String
		{
			return this._name;
		}

		public function get style(): StyleSelector
		{
			if (_styleUrl && _parentDocument)
				var currStyle: StyleSelector = _parentDocument.getStyleSelectorByID(_styleUrl);
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

		public function changeVisibility(value: Boolean): void
		{
			if (this._visibility != value)
			{
				this._visibility = value;
				dispatchEvent(new Event(VISIBILITY_CHANGE));
			}
		}

		public function get visibility(): Boolean
		{
			return this._visibility;
		}

		public function get kmlVisibility(): Boolean
		{
			return getKMLVisibility();
		}

		public function get region(): Region
		{
			return this._region;
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
		public function get open(): Boolean
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
		public function get description(): String
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
		public function get snippet(): String
		{
			return this._snippet;
		}

		public override function toString(): String
		{
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

		/**
		 *  Debug functions
		 *
		 */
		protected function startProfileTimer(): int
		{
			return ProfilerUtils.startProfileTimer();
		}

		/**
		 * Return time interval in seconds
		 * @param startTime
		 * @return
		 *
		 */
		protected function stopProfileTimer(startTime: int): Number
		{
			return ProfilerUtils.stopProfileTimer(startTime);
		}
		public static var debugConsole: IConsole;

		public function debug(txt: String): void
		{
			if (debugConsole)
				debugConsole.print("KMLFeature: " + txt, 'Info', 'KMLFeature');
		}
	}
}
