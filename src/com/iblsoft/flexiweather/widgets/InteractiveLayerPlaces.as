package com.iblsoft.flexiweather.widgets
{
	import com.iblsoft.flexiweather.proj.Coord;
	
	import flash.display.Graphics;
	import flash.display.Sprite;
	import flash.geom.Point;
	import flash.text.TextField;
	
	import mx.collections.ArrayCollection;
	import mx.events.CollectionEvent;
	
	public class InteractiveLayerPlaces extends InteractiveLayer
	{
		private var placeSpacing: int = 5;
		
		protected var ma_coords: ArrayCollection = new ArrayCollection();
		protected var m_highlightedCoord: Coord = null;
		protected var m_selectedCoord: Coord = null;
//		protected var m_highlightedLineFrom: Coord = null;

		public static const CHANGE: String = "interactiveLayerPlacesChanged";
		 
		public function InteractiveLayerPlaces(container: InteractiveWidget = null)
		{
			super(container);
			
			_sprites = new Array();
			ma_coords.addEventListener(CollectionEvent.COLLECTION_CHANGE, onCoordsCollectionChanged);
		}
		
		private var _sprites: Array;
		
		private function clearOldState(): void
		{
			trace("PLACES EMPTY clearOldState");
			var total: int = numChildren;
			
			while (numChildren > 0)
			{
				var sprite: PlaceSprite = removeChildAt(0) as PlaceSprite;
				sprite.destroy();
				_sprites.push(sprite);
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
			
			addChild(sprite);
			
			return sprite;
			
		}
		
		override public function onAreaChanged(b_finalChange: Boolean): void
		{
			//ma_coords.removeAll();
			invalidateDynamicPart();
		}

		/**
		 * set all places at once 
		 * @param places - ArrayCollection of InteractiveLayerPlace items
		 * 
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
			clearOldState();
		}
		
		override public function draw(graphics: Graphics): void
		{
			super.draw(graphics);

			trace("PLACES draw");

			if (ma_coords && ma_coords.length > 0)
				trace("PLACES ma_coords: " + ma_coords.length);
			else {
				trace("PLACES EMPTY ma_coords");
				
			}
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
						/*
						var xPos: Number = 0;
						for each (var place: InteractiveLayerPlace in places)
						{
							xPos += drawPlace(place, xPos) + placeSpacing;
						}*/
					}
				}
				
			}
		}
		
		private function drawPlace(place: Object, xPos: Number = 0): void
		{
			var sprite: PlaceSprite = getNewPlaceSprite();
			var c: Coord;
			var pt:Point;
			if (place is InteractiveLayerPlace)
			{
				
				
				c = place.coord;
				pt = container.coordToPoint(c);
				
				sprite.draw(place as InteractiveLayerPlace, pt, xPos);
				
				//var size: Number = sprite.placeWidth;
			} else {
				if (place is Array)
				{
					c = ((place as Array)[0] as InteractiveLayerPlace).coord;
					pt = container.coordToPoint(c);
					sprite.drawMultiple(place as Array, pt);
				}
			}
			
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
	

class PlaceSpriteTooltip extends Sprite
{
	public function PlaceSpriteTooltip(): void
	{
		
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
	
	public function get placeWidth(): Number
	{
		return size / 2 + gap * 3 + labelTxt.textWidth;
	}
	public function PlaceSprite(): void
	{
		_letters = new Array();
		createLabel();

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
		labelTxt.y = point.y - labelTxt.textHeight / 2;
	}
	public function setLabelText(text: String): void
	{
		labelTxt.text = text;
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
			}
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
		
//		gr.lineStyle(1, 0xffffff);
//		
//		var add: int = 1;
//		
//		gr.moveTo(pt.x - crossSize + add, pt.y - crossSize + add);
//		gr.lineTo(pt.x + crossSize + add, pt.y + crossSize + add);
//		gr.moveTo(pt.x + crossSize + add, pt.y - crossSize + add);
//		gr.lineTo(pt.x - crossSize + add, pt.y + crossSize + add);
		
		gr.lineStyle(1, 0x000000);
		
		var add: int = 0;
		
		gr.moveTo(pt.x - crossSize + add, pt.y - crossSize + add);
		gr.lineTo(pt.x + crossSize + add, pt.y + crossSize + add);
		gr.moveTo(pt.x + crossSize + add, pt.y - crossSize + add);
		gr.lineTo(pt.x - crossSize + add, pt.y + crossSize + add);
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
		letterTxt.setTextFormat(format);
		
		letterTxt.x = pt.x - letterTxt.textWidth / 2 - 2;
		letterTxt.y = pt.y - letterTxt.textHeight / 2 - 1 + iconsPosition;
	}
	
	private function createLabel(): void
	{
		labelTxt = new TextField();
		labelTxt.width = 100;
		labelTxt.height = 16;
		
		var format: TextFormat = labelTxt.getTextFormat();
		//format.color = 0xffffff;
		format.bold = true;
		format.size = 12;
		labelTxt.setTextFormat(format);
		
		var glow:GlowFilter = new GlowFilter(0xffffff,1,3,3,3);
		filters = [glow];

		addChild(labelTxt);
		
	}
}