package com.iblsoft.flexiweather.widgets
{
	import com.iblsoft.flexiweather.ogc.wfs.WFSFeature;
	import com.iblsoft.flexiweather.proj.Coord;
	import flash.display.DisplayObjectContainer;
	import flash.display.Graphics;
	import flash.display.Sprite;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	import flash.text.TextField;
	import mx.collections.ArrayCollection;
	import mx.events.CollectionEvent;
	import mx.events.DynamicEvent;

	public class InteractiveLayerPlaces extends InteractiveLayer
	{
		private var placeSpacing: int = 5;
		protected var ma_coords: ArrayCollection = new ArrayCollection();
		public static const CHANGE: String = "interactiveLayerPlacesChanged";
		public static const SHOW_TOOLTIP: String = 'showTooltip';
		public static const HIDE_TOOLTIP: String = 'hideTooltip';

		public function InteractiveLayerPlaces(container: InteractiveWidget = null)
		{
			super(container);
			mouseChildren = true;
			mouseEnabled = true;
			_sprites = new Array();
			ma_coords.addEventListener(CollectionEvent.COLLECTION_CHANGE, onCoordsCollectionChanged);
		}
		private var _sprites: Array;

		private function clearOldState(): void
		{
			var total: int = numChildren;
			while (numChildren > 0)
			{
				var sprite: PlaceSprite = removeChildAt(0) as PlaceSprite;
				if (sprite)
				{
					sprite.destroy();
					_sprites.push(sprite);
				}
//				if (tooltip && tooltip.parent == this)
//				{
//					removeChild(tooltip);
//					tooltip = null;
//				}
			}
		}

		private function getNewPlaceSprite(): PlaceSprite
		{
			var sprite: PlaceSprite;
			if (_sprites && _sprites.length > 0)
				sprite = _sprites.pop();
			else
				sprite = new PlaceSprite();
			sprite.mouseEnabled = true;
			sprite.mouseChildren = true;
			addChild(sprite);
			return sprite;
		}

		override public function onAreaChanged(b_finalChange: Boolean): void
		{
			invalidateDynamicPart();
		}

		/**
		 * set all places at once
		 * @param places - ArrayCollection of InteractiveLayerPlace items
		 * o
		 */
		public function setPlaces(places: ArrayCollection): void
		{
			ma_coords = places;
			invalidateDynamicPart();
		}

		public function addPlaceCoord(coord: Coord): void
		{
			ma_coords.addItem(coord);
			invalidateDynamicPart();
		}

		protected function onCoordsCollectionChanged(event: CollectionEvent): void
		{
			invalidateDynamicPart();
		}

		override public function invalidateDynamicPart(b_invalid: Boolean = true): void
		{
			super.invalidateDynamicPart(b_invalid);
			//clearOldState();
		}

		override public function draw(graphics: Graphics): void
		{
			super.draw(graphics);
			clearOldState();
			for each (var placeObject: Object in ma_coords)
			{
				if (placeObject is InteractiveLayerPlace)
					drawPlace(placeObject as InteractiveLayerPlace);
				else
				{
					if (placeObject is Array)
					{
						var places: Array = placeObject as Array;
						drawPlace(places);
					}
				}
			}
		}

		private function drawPlace(place: Object, xPos: Number = 0): void
		{
			var sprite: PlaceSprite = getNewPlaceSprite();
			var c: Coord;
			var pt: Point;
			if (place is InteractiveLayerPlace)
			{
				c = place.coord;
				pt = container.coordToPoint(c);
				sprite.draw(place as InteractiveLayerPlace, pt, xPos);
			}
			else
			{
				if (place is Array)
				{
					c = ((place as Array)[0] as InteractiveLayerPlace).coord;
					pt = container.coordToPoint(c);
					sprite.drawMultiple(place as Array, pt);
				}
			}
		}

		private function debugParent(object: DisplayObjectContainer, name: String): void
		{
			var str: String = 'DEBUG parent [' + object.name + ']\n';
			str += 'mouseEnabled: ' + object.mouseEnabled + ' mouseChildren: ' + object.mouseChildren + '\n';
			str += 'parents: ';
			while (object.parent)
			{
				str += object.parent.name + ' [' + object.parent.mouseEnabled + ',' + object.parent.mouseChildren + '] | ';
				object = object.parent;
			}
		}

		private function debugSprites(): void
		{
			return;
			var sprite: PlaceSprite;
			var str: String = 'DEBUG sprites\n';
			for each (sprite in _sprites)
			{
				str += sprite + ' tooltip: ' + sprite.tooltip + ' letters: ' + sprite.debugLetters() + ' | ';
			}
			var total: int = numChildren;
			for (var i: int = 0; i < total; i++)
			{
				sprite = getChildAt(i) as PlaceSprite;
				if (sprite)
					str += 'On display list: ' + sprite + ' | ';
			}
		}

		override public function onMouseClick(event: MouseEvent): Boolean
		{
			if (event.target is IconSprite)
			{
				//debugParent(event.target as DisplayObjectContainer, 'sprite');
				onMouseOver(event);
			}
			else
				onMouseOut(event);
			return false;
		}

		private function onMouseOver(event: MouseEvent = null): void
		{
			var txt: String = (event.target as IconSprite).tooltip;
			var feature: WFSFeature = (event.target as IconSprite).place.feature;
			var de: DynamicEvent = new DynamicEvent(SHOW_TOOLTIP, true);
			de['text'] = txt;
			de['x'] = event.localX;
			de['y'] = event.localY + 10;
			de['feature'] = feature;
			dispatchEvent(de);
		}

		private function onMouseOut(event: MouseEvent = null): void
		{
			var de: DynamicEvent = new DynamicEvent(HIDE_TOOLTIP, true);
			dispatchEvent(de);
		}

		// getters & setters
		public function get coords(): ArrayCollection
		{
			return ma_coords;
		}
	}
}
import flash.text.TextField;
import flash.display.Sprite;
import flash.text.TextFormat;
import flash.geom.Point;
import com.iblsoft.flexiweather.widgets.InteractiveLayerPlace;
import flash.display.Graphics;
import com.iblsoft.flexiweather.proj.Coord;
import flash.filters.DropShadowFilter;
import flash.filters.GlowFilter;
import flash.events.MouseEvent;
import mx.containers.Canvas;
import mx.controls.TextArea;
import mx.core.UIComponent;
import mx.core.UITextField;

