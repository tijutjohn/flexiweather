package com.iblsoft.flexiweather.components.charts
{
	import flash.display.Graphics;
	
	import mx.collections.ArrayCollection;
	import mx.core.UIComponent;
	import mx.events.CollectionEvent;
	
	/**
	 * Display simple chart for Flex project
	 *  
	 * @author fkormanak
	 * 
	 */	
	public class FlexChart extends UIComponent
	{
		private var _dataProvider: ArrayCollection;
		private var _dataProviderChanged: Boolean;
		
		[Bindable]
		public function get dataProvider():ArrayCollection
		{
			return _dataProvider;
		}

		public function set dataProvider(value:ArrayCollection):void
		{
			if (_dataProvider)
			{
				_dataProvider.removeEventListener(CollectionEvent.COLLECTION_CHANGE, onDataProviderChange);
			}
			
			_dataProvider = value;
			
			if (_dataProvider)
			{
				_dataProvider.addEventListener(CollectionEvent.COLLECTION_CHANGE, onDataProviderChange);
			}
			_dataProviderChanged = true;
			invalidateProperties();
		}
		
		protected var simpleChart: SimpleChart;
		
		public function FlexChart()
		{
			super();
		}
		
		private function onDataProviderChange(event: CollectionEvent): void
		{
//			trace("onDataProviderChange " + event.kind);
			simpleChart.refresh();
		}

		override protected function commitProperties():void
		{
			super.commitProperties();
			
			if (_dataProviderChanged)
			{
				if (dataProvider)
					simpleChart.data = dataProvider.source;
				else 
					simpleChart.data = [];
				
				_dataProviderChanged = false;
				simpleChart.refresh();
			}
		}
		override protected function createChildren():void
		{
			super.createChildren();
			
			simpleChart = new SimpleChart();
			addChild(simpleChart);
			simpleChart.xField = 'Month';
			simpleChart.yField = 'Profit';
			
			
			simpleChart.x = 0;
			simpleChart.y = 0;
			
			simpleChart.draw(width, height);
		}
		
		override protected function childrenCreated():void
		{
			super.childrenCreated();
		}
		
		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void
		{
			super.updateDisplayList(unscaledWidth, unscaledHeight);
			
			var gr: Graphics = graphics;
			gr.clear();
			gr.beginFill(0x000000);
			gr.drawRect(0,0,unscaledWidth, unscaledHeight);
			gr.endFill();
			
			if (simpleChart)
				simpleChart.draw(unscaledWidth, unscaledHeight);
		}
	}
}