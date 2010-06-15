package com.iblsoft.flexiweather.widgets
{
	import com.iblsoft.flexiweather.proj.Coord;
	
	import flash.display.DisplayObjectContainer;
	import flash.display.Graphics;
	import flash.display.Sprite;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	import flash.text.TextField;
	
	import mx.collections.ArrayCollection;
	import mx.events.CollectionEvent;
	
	public class InteractiveLayerPlaces extends InteractiveLayer
	{
		private var placeSpacing: int = 5;
		
		protected var ma_coords: ArrayCollection = new ArrayCollection();

		public static const CHANGE: String = "interactiveLayerPlacesChanged";
		 
		public function InteractiveLayerPlaces(container: InteractiveWidget = null)
		{
			super(container);
			
			mouseChildren = true;
			mouseEnabled = true;
			
			_sprites = new Array();
			ma_coords.addEventListener(CollectionEvent.COLLECTION_CHANGE, onCoordsCollectionChanged);
			
			mouseChildren = true;
			mouseEnabled = true;
		}
		
		private var _sprites: Array;
		
		private function clearOldState(): void
		{
			trace("CLEAR OLD STATE");
			var total: int = numChildren;
			
			while (numChildren > 0)
			{
				var sprite: PlaceSprite = removeChildAt(0) as PlaceSprite;
				if (sprite)
				{
					sprite.destroy();
					_sprites.push(sprite);
				} 
				
				if (tooltip && tooltip.parent == this)
				{
					removeChild(tooltip);
					tooltip = null;
				}
			}
		}
		
		private function getNewPlaceSprite(): PlaceSprite
		{
			var sprite: PlaceSprite;
			if (_sprites && _sprites.length > 0)
			{
				sprite = _sprites.pop();
			} else {
				sprite = new PlaceSprite();
			}
			
			sprite.mouseEnabled = true;
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
 			
			for each(var placeObject: Object in ma_coords) 
			{			
				if (placeObject is InteractiveLayerPlace)
				{
					drawPlace(placeObject as InteractiveLayerPlace);
				} else {
					if (placeObject is Array)
					{
						var places: Array = placeObject as Array;
						drawPlace(places);

					}
				}
				
			}
		}
		
		private var tooltip: PlaceSpriteTooltip;
		
		private function drawPlace(place: Object, xPos: Number = 0): void
		{
			var sprite: PlaceSprite = getNewPlaceSprite();
			sprite.mouseEnabled = true;
			sprite.mouseChildren = false;
			
			trace("DRAW PLACE" + sprite)
			var c: Coord;
			var pt:Point;
			if (place is InteractiveLayerPlace)
			{
				c = place.coord;
				pt = container.coordToPoint(c);
				
				sprite.draw(place as InteractiveLayerPlace, pt, xPos);
				
			} else {
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
			var str: String = 'DEBUG parent ['+object.name+']\n';
			str += 'mouseEnabled: ' + object.mouseEnabled + ' mouseChildren: ' + object.mouseChildren + '\n';
			str += 'parents: ';
			while (object.parent)
			{
				str += object.parent.name + ' ['+object.parent.mouseEnabled+','+object.parent.mouseChildren+'] | ';
				object = object.parent;
			}	
			
			trace(str);
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
					str += 'On display list: ' + sprite + ' tooltip: ' + sprite.tooltip + ' letters: ' + sprite.debugLetters() + ' | ';
			}
			
			trace(str);
		}
		override public function onMouseClick(event:MouseEvent):Boolean
		{
			trace("\n\n**********************************");
			trace('mouseClick' + event.target);
			
			if (event.target is PlaceSprite)
			{
				//debugParent(event.target as DisplayObjectContainer, 'sprite');
				onMouseOver(event);
			} else {
				onMouseOut(event);
			}
			
//			debugSprites();
			
//			debugParent(event.target as DisplayObjectContainer, 'target');
//			debugParent(event.currentTarget as DisplayObjectContainer, 'currentTarget');
			
//			if (event.currentTarget.name == 'm_iw' && event.currentTarget is InteractiveWidget)
//			{
//				var widget: InteractiveWidget = event.currentTarget as InteractiveWidget;
//
//			}
				
			return false;
		}
		
		private function onMouseOver(event: MouseEvent = null): void
		{
			if (!tooltip)
				tooltip = new PlaceSpriteTooltip();
	
			tooltip.mouseChildren = false;
			tooltip.mouseEnabled = false;
			
			addChild(tooltip);
			
							
			var txt: String = (event.target as PlaceSprite).tooltip;
			tooltip.draw(txt);
			
			tooltip.x = event.localX - tooltip.width / 2;
			tooltip.y = event.localY + 10;
			
			trace("Tooltip ["+tooltip.x + ", " + tooltip.y + "] ["+tooltip.width+","+tooltip.height+"] visible:" + tooltip.visible + " alpha: " + tooltip.alpha + " tooltip: " + tooltip.parent);
			tooltip.visible = true;
			tooltip.alpha = 1;
		}
		
		private function onMouseOut(event: MouseEvent = null): void
		{
			if (tooltip && tooltip.parent == this)
				removeChild(tooltip);
		}
	
		

		// getters & setters
		public function get coords(): ArrayCollection
		{ return ma_coords; }
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
	

class PlaceSpriteTooltip extends Sprite
{
	private var tf: TextField;
	
	public function PlaceSpriteTooltip(): void
	{
		tf = new TextField();
		addChild(tf);
		
		tf.x = 5;
		tf.y = 5;
		
	}
	
	public function draw(txt: String): void
	{
		var gr: Graphics = graphics;
		
		tf.text = txt;
		tf.autoSize = 'left';
		var format: TextFormat = tf.getTextFormat();
		format.font = '_typewriter';
		format.size = 13;
		format.color = 0x555555;
		tf.setTextFormat(format);
		
		
		gr.clear();
		gr.beginFill(0xf0f0f0);
		gr.lineStyle(1, 0x888888);
		gr.drawRect(0,0, tf.textWidth + 10, tf.textHeight + 10);
		gr.endFill();
	}
}

class PlaceSprite extends Sprite
{
	private var _letters: Array;
	
	private var labelTxt: TextField;
	
	private var size: int = 16;
	private function get halfSize(): Number
	{
		return size / 2;
	}
	private var iconsPosition: int = 16;
	private var gap: int = 3;
	
	private static var cnt: int = 0;
	
	
	public function get placeWidth(): Number
	{
		return size / 2 + gap * 3 + labelTxt.textWidth;
	}
	public function PlaceSprite(): void
	{
		cnt++;
		name = 'PlaceSprite'+cnt;
		
		_letters = new Array();
		createLabel();
		

	}
	
	
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
		
	}
	public function destroy(): void
	{
		if (_letters && _letters.length > 0)
		{
			for each (var txt: TextField in _letters)
			{
				if (txt.parent == this)
					removeChild(txt);
				txt = null;
			}
			_letters = [];
		}
	}
	private function createLetter(): TextField
	{
		var txt: TextField = new TextField();
		_letters.push(txt);
		
		addChild(txt);
		
		return txt;
	}
	public function setLabelPosition(point: Point): void
	{
		labelTxt.x = point.x;
		labelTxt.y = point.y - labelTxt.textHeight / 2 -  2;
	}
	public function setLabelText(text: String): void
	{
		labelTxt.text = text;
		
		var format: TextFormat = labelTxt.getTextFormat();
		
		labelTxt.autoSize = 'left';
		
		format.bold = false;
		format.size = 13;
		format.font = '_typewriter';
		labelTxt.setTextFormat(format);
		
	}
	
	/**
	 * Draw multiple places. There will be just 1 label (from first place) and under there will be all icons 
	 * @param places
	 * @param pt
	 * 
	 */	
	public function drawMultiple(places: Array, pt: Point): void
	{
		var gr: Graphics = graphics;
		gr.clear();
		
		var placeName: String = '';
		var cnt: int = 0;
		var labelPoint: Point;
		
		for each (var place: InteractiveLayerPlace in places)
		{
			drawItem(gr, pt, place);
			
			setLetterProperties(place, pt);
			
			if (cnt == 0)
			{
				placeName = place.placeLabel;
				labelPoint = new Point(pt.x, pt.y);
				
				tooltip = place.tooltip;
			}
			pt.x += size + gap;
			
			cnt++;
			
		}
		drawPointCross(gr, labelPoint);
		setLabelPosition(new Point(labelPoint.x + gap, labelPoint.y));
		setLabelText(placeName);
	}
	
	public var tooltip: String;
	
	/**
	 * Draw single place (1 object inside) 
	 * @param place
	 * @param pt
	 * @param xPos
	 * 
	 */	
	public function draw(place: InteractiveLayerPlace, pt: Point, xPos: Number): void
	{
		tooltip = place.tooltip;
		var gr: Graphics = graphics;
		gr.clear();
		
		drawPointCross(gr, pt);
		drawItem(gr, pt, place, xPos);
		
		setLetterProperties(place, pt);
		
		setLabelText(place.placeLabel);
		setLabelPosition(new Point(pt.x  + gap, pt.y));

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
		
		gr.lineStyle(1,0x880000);
		gr.beginFill(0xff0000);
		gr.drawCircle(pt.x, pt.y, 3);
		gr.endFill();
	}
	
	private function drawItem(gr: Graphics, pt: Point, place: InteractiveLayerPlace, xPos: Number = 0): void
	{
		gr.beginFill(place.pointColor);
		gr.lineStyle(1,0);
		
		//move place in x axis (in case there is more place for same location)
		pt.x += xPos;
		
		switch (place.pointType)
		{
			case 'Circle':
				gr.drawCircle(pt.x, pt.y + iconsPosition, halfSize);
				break;
			default:
			case 'Square':
				gr.drawRect(pt.x - halfSize, pt.y - halfSize + iconsPosition, size, size);
				break;
		}
		
		gr.endFill();
	}
	
	private function setLetterProperties(place: InteractiveLayerPlace, pt: Point): void
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
	
	private function createLabel(): void
	{
		if (!labelTxt)
		{
			labelTxt = new TextField();
			var glow:GlowFilter = new GlowFilter(0xffffff,1,3,3,3);
			filters = [glow];
			labelTxt.height = 16;
	
			addChild(labelTxt);
			
			
		}
	}
	
	override public function toString():String
	{
		return 'PlaceSprite: ' + name;
	}
}