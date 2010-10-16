package com.iblsoft.flexiweather.utils
{
	import flash.display.BitmapData;
	import flash.display.BlendMode;
	import flash.display.DisplayObject;
	import flash.display.Sprite;
	import flash.events.TimerEvent;
	import flash.geom.ColorTransform;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.utils.Timer;
	
	import mx.collections.ArrayCollection;
	import mx.core.UIComponent;

	public class AnticollisionLayout extends Sprite
	{
		protected var m_boundaryRect: Rectangle;
		public var m_placementBitmap: BitmapData; // HACK: change back to protected
		protected var mb_dirty: Boolean = true;
		protected var m_updateTimer: Timer;
		
		protected var ma_layoutObjects: ArrayCollection = new ArrayCollection();
		
		public static const DISPLACE_NOT_ALLOWED: uint = 0;
		public static const DISPLACE_AUTOMATIC: uint = 1;

		public function AnticollisionLayout()
		{
			super();
			m_updateTimer = new Timer(0, 1);
			m_updateTimer.addEventListener(TimerEvent.TIMER_COMPLETE, onUpdateTimer, false, 0, true);
			m_updateTimer.stop();
		}
		
		public function addObject(object: DisplayObject, i_displacementMode: uint = DISPLACE_AUTOMATIC): void
		{
			setDirty();
			ma_layoutObjects.addItem(new LayoutObject(object, i_displacementMode));
		}
		
		public function removeObject(object: DisplayObject): Boolean
		{
			for(var i: int = 0; i < ma_layoutObjects.length; ++i) {
				if(ma_layoutObjects[i].m_object == object) {
					ma_layoutObjects.removeItemAt(i);
					setDirty();
					return true;
				}
			}
			return false;
		}

		public function getReferenceLocation(object: DisplayObject): Point
		{
			for each(var lo: LayoutObject in ma_layoutObjects) {
				if(lo.m_object == object)
					return lo.m_referenceLocation;
			}
			return null;
		}

		public function setReferenceLocation(object: DisplayObject, referenceLocation: Point): Boolean
		{
			for each(var lo: LayoutObject in ma_layoutObjects) {
				if(lo.m_object == object) {
					lo.m_referenceLocation = referenceLocation;
				}
			}
			return false;
		}

		public function reset(): void
		{
			ma_layoutObjects.removeAll();
			setDirty();
		}

		public function setBoundary(boundary: Rectangle): void
		{
			m_boundaryRect = new Rectangle(boundary.x, boundary.y, boundary.width, boundary.height);
			setDirty();
		}
		
		public function update(): void
		{
			mb_dirty = true;
			m_updateTimer.stop();

			var i_roundedWidth: uint = Math.round(m_boundaryRect.width + 0.9999999999);
			var i_roundedHeight: uint = Math.round(m_boundaryRect.height + 0.9999999999);

			// ensure we have a white 
			if(m_placementBitmap == null
					|| m_placementBitmap.width != i_roundedWidth
					|| m_placementBitmap.height != i_roundedHeight) {
				m_placementBitmap = new BitmapData(i_roundedWidth, i_roundedHeight, true, 0x00FFFFFF);
			}
			else {
				m_placementBitmap.fillRect(new Rectangle(0, 0, i_roundedWidth, i_roundedHeight), 0x00FFFFFF);
			}
			
			var lo: LayoutObject; 
			// first pass - render nonmoveable objects
			for each(lo in ma_layoutObjects) {
				if(lo.mi_displacementMode == DISPLACE_NOT_ALLOWED) {
					drawObjectPlacement(lo, 0, 0);
				}
			}
			// second pass
			for each(lo in ma_layoutObjects) {
				if(lo.mi_displacementMode == DISPLACE_AUTOMATIC) {
					var f_dx: Number = 0;
					var f_dy: Number = 0;
					// get the bounds of object at it's reference (== original location)
					var bounds: Rectangle = lo.m_object.getBounds(null);
					bounds.x = lo.m_referenceLocation.x;
					bounds.y = lo.m_referenceLocation.y;
					var b_foundPlace: Boolean = false;
					// first try the reference point
					if(checkObjectPlacement(lo, bounds)) {
						b_foundPlace = true;
					}
					else {
						// if not available, try the surrounding point
						var f_pi2: Number = 2 * Math.PI;
						outterCycle:
						for(var i_displace: int = 1; i_displace < 20; ++i_displace) {
							var i_angleSteps: uint = (i_displace / i_displace + 3) / 4 * 4;
							var f_angleStep: Number = f_pi2 / i_angleSteps;
							for(var f_angle: Number = 0; f_angle < f_pi2; f_angle += f_angleStep) {
								f_dx = int(Math.round(Math.cos(f_angle) * i_displace * 10));
								f_dy = int(Math.round(Math.sin(f_angle) * i_displace * 10));
								var boundsDisplaced: Rectangle = new Rectangle(
										bounds.x + f_dx, bounds.y + f_dy, bounds.width, bounds.height);
								// quick check if resulting boundary is within the m_boundaryRect 
								if(checkObjectPlacement(lo, boundsDisplaced)) {
									b_foundPlace = true;
									break outterCycle;
								}
							}
						}
					}
					if(!b_foundPlace) {
						f_dx = f_dy = 0;
					}
					lo.m_object.x = lo.m_referenceLocation.x + f_dx;
					lo.m_object.y = lo.m_referenceLocation.y + f_dy;
					drawObjectPlacement(lo, f_dx, f_dy);
				}
			}
		}
		
		public function needsUpdate(): Boolean
		{
			return !mb_dirty;
		}
		
		private var m_makeRed: ColorTransform = new ColorTransform(1, 1, 1, 1, 255, -255, -255, 255);

		private function drawObjectPlacement(layoutObject: LayoutObject, f_dx: Number, f_dy: Number): void
		{
			var matrix: Matrix = new Matrix();
			matrix.translate(-m_boundaryRect.x, -m_boundaryRect.y);
			layoutObject.m_object.x = layoutObject.m_referenceLocation.x + f_dx;
			layoutObject.m_object.y = layoutObject.m_referenceLocation.y + f_dy;
			matrix.translate(layoutObject.m_object.x, layoutObject.m_object.y);
			if(layoutObject.m_object is UIComponent)
				UIComponent(layoutObject.m_object).validateNow();
			m_placementBitmap.draw(layoutObject.m_object, matrix, m_makeRed);
		}

		private function checkObjectPlacement(layoutObject: LayoutObject, bounds: Rectangle): Boolean
		{
			if(bounds.left < m_boundaryRect.left)
				return false;
			if(bounds.right > m_boundaryRect.right)
				return false;
			if(bounds.top < m_boundaryRect.top)
				return false;
			if(bounds.bottom > m_boundaryRect.bottom)
				return false;
			var boundsInPlacementBitmap: Rectangle = new Rectangle();
			boundsInPlacementBitmap.x = bounds.x - m_boundaryRect.x;
			boundsInPlacementBitmap.y = bounds.y - m_boundaryRect.y;
			boundsInPlacementBitmap.width = bounds.width;
			boundsInPlacementBitmap.height = bounds.height;
			//var i_pixel: uint = m_placementBitmap.getPixel32(boundsInPlacementBitmap.x, boundsInPlacementBitmap.y);
			var b_hit: Boolean = m_placementBitmap.hitTest(new Point(0, 0), 0x01, boundsInPlacementBitmap);
			return !b_hit;
		}
		
		protected function setDirty(): void
		{
			mb_dirty = false;
			m_updateTimer.reset();
			m_updateTimer.start();
		}
		
		protected function onUpdateTimer(event: TimerEvent): void
		{
			if(!mb_dirty)
				update();
		}
	}
}

