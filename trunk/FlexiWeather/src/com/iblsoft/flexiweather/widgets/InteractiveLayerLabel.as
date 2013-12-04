package com.iblsoft.flexiweather.widgets
{
	import com.iblsoft.flexiweather.ogc.InteractiveLayerMSBase;
	import com.iblsoft.flexiweather.ogc.SynchronisedVariableChangeEvent;
	import com.iblsoft.flexiweather.ogc.multiview.synchronization.ISynchronizator;
	import com.iblsoft.flexiweather.utils.DimensionLabelParser;
	import com.iblsoft.flexiweather.utils.ISO8601Parser;
	
	import flash.display.DisplayObjectContainer;
	import flash.display.Graphics;
	import flash.display.Sprite;
	import flash.events.DataEvent;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	import flash.text.TextField;
	import flash.text.TextFormat;
	import flash.text.TextFormatAlign;
	
	import mx.collections.ArrayCollection;
	import mx.events.CollectionEvent;
	import mx.events.DynamicEvent;
	import mx.states.OverrideBase;
	import mx.utils.ArrayUtil;
	
	import spark.components.Label;

	public class InteractiveLayerLabel extends InteractiveLayer
	{
		private var _label: TextField;
		private var _synchronizator: ISynchronizator
		private var _synchronizedVariableNames: Array;
		private var _primaryLayer: InteractiveLayerMSBase;

		public function get synchronizator(): ISynchronizator
		{
			return _synchronizator;
		}

		public function set synchronizator(value: ISynchronizator): void
		{
			_synchronizator = value;
		}

		public function InteractiveLayerLabel(synchronizator: ISynchronizator, container: InteractiveWidget = null)
		{
			super(container);
			_synchronizator = synchronizator;
			_synchronizedVariableNames = [];
			mouseChildren = false;
			mouseEnabled = false;
			if (container)
			{
				container.addEventListener(InteractiveLayerMap.PRIMARY_LAYER_CHANGED, onPrimaryLayerChanged);
				updatePrimaryLayer();
			}
		}

//		public function addSynchronisedVariable(synchronisedVariable: String): void
//		{
//			if (ArrayUtil.getItemIndex(synchronisedVariable, _synchronizedVariableNames) == -1)
//			{
//				_synchronizedVariableNames.push(synchronisedVariable);
//				invalidateDynamicPart();
//			} else {
//				trace("\tInteractiveLayerLabel addSynchronisedVariable: " + synchronisedVariable + " NOT ADDED");
//			}
//		}
		override protected function createChildren(): void
		{
			_label = new TextField();
		}

		override protected function childrenCreated(): void
		{
			addChild(_label);
		}

		private function onPrimaryLayerChanged(event: DataEvent = null): void
		{
			updatePrimaryLayer();
		}

		private function updatePrimaryLayer(): void
		{
			if (_primaryLayer)
			{
				_primaryLayer.removeEventListener(SynchronisedVariableChangeEvent.SYNCHRONISED_VARIABLE_DOMAIN_CHANGED, onSychronisedVariableChanged);
				_primaryLayer.removeEventListener(SynchronisedVariableChangeEvent.SYNCHRONISED_VARIABLE_CHANGED, onSychronisedVariableChanged);
			}
			if (container && container.interactiveLayerMap)
				_primaryLayer = container.interactiveLayerMap.primaryLayer;
			if (_primaryLayer)
			{
				_primaryLayer.addEventListener(SynchronisedVariableChangeEvent.SYNCHRONISED_VARIABLE_DOMAIN_CHANGED, onSychronisedVariableChanged);
				_primaryLayer.addEventListener(SynchronisedVariableChangeEvent.SYNCHRONISED_VARIABLE_CHANGED, onSychronisedVariableChanged);
				invalidateDynamicPart();
			}
		}

		private function onSychronisedVariableChanged(event: SynchronisedVariableChangeEvent): void
		{
//			var layer: InteractiveLayerMSBase = event.target as InteractiveLayerMSBase;
//			var synchronizedVariable: String = event.variableId;
			invalidateDynamicPart();
		}

		override public function invalidateDynamicPart(b_invalid: Boolean = true): void
		{
			super.invalidateDynamicPart(b_invalid);
			//clearOldState();
		}

		private function updateLayerLabel(text: String): void
		{
			var id: String = container.id;
//			_label.text = "["+id+"]"+text;
			_label.text = text;
			updateLabelStyles();
		}
		override public function draw(graphics: Graphics): void
		{
			super.draw(graphics);
			var dimensionLabelParser: DimensionLabelParser = new DimensionLabelParser();
			if (_synchronizator)
			{
				var labelText: String = dimensionLabelParser.parseLabel(_synchronizator.labelString, container.interactiveLayerMap);
				updateLayerLabel(labelText);
			}
			//we want to display info just from _synchronizedVariableName
//			if (_synchronizedVariableNames && _synchronizedVariableNames.length > 0 && _primaryLayer)
//			{
//				var _currValue: String = '';
//				
//				for each (var syncVarName: String in _synchronizedVariableNames)
//				{
//					var value: Object = _primaryLayer.getSynchronisedVariableValue(syncVarName);
//					if (value)
//					{
//						if (value is String)
//							_currValue += value as String;
//						else if (value is Date)
//							_currValue += ISO8601Parser.dateToString(value as Date);
//						else if (value is Object)
//							_currValue += value.label as String;
//					}
//				}
//				
//				updateLayerLabel(_currValue);
//				
//			} else {
//				trace("InteractiveLayerLabel synchro problem");
//			}
			//draw label
			var bkgColor: uint = 0x000000;
			
			var dataAvailable: Boolean = true;
			if (_primaryLayer) 
			{
				if (_primaryLayer.status == InteractiveDataLayer.STATE_NO_SYNCHRONISATION_DATA_AVAILABLE)	dataAvailable = false;
				if (!_primaryLayer.container.enabled) dataAvailable = false;
			}
			if (labelText == '') dataAvailable = false;
			
			if (!dataAvailable)
			{
				bkgColor = 0x880000;
				updateLayerLabel("No data");
			}
			
			var w: int = 100;
			var h: int = 25;
			var paddingHorizontal: int = 4;
			var paddingVertical: int = 3;
			if (_label)
			{
				w = _label.textWidth + 2 * paddingHorizontal;
				h = _label.textHeight + 2 * paddingVertical;
			}
			if (w < 10 || h < 10)
			{
				bkgColor = 0x880000;
			}
			if (_label)
			{
				_label.x = paddingHorizontal;
				_label.y = height - h + paddingVertical;
				_label.width = w;
				_label.height = h;
			}
			var gr: Graphics = graphics;
			gr.clear();
			gr.beginFill(0x000000);
			gr.drawRect(0, height - h, w, h);
			gr.endFill();
		}

		private function updateLabelStyles(): void
		{
			_label.multiline = false;
			_label.border = false;
			var tf: TextFormat = _label.getTextFormat();
			tf.color = 0xffffff;
			tf.align = TextFormatAlign.LEFT;
			_label.setTextFormat(tf);
		}
	}
}