/*****************************************************************************************************************************************
 *
 *  Class which draw 1 icon for location
 *
*****************************************************************************************************************************************/
class IconSprite extends Sprite
{
	public var place: InteractiveLayerPlace;
	//private var _letters: Array;
	public var tooltip: String;
	private var iconsPosition: int = 16;
	private var size: int = 16;

	private function get halfSize(): Number
	{
		return size / 2;
	}

	public function IconSprite()
	{
		//_letters = new Array();
	}

	public function drawItem(pt: Point, _place: InteractiveLayerPlace, xPos: Number = 0): void
	{
		place = _place
		var gr: Graphics = graphics;
		gr.beginFill(place.pointColor);
		gr.lineStyle(1, 0);
		//move place in x axis (in case there is more place for same location)
		pt.x += xPos;
		switch (place.pointType)
		{
			case 'Circle':
			{
				gr.drawCircle(pt.x, pt.y + iconsPosition, halfSize);
				break;
			}
			default:
			case 'Square':
			{
				gr.drawRect(pt.x - halfSize, pt.y - halfSize + iconsPosition, size, size);
				break;
			}
		}
		gr.endFill();
	}

	public function setLetterProperties(place: InteractiveLayerPlace, pt: Point): void
	{
		var letterTxt: TextField = createLetter();
		letterTxt.text = place.pointLetter;
		var format: TextFormat = letterTxt.getTextFormat();
		format.color = place.pointLetterColor;
		format.size = 12;
		format.font = '_sans';
		letterTxt.setTextFormat(format);
		letterTxt.x = pt.x - letterTxt.textWidth / 2 - 2;
		letterTxt.y = pt.y - letterTxt.textHeight / 2 - 2 + iconsPosition;
		letterTxt.width = size;
		letterTxt.height = size;
	}

	private function createLetter(): TextField
	{
		var txt: TextField = new TextField();
		//_letters.push(txt);
		txt.mouseEnabled = false;
		addChild(txt);
		return txt;
	}
}

/*****************************************************************************************************************************************
 *
 *  Class which draw 1 location in map
 *
*****************************************************************************************************************************************/
class PlaceSprite extends Sprite
{
	private var labelTxt: TextField;
	private var size: int = 16;

	private function get halfSize(): Number
	{
		return size / 2;
	}
	private var gap: int = 3;
	private static var cnt: int = 0;
	private var icons: Sprite;

	public function get placeWidth(): Number
	{
		return size / 2 + gap * 3 + labelTxt.textWidth;
	}

