package com.iblsoft.flexiweather.widgets
{
	import com.iblsoft.flexiweather.ogc.BBox;
	import com.iblsoft.flexiweather.proj.Coord;
	import com.iblsoft.flexiweather.proj.Projection;
	
	import flash.display.Graphics;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.GesturePhase;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.events.TimerEvent;
	import flash.events.TransformGestureEvent;
	import flash.geom.Rectangle;
	import flash.ui.Multitouch;
	import flash.utils.Timer;
	
	public class InteractiveLayerZoom extends InteractiveLayer
	{
		public static const ZOOM: String = 'zoom';
		protected var mb_requireCtrlKey: Boolean = true;
		protected var m_areaZoomingRectangle: Rectangle;
		protected var m_wheelZoomTimer: Timer = new Timer(2500, 1);
		protected var mb_finalChangeOccuredAfterWheelZoom: Boolean = true;
		private var m_slideZoomSprite: Sprite;
		private var mi_slideZoomStartY: int = -1;
		private var mb_showSlideZoomingSprite: Boolean = false;
		private var m_previousGestureZoomMidPoint: Coord = null;
		private var m_delayBeforeLoad: int
		private var m_delayBeforeLoadChanged: Boolean;


		public function get minimimMapScale():Number
		{
			return _minimimMapScale;
		}

		public function set minimimMapScale(value:Number):void
		{
			_minimimMapScale = value;
		}

		override public function set enabled(value:Boolean):void
		{
			super.enabled = value;
		}
		/**
		 * Delay before load when user zoom in/out. Loading wait to do not halt server from loading data when user intensively zoon in/out.
		 * @return
		 *
		 */
		public function get delayBeforeLoad(): int
		{
			return m_delayBeforeLoad;
		}

		public function set delayBeforeLoad(value: int): void
		{
			m_delayBeforeLoad = value;
			m_delayBeforeLoadChanged = true;
			invalidateProperties();
		}

        protected function turnOnZoomSprite():void {
            mb_showSlideZoomingSprite = true;
        }

        protected function turnOffZoomSprite():void {
            mb_showSlideZoomingSprite = false;
        }

		public function InteractiveLayerZoom(container: InteractiveWidget = null)
		{
			super(container);
			_type = ZOOM;
			m_wheelZoomTimer.stop();
			m_wheelZoomTimer.addEventListener(TimerEvent.TIMER_COMPLETE, onMouseWheelTimer);
			waitForContainer();
		}

		override protected function commitProperties(): void
		{
			super.commitProperties();
			if (m_delayBeforeLoadChanged)
			{
				m_wheelZoomTimer.delay = m_delayBeforeLoad;
				m_delayBeforeLoadChanged = false;
			}
		}

		private function waitForContainer(): void
		{
			if (!container || !container.stage)
				callLater(waitForContainer)
			else
			{
				if (Multitouch.supportedGestures)
					container.stage.addEventListener(TransformGestureEvent.GESTURE_ZOOM, onGestureZoom);
			}
		}

		override protected function createChildren(): void
		{
			super.createChildren();
			createChildrenNoGesturesMode();
		}

		private function createChildrenNoGesturesMode(): void
		{
			m_slideZoomSprite = new Sprite();
			addChild(m_slideZoomSprite);
			m_slideZoomSprite.visible = mb_showSlideZoomingSprite;
		}

		override public function destroy(): void
		{
			if (m_slideZoomSprite && m_slideZoomSprite.parent == this)
				removeChild(m_slideZoomSprite);
		}

		override public function onMouseRollOver(event: MouseEvent): Boolean
		{
			if (container && container.stage)
			{
				container.stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
				container.stage.addEventListener(KeyboardEvent.KEY_UP, onKeyUp);
			}
			return true;
		}

		override public function onMouseRollOut(event: MouseEvent): Boolean
		{
			if (container && container.stage)
			{
				container.stage.removeEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
				container.stage.removeEventListener(KeyboardEvent.KEY_UP, onKeyUp);
			}
			return true;
		}

		private function onKeyDown(event: KeyboardEvent): void
		{
			if (!mb_showSlideZoomingSprite && event.ctrlKey)
			{
                turnOnZoomSprite();
				invalidateDisplayList();
			}
		}

		private function onKeyUp(event: KeyboardEvent): void
		{
			if (mb_showSlideZoomingSprite && !event.ctrlKey)
			{
				turnOffZoomSprite();
				invalidateDisplayList();
				//automatically after CtrlKey is Up, update data
				onMouseWheelTimer();
			}
		}

		override public function onMouseDown(event: MouseEvent): Boolean
		{
			if (!event.ctrlKey && mb_requireCtrlKey || event.shiftKey)
				return false;
			if (!event.buttonDown)
				return false;
			if (event.target == m_slideZoomSprite)
				mi_slideZoomStartY = event.localY;
			else
			{
				initializeRectangle(event.localX, event.localY);
			}
			return true;
		}

        protected function initializeRectangle(x:Number, y:Number):void {
            m_areaZoomingRectangle = new Rectangle(x, y, 0, 0);
            invalidateDynamicPart();
        }

		override public function onMouseUp(event: MouseEvent): Boolean
		{
			if (m_areaZoomingRectangle == null)
				return false;
			if (event.target == m_slideZoomSprite)
				mi_slideZoomStartY = -1;
			else
			{
				finalizeRectangle();
			}
			return true;
		}

        protected function finalizeRectangle():void {
            //create new rectangle from old one with correct left, top, right, bottom properties (it matters on direction of draggine when zoom rectange is created
            m_areaZoomingRectangle = new Rectangle(Math.min(m_areaZoomingRectangle.left, m_areaZoomingRectangle.right), Math.min(m_areaZoomingRectangle.top, m_areaZoomingRectangle.bottom), Math.abs(m_areaZoomingRectangle.left - m_areaZoomingRectangle.right), Math.abs(m_areaZoomingRectangle.top - m_areaZoomingRectangle.bottom));
            if ((m_areaZoomingRectangle.width) > 5 && (m_areaZoomingRectangle.height) > 5)
            {
                var r: Rectangle = container.getViewBBox().toRectangle();
                var w: Number = container.width;
                var h: Number = container.height;
                var bW: Number = r.width;
                var bH: Number = r.height;
                r.width = bW / w * m_areaZoomingRectangle.width;
                r.height = bH / h * m_areaZoomingRectangle.height;
                r.x = r.x + m_areaZoomingRectangle.x / w * bW;
                r.y = r.y + (h - m_areaZoomingRectangle.bottom) / h * bH;
                setViewBBoxFromRectangle(BBox.fromRectangle(r), true);
            }
            m_areaZoomingRectangle = null;
            invalidateDynamicPart();
        }

		override public function onMouseMove(event: MouseEvent): Boolean
		{
			if (event.target == m_slideZoomSprite)
			{
				if (!event.ctrlKey && mb_requireCtrlKey || event.shiftKey)
					return false;
				if (!event.buttonDown)
					return false;
				if (mi_slideZoomStartY > 0)
				{
					var diff: Number = (event.localY - mi_slideZoomStartY);
					doDeltaZoom(diff);
					mi_slideZoomStartY = event.localY;
				}
			}
			else
			{
				if (m_areaZoomingRectangle == null)
					return false;
				m_areaZoomingRectangle.width = event.localX - m_areaZoomingRectangle.x;
				m_areaZoomingRectangle.height = event.localY - m_areaZoomingRectangle.y;
				invalidateDynamicPart();
			}
			return true;
		}

		override public function onAreaChanged(b_finalChange: Boolean): void
		{
			if (b_finalChange)
			{
				// remember final area change
				mb_finalChangeOccuredAfterWheelZoom = true;
			}
			else
			{
				if (m_wheelZoomTimer.running)
				{
					// non-final area change occured while waiting for final change,
					// so just waiting timeout
					m_wheelZoomTimer.repeatCount = 1;
					m_wheelZoomTimer.reset();
					m_wheelZoomTimer.start();
				}
			}
		}

		override public function onMouseWheel(event: MouseEvent): Boolean
		{
			//if(!event.ctrlKey && mb_requireCtrlKey)
			//	return false;
			return doDeltaZoom(event.delta)
		}

		public function doDeltaZoom(delta: int): Boolean
		{
//			trace("doDeltaZoom: " + delta);
			var bbox: Rectangle = container.getViewBBox().toRectangle();
			var f_bboxCenterX: Number = bbox.x + bbox.width / 2.0;
			var f_bboxCenterY: Number = bbox.y + bbox.height / 2.0;
			var f_width: Number = bbox.width;
			var f_height: Number = bbox.height;
			var b_changed: Boolean = false;
			
			var deltaAbs: int = Math.abs(delta);
			if (deltaAbs > 25)
				deltaAbs = 25;
			
			//it can vary from 0.75 to 0.25
			var zoomChangeFromDelta: Number = 0.75 - 0.5* (deltaAbs / 25);
			
//			zoomChangeFromDelta = 0.75;
			if (zoomChangeFromDelta > 1) zoomChangeFromDelta = 1;
			if (zoomChangeFromDelta < 0.5) zoomChangeFromDelta = 0.5;
			
			trace("doDeltaZoom: " + delta + " zoomChangeFromDelta: " + zoomChangeFromDelta);
			if (delta > 0)
			{
				f_width *= zoomChangeFromDelta;
				f_height *= zoomChangeFromDelta;
				b_changed = true;
			}
			if (delta < 0)
			{
				f_width /= zoomChangeFromDelta;
				f_height /= zoomChangeFromDelta;
				b_changed = true;
			}
			if (b_changed)
			{
				m_wheelZoomTimer.repeatCount = 1;
				m_wheelZoomTimer.reset();
				m_wheelZoomTimer.start();
				// do only non-final area change
				var r: Rectangle = new Rectangle(f_bboxCenterX - f_width / 2.0, f_bboxCenterY - f_height / 2.0, f_width, f_height);
				var viewBBoxUpdated: Boolean = setViewBBoxFromRectangle(BBox.fromRectangle(r), false, delta < 0);
				if (viewBBoxUpdated)
				{
					invalidateDynamicPart();
					// but start timer to defer final zoom change, but only if final change
					// doesn't occur in between (initiated by someone else)
					mb_finalChangeOccuredAfterWheelZoom = false;
				} 
			}
			return true;
		}

		protected function onMouseWheelTimer(event: Event = null): void
		{
			if (!mb_finalChangeOccuredAfterWheelZoom)
			{
				// noone else commited a final area change, so let's do it
				if (container)
					setViewBBoxFromRectangle(container.getViewBBox(), true);
			}
		}

		private function onGestureZoom(event: TransformGestureEvent): void
		{
			if (!enabled)
				return;
			var b_finalChange: Boolean = event.phase == GesturePhase.END;
			if (event.phase == GesturePhase.BEGIN)
				m_previousGestureZoomMidPoint = null;
			var newViewBBox: Rectangle = container.getViewBBox().toRectangle();
			var oldViewBBox: Rectangle = container.getViewBBox().toRectangle();
			var f_pxWidth: Number = container.width;
			var f_pxHeight: Number = container.height;
			var f_viewWidth: Number = oldViewBBox.width;
			var f_viewHeight: Number = oldViewBBox.height;
			var f_aspectedScale: Number = (event.scaleX + event.scaleY) / 2;
			var newMidPoint: Coord = container.pointToCoord(event.localX, event.localY);
			if (!newMidPoint)
				return;
			// apply scaling of the view BBox
			newViewBBox.x = newMidPoint.x - (newMidPoint.x - oldViewBBox.x) / f_aspectedScale;
			newViewBBox.y = newMidPoint.y - (newMidPoint.y - oldViewBBox.y) / f_aspectedScale;
			if (m_previousGestureZoomMidPoint)
			{
				// apply panning
				newViewBBox.x -= newMidPoint.x - m_previousGestureZoomMidPoint.x;
				newViewBBox.y -= newMidPoint.y - m_previousGestureZoomMidPoint.y;
				m_previousGestureZoomMidPoint = null;
			}
			else
				m_previousGestureZoomMidPoint = newMidPoint;
			newViewBBox.width = oldViewBBox.width / f_aspectedScale;
			newViewBBox.height = oldViewBBox.height / f_aspectedScale;
			setViewBBoxFromRectangle(BBox.fromRectangle(newViewBBox), b_finalChange);
//			container.setViewBBox(BBox.fromRectangle(newViewBBox), b_finalChange);
			invalidateDynamicPart();
		}

		override public function draw(graphics: Graphics): void
		{
			super.draw(graphics);
			//draw zoom area on right side
			var gr: Graphics = m_slideZoomSprite.graphics;
			gr.clear()
			gr.beginFill(0, 0.35);
			gr.drawRoundRectComplex(width - 50, 20, 30, height - 40, 5, 5, 5, 5);
			gr.endFill();
			m_slideZoomSprite.visible = mb_showSlideZoomingSprite;
			if (m_areaZoomingRectangle != null)
			{
				graphics.beginFill(0, 0.5);
				graphics.lineStyle(1, 0xFFFFFF, 0.8);
				graphics.drawRect(m_areaZoomingRectangle.x, m_areaZoomingRectangle.y, m_areaZoomingRectangle.width, m_areaZoomingRectangle.height);
				graphics.endFill();
			}
		}

		private var _minimimMapScale: Number = 20000;
		
		/**
		 * One common function for setting viewBBox from Rectangle with check for projection which allows horizontal wrap to do not allow zoom outside extent.
		 * @param r
		 * @param b_finalChange
		 *
		 */
		private function setViewBBoxFromRectangle(viewBBox: BBox, b_finalChange: Boolean, bZoomOutAction: Boolean = false): Boolean
		{
			//check max distance of viewBBox
			var maxDistance: Number = viewBBox.getBBoxMaximumDistance(container.getCRS());
			var mapScale: Number = container.getMapScale();
			var mapScaleRatio: Number = 1 / mapScale;
			if (mapScaleRatio < minimimMapScale && !bZoomOutAction)
			{
				//do not support map scale more than 1:1
				trace("do not support map scale more than 1:"+_minimimMapScale + " mapScaleRatio: " + mapScaleRatio);
				return false;
			} else {
				trace("current map scale [min: "+minimimMapScale+"]: " + mapScale + " , " + (1/mapScale) + " bZoomOutAction: " + bZoomOutAction);
			}
			var extentBBox: BBox = container.getExtentBBox();
			var allowHorizontalWrap: Boolean = allowWrapHorizontally();
			if (!allowHorizontalWrap)
			{
				var scale: Number = 1;
				if (viewBBox.width > extentBBox.width)
				{
					scale = extentBBox.width / viewBBox.width
					viewBBox = viewBBox.scaled(scale, scale);
				}
				if (viewBBox.height > extentBBox.height)
				{
					scale = extentBBox.height / viewBBox.height;
					viewBBox = viewBBox.scaled(scale, scale);
				}
			}
			container.setViewBBox(viewBBox, b_finalChange);
			
			return true;
		}

		private function extentRatio(): Number
		{
			var projection: Projection = container.getCRSProjection();
			var viewBBox: BBox = container.getExtentBBox();
			var extentRatio: Number = 100 * viewBBox.width / projection.extentBBox.width;
			return extentRatio;
		}

		private function allowWrapHorizontally(): Boolean
		{
			var projection: Projection = container.getCRSProjection();
			var extentRatio: Number = extentRatio();
			var percentageTreshold: Number = 1;
			var withinTreshold: Boolean = Math.abs(100 - extentRatio) < percentageTreshold;
			return projection.wrapsHorizontally && withinTreshold;
		}

		// getters & setters
		[Bindable]
		public function get requireCtrlKey(): Boolean
		{
			return mb_requireCtrlKey;
		}

		public function set requireCtrlKey(b: Boolean): void
		{
			mb_requireCtrlKey = b;
		}

		public function set notRequireCtrlKey(b: Boolean): void
		{
			mb_requireCtrlKey = !b;
		}

		override public function toString(): String
		{
			return "InteractiveLayerZoom ";
		}
	}
}
