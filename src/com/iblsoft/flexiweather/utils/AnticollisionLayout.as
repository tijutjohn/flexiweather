package com.iblsoft.flexiweather.utils
{
	import com.iblsoft.flexiweather.constants.AnticollisionDisplacementMode;
	import com.iblsoft.flexiweather.ogc.FeatureBase;
	import com.iblsoft.flexiweather.ogc.kml.features.LineString;
	import com.iblsoft.flexiweather.ogc.kml.features.LinearRing;
	import com.iblsoft.flexiweather.ogc.kml.features.Placemark;
	import com.iblsoft.flexiweather.ogc.kml.features.Polygon;
	import com.iblsoft.flexiweather.ogc.wfs.IWFSFeatureWithAnnotation;
	import com.iblsoft.flexiweather.plugins.IConsole;
	import com.iblsoft.flexiweather.proj.Projection;
	import com.iblsoft.flexiweather.utils.geometry.ILineSegmentApproximableBounds;
	import com.iblsoft.flexiweather.utils.geometry.LineSegment;
	
	import flash.display.BitmapData;
	import flash.display.BlendMode;
	import flash.display.DisplayObject;
	import flash.display.Graphics;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.TimerEvent;
	import flash.geom.ColorTransform;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.utils.Timer;
	import flash.utils.getTimer;
	
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
		public static const ANTICOLLISTION_UPDATED: String = 'anticollisionUpdated';
		
		protected var m_boundaryRect: Rectangle;
		public var m_placementBitmap: BitmapData; // HACK: change back to protected

		protected var mi_lastUpdate: int = 0;
		protected var mb_dirty: Boolean = false;
		
		protected var ma_layoutObjects: ArrayCollection = new ArrayCollection();
		protected var m_anchorsLayer: Sprite = new Sprite();
		

		/**
		 * Set it to true when you want suspend anticaollision processing (e.g. user is dragging map) 
		 */		
		private var m_suspendAnticollisionProcessing: Boolean;
		private var m_drawAnnotationAnchor: Boolean;
		
		private var m_updateInterval: int = 500;
		
		public function AnticollisionLayout()
		{
			super();
			
			m_drawAnnotationAnchor = true;
			
			addEventListener(Event.RENDER, onRender, false, 0, true); 
			addChild(m_anchorsLayer);
		}
		
		public function destroy(): void
		{
			removeEventListener(Event.RENDER, onRender);
			removeChild(m_anchorsLayer);
			if (m_placementBitmap)
			{
				m_placementBitmap.dispose();
				m_placementBitmap = null;	
			}
			if (ma_layoutObjects && ma_layoutObjects.length > 0)
			{
				for each (var obj: Object in ma_layoutObjects)
				{
					trace(obj);
				}
			}
		}
		
		/**
		 * Adds externally managed DisplayObject which must not be displaced to the layout
		 * Basically this means that all other objects will be displaced so that they don't
		 * overlap with this one.
		 **/
		public function addObstacle(object: DisplayObject): void
		{
			setDirty();
			var lo: AnticollisionLayoutObject = new AnticollisionLayoutObject(object, false, AnticollisionDisplacementMode.DISPLACE_NOT_ALLOWED);
			lo.name = "Obstacle";
			ma_layoutObjects.addItem(lo);
		}

		/**
		 * Add a displaceble object to the layout. By default any displace is allowed
		 * and object is added as the child to the layout.
		 **/
		public function addObject(
				object: DisplayObject,
				a_anchors: Array = null,
				i_reflection: int = 0,
				i_displacementMode: String = AnticollisionDisplacementMode.DISPLACE_AUTOMATIC,
				b_addAsChild: Boolean = true): AnticollisionLayoutObject
		{
			setDirty();
			if(b_addAsChild)
				addChild(object);
			var lo: AnticollisionLayoutObject = new AnticollisionLayoutObject(object, b_addAsChild, i_displacementMode);
			
			lo.name = "Object"+i_reflection;
			
			lo.objectsToAnchor = a_anchors;
			lo.reflectionID = i_reflection;
			lo.manageVisibilityWithAnchors = a_anchors != null;
			ma_layoutObjects.addItem(lo);
			
			return lo;
		}
		
		public function removeObject(object: DisplayObject): Boolean
		{
			for(var i: int = 0; i < ma_layoutObjects.length; ++i) {
				var lo: AnticollisionLayoutObject = ma_layoutObjects[i]; 
				if(lo.object === object) {
					if(lo.managedChild)
					{
						if (lo.object && lo.object.parent == this)
							removeChild(lo.object);
					}
					ma_layoutObjects.removeItemAt(i);
					setDirty();
					return true;
				}
			}
			return false;
		}

		public function getObjectReferenceLocation(object: DisplayObject): Point
		{
			var lo: AnticollisionLayoutObject = getAnticollisionLayoutObjectFor(object);
			if(lo == null)
				return null;
			return lo.referenceLocation;
		}

		public function updateObjectReferenceLocationWithCustomPosition(object: DisplayObject, rlX: Number, rlY: Number): Boolean
		{
			
			var lo: AnticollisionLayoutObject = getAnticollisionLayoutObjectFor(object);
			
			if(lo == null)
				return false;
			if(lo.referenceLocation.x != rlX || lo.referenceLocation.y != rlY) 
			{ 
				setDirty();
				lo.referenceLocation = new Point(rlX, rlY);
			}
			
			return true;
		}
		public function updateObjectReferenceLocation(object: DisplayObject): Boolean
		{
			var lo: AnticollisionLayoutObject = getAnticollisionLayoutObjectFor(object);
			
			if(lo == null)
				return false;
			if(lo.referenceLocation.x != object.x || lo.referenceLocation.y != object.y) 
			{ 
				setDirty();
				lo.referenceLocation = new Point(object.x, object.y);
			}
			
			return true;
		}
		
		public function reset(): void
		{
			for each(var lo: AnticollisionLayoutObject in ma_layoutObjects) {
				removeChild(lo.object);
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
			var time: int = ProfilerUtils.startProfileTimer();
			
			if (!m_suspendAnticollisionProcessing)
			{
//				trace("Anti layout ma_layoutObjects: " + ma_layoutObjects.length);
				if (!m_boundaryRect)
					return;
				
				mb_dirty = false;
				mi_lastUpdate = getTimer();
	
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
				
				var lo: AnticollisionLayoutObject;
				var loAnchored: AnticollisionLayoutObject;
				var objectToAnchor: DisplayObject;
				
				// first pass - analyse current absolute visibility of objects
				for each(lo in ma_layoutObjects) {
					if(lo.manageVisibilityWithAnchors)
						lo.visible = true;
					else
						lo.visible = getAbsoluteVisibility(lo.object);
					
				}
				
				var b_change: Boolean = true;
				while(b_change) {
					b_change = false;
					for each(lo in ma_layoutObjects) {
						if(lo.objectsToAnchor != null && lo.objectsToAnchor.length > 0) {
							for each(objectToAnchor in lo.objectsToAnchor) {
								loAnchored = getAnticollisionLayoutObjectFor(objectToAnchor);
								if(loAnchored == null)
									continue;
								if(!loAnchored.visible) {
									if(lo.visible) {
										lo.visible = false;
										b_change = true;
									}
								}
							}
						}
					}
				} // while(b_change)
				
				// second pass - render nonmoveable objects
				for each(lo in ma_layoutObjects) {
					if(!lo.visible)
						continue;
					if(lo.displacementMode == AnticollisionDisplacementMode.DISPLACE_NOT_ALLOWED) {
						drawObjectPlacement(lo, 0, 0);
					}
				}
	
				// third pass - displace & render other object
				
				
				for each(lo in ma_layoutObjects) {
					if(!lo.visible)
						continue;
					if(lo.displacementMode == AnticollisionDisplacementMode.DISPLACE_AUTOMATIC || lo.displacementMode == AnticollisionDisplacementMode.DISPLACE_AUTOMATIC_SIMPLE|| lo.displacementMode == AnticollisionDisplacementMode.DISPLACE_HIDE) {
						if(lo.visible != lo.object.visible)
							lo.object.visible = lo.visible; 
						var f_dx: Number = 0;
						var f_dy: Number = 0;
						// get the bounds of object at it's reference (== original location)
						var bounds: Rectangle = lo.object.getBounds(null);
						
//						trace("\n\t update m_referenceLocation: " + lo.referenceLocation + " object: " + lo.object);
						
						bounds.x = lo.referenceLocation.x;
						bounds.y = lo.referenceLocation.y;
						var b_foundPlace: Boolean = false;
						
						// first try the reference point
						if(checkObjectPlacement(lo, bounds)) {
							b_foundPlace = true;
						}
						else {
							if (lo.displacementMode == AnticollisionDisplacementMode.DISPLACE_HIDE)
							{
								// do not continue if object has no placement and displacement mode is DISPLACE_HIDE
								lo.visible = false;
								lo.object.visible = false;
								continue;
							}
							// if not available, try the surrounding point
							var f_pi2: Number = 2 * Math.PI;
							
							if (lo.displacementMode == AnticollisionDisplacementMode.DISPLACE_AUTOMATIC)
							{
								trace("\n DISPLACE_AUTOMATIC");
								outterCycle:
								for(var i_displace: int = 1; i_displace < 20; ++i_displace) 
								{
									var i_angleSteps: uint = (i_displace / i_displace + 3) / 4 * 4;
									var f_angleStep: Number = f_pi2 / i_angleSteps;
									var i_disp10: int = i_displace * 10;
									for(var f_angle: Number = 0; f_angle < f_pi2; f_angle += f_angleStep) 
									{
										f_dx = int(Math.round(Math.cos(f_angle) * i_disp10));
										f_dy = int(Math.round(Math.sin(f_angle) * i_disp10));
										
//										trace("displace: ["+i_displace+"] angle: ["+f_angle+"] dx: " + f_dx + " dy: " + f_dy);
										var boundsDisplaced: Rectangle = new Rectangle(bounds.x + f_dx, bounds.y + f_dy, bounds.width, bounds.height);
										
										// quick check if resulting boundary is within the m_boundaryRect 
										if(checkObjectPlacement(lo, boundsDisplaced)) {
											b_foundPlace = true;
											break outterCycle;
										}
									}
								}
								trace("END OF DISPLACE_AUTOMATIC \n");
							} else if (lo.displacementMode == AnticollisionDisplacementMode.DISPLACE_AUTOMATIC_SIMPLE) {
								
								var dist: int = 100;
								var possiblePositions: Array = [new Point(dist,0), new Point(0,dist), new Point(0,-1*dist), new Point(-1*dist,0)]
									
								for each (var possiblePosition: Point in possiblePositions)
								{
									f_dx = possiblePosition.x;
									f_dy = possiblePosition.y;
									
									var boundsDisplacedSimple: Rectangle = new Rectangle(
										bounds.x + f_dx, bounds.y + f_dy, bounds.width, bounds.height);
									// quick check if resulting boundary is within the m_boundaryRect 
									if(checkObjectPlacement(lo, boundsDisplacedSimple)) {
										b_foundPlace = true;
										break;
									}
								}
							}
						}
						if(!b_foundPlace) {
							f_dx = f_dy = 0;
							lo.visible = false;
							lo.object.visible = false;
						}
						lo.object.x = lo.referenceLocation.x + f_dx;
						lo.object.y = lo.referenceLocation.y + f_dy;
//						trace("\t\t update set object pos: object: " + lo.object.x + " , " + lo.object.y);
						drawObjectPlacement(lo, f_dx, f_dy);
					}
				}
				
				// now we can assume that all objects are laid out
				
				// draw anchors between 
				var g: Graphics = m_anchorsLayer.graphics;
				
				trace("\n\nAnticollisionLayout");
				g.clear();
				for each(lo in ma_layoutObjects) {
					trace("\t lo: " + lo);
					if(lo.objectsToAnchor == null || lo.objectsToAnchor.length == 0)
						continue;
	
					if(lo.manageVisibilityWithAnchors)
						lo.object.visible = lo.visible;
	
					if(!lo.visible)
						continue;
	
					//if(lo.displacementMode != DISPLACE_AUTOMATIC)
					//	continue;
					for each(objectToAnchor in lo.objectsToAnchor) {
						loAnchored = getAnticollisionLayoutObjectForAnchor(objectToAnchor);
						
						trace("\t\t objectToAnchor: " + objectToAnchor + " loAnchored: " + loAnchored);
						if(loAnchored == null)
							continue;
						if(!loAnchored.visible)
							continue;
						var boundsFrom: Rectangle = lo.object.getBounds(this);
						var boundsTo: Rectangle = objectToAnchor.getBounds(this);
	
						trace("\t\t boundsFrom: " + boundsFrom + " boundsTo: " + boundsTo);
						if (boundsFrom.width < 10 && boundsFrom.height < 10)
						{
							//object is too small, do not do anticollision for it
							trace("object is too small, do not do anticollision for it");
							continue;
						}
						var a_boundingLineSegmentsFrom: Array = getLineSegmentApproximation(lo.object);
						
						//FIXME this have to work with reflections
						var a_boundingLineSegmentsTo: Array = getLineSegmentApproximation(objectToAnchor);
	
						//debug
//						drawApproximationFunction(g, a_boundingLineSegmentsFrom, 0xff0000, 3);
//						drawApproximationFunction(g, a_boundingLineSegmentsTo, 0x00ff00, 1);
						
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
						
						var clr: uint = lo.anchorColor;
						var anchorAlpha: Number = lo.anchorAlpha;
						if (objectToAnchor is IWFSFeatureWithAnnotation)
						{
							var annotation: AnnotationBox = (objectToAnchor as IWFSFeatureWithAnnotation).annotation;
							if (annotation)
								clr = annotation.color;
							anchorAlpha = 1;
						}
						
						//FIXME draw to correct reflection not to original object
						drawAnnotationAnchorFunction(g, lo.drawAnchorArrow,
								bestPointFrom.x, bestPointFrom.y,
								bestPointTo.x, bestPointTo.y, clr, anchorAlpha);
					}
				}
			}
			
//			debug("update time: " + ProfilerUtils.stopProfileTimer(time) + "ms   ma_layoutObjects items: " + ma_layoutObjects.length);
		}
		
		public function needsUpdate(): Boolean
		{
			return mb_dirty;
		}
		
		public function setDirty(): void
		{
			mb_dirty = true;
		}
		
		// helpers
		protected function getAbsoluteVisibility(object: DisplayObject): Boolean
		{
			if(object == null)
				return false;
			// check if at least part of object is within m_boundaryRect
			var bounds: Rectangle = object.getBounds(this);
			if(bounds.right < m_boundaryRect.left)
				return false;
			if(bounds.left > m_boundaryRect.right)
				return false;
			if(bounds.bottom < m_boundaryRect.top)
				return false;
			if(bounds.top > m_boundaryRect.bottom)
				return false;
			// analyse chain of visibility flags
			while(object != null) {
				if(!object.visible)
					return false;
				object = object.parent;
			}
			return true;
		}
		
		/**
		 * This is debug draw function
		 *  
		 * @param graphics
		 * @param approx
		 * @param clr
		 * @param thickness
		 * 
		 */		
		protected function drawApproximationFunction(graphics: Graphics, approx: Array, clr: int,thickness: int = 1): void
		{
			if (approx && approx.length > 0)
			{
				graphics.clear();
				graphics.lineStyle(thickness,clr);
				var cnt: int = 0;
				for each (var point: LineSegment in approx)
				{
					graphics.moveTo(point.x1, point.y1);
					graphics.lineTo(point.x2, point.y2);
					cnt++;
				}
			}
		}
		protected function drawAnnotationAnchorFunction(
				graphics: Graphics, b_drawArrow: Boolean,
				f_x1: Number, f_y1: Number, f_x2: Number, f_y2: Number, color: uint, alpha: Number): void
		{
			if (m_drawAnnotationAnchor)
			{
				var f_xc: Number = (f_x1 + f_x2) / 2;
				var f_yc: Number = (f_y1 + f_y2) / 2;
				
				graphics.lineStyle(2, color, alpha);
				graphics.moveTo(f_x1, f_y1);
				graphics.lineTo(f_x2, f_y2);
				
				//draw arrow
				var w: int = f_x1 - f_x2;
				var h: int = f_y1 - f_y2;
				var angle: Number = Math.atan2(h , w);
				var arrowSize: int = 10;
				
				var angle1: Number = (angle * 180 / Math.PI - 10) * Math.PI / 180;
				var angle2: Number = (angle * 180 / Math.PI + 10) * Math.PI / 180;
				var x1: int = f_x2 + arrowSize * Math.cos(angle1);
				var y1: int = f_y2 + arrowSize * Math.sin(angle1);
				var x2: int = f_x2 + arrowSize * Math.cos(angle2);
				var y2: int = f_y2 + arrowSize * Math.sin(angle2);
				
				graphics.beginFill(color, alpha);
				graphics.moveTo(f_x2, f_y2);
				graphics.lineTo(x1, y1);
				graphics.lineTo(x2, y2);
				graphics.lineTo(f_x2, f_y2);
				graphics.endFill();
			}
		}
		
		private function getLineSegmentApproximation(object: DisplayObject): Array
		{
			var lsab: ILineSegmentApproximableBounds = object as ILineSegmentApproximableBounds;
			var a: Array;
			if(lsab != null)
				a = lsab.getLineSegmentApproximationOfBounds();
			
			if (lsab == null || (lsab != null && a == null))
			{
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
		
		private function getAnticollisionLayoutObjectFor(object: DisplayObject): AnticollisionLayoutObject
		{
			for each(var lo: AnticollisionLayoutObject in ma_layoutObjects) {
				if(lo.object === object) {
					return lo;
				}
			}
			return null;
		}
		private function getAnticollisionLayoutObjectForAnchor(anchor: DisplayObject): AnticollisionLayoutObject
		{
			for each(var lo: AnticollisionLayoutObject in ma_layoutObjects) {
				if (lo.objectsToAnchor)
				{
					var arr: Array = lo.objectsToAnchor;
					for each (var obj: DisplayObject in arr)
					{
						if(obj === anchor) {
							return lo;
						}
					}
				}
			}
			return null;
		}

		private var m_makeRed: ColorTransform = new ColorTransform(1, 1, 1, 1, 255, -255, -255, 255);

		private function drawObjectPlacement(layoutObject: AnticollisionLayoutObject, f_dx: Number, f_dy: Number): void
		{
			var matrix: Matrix = new Matrix();
			matrix.translate(-m_boundaryRect.x, -m_boundaryRect.y);
			
			layoutObject.object.x = layoutObject.referenceLocation.x + f_dx;
			layoutObject.object.y = layoutObject.referenceLocation.y + f_dy;
			
			matrix.translate(layoutObject.object.x, layoutObject.object.y);
			if(layoutObject.object is UIComponent)
				UIComponent(layoutObject.object).validateNow();
			m_placementBitmap.draw(layoutObject.object, matrix, m_makeRed);
		}

		private function checkObjectPlacement(layoutObject: AnticollisionLayoutObject, bounds: Rectangle): Boolean
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
		
		protected function onRender(event: Event): void
		{
			if(mb_dirty) {
				if(getTimer() - mi_lastUpdate > m_updateInterval) {
					update();
				}
			}
		}
		
		public function get suspendAnticollisionProcessing():Boolean
		{ return m_suspendAnticollisionProcessing; }
		
		public function set suspendAnticollisionProcessing(value:Boolean):void
		{ 
			debug("suspendAnticollisionProcessing = " + value);
			m_suspendAnticollisionProcessing = value; 
			update();
		}


		public function get drawAnnotationAnchor():Boolean
		{
			return m_drawAnnotationAnchor;
		}

		public function set drawAnnotationAnchor(value:Boolean):void
		{
			m_drawAnnotationAnchor = value;
		}
		
		public function get updateInterval():int
		{
			return m_updateInterval;
		}
		
		public function set updateInterval(value:int):void
		{
			m_updateInterval = value;
		}
		
		/**
		 *  Debug functions
		 * 
		 */
		
		public static var debugConsole: IConsole;
		protected function debug(txt: String): void
		{
			if (debugConsole)
			{
				debugConsole.print("AnticollisionLayout: " + txt,'Info','AnticollisionLayout');
			}
		}




	}
}