	public function PlaceSprite(): void
	{
		cnt++;
		name = 'PlaceSprite' + cnt;
		icons = new Sprite();
		addChild(icons);
		hitArea = icons;
		createLabel();
	}

	/*
	public function debugLetters(): String
	{
		var retStr: String = '';

		if (_letters && _letters.length > 0)
		{
			for each (var txt: TextField in _letters)
			{
				retStr += txt.text + ', ';
			}
		}
		return retStr;

	}*/
	public function destroy(): void
	{
	/*
	if (_letters && _letters.length > 0)
	{
		for each (var txt: TextField in _letters)
		{
			if (txt.parent == this)
				removeChild(txt);
			txt = null;
		}
		_letters = [];
	}*/
	}

	public function setLabelPosition(point: Point): void
	{
		labelTxt.x = point.x;
		labelTxt.y = point.y - labelTxt.textHeight / 2 - 2;
	}

	public function setLabelText(text: String): void
	{
		if (!text)
			text = '';
		labelTxt.text = text;
		var format: TextFormat = labelTxt.getTextFormat();
		labelTxt.autoSize = 'left';
		format.bold = false;
		format.size = 13;
		format.font = '_sans';
		labelTxt.setTextFormat(format);
		labelTxt.mouseEnabled = false;
	}

	private function destroyAllIcons(): void
	{
		while (icons.numChildren)
		{
			icons.removeChildAt(0);
		}
	}

	/**
	 * Draw multiple places. There will be just 1 label (from first place) and under there will be all icons
	 * @param places
	 * @param pt
	 *
	 */
	public function drawMultiple(places: Array, pt: Point): void
	{
		destroyAllIcons();
		var gr: Graphics = icons.graphics;
		gr.clear();
		var placeName: String = '';
		var cnt: int = 0;
		var labelPoint: Point;
		for each (var place: InteractiveLayerPlace in places)
		{
			var iconSprite: IconSprite = new IconSprite();
			icons.addChild(iconSprite);
			iconSprite.drawItem(pt, place);
			iconSprite.setLetterProperties(place, pt);
			if (cnt == 0)
			{
				placeName = place.placeLabel;
				labelPoint = new Point(pt.x, pt.y);
			}
			iconSprite.tooltip = place.placeLabel + '\n\n' + place.tooltip;
			pt.x += size + gap;
			cnt++;
		}
		drawPointCross(gr, labelPoint);
		setLabelPosition(new Point(labelPoint.x + gap, labelPoint.y));
		setLabelText(placeName);
	}

	/**
	 * Draw single place (1 object inside)
	 * @param place
	 * @param pt
	 * @param xPos
	 *
	 */
	public function draw(place: InteractiveLayerPlace, pt: Point, xPos: Number): void
	{
		destroyAllIcons();
		var iconSprite: IconSprite = new IconSprite();
		icons.addChild(iconSprite);
		iconSprite.tooltip = place.placeLabel + '\n\n' + place.tooltip;
		var gr: Graphics = icons.graphics;
		gr.clear();
		drawPointCross(gr, pt);
		iconSprite.drawItem(pt, place, xPos);
		iconSprite.setLetterProperties(place, pt);
		setLabelText(place.placeLabel);
		setLabelPosition(new Point(pt.x + gap, pt.y));
	}

	private function drawPointCross(gr: Graphics, pt: Point): void
	{
		var crossSize: int = 3;
		/*
		gr.lineStyle(1, 0x000000);

		var add: int = 0;

		gr.moveTo(pt.x - crossSize + add, pt.y - crossSize + add);
		gr.lineTo(pt.x + crossSize + add, pt.y + crossSize + add);
		gr.moveTo(pt.x + crossSize + add, pt.y - crossSize + add);
		gr.lineTo(pt.x - crossSize + add, pt.y + crossSize + add);
		*/
		gr.lineStyle(1, 0x880000);
		gr.beginFill(0xff0000);
		gr.drawCircle(pt.x, pt.y, 3);
		gr.endFill();
	}

	private function createLabel(): void
	{
		if (!labelTxt)
		{
			labelTxt = new TextField();
			var glow: GlowFilter = new GlowFilter(0xffffff, 1, 5, 5);
			filters = [glow];
			labelTxt.height = 16;
			//labelTxt.antiAliasType = Text
//			labelTxt.mouseEnabled = false;
			labelTxt.selectable = false;
			labelTxt.border = false;
			addChild(labelTxt);
		}
	}

	override public function toString(): String
	{
		return 'PlaceSprite: ' + name;
	}
}
