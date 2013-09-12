package com.iblsoft.flexiweather.ogc.editable
{
	import com.iblsoft.flexiweather.ogc.FeatureBase;
	import com.iblsoft.flexiweather.ogc.InteractiveLayerWFS;
	import com.iblsoft.flexiweather.ogc.Version;
	import com.iblsoft.flexiweather.ogc.wfs.WFSFeatureBase;
	import com.iblsoft.flexiweather.utils.ScreenUtils;
	import com.iblsoft.flexiweather.widgets.InteractiveWidget;
	
	import flash.display.DisplayObject;
	import flash.display.Sprite;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	
	import mx.collections.ArrayCollection;
	import mx.events.PropertyChangeEvent;
	import mx.events.PropertyChangeEventKind;

	[Event(name = "wfsEditableSelectionChange", type = "mx.events.PropertyChangeEvent")]
	public class InteractiveLayerWFSEditable extends InteractiveLayerWFS implements IHighlightableItemManager, ISelectableItemManager, IEditableItemManager
	{
		public static const SELECTION_CHANGE: String = "wfsEditableSelectionChange";
		protected var ma_items: ArrayCollection = new ArrayCollection();
		protected var m_highlightedItem: IHighlightableItem = null;
		protected var m_selectedItem: ISelectableItem = null;
		protected var m_mouseMoveCapturingItem: IMouseEditableItem = null;
		protected var ml_mouseMoveCapturingItemStack: Array = [];
		protected var m_mouseClickCapturingItem: IMouseEditableItem = null;
		protected var ml_mouseClickCapturingItemStack: Array = [];
		protected var m_editingComponentsContainer: Sprite = new Sprite;

		public function InteractiveLayerWFSEditable(
				container: InteractiveWidget = null,
				version: Version = null)
		{
			super(container, version);
			mouseChildren = true;
			// add a layer for any components which are realted to feature editing
			addChild(m_editingComponentsContainer);
		}

		// IEditableItemManager implementation
		public function addEditableItem(item: IEditableItem): void
		{
			ma_items.addItem(item);
			item.onRegisteredAsEditableItem(this);
		}

		public function removeEditableItem(item: IEditableItem): void
		{
			var i: int = ma_items.getItemIndex(item);
			if (i >= 0)
			{
				if (m_highlightedItem == item)
					m_highlightedItem = null;
				if (m_selectedItem == item)
					selectedItem = null;
				if (m_mouseMoveCapturingItem == item)
					m_mouseMoveCapturingItem = null;
				if (m_mouseClickCapturingItem == item)
					m_mouseClickCapturingItem = null;
				ma_items.removeItemAt(i);
				item.onUnregisteredAsEditableItem(this);
			}
		}

		public function setMouseMoveCapture(item: IMouseEditableItem): void
		{
			if (item == null)
				throw new Error("Cannot capture mouse moves for a null object");
			if (m_mouseMoveCapturingItem != null)
				ml_mouseMoveCapturingItemStack.push(m_mouseMoveCapturingItem);
			m_mouseMoveCapturingItem = item;
		}

		public function releaseMouseMoveCapture(item: IMouseEditableItem): void
		{
			if (m_mouseMoveCapturingItem != item)
				throw new Error("setMouseMoveCapture/releaseMouseMoveCapture called in invalid order");
			if (ml_mouseMoveCapturingItemStack.length)
				m_mouseMoveCapturingItem = ml_mouseMoveCapturingItemStack.pop();
			else
				m_mouseMoveCapturingItem = null;
		}

		public function setMouseClickCapture(item: IMouseEditableItem): void
		{
			if (item == null)
				throw new Error("Cannot capture mouse clicks for a null object");
			if (m_mouseClickCapturingItem != null)
				ml_mouseClickCapturingItemStack.push(m_mouseClickCapturingItem);
			m_mouseClickCapturingItem = item;
		}

		public function releaseMouseClickCapture(item: IMouseEditableItem): void
		{
			if (m_mouseClickCapturingItem != item)
			{
				while (ml_mouseClickCapturingItemStack.length)
				{
					ml_mouseClickCapturingItemStack.pop();
				}
				m_mouseClickCapturingItem = null;
				throw new Error("setMouseClickCapture/releaseMouseClickCapture called in invalid order");
			}
			if (ml_mouseClickCapturingItemStack.length)
				m_mouseClickCapturingItem = ml_mouseClickCapturingItemStack.pop();
			else
				m_mouseClickCapturingItem = null;
		}

		// IHighlightableEditableItemManager implementation
		public function highlightItem(hItem: IHighlightableItem): void
		{
			if (hItem != null && hItem.highlighted)
				return;
			if (m_highlightedItem != null && !m_highlightedItem.canReleaseHighlight())
				return;
			for each (var item: IEditableItem in ma_items)
			{
				var hi: IHighlightableItem = item as IHighlightableItem;
				if (hi == null)
					continue;
				if (hi != hItem)
					hi.highlighted = false;
			}
			if (hItem != null)
				hItem.highlighted = true;
			m_highlightedItem = hItem;
		}

		// ISelectableEditableItemManager implementation
		public function selectItem(sItem: ISelectableItem, mouseEvent: MouseEvent = null, dispatchChangeEvent: Boolean = true): void
		{
			if (sItem != null && sItem.selected)
				return;
			for each (var item: IEditableItem in ma_items)
			{
				var si: ISelectableItem = item as ISelectableItem;
				if (si == null)
					continue;
				if (si != sItem)
					si.selected = false;
			}
			if (sItem != null)
				sItem.selected = true;
			if (m_selectedItem != sItem)
			{
				var oldSItem: ISelectableItem = m_selectedItem;
				m_selectedItem = sItem;
				if (dispatchChangeEvent)
				{
					dispatchEvent(new PropertyChangeEvent(
							SELECTION_CHANGE, true, false,
							PropertyChangeEventKind.UPDATE, "selectedItem",
							oldSItem, m_selectedItem, this));
				}
			}
			// force update of labels layout
			container.labelLayout.update();
		}

		override protected function onFeatureAdded(feature: FeatureBase): void
		{
			super.onFeatureAdded(feature);
			var item: IEditableItem = feature as IEditableItem;
			if (item != null)
				addEditableItem(item);
		}

		override protected function onFeatureRemoved(feature: FeatureBase): void
		{
			super.onFeatureRemoved(feature);
			var item: IEditableItem = feature as IEditableItem;
			var oldSItem: ISelectableItem = item as ISelectableItem;
			if (item != null)
				removeEditableItem(item);
			
			//FW-76: this SELECTION_CHANGE event does not needs to be called, as it will be dispatched when selectedItem = null
			/*
			dispatchEvent(new PropertyChangeEvent(
					SELECTION_CHANGE, true, false,
					PropertyChangeEventKind.UPDATE, "selectedItem",
					oldSItem, null, this));
			*/
		}

		public function doHitTest(
				f_stageX: Number, f_stageY: Number,
				classFilter: Class = null,
				b_visibleOnly: Boolean = true): Array
		{
			var a: Array = [];
			for each (var item: IEditableItem in ma_items)
			{
				if (classFilter != null && !(item is classFilter))
					continue;
				if (b_visibleOnly)
				{
					var o: DisplayObject = item as DisplayObject;
					if (o != null && !ScreenUtils.isVisible(o))
						continue;
				}
				if(item.hitTestPoint(f_stageX, f_stageY, true))
					a.push(item);
			}
			a.sortOn("editPriority");
			return a;
		}

		override public function onMouseMove(event: MouseEvent): Boolean
		{
			if(event.ctrlKey || event.shiftKey)
				return false;
			if(m_mouseMoveCapturingItem != null)
				//if(m_mouseMoveCapturingItem.onMouseMove(new Point(event.localX, event.localY)))
				if(m_mouseMoveCapturingItem.onMouseMove(new Point(DisplayObject(event.currentTarget).mouseX, DisplayObject(event.currentTarget).mouseY), event)){
					event.updateAfterEvent();
					return true;
				}
			// highlighting
			var l_hitItems: Array = doHitTest(event.stageX, event.stageY, IHighlightableItem);
			for each(var hItem: IHighlightableItem in l_hitItems) {
				highlightItem(hItem);
				return true;
			}
			highlightItem(null);
			return false;
		}

		override public function onMouseClick(event: MouseEvent): Boolean
		{
			if(event.ctrlKey || event.shiftKey)
				return false;
			if(m_mouseClickCapturingItem != null)
				//if(m_mouseClickCapturingItem.onMouseClick(new Point(event.localX, event.localY)))
				if(m_mouseClickCapturingItem.onMouseClick(new Point(DisplayObject(event.currentTarget).mouseX, DisplayObject(event.currentTarget).mouseY), event))
				{
					return true;
				}
			if(m_highlightedItem != null) {
				var mItem: IMouseEditableItem = m_highlightedItem as IMouseEditableItem;
				if(mItem != null) {
					//if(mItem.onMouseClick(new Point(event.localX, event.localY)))
					if(mItem.onMouseClick(new Point(DisplayObject(event.currentTarget).mouseX, DisplayObject(event.currentTarget).mouseY), event))
					{
						return true;
					}
				}
			}
			
			// selecting
			var l_hitItems: Array = doHitTest(event.stageX, event.stageY, ISelectableItem);
			for each(var sItem: ISelectableItem in l_hitItems) {
				selectItem(sItem, event);
				return true;
			}
			
			return false;
		}

		override public function onMouseDoubleClick(event: MouseEvent): Boolean
		{
			if(event.ctrlKey || event.shiftKey)
				return false;
			if(m_mouseClickCapturingItem != null)
				//if(m_mouseClickCapturingItem.onMouseDoubleClick(new Point(event.localX, event.localY)))
				if(m_mouseClickCapturingItem.onMouseDoubleClick(new Point(DisplayObject(event.currentTarget).mouseX, DisplayObject(event.currentTarget).mouseY), event))
					return true;
			var l_hitItems: Array = doHitTest(event.stageX, event.stageY, IMouseEditableItem);
			for each(var mItem: IMouseEditableItem in l_hitItems) {
				//if(mItem.onMouseDoubleClick(new Point(event.localX, event.localY)))
				if(mItem.onMouseDoubleClick(new Point(DisplayObject(event.currentTarget).mouseX, DisplayObject(event.currentTarget).mouseY), event))
					return true;
			}
			return false;
		}

		override public function onMouseDown(event: MouseEvent): Boolean
		{
			if(event.ctrlKey || event.shiftKey)
				return false;
			if(m_mouseClickCapturingItem != null)
				//if(m_mouseClickCapturingItem.onMouseDown(new Point(event.localX, event.localY)))
				if(m_mouseClickCapturingItem.onMouseDown(new Point(DisplayObject(event.currentTarget).mouseX, DisplayObject(event.currentTarget).mouseY), event))
				{
					return true;
				}
			var l_hitItems: Array = doHitTest(event.stageX, event.stageY, IMouseEditableItem);
			var _selectedItemHitted: Boolean;
			
			for each(var mItem: IMouseEditableItem in l_hitItems) {
				//if(mItem.onMouseDown(new Point(event.localX, event.localY)))
				if (mItem == m_selectedItem)
				{
					_selectedItemHitted = true;
				}
				if(mItem.onMouseDown(new Point(DisplayObject(event.currentTarget).mouseX, DisplayObject(event.currentTarget).mouseY), event))
				{
					return true;
				}
			}

			if (!_selectedItemHitted)
				selectItem(null);
			
			return false;
		}

		override public function onMouseUp(event: MouseEvent): Boolean
		{
			if(event.ctrlKey || event.shiftKey)
				return false;
			if(m_mouseClickCapturingItem != null)
				if(m_mouseClickCapturingItem.onMouseUp(new Point(event.localX, event.localY), event))
					return true;
			var l_hitItems: Array = doHitTest(event.stageX, event.stageY, IMouseEditableItem);
			for each(var mItem: IMouseEditableItem in l_hitItems) {
				if(mItem.onMouseUp(new Point(event.localX, event.localY), event))
					return true;
			}
			return false;
		}

		// getters & setters
		[Bindable]
		public function get selectedItem(): ISelectableItem
		{
			return m_selectedItem;
		}

		public function set selectedItem(item: ISelectableItem): void
		{
			selectItem(item);
		}

		public function get editingComponentsContainer(): Sprite
		{
			return m_editingComponentsContainer;
		}
		
		override public function toString(): String
		{
			return "InteractiveLayerWFSEditable: " + name + ", " + id + " ";
		}
	}
}