import flash.display.DisplayObject;
import flash.geom.Point;

class LayoutObject
{
	internal var m_object: DisplayObject;
	internal var mi_displacementMode: uint;
	internal var m_referenceLocation: Point;
	
	function LayoutObject(object: DisplayObject, i_displacementMode: uint)
	{
		m_object = object;
		mi_displacementMode = i_displacementMode;
		m_referenceLocation = new Point(object.x, object.y);
	}
}

import flash.display.BitmapData;
import flash.display.BlendMode;
import flash.display.DisplayObject;
import flash.display.DisplayObjectContainer;
import flash.geom.Matrix;
import flash.geom.ColorTransform;
import flash.geom.Rectangle;

class CollisionDetection
{
	public static function checkForCollision(firstObj: DisplayObject, secondObj: DisplayObject): Rectangle
	{
		var bounds1: Object = firstObj.getBounds(firstObj.root);
		var bounds2: Object = secondObj.getBounds(secondObj.root);
		
		if(((bounds1.right < bounds2.left)
				|| (bounds2.right < bounds1.left))
				|| ((bounds1.bottom < bounds2.top)
				|| (bounds2.bottom < bounds1.top)))
			return null;
		
		var bounds: Object = {};
		bounds.left = Math.max(bounds1.left, bounds2.left);
		bounds.right= Math.min(bounds1.right, bounds2.right);
		bounds.top = Math.max(bounds1.top, bounds2.top);
		bounds.bottom = Math.min(bounds1.bottom, bounds2.bottom);
		
		var w: Number = bounds.right-bounds.left;
		var h: Number = bounds.bottom-bounds.top;
		
		if(w < 1 || h < 1)
			return null;
		
		var bitmapData: BitmapData = new BitmapData(w, h, false);
		var matrix: Matrix = firstObj.transform.concatenatedMatrix;
		matrix.tx -= bounds.left;
		matrix.ty -= bounds.top;
		bitmapData.draw(firstObj, matrix, new ColorTransform(1, 1, 1, 1, 255, -255, -255, 255));
		
		matrix = secondObj.transform.concatenatedMatrix;
		matrix.tx -= bounds.left;
		matrix.ty -= bounds.top;
		bitmapData.draw(secondObj, matrix, new ColorTransform(1, 1, 1, 1, 255, 255, 255, 255), BlendMode.DIFFERENCE);
		
		var intersection: Rectangle = bitmapData.getColorBoundsRect(0xFFFFFFFF, 0xFF00FFFF);
		
		if(intersection.width == 0) 
			return null;
		
		intersection.x += bounds.left;
		intersection.y += bounds.top;
		
		return intersection;
	}
}
