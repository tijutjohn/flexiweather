package com.iblsoft.flexiweather.utils
{
	import com.iblsoft.flexiweather.utils.geometry.ILineSegmentApproximableBounds;
	import com.iblsoft.flexiweather.utils.geometry.LineSegment;
	
	import flash.display.BitmapData;
	import flash.display.BlendMode;
	import flash.display.DisplayObject;
	import flash.display.Graphics;
	import flash.display.Sprite;
	import flash.events.TimerEvent;
	import flash.geom.ColorTransform;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.utils.Timer;
	
	import mx.collections.ArrayCollection;
	import mx.core.UIComponent;

	/**
	 * Special helper class for layout of DisplayObject's so that they don't overlap.
	 * This can be for example used to lay out anchored annotation label around some objects.
	 *     
  	 * Collision resolution is performed using displacement of "objects" (DisplayObject's)
	 * for which this is allowed. Objects which cannot be displaced are called "obstacles" here.
	 * Collision is resolved by a partly bitmap algorithm (for obstacles).
	 * 
	 * Any object can be optionaly connected (anchored) to any other object in the layout.
	 * For used displaced DisplayObject's it's recommend the ILineApproximableBounds
	 * interface, which helps to put the anchor line nicely from edge-to-edge between objects.
	 * If object does not implement ILineApproximableBounds the it's assumed that the object
	 * is rectangle.
	 **/
	public class AnticollisionLayout extends Sprite
	{
		protected var m_boundaryRect: Rectangle;
		public var m_placementBitmap: BitmapData; // HACK: change back to protected
		protected var mb_dirty: Boolean = true;
		protected var m_updateTimer: Timer;
		
		protected var ma_layoutObjects: ArrayCollection = new ArrayCollection();
		protected var m_anchorsLayer: Sprite = new Sprite();
		
		public static const DISPLACE_NOT_ALLOWED: uint = 0;
		public static const DISPLACE_AUTOMATIC: uint = 1;

		public function AnticollisionLayout()
		{
			super();
			m_updateTimer = new Timer(0, 1);
			m_updateTimer.addEventListener(TimerEvent.TIMER_COMPLETE, onUpdateTimer, false, 0, true);
			m_updateTimer.stop();
			
			addChild(m_anchorsLayer);
		}
		
		/**
		 * Adds externally managed DisplayObject which must not be displaced to the layout
		 * Basically this means that all other objects will be displaced so that they don't
		 * overlap with this one.
		 **/
		public function addObstacle(object: DisplayObject): void
		{
			setDirty();
			var lo: LayoutObject = new LayoutObject(object, false, DISPLACE_NOT_ALLOWED);
			ma_layoutObjects.addItem(lo);
		}

		/**
		 * Add a displaceble object to the layout. By default any displace is allowed
		 * and object is added as the child to the layout.
		 **/
		public function addObject(
				object: DisplayObject,
				a_anchors: Array = null,
				i_displacementMode: uint = DISPLACE_AUTOMATIC,
				b_addAsChild: Boolean = true): void
		{
			setDirty();
			if(b_addAsChild)
				addChild(object);
			var lo: LayoutObject = new LayoutObject(object, b_addAsChild, i_displacementMode);
			lo.ma_objectsToAnchor = a_anchors;
			ma_layoutObjects.addItem(lo);
		}
		
		public function removeObject(object: DisplayObject): Boolean
		{
			for(var i: int = 0; i < ma_layoutObjects.length; ++i) {
				var lo: LayoutObject = ma_layoutObjects[i]; 
				if(lo.m_object === object) {
					if(lo.mb_managedChild)
						removeChild(lo.m_object);
					ma_layoutObjects.removeItemAt(i);
					setDirty();
					return true;
				}
			}
			return false;
		}

		public function getObjectReferenceLocation(object: DisplayObject): Point
		{
			var lo: LayoutObject = getLayoutObjectFor(object);
			if(lo == null)
				return null;
			return lo.m_referenceLocation;
		}

		public function updateObjectReferenceLocation(object: DisplayObject): Boolean
		{
			var lo: LayoutObject = getLayoutObjectFor(object);
			if(lo == null)
				return false;
			if(lo.m_referenceLocation.x != object.x
					|| lo.m_referenceLocation.y != object.y) { 
				setDirty();
				lo.m_referenceLocation = new Point(object.x, object.y);
			}
			return true;
		}
		
		public function reset(): void
		{
			for each(var lo: LayoutObject in ma_layoutObjects) {
				removeChild(lo.m_object);
			}
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
				if(!lo.m_object.visible)
					continue;
				if(lo.mi_displacementMode == DISPLACE_NOT_ALLOWED) {
					drawObjectPlacement(lo, 0, 0);
				}
			}
			// second pass
			for each(lo in ma_layoutObjects) {
				if(!lo.m_object.visible)
					continue;
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
			
			// now we can assume that all objects are laid out
			
			// draw anchors between 
			var g: Graphics = m_anchorsLayer.graphics;
			g.clear();
			for each(lo in ma_layoutObjects) {
				if(!lo.m_object.visible)
					continue;
				if(lo.ma_objectsToAnchor == null || lo.ma_objectsToAnchor.length == 0)
					continue;
				//if(lo.mi_displacementMode != DISPLACE_AUTOMATIC)
				//	continue;
				for each(var objectToAnchor: DisplayObject in lo.ma_objectsToAnchor) {
					var boundsFrom: Rectangle = lo.m_object.getBounds(this);
					var boundsTo: Rectangle = objectToAnchor.getBounds(this);

					var a_boundingLineSegmentsFrom: Array = getLineSegmentApproximation(lo.m_object);
					var a_boundingLineSegmentsTo: Array = getLineSegmentApproximation(objectToAnchor);

					var bestPointTo: Point = boundsTo.bottomRight;
					var bestPointFrom: Point = boundsFrom.topLeft;
					var f_bestDistance: Number = 123e45;
					
					for each(var lineSegmentFrom: LineSegment in a_boundingLineSegmentsFrom) {
						for each(var lineSegmentTo: LineSegment in a_boundingLineSegmentsTo) {
							// approach: overall 2 closest points
							/*
							var connection: LineSegment = lineSegmentFrom.shortestConnectionToLineSegment(lineSegmentTo);
							var f_distance: Number = connection.length;
							if(f_distance < f_bestDistance) {
								bestPointFrom = connection.startPoint; 
								bestPointTo = connection.endPoint;
								f_bestDistance = f_distance;
							}
							*/
							// approach: mid-points of 2 closest line segments
							var f_distance: Number = lineSegmentFrom.minimumDistanceToLineSegment(lineSegmentTo);
							if(f_distance < f_bestDistance) {
								bestPointFrom = lineSegmentFrom.midPoint; 
								bestPointTo = lineSegmentTo.midPoint;
								f_bestDistance = f_distance;
							}
						}
					}
					
					drawAnnotationAnchor(g,
							bestPointFrom.x, bestPointFrom.y,
							bestPointTo.x, bestPointTo.y);
				}
			}
		}
		
		public function needsUpdate(): Boolean
		{
			return !mb_dirty;
		}
		
		// helpers
		public static function drawAnnotationAnchor(
				graphics: Graphics,
				f_x1: Number, f_y1: Number, f_x2: Number, f_y2: Number): void
		{
			var f_xc: Number = (f_x1 + f_x2) / 2;
			var f_yc: Number = (f_y1 + f_y2) / 2;
			graphics.lineStyle(2, 0, 1);
			graphics.moveTo(f_x1, f_y1);
			graphics.lineTo(f_x2, f_y2);
		}
		
		private function getLineSegmentApproximation(object: DisplayObject): Array
		{
			var lsab: ILineSegmentApproximableBounds = object as ILineSegmentApproximableBounds;
			var a: Array;
			if(lsab != null)
				a = lsab.getLineSegmentApproximationOfBounds();
			else {
				a = [];
				var bounds: Rectangle = object.getBounds(this);
				a.push(new LineSegment(bounds.left, bounds.top, bounds.right, bounds.top));
				a.push(new LineSegment(bounds.right, bounds.top, bounds.right, bounds.bottom));
				a.push(new LineSegment(bounds.right, bounds.bottom, bounds.left, bounds.bottom));
				a.push(new LineSegment(bounds.left, bounds.bottom, bounds.left, bounds.top));
			}
			return a;
			/*
			var a_refined: Array = [];
			for each(var ls: LineSegment in a) {
				var ptM: Point = ls.midPoint;
				a_refined.push(new LineSegment(ls.x1, ls.y1, ptM.x, ptM.y));
				a_refined.push(new LineSegment(ptM.x, ptM.y, ls.x2, ls.y2));
			}
			return a_refined;
			*/
		}
		
		private function getLayoutObjectFor(object: DisplayObject): LayoutObject
		{
			for each(var lo: LayoutObject in ma_layoutObjects) {
				if(lo.m_object === object) {
					return lo;
				}
			}
			return null;
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
	internal var mb_managedChild: Boolean;
	internal var mi_displacementMode: uint;
	internal var m_referenceLocation: Point;
	internal var ma_objectsToAnchor: Array;
	
	function LayoutObject(
			object: DisplayObject,
			b_managedChild: Boolean,
			i_displacementMode: uint)
	{
		m_object = object;
		mb_managedChild = b_managedChild;
		mi_displacementMode = i_displacementMode;
		m_referenceLocation = new Point(object.x, object.y);
	}
}
