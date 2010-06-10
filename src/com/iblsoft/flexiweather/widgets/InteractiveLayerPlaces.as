package com.iblsoft.flexiweather.widgets
{
	import com.iblsoft.flexiweather.proj.Coord;
	
	import flash.display.Graphics;
	import flash.geom.Point;
	
	import mx.collections.ArrayCollection;
	import mx.events.CollectionEvent;
	
	public class InteractiveLayerPlaces extends InteractiveLayer
	{
		protected var ma_coords: ArrayCollection = new ArrayCollection();
		protected var m_highlightedCoord: Coord = null;
		protected var m_selectedCoord: Coord = null;
//		protected var m_highlightedLineFrom: Coord = null;

		public static const CHANGE: String = "interactiveLayerPlacesChanged";
		 
		public function InteractiveLayerPlaces(container: InteractiveWidget = null)
		{
			super(container);
			setStyle("routeColor", 0x000000);
			setStyle("routeAlpha", 1.0);
			setStyle("routeFillColor", 0x00FF00);
			setStyle("routeFillAlpha", 1.0);
			setStyle("pointColor", 0x000000);
			setStyle("pointAlpha", 1.0);
			setStyle("pointFillColor", 0x00FF00);
			setStyle("pointFillAlpha", 1.0);
			setStyle("pointHighlightFillColor", 0xFFFFFF);
			setStyle("pointHighlightFillAlpha", 1.0);
			ma_coords.addEventListener(CollectionEvent.COLLECTION_CHANGE, onCoordsCollectionChanged);
		}
		
		override public function onAreaChanged(b_finalChange: Boolean): void
		{
			ma_coords.removeAll();
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
		
		override public function draw(graphics: Graphics): void
		{
			super.draw(graphics);

			for each(var place: InteractiveLayerPlace in ma_coords) 
			{			
				var c: Coord = place.coord;
				
				var pt:Point = container.coordToPoint(c);
				
				graphics.beginFill(place.pointColor);
				graphics.lineStyle(1,0);
				
				var size: int = 12;
				var halfSize: int = size / 2;
				switch (place.pointType)
				{
					case 'Circle':
						graphics.drawCircle(pt.x, pt.y, halfSize);
						break;
					case 'Square':
						graphics.drawRect(pt.x - halfSize, pt.y - halfSize, size, size);
						break;
				}
				
				graphics.endFill();
			}
		}

		// getters & setters
		public function get coords(): ArrayCollection
		{ return ma_coords; }
	}
}
