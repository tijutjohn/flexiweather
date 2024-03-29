package com.iblsoft.flexiweather.widgets
{
	import com.iblsoft.flexiweather.events.InteractiveLayerEvent;
	import com.iblsoft.flexiweather.ogc.InteractiveLayerWMS;
	import com.iblsoft.flexiweather.ogc.events.GetCapabilitiesEvent;
	import com.iblsoft.flexiweather.ogc.kml.features.Point;
	import com.iblsoft.flexiweather.utils.packing.DynamicArea;
	import com.iblsoft.flexiweather.utils.packing.PackingLayoutProperties;
	import com.iblsoft.flexiweather.utils.packing.Padding;

	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.Graphics;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.Rectangle;
	import flash.utils.Dictionary;
	import flash.utils.setTimeout;

	import mx.collections.ArrayCollection;
	import mx.core.IVisualElement;
	import mx.events.ResizeEvent;
	import mx.logging.ILogger;
	import mx.logging.Log;

	[Style(name = "horizontalGap", type = "Number", format = "Length", inherit = "no")]
	[Style(name = "verticalGap", type = "Number", format = "Length", inherit = "no")]
	[Style(name = "labelAlign", type = "String", enumeration = "left,center,right", inherit = "no")]
	[Style(name = "horizontalAlign", type = "String", enumeration = "left,center,right", inherit = "no")]
	[Style(name = "horizontalDirection", type = "String", enumeration = "none,left,right", inherit = "no")]
	[Style(name = "verticalAlign", type = "String", enumeration = "bottom,middle,top", inherit = "no")]
	[Style(name = "verticalDirection", type = "String", enumeration = "none,down,up", inherit = "no")]
	[Style(name = "legendsBackgroundColor", type = "uint", format = "Color", inherit = "no")]
	[Style(name = "legendsBackgroundAlpha", type = "Number", format = "Length", inherit = "no")]
	[Style(name = "legendsBackgroundPadding", type = "uint", format = "Color", inherit = "no")]
	/**
	 *  Number of pixels between the container's bottom border
	 *  and the bottom of its content area.
	 *  The default value is 0.
	 */
	[Style(name = "paddingBottom", type = "Number", format = "Length", inherit = "no")]
	/**
	 *  Number of pixels between the container's top border
	 *  and the top of its content area.
	 *  The default value is 0.
	 */
	[Style(name = "paddingTop", type = "Number", format = "Length", inherit = "no")]
	/**
	 *  Number of pixels between the container's left border
	 *  and the left of its content area.
	 *  The default value is 0.
	 */
	[Style(name = "paddingLeft", type = "Number", format = "Length", inherit = "no")]
	/**
	 *  Number of pixels between the container's right border
	 *  and the right of its content area.
	 *  The default value is 0.
	 */
	[Style(name = "paddingRight", type = "Number", format = "Length", inherit = "no")]
	[Event(name = "legendsLoadingStarted", type = "flash.events.Event")]
	[Event(name = "legendsLoadingFinished", type = "flash.events.Event")]
	[Event(name = "legendsLayeringStarted", type = "flash.events.Event")]
	[Event(name = "legendsLayeringFinished", type = "flash.events.Event")]
	public class InteractiveLayerLegends extends InteractiveLayer
	{
		public static const LEGENDS_LOADING_STARTED: String = 'legendsLoadingStarted';
		public static const LEGENDS_LOADING_FINISHED: String = 'legendsLoadingFinished';
		public static const LEGENDS_LAYERING_STARTED: String = 'legendsLayeringStarted';
		public static const LEGENDS_LAYERING_FINISHED: String = 'legendsLayeringFinished';


		override public function set mouseEnabled(enabled:Boolean):void
		{
			super.mouseEnabled = enabled;
		}

		override public function set mouseChildren(enable:Boolean):void
		{
			super.mouseChildren = enable;
		}

		private var m_layers: ArrayCollection = new ArrayCollection();
		public function get layers(): ArrayCollection
		{
			return m_layers;
		}
		private var _legendsLoadingCount: int;
		private var _legendsAlreadyLoaded: int;
		private var _legendScaleX: Number = 1;
		private var _legendScaleY: Number = 1;
		private var _maximumArea: Rectangle;
		private var _logger: ILogger;

		override public function set visible(b_visible:Boolean):void
		{
			super.visible = b_visible;
		}

		public function get maximumArea(): Rectangle
		{
			return _maximumArea;
		}

		[Bindable]
		public function get legendScaleX(): Number
		{
			return _legendScaleX;
		}

		public function set legendScaleX(value: Number): void
		{
			_legendScaleX = value;
		}

		[Bindable]
		public function get legendScaleY(): Number
		{
			return _legendScaleY;
		}

		public function set legendScaleY(value: Number): void
		{
			_legendScaleY = value;
		}

		public function get legendsLoadingCount(): int
		{
			return _legendsLoadingCount;
		}

		public function set legendsLoadingCount(value: int): void
		{
			_legendsLoadingCount = value;
//			debug("_legendsLoading = " + _legendsLoadingCount);
		}

		public function get legendsAlreadyLoaded(): int
		{
			return _legendsAlreadyLoaded;
		}

		public function set legendsAlreadyLoaded(value: int): void
		{
			_legendsAlreadyLoaded = value;
//			debug("_legendsAlreadyLoaded = " + _legendsAlreadyLoaded);
		}
		private var legendsBkgRectangle: Rectangle;
		private var _currentRectangle: Rectangle;

		public function InteractiveLayerLegends(container: InteractiveWidget = null)
		{
			super(container);
			_logger = Log.getLogger('InteractiveLayerLegends');
			mouseChildren = true;
			mouseEnabled = true;

		}

		public function getLayerAt(id: int): InteractiveLayer
		{
			if (m_layers.length > id)
				return m_layers.getItemAt(id) as InteractiveLayer;
			return null;
		}

		public function isLayerInside(l: InteractiveLayer): Boolean
		{
			var id: int = m_layers.getItemIndex(l);
			return id > -1;
		}
		public function addLayer(l: InteractiveLayer): void
		{
			debug("\n\tILLegend addLayer: " + l.name + " id: " + l.layerID);
			m_layers.addItemAt(l, 0);
			l.addEventListener(InteractiveLayerEvent.VISIBILITY_EFFECT_FINISHED, onLayerVisibilityChanged);
			l.addEventListener(GetCapabilitiesEvent.CAPABILITIES_RECEIVED, onLayerGetCapabilitiesReceived);
		}

		public function removeLayer(l: InteractiveLayer): void
		{
			var i: int = m_layers.getItemIndex(l);
			if (i >= 0)
			{
				debug("\n\tILLegend removeLayer: " + l.name + " id: " + l.layerID);
//				unbindSubLayer(l);
				l.removeEventListener(InteractiveLayerEvent.VISIBILITY_EFFECT_FINISHED, onLayerVisibilityChanged);
				l.removeEventListener(GetCapabilitiesEvent.CAPABILITIES_RECEIVED, onLayerGetCapabilitiesReceived);
				m_layers.removeItemAt(i);

				var legendGroup: InteractiveLayerLegendGroup = getGroupFromDictionary(l);
				if (!legendGroup)
				{
					debug("\tDoes not find legendGroup in removeLayer for layer: " + l.name + " id: " + l.layerID);
				} else {
					l.removeLegend(legendGroup);
					removeCanvasFromDictionary(l);
				}
			} else {
				debug("Problem with remove layer from ILayerLegends");
			}

		}

		private var _legendsInvalidated: Boolean;

		public function invalidateLayerLegend(l: InteractiveLayer): void
		{
			var group: InteractiveLayerLegendGroup = getGroupFromDictionary(l);
			if (group && l)
			{
				l.removeLegend(group);
				removeCanvasFromDictionary(l);
			}


			_legendsInvalidated = true;
			invalidateProperties();
		}

		override protected function commitProperties():void
		{
			super.commitProperties();

			if (_legendsInvalidated)
			{
				repositionedLegends();
				_legendsInvalidated = false;
			}
		}

		override public function refresh(b_force: Boolean): void
		{
			super.refresh(b_force);
//			debug("Legends refresh");
		}

		override public function draw(graphics: Graphics): void
		{
			super.draw(graphics);
			//drawLegendsBackground(legendsBkgRectangle);
		}

		override public function onAreaChanged(b_finalChange: Boolean): void
		{
			super.onAreaChanged(b_finalChange);
//			debug("Legends onAreaChanged");
		}

		private function onLayerGetCapabilitiesReceived(event: GetCapabilitiesEvent): void
		{
			var layer: InteractiveLayer = (event.target) as  InteractiveLayer;
//			debug("onLayerGetCapabilitiesReceived for layer: " + layer);
			invalidateLayerLegend(layer);
		}
		private function onLayerVisibilityChanged(event: InteractiveLayerEvent): void
		{
			renderLegendsStack();
		}

		override public function onContainerSizeChanged(): void
		{
			super.onContainerSizeChanged();
//			debug("Legends onContainerSizeChanged");
			renderLegendsStack();
		}

		public function removeAllLayers(): void
		{
			debug("\n remove all layers (legends)");
//			for each(var l: InteractiveLayer in m_layers)
//				unbindSubLayer(l);
			m_layers.removeAll();
		}

		private function repositionedLegends(): void
		{
			renderLegendsStack(true);
//			debug("repositionedLegends: " + legendsBkgRectangle);
			var ile: InteractiveLayerEvent = new InteractiveLayerEvent(InteractiveLayerEvent.LEGENDS_AREA_UPDATED);
			ile.area = legendsBkgRectangle;
			dispatchEvent(ile);
		}

		/**
		 * Dictionary, which holds parent for legends, which are already loding
		 */
		private var m_groupDictionary: Dictionary = new Dictionary();
		private var _legends: Array = new Array();

		public function clearCanvasDictionary(): void
		{
			m_groupDictionary = new Dictionary();
			_legends = new Array();
		}

		private function addLegendGroupListeners(group: InteractiveLayerLegendGroup): void
		{
			if (group)
			{
				group.addEventListener(MouseEvent.CLICK, onLegendGroupClick);
				group.addEventListener(MouseEvent.MOUSE_OVER, onLegendGroupRollover);
				group.addEventListener(MouseEvent.ROLL_OVER, onLegendGroupRollover);
				group.addEventListener(MouseEvent.MOUSE_OUT, onLegendGroupRollout);
				group.addEventListener(MouseEvent.ROLL_OUT, onLegendGroupRollout);
			}
		}
		private function removeLegendGroupListeners(group: InteractiveLayerLegendGroup): void
		{
			if (group)
			{
				group.removeEventListener(MouseEvent.CLICK, onLegendGroupClick);
				group.removeEventListener(MouseEvent.MOUSE_OVER, onLegendGroupRollover);
				group.removeEventListener(MouseEvent.ROLL_OVER, onLegendGroupRollover);
				group.removeEventListener(MouseEvent.MOUSE_OUT, onLegendGroupRollout);
				group.removeEventListener(MouseEvent.ROLL_OUT, onLegendGroupRollout);
			}
		}
		private function removeCanvasFromDictionary(layer: InteractiveLayer): void
		{
			debug("\t\tremoveCanvasFromDictionary: " + layer.name);
			var group: InteractiveLayerLegendGroup = m_groupDictionary[layer];
			removeLegendGroupListeners(group);
			delete m_groupDictionary[layer];
			if (group.parent)
			{
				(group.parent as DisplayObjectContainer).removeChild(group);
			}
		}
		private function addCanvasToDictionary(group: InteractiveLayerLegendGroup, layer: InteractiveLayer): void
		{
			if (!group)
				debug("addCanvasToDictionary cnv IS NULL ");
			debug("\t\taddCanvasToDictionary [" + layer.name+"]: " + group);
			m_groupDictionary[layer] = group;
			addLegendGroupListeners(group);
//			_legends[layer] = new Rectangle(cnv.x, cnv.y, cnv.width, cnv.height);
		}
		private var _scaleDict: Dictionary = new Dictionary();

		private function getRectangleFromLayer(layer: InteractiveLayer): Rectangle
		{
			if (layer && layer.hasLegend() && layer.visible)
			{
				var cnv: InteractiveLayerLegendGroup = getGroupFromDictionary(layer);
				var oldScaleX: Number = 1;
				var oldScaleY: Number = 1;
				var oldScaleObj: Object = _scaleDict[layer];
				if (oldScaleObj)
				{
					oldScaleX = oldScaleObj.oldScaleX;
					oldScaleY = oldScaleObj.oldScaleY;
				}
				debug("\nBEFORE \ngetRectangleFromLayer rect: " + rect);
				debug("getRectangleFromLayer cnv size: " + cnv.width + " , " + cnv.height);
				debug("getRectangleFromLayer cnv scale: " + oldScaleX + " , " + oldScaleY);
				debug("getRectangleFromLayer _legendScaleX: " + _legendScaleX + " , " + _legendScaleX);
				var rect: Rectangle = new Rectangle(0, 0, cnv.width / oldScaleX * _legendScaleX, cnv.height / oldScaleY * _legendScaleY);
				debug("\nAFTER\ngetRectangleFromLayer rect: " + rect);
				debug("getRectangleFromLayer cnv size: " + cnv.width + " , " + cnv.height);
				debug("getRectangleFromLayer cnv scale: " + oldScaleX + " , " + oldScaleY);
				debug("getRectangleFromLayer _legendScaleX: " + _legendScaleX + " , " + _legendScaleX);
				_scaleDict[layer] = {layer: layer, oldScaleX: _legendScaleX, oldScaleY: _legendScaleY};
				return rect;
			}
			return null;
		}

		private function getGroupFromDictionary(layer: InteractiveLayer): InteractiveLayerLegendGroup
		{
			var grp: InteractiveLayerLegendGroup = m_groupDictionary[layer];
			return grp;
		}

		public override function clear(graphics: Graphics): void
		{
			super.clear(graphics);
			graphics.clear();
		}
		private var _legendsAreLoading: Boolean;

		/**
		 * Load legends and do not layout them
		 * @return How many legends needs to be loaded
		 *
		 */
		private function loadLegends(): int
		{
			debug("loadLegends");
			var _tmpExistedCanvases: int = 0;
			var _tmpLegendsToBeLoaded: int = 0;
			var l: InteractiveLayer;
			var group: InteractiveLayerLegendGroup;
			//find total count of layers for which legend should be rendered
			var _tempCanvases: Array = [];
			for each (l in m_layers)
			{
				if (l.hasLegend() && l.visible)
				{
					group = getGroupFromDictionary(l);
					if (group)
					{
						debug("loadLegends1: Legend for layer: " + l.name + " id: " + l.layerID + " is already loading");
						_tmpExistedCanvases++;
						_tempCanvases.push(group);
					}
					else
						_tmpLegendsToBeLoaded++;
				}
			}
			/*
			//TODO why we call this here?
			if (_tempCanvases.length)
			{
				while (_tempCanvases.length > 0)
				{
					canvas = _tempCanvases.shift();
					onLegendRendered(canvas);
				}
			}
			*/
			legendsAlreadyLoaded = _tmpExistedCanvases;
			if (_tmpLegendsToBeLoaded == 0)
			{
				legendsLoadingCount = _tmpLegendsToBeLoaded;
				return _tmpLegendsToBeLoaded;
			}
			if (_legendsAreLoading)
			{
				//loading already started, do not load it again
				legendsLoadingCount = _tmpLegendsToBeLoaded;
				return _tmpLegendsToBeLoaded
			}
			for each (l in m_layers)
			{
				if (l.hasLegend() && l.visible)
				{
					group = getGroupFromDictionary(l);
					if (!group)
					{
						if (!_legendsAreLoading)
						{
							_legendsAreLoading = true;
							notify(LEGENDS_LOADING_STARTED);
						}
						group = new InteractiveLayerLegendGroup();
						addChild(group);
						group.addEventListener(MouseEvent.CLICK, onLegendGroupClick);
						group.addEventListener(MouseEvent.MOUSE_OVER, onLegendGroupRollover);
						group.addEventListener(MouseEvent.ROLL_OVER, onLegendGroupRollover);
						group.addEventListener(MouseEvent.MOUSE_OUT, onLegendGroupRollout);
						group.addEventListener(MouseEvent.ROLL_OUT, onLegendGroupRollout);
						group.visible = false;
						addCanvasToDictionary(group, l);
						debug(" layer: " + l + "  loadLegends renderLegend => LOAD");
						l.renderLegend(group, onLegendRendered, onLegendError, legendScaleX, legendScaleY, getStyle('labelAlign'));
					}
					else
					{
						debug("loadLegends2: Legend for layer: " + l.name + " id: " + l.layerID + " is already loading");
						//already rendered
//						_tmpLegendsToBeRendered--;
					}
				}
			}
			legendsLoadingCount = _tmpLegendsToBeLoaded;
			return legendsLoadingCount;
		}

		private function onLegendGroupClick(event: MouseEvent): void
		{
			var group: InteractiveLayerLegendGroup = event.currentTarget as InteractiveLayerLegendGroup;
			if (group)
			{
				var legend: InteractiveLayerLegendImage = getLegendImageFromGroup(group);
			}
		}
		private function onLegendGroupRollover(event: MouseEvent): void
		{
			var group: InteractiveLayerLegendGroup = event.target as InteractiveLayerLegendGroup;
			if (group)
			{
				var legend: InteractiveLayerLegendImage = getLegendImageFromGroup(group);
				var e: InteractiveLayerLegendEvent = new InteractiveLayerLegendEvent(InteractiveLayerLegendEvent.LEGEND_ROLLOVER, legend);
				e.legendGroup = group;
				dispatchEvent(e);
			}
		}
		private function onLegendGroupRollout(event: MouseEvent): void
		{
			var group: InteractiveLayerLegendGroup = event.target as InteractiveLayerLegendGroup;
			if (group)
			{
				var legend: InteractiveLayerLegendImage = getLegendImageFromGroup(group);
				var e: InteractiveLayerLegendEvent = new InteractiveLayerLegendEvent(InteractiveLayerLegendEvent.LEGEND_ROLLOVER, legend);
				e.legendGroup = group;
				dispatchEvent(e);
			}
		}

		private function checkIfAllLegendsAreLoaded(): Boolean
		{
			var needLoading: Boolean;
			var l: InteractiveLayer;
			var group: InteractiveLayerLegendGroup;
			for each (l in m_layers)
			{
				debug("LEGENDS checkIfAllLegendsAreLoaded l: " + l.name + " id: " + l.layerID + " hasLegend: " + l.hasLegend() + " visible: " + l.visible);
				if (l.hasLegend() && l.visible)
				{
					group = getGroupFromDictionary(l);
					if (!group)
					{
						debug("\t LEGENDS checkIfAllLegendsAreLoaded NEEDS LOADING l: " + l.name  + " id: " + l.layerID);
						//it needs to be loaded
						needLoading = true;
					} else {
						debug("LEGENDS checkIfAllLegendsAreLoaded l: " + l.name + " id: " + l.layerID + " HAVE GROUP for layer");
					}
				}
			}
			debug("InteractieLayerLegends checkIfAllLegendsAreLoaded needLoading: " + needLoading);
			return needLoading;
		}

		public function heightCompare(obj1: Object, obj2: Object): int
		{
			var l1: InteractiveLayer = obj1 as InteractiveLayer;
			var l2: InteractiveLayer = obj2 as InteractiveLayer;
			var rect1: Rectangle = getRectangleFromLayer(l1);
			var rect2: Rectangle = getRectangleFromLayer(l2);
			if (rect1.height < rect2.height)
				return 1;
			if (rect1.height > rect2.height)
				return -1;
			if (rect1.width < rect2.width)
				return 1;
			if (rect1.width > rect2.width)
				return -1;
			return 0;
		}

		public function widthCompare(obj1: Object, obj2: Object): int
		{
			var l1: InteractiveLayer = obj1 as InteractiveLayer;
			var l2: InteractiveLayer = obj2 as InteractiveLayer;
			var rect1: Rectangle = getRectangleFromLayer(l1);
			var rect2: Rectangle = getRectangleFromLayer(l2);
			if (rect1.width < rect2.width)
				return 1;
			if (rect1.width > rect2.width)
				return -1;
			if (rect1.height < rect2.height)
				return 1;
			if (rect1.height > rect2.height)
				return -1;
			return 0;
		}

		private function getFirstAreaDirection(directionX: int, directionY: int): String
		{
			if (directionX == 1)
				return "right";
			if (directionX == -1)
				return "left";
			if (directionY == 1)
				return "down";
			if (directionY == -1)
				return "up";
			return '';
		}

		private function getSecondAreaDirection(directionX: int, directionY: int, horizontalAlign: String, verticalAlign: String): String
		{
			if (directionX != 0)
			{
				if (verticalAlign == 'top')
					return "down";
				if (verticalAlign == 'bottom')
					return "up";
			}
			if (directionY != 0)
			{
				if (horizontalAlign == 'left')
					return "right";
				if (horizontalAlign == 'right')
					return "left";
			}
			return '';
		}

		private function getPrefferedSortingType(horizontalDirection: String, verticalDirection: String): int
		{
			if (horizontalDirection == 'none')
				return 1;
			return 0;
		}
		private var properties: PackingLayoutProperties;
		private var _topArea: DynamicArea;
		public var step: int;

		private function notify(type: String): void
		{
//			debug("InteractiveLayerLegends NOTIFY: " + type);
			dispatchEvent(new Event(type));
		}

		public function renderLegendsStack(justReposition: Boolean = false): void
		{
			debug("\n\n******************************");
			debug("******************************");
			debug("\trenderLegendsStack justReposition = " + justReposition);
			if (checkIfAllLegendsAreLoaded())
			{
				if (!_legendsAreLoading)
					loadLegends();
				return;
			}
			notify(LEGENDS_LAYERING_STARTED);
			var l: InteractiveLayerWMS;
			var posX: int = 0;
			var posY: int = 0;
//			var maxWidth: int = Math.max(width, 600);
//			var maxHeight: int = Math.max(height, 200);
			var maxWidth: int = Math.max(width, 100);
			var maxHeight: int = Math.max(height, 100);
			if (maxWidth == 0 || maxHeight == 0)
			{
				return;
			}
			if (maxWidth < 100 || maxHeight < 100)
				debug("Small area: STOP");
			debug("maxWidth: " + maxWidth + " maxHeight: " + maxHeight);
			var paddingLeft: int = getStyle('paddingLeft');
			var paddingRight: int = getStyle('paddingRight');
			var paddingTop: int = getStyle('paddingTop');
			var paddingBottom: int = getStyle('paddingBottom');
			var horizontalAlign: String = getStyle('horizontalAlign');
			var verticalAlign: String = getStyle('verticalAlign');
			var horizontalDirection: String = getStyle('horizontalDirection');
			var verticalDirection: String = getStyle('verticalDirection');
			_legends = getAllLegendLayers();
			var sortType: int = getPrefferedSortingType(horizontalDirection, verticalDirection);
			switch (sortType)
			{
				case 0:
				{
					_legends.sort(heightCompare);
					break;
				}
				case 1:
				{
					_legends.sort(widthCompare);
					break;
				}
			}
			var hAlign: String = horizontalAlign;
			var vAlign: String = verticalAlign;
			var directionX: int = 0;
			var directionY: int = 0;
			if (horizontalDirection == 'left')
				directionX = -1;
			else
			{
				if (horizontalDirection == 'right')
					directionX = 1;
			}
			if (verticalDirection == 'up')
				directionY = -1;
			else
			{
				if (verticalDirection == 'down')
					directionY = 1;
			}
			switch (hAlign)
			{
				case 'left':
				{
					posX = paddingLeft;
					break;
				}
				case 'center':
				{
					posX = maxWidth / 2;
					break;
				}
				case 'right':
				{
					posX = maxWidth - paddingRight;
					break;
				}
			}
			switch (vAlign)
			{
				case 'top':
				{
					posY = paddingTop;
					break;
				}
				case 'middle':
				{
					posY = maxHeight / 2;
					break;
				}
				case 'bottom':
				{
					posY = maxHeight - paddingBottom;
					break;
				}
			}
			var initialX: int = posX;
			var initialY: int = posY;
			var startX: int = posX;
			var startY: int = posY;
			var endX: int = posX;
			var endY: int = posY;
			var startX2: int = posX;
			var startY2: int = posY;
			var endX2: int = posX;
			var endY2: int = posY;
			var rowItems: int = 0;
			var colItems: int = 0;
			var initialReposition: Boolean = false;
			debug("\n\nLEGENDS graphics clear");
			clear(graphics);
			legendsBkgRectangle = new Rectangle();
			_currentRectangle = new Rectangle();
			var gapX: int = 10;
			var gapY: int = 10;
			if (getStyle('horizontalGap'))
				gapX = getStyle('horizontalGap');
			if (getStyle('verticalGap'))
				gapY = getStyle('verticalGap');
			properties = new PackingLayoutProperties();
			properties.horizontalAlign = horizontalAlign;
			properties.verticalAlign = verticalAlign;
			properties.horizontalDirection = horizontalDirection;
			properties.verticalDirection = verticalDirection;
			var bkgPadding: int = 0;
			if (getStyle('legendsBackgroundPadding'))
				bkgPadding = getStyle('legendsBackgroundPadding');
			var padding: Padding = new Padding();
			padding.bottom = bkgPadding;
			padding.top = bkgPadding;
			padding.left = bkgPadding;
			padding.right = bkgPadding;
			properties.padding = padding;
			properties.colItems = colItems;
			properties.rowItems = rowItems;
			properties.maxWidth = maxWidth;
			properties.maxHeight = maxHeight;
			properties.gapX = gapX;
			properties.gapY = gapY;
			properties.posX = posX;
			properties.posY = posY;
			properties.directionX = directionX;
			properties.directionY = directionY;
			properties.initialX = initialX;
			properties.initialY = initialY;
			properties.startX = startX;
			properties.startY = startY;
			properties.startX2 = startX2;
			properties.startY2 = startY2;
			properties.endX = endX;
			properties.endX2 = endX2;
			properties.endY = endY;
			properties.endY2 = endY2;
			properties.initialReposition = initialReposition;
			var debugPos: Boolean = true;
			debug("\n\n NEW ROUND");
			l = _legends[0] as InteractiveLayerWMS;
			var _currentArea: DynamicArea = new DynamicArea(null);

			_currentArea.area = new Rectangle(paddingLeft, paddingTop, maxWidth - paddingLeft - paddingRight, maxHeight - paddingBottom - paddingTop);

			_topArea = _currentArea;
			var cnv: InteractiveLayerLegendGroup = getGroupFromDictionary(l);
			var rect: Rectangle = getRectangleFromLayer(l);
			if (rect && rect.width > 0)
			{
				padding.updateRectangleSizeWithPadding(rect);
				properties.firstAreaDirection = getFirstAreaDirection(directionX, directionY);
				properties.secondAreaDirection = getSecondAreaDirection(directionX, directionY, horizontalAlign, verticalAlign);
				_currentArea.createFromItem(rect, properties.firstAreaDirection, properties.secondAreaDirection);
				rect = _currentArea.itemArea;
				cnv.x = rect.x;
				cnv.y = rect.y;
				debug("renderLegendsStack pos: ["+cnv.x + "," + cnv.y+"] size: ["+cnv.width+","+cnv.height+"] rect: " + rect);
				updateLegendScale(l);
				drawLegendsBackground(rect);
				step = 1;
				nextStep();
			}
		}

		/**
		 * Return all layers which has legend and legend is alread loaded
		 * @return
		 *
		 */
		private function getAllLegendLayers(): Array
		{
			var _arr: Array = [];
			for each (var l: InteractiveLayer in m_layers)
			{
				if (l.hasLegend())
				{
					var canvas: InteractiveLayerLegendGroup = getGroupFromDictionary(l);
					if (canvas)
					{
						canvas.visible = l.visible;
						//					var canvas: Rectangle = l.clone();
						if (l.visible)
							_arr.push(l);
					}
				}
			}
			debug("getAllLegendLayers : " + _arr.length);
			return _arr;
		}

		private function nextStep(): void
		{
			if (_legends.length > step)
			{
//				var l: Rectangle = _legends[step];
//				var l: InteractiveLayerWMS = getLayerAt(step) as InteractiveLayerWMS;
				var l: InteractiveLayerWMS = _legends[step] as InteractiveLayerWMS;
				properties = placeRectangle(l, properties);
				if (!properties)
				{
					//there were problem, try run again rendering
					setTimeout(renderLegendsStack, 1000);
					return;
				}
				step++;
//				if (chbAutomate.selected)
				nextStep();
			}
			else
			{
				//end of algorithm
				_maximumArea = new Rectangle();
				_topArea.getBiggestItemArea(maximumArea);
				notify(LEGENDS_LAYERING_FINISHED);
			}
		}

		private function placeRectangle(l: InteractiveLayerWMS, properties: PackingLayoutProperties): PackingLayoutProperties
		{
			var debugPos: Boolean = true;
			var horizontalAlign: String = properties.horizontalAlign;
			var padding: Padding = properties.padding;

			if (l.hasLegend())
			{
				var canvas: InteractiveLayerLegendGroup = getGroupFromDictionary(l);
				if (canvas)
				{
					canvas.visible = l.visible;
					if (l.visible)
					{
						var rect: Rectangle = getRectangleFromLayer(l);
						if (rect.width == 0 || rect.height == 0)
						{
							debug("Wrong rect, skip");
							return null;
						}
						padding.updateRectangleSizeWithPadding(rect);
						var areas: Array = [];
						_topArea.findSuitableArea(rect, 'both', areas);
						if (areas.length > 0)
						{
							debug("Areas found: " + areas.length);
							var bestArea: DynamicArea = areas[0].area;
							var bestDenstiy: Number = areas[0].density;
							if (bestArea.area.width == 0 || bestArea.area.height == 0)
								debug("stop area is 0");
							bestArea.createFromItem(rect, properties.firstAreaDirection, properties.secondAreaDirection);
							rect = bestArea.itemArea;
							canvas.x = rect.x;
							canvas.y = rect.y;
							debug("placeRectangle pos: ["+canvas.x + "," + canvas.y+"] size: ["+canvas.width+","+canvas.height+"] rect: " + rect);
							updateLegendScale(l);
							drawLegendsBackground(rect);
						}
						else
							debug("Areas: did not found suitable area : topArea: " + _topArea.area);
					}
				}
			}
//			debug("******************************\n\n");
			//				properties.paddingRight = paddingRight;
//			properties.colItems = colItems;
//			properties.rowItems = rowItems;
//			properties.maxWidth = maxWidth;
//			properties.maxHeight = maxHeight;
//			properties.gapX = gapX;
//			properties.gapY = gapY;
//			properties.posX = posX;
//			properties.posY = posY;
//			properties.initialReposition = initialReposition;
			return properties;
		}

		private function updateLegendScale(l: InteractiveLayer): void
		{
//			debug("updateLegendScale scale ["+legendScaleX+","+legendScaleY+"]")
//			var canvas: Canvas = getCanvasFromDictionary(l);
//			l.renderLegend(canvas, null, legendScaleX, legendScaleY, getStyle('labelAlign'), true);
		}

		private function drawLegendsBackground(rect: Rectangle): void
		{
			if (getStyle('legendsBackgroundColor'))
			{
				var bkgClr: uint = 0xff0000;
				var bkgAlpha: Number = 1;
				var bkgPadding: int = 0;
				if (getStyle('legendsBackgroundColor'))
					bkgClr = getStyle('legendsBackgroundColor');
				if (getStyle('legendsBackgroundAlpha'))
					bkgAlpha = getStyle('legendsBackgroundAlpha');
				if (getStyle('legendsBackgroundPadding'))
					bkgPadding = getStyle('legendsBackgroundPadding');
				var gr: Graphics = graphics;
				gr.beginFill(bkgClr, bkgAlpha);
				gr.drawRect(rect.x - bkgPadding, rect.y - bkgPadding, rect.width + bkgPadding * 2, rect.height + bkgPadding * 2);
				gr.endFill();
//				debug("drawLegendsBackground "+bkgClr+", "+bkgAlpha);
//				debug("drawLegendsBackground "+width+", "+height);
//				debug("drawLegendsBackground "+(rect.x - bkgPadding)+", "+(rect.y - bkgPadding)+", "+(rect.width + bkgPadding)+", "+(rect.height + bkgPadding));
			}
		}

		private function onLegendError(cnv: InteractiveLayerLegendGroup): void
		{
			debug("\n\n onLegendError  legendsToBeRendered: " + legendsLoadingCount + " canvas: " + cnv.width + ", " + cnv.height + " Position: " + cnv.x + " , " + cnv.y);
			cnv.visible = false;
			legendReceived();
		}
		private function onLegendRendered(cnv: InteractiveLayerLegendGroup): void
		{
			debug("\n\n onLegendRendered  legendsToBeRendered: " + legendsLoadingCount + " canvas: " + cnv.width + ", " + cnv.height + " Position: " + cnv.x + " , " + cnv.y);
			cnv.visible = true;
			legendReceived();
		}

		private function legendReceived(): void
		{
			legendsLoadingCount--;
			if (legendsLoadingCount < 1)
			{
				debug("ALL LEGENDS ARE LOADED");
				_legendsAreLoading = false;
				notify(LEGENDS_LOADING_FINISHED);
				repositionedLegends();
			}
		}

		override protected function updateDisplayList(unscaledWidth: Number, unscaledHeight: Number): void
		{
//			graphics.clear();
//			draw(graphics);
		}

		private function getLegendImageFromGroup(currGroup: InteractiveLayerLegendGroup): InteractiveLayerLegendImage
		{
			var elements: int = currGroup.numElements;
			var legend: InteractiveLayerLegendImage;
			for (var i: int = 0; i < elements; i++)
			{
				var dObj: IVisualElement = currGroup.getElementAt(i);

				if (dObj is InteractiveLayerLegendImage)
				{
					legend = dObj as InteractiveLayerLegendImage;
				}
			}
			return legend;
		}
		override public function onMouseClick(event: MouseEvent): Boolean
		{
//			var group: InteractiveLayerLegendGroup = event.target as InteractiveLayerLegendGroup;
//			if (group)
//			{
				for each (var currGroup: InteractiveLayerLegendGroup in  m_groupDictionary)
				{
					var hit: Boolean = currGroup.hitTestPoint(event.stageX, event.stageY, true);
					if (hit)
					{
						var legend: InteractiveLayerLegendImage = getLegendImageFromGroup(currGroup);
						var e: InteractiveLayerLegendEvent = new InteractiveLayerLegendEvent(InteractiveLayerLegendEvent.LEGEND_CLICK, legend);
						e.legendGroup = currGroup;
						dispatchEvent(e);
						return true;
					}
				}
//			}
			return false;
		}

		private function debug(str: String): void
		{
//			_logger.debug(str);
//			trace(this + str);
		}

		override public function toString(): String
		{
			return "InteractiveLayerLegends: ";
		}
	}
}
