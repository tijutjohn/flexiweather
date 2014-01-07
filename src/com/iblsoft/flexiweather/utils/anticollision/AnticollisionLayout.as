package com.iblsoft.flexiweather.utils.anticollision
{
	import com.iblsoft.flexiweather.constants.AnticollisionDisplayMode;
	import com.iblsoft.flexiweather.ogc.BBox;
	import com.iblsoft.flexiweather.ogc.FeatureBase;
	import com.iblsoft.flexiweather.ogc.kml.controls.KMLLabel;
	import com.iblsoft.flexiweather.ogc.kml.controls.KMLSprite;
	import com.iblsoft.flexiweather.ogc.kml.features.KMLFeature;
	import com.iblsoft.flexiweather.ogc.kml.features.LineString;
	import com.iblsoft.flexiweather.ogc.kml.features.LinearRing;
	import com.iblsoft.flexiweather.ogc.kml.features.Placemark;
	import com.iblsoft.flexiweather.ogc.kml.features.Polygon;
	import com.iblsoft.flexiweather.ogc.wfs.IWFSFeatureWithAnnotation;
	import com.iblsoft.flexiweather.plugins.IConsole;
	import com.iblsoft.flexiweather.proj.Projection;
	import com.iblsoft.flexiweather.utils.AnnotationBox;
	import com.iblsoft.flexiweather.utils.ProfilerUtils;
	import com.iblsoft.flexiweather.utils.geometry.ILineSegmentApproximableBounds;
	import com.iblsoft.flexiweather.utils.geometry.LineSegment;
	import com.iblsoft.flexiweather.widgets.InteractiveLayer;
	import com.iblsoft.flexiweather.widgets.InteractiveWidget;
	
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
	import mx.utils.object_proxy;

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
		public static var drawDebugMap: Boolean = false;
		/**
		 * Debug variable to test how many objects needs to be layouted
		 */
		public var layoutObjectsLength: int;
		protected var m_boundaryRect: Rectangle;
		public var m_placementBitmap: BitmapData; // HACK: change back to protected
		protected var mi_lastUpdate: int = 0;
		protected var mb_dirty: Boolean = false;
		protected var ma_layoutObjects: Array = new Array();
		protected var ma_currentLayoutObjects: Array = new Array();
		protected var m_anchorsLayer: Sprite = new Sprite();
		/**
		 * Set it to true when you want suspend anticaollision processing (e.g. user is dragging map)
		 */
		private var m_suspendAnticollisionProcessing: Boolean;
		private var m_drawAnnotationAnchor: Boolean;
		private var m_updateInterval: int = 500;
		private var m_areaChangedUpdateTime: Number;
		private var _layoutName: String;
		private var _updateLocationDictionary: UpdateLocationDictionary;

		public function get layoutObjects(): Array
		{
			return ma_layoutObjects;
		}
		
		override public function set visible(value:Boolean):void
		{
			if (!m_suspendAnticollisionProcessing)
			{
				if (super.visible != value)
				{
					super.visible = value;
					trace(this + " visible = " + value);
					onVisibilityChanged();
				}
			}
		}
		
		private var _parentContainer: InteractiveWidget;
		
		public static var uid: int = 0;
		public var id: int;
		
		public function AnticollisionLayout(layoutName: String, parent: DisplayObject)
		{
			id = uid++;
			super();
		
			_parentContainer = parent as InteractiveWidget;
			if (parent && parent is InteractiveWidget)
			{
				if (!(parent as InteractiveWidget).usedForIcon)
				{
					//trace("new AnticollisionLayout is created");
				}
			}
			_layoutName = layoutName;
			_updateLocationDictionary = new UpdateLocationDictionary(this);
			m_drawAnnotationAnchor = true;
			addEventListener(Event.RENDER, onRender, false, 0, true);
			addChild(m_anchorsLayer);
			m_areaChangedUpdateTime = getTimer();
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
		}
		
		private function onVisibilityChanged(): void
		{
			var currObjects: Array = ma_layoutObjects;
			var lo: AnticollisionLayoutObject;
			for each (lo in currObjects)
			{
				lo.visible = visible;
			}
		}
		
		private var _areaChangedScheduled: Boolean;
		private var _areaChangedScheduledBBox: BBox;

		/**
		 * Visible area is changed. This function needs to be called when viewBBox is changed for increasing AnticollisionLayout performance.
		 * @param bbox
		 *
		 */
		public function areaChanged(bbox: BBox): void
		{
		/*
		var diffTime: Number = (getTimer() - m_areaChangedUpdateTime);
		if (diffTime > 3000 && !suspendAnticollisionProcessing)
		{

			var time: int = ProfilerUtils.startProfileTimer();

			ma_currentLayoutObjects = [];

			//we are working with screen position, which much faster then checking coords convert them CRS: 84 (if needed) and check if it is inside BBox
			for each (var obj: AnticollisionLayoutObject in ma_layoutObjects)
			{
				var object: DisplayObject = obj.object;

//					if (!object.visible)
//						continue;

				if (object.x < 0 || object.y < 0)
				{
					object.visible = false;
					continue;
				}

				if (object.x > 1000 || object.y > 600)
				{
					object.visible = false;
					continue;
				}


				object.visible = true;
				ma_currentLayoutObjects.push(obj);
			}

			m_areaChangedUpdateTime = getTimer();

			_areaChangedScheduled = false;

		} else {
			_areaChangedScheduledBBox = bbox;
			_areaChangedScheduled = true;
		}
		*/
		}

		/**
		 * Adds externally managed DisplayObject which must not be displaced to the layout
		 * Basically this means that all other objects will be displaced so that they don't
		 * overlap with this one.
		 **/
		public function addObstacle(object: DisplayObject, parentLayer: InteractiveLayer): void
		{
			setDirty();
			var lo: AnticollisionLayoutObject = new AnticollisionLayoutObject(object, parentLayer, false, AnticollisionDisplayMode.FIXED);
			lo.name = "Obstacle";
			ma_layoutObjects.push(lo);
			updateLayoutObjectsLength();
		}

		/**
		 * This is just debug function
		 * @param object
		 * @return
		 *
		 */
		public function isObjectInside(object: DisplayObject): Boolean
		{
			for each (var lo: AnticollisionLayoutObject in ma_layoutObjects)
			{
				if (lo.object == object)
					return true;
			}
			return false;
		}

		public function setObjectVisibility(object: DisplayObject, visible: Boolean): void
		{
			for each (var lo: AnticollisionLayoutObject in ma_layoutObjects)
			{
				if (lo.object == object)
				{
					lo.visible = visible;
					lo.object.visible = visible;
					return;
				}
			}
		}
		/**
		 * Add a displaceble object to the layout. By default any displace is allowed
		 * and object is added as the child to the layout.
		 **/
		public function addObject(object: DisplayObject, parentLayer: InteractiveLayer, a_anchors: Array = null, i_reflection: int = 0, i_displacementMode: String = AnticollisionDisplayMode.DISPLACE_AROUND, b_addAsChild: Boolean = true): AnticollisionLayoutObject
		{
			trace(this + " addObject to this layout");
			setDirty();
			if (b_addAsChild)
				addChild(object);
			var lo: AnticollisionLayoutObject = new AnticollisionLayoutObject(object, parentLayer, b_addAsChild, i_displacementMode);
			lo.name = "Object" + i_reflection;
			lo.objectsToAnchor = a_anchors;
			lo.reflectionID = i_reflection;
			lo.manageVisibilityWithAnchors = (a_anchors != null && a_anchors.length > 0);
			ma_layoutObjects.push(lo);
			updateLayoutObjectsLength();
			var objName: String = '';
			var instanceName: String = '';
			if (object is KMLLabel)
			{
				objName = (object as KMLLabel).text;
				instanceName = (object as KMLLabel).name;
			}
			if (object is IAnticollisionLayoutObject)
				(object as IAnticollisionLayoutObject).anticollisionLayoutObject = lo;
			return lo;
		}

		private function updateLayoutObjectsLength(): void
		{
			if (ma_layoutObjects)
				layoutObjectsLength = ma_layoutObjects.length;
			else
				layoutObjectsLength = 0;
		}

		public function removeObject(object: DisplayObject): Boolean
		{
			if (object is IAnticollisionLayoutObject)
				(object as IAnticollisionLayoutObject).anticollisionLayoutObject = null;
			for (var i: int = 0; i < ma_layoutObjects.length; ++i)
			{
				var lo: AnticollisionLayoutObject = ma_layoutObjects[i];
				if (lo.object === object)
				{
					if (lo.managedChild)
					{
						if (lo.object && lo.object.parent == this)
							removeChild(lo.object);
					}
					ma_layoutObjects.splice(i, 1);
					updateLayoutObjectsLength();
					setDirty();
					return true;
				}
			}
			return false;
		}

		public function getObjectReferenceLocation(object: IAnticollisionLayoutObject): Point
		{
			var lo: AnticollisionLayoutObject = getAnticollisionLayoutObjectFor(object);
			if (lo == null)
				return null;
			return lo.referenceLocation;
		}
		
		public function moveObjectIntoAnticollisionLayout(layout: AnticollisionLayout): void
		{
			if (layout)
			{
				var lo: AnticollisionLayoutObject;
				var i: int;
				for (i = 0; i < ma_layoutObjects.length; i++)
				{
					lo = ma_layoutObjects[i];
					if (lo.name == "Obstacle")
					{
						layout.addObstacle(lo.object, lo.layer);
					} else {
						layout.addObject(lo.object, lo.layer, lo.objectsToAnchor, lo.reflectionID, lo.displacementMode, lo.managedChild);
					}
					
				}
				ma_layoutObjects.splice(0, ma_layoutObjects.length);
				//trace("ma_layoutObjects: " + ma_layoutObjects.length);
				setDirty();
				updateLayoutObjectsLength();
			}
		}

		public function reset(): void
		{
			for each (var lo: AnticollisionLayoutObject in ma_layoutObjects)
			{
				removeChild(lo.object);
			}
			ma_layoutObjects = [];
			setDirty();
			updateLayoutObjectsLength();
		}

		public function setBoundary(boundary: Rectangle): void
		{
			m_boundaryRect = new Rectangle(boundary.x, boundary.y, boundary.width, boundary.height);
			setDirty();
		}
		private var _updateLocked: Boolean;

		public function update(): void
		{
			if (!m_suspendAnticollisionProcessing && !_updateLocked)
			{
				trace(this + " UPDATE");
				var time: int = ProfilerUtils.startProfileTimer();
				var pass: int = 0;
				var diffTime: Number = getTimer() - mi_lastUpdate;
				if (diffTime < 500)
					return;
				//if (ma_layoutObjects.length > 0)
				//	trace("\n ACL update");
				var currObjects: Array = ma_layoutObjects;
//				var currObjects: Array = ma_currentLayoutObjects;
				if (!m_boundaryRect)
					return;
				_updateLocked = true;
				mb_dirty = false;
				mi_lastUpdate = getTimer();
				var i_roundedWidth: uint = Math.round(m_boundaryRect.width + 0.9999999999);
				var i_roundedHeight: uint = Math.round(m_boundaryRect.height + 0.9999999999);
				// ensure we have a white 
				if (m_placementBitmap == null || m_placementBitmap.width != i_roundedWidth || m_placementBitmap.height != i_roundedHeight)
					m_placementBitmap = new BitmapData(i_roundedWidth, i_roundedHeight, true, 0x00FFFFFF);
				else
					m_placementBitmap.fillRect(new Rectangle(0, 0, i_roundedWidth, i_roundedHeight), 0x00FFFFFF);
				var lo: AnticollisionLayoutObject;
				var loAnchored: AnticollisionLayoutObject;
				var objectToAnchor: DisplayObject;
				var currTime: int;
				// first pass - analyse current absolute visibility of objects
				currTime = ProfilerUtils.startProfileTimer();
				for each (lo in currObjects)
				{
					pass++;
					if (lo.manageVisibilityWithAnchors) 
					{
						var newVisibility: Boolean;
						if (lo.objectsToAnchor.length > 0)
						{
							newVisibility = (lo.objectsToAnchor[0] as DisplayObject).visible;
						}
						
						if (lo.layer)
						{
							newVisibility = newVisibility && lo.layer.visible;
						}
						lo.visible = newVisibility;
					} else {
						var objectAbsoluteVisibility: Boolean = getAbsoluteVisibility(lo.object);
	//						trace("ACL obj: " +  lo.object + " absolute visibility: " + objectAbsoluteVisibility);
						if (lo.layer && objectAbsoluteVisibility)
						{
							objectAbsoluteVisibility = lo.layer.visible;
						}
						lo.visible = objectAbsoluteVisibility;
					}
				}
//				currTime = ProfilerUtils.startProfileTimer();
				var b_change: Boolean = true;
				while (b_change)
				{
					b_change = false;
					for each (lo in currObjects)
					{
						pass++;
						if (lo.objectsToAnchor != null && lo.objectsToAnchor.length > 0)
						{
							for each (objectToAnchor in lo.objectsToAnchor)
							{
								pass++;
								loAnchored = getAnticollisionLayoutObjectFor(objectToAnchor as IAnticollisionLayoutObject);
								if (loAnchored == null)
									continue;
								if (!loAnchored.visible)
								{
									if (lo.visible)
									{
										lo.visible = false;
										b_change = true;
									}
								} else if (loAnchored.visible)
								{
									if (!lo.visible)
									{
										lo.visible = true;
										b_change = true;
									}
								}
							}
						}
					}
				} // while(b_change)
//				currTime = ProfilerUtils.startProfileTimer();
				// second pass - render nonmoveable objects
				for each (lo in currObjects)
				{
					pass++;
					if (!lo.visible)
						continue;
					if (lo.displacementMode == AnticollisionDisplayMode.FIXED)
						drawObjectPlacement(lo, 0, 0);
				}
//				currTime = ProfilerUtils.startProfileTimer();
				// third pass - displace & render other object
				for each (lo in currObjects)
				{
					pass++;
					if (!lo.visible)
						continue;
					if (lo.displacementMode == AnticollisionDisplayMode.DISPLACE_AROUND || lo.displacementMode == AnticollisionDisplayMode.HIDE_IF_OCCUPIED)
					{
						if (lo.visible != lo.object.visible)
							lo.object.visible = lo.visible;
						var f_dx: Number = 0;
						var f_dy: Number = 0;
						// get the bounds of object at it's reference (== original location)
						var bounds: Rectangle = lo.object.getBounds(null);
						var loRefx: Number = lo.referenceLocation.x;
						var loRefy: Number = lo.referenceLocation.y;
						if (loRefx == 0 && loRefy == 0)
							continue;
						bounds.x = loRefx;
						bounds.y = loRefy;
						var b_foundPlace: Boolean = false;
						// first try the reference point
						if (checkObjectPlacement(lo, bounds))
							b_foundPlace = true;
						else
						{
							if (lo.displacementMode == AnticollisionDisplayMode.HIDE_IF_OCCUPIED)
							{
								// do not continue if object has no placement and displacement mode is DISPLACE_HIDE
								lo.visible = false;
								lo.object.visible = false;
								continue;
							}
							// if not available, try the surrounding point
							var f_pi2: Number = 2 * Math.PI;
							if (lo.displacementMode == AnticollisionDisplayMode.DISPLACE_AROUND)
							{
								var outterCycle: int = ProfilerUtils.startProfileTimer();
								outterCycle: for (var i_displace: int = 1; i_displace < 20; ++i_displace)
								{
									pass++;
									var i_angleSteps: Number = (i_displace / i_displace + 3) / 4 * 4;
									var i_angleSteps2: Number = (i_displace / (i_displace + 3)) / 4 * 4;
									var f_angleStep: Number = f_pi2 / i_angleSteps;
									var f_angleStep2: Number = f_pi2 / i_angleSteps2;
									var i_disp10: int = i_displace * 10;
									var innerCycle: int = ProfilerUtils.startProfileTimer();
									for (var f_angle: Number = 0; f_angle < f_pi2; f_angle += f_angleStep)
									{
										pass++;
										f_dx = int(Math.round(Math.cos(f_angle) * i_disp10));
										f_dy = int(Math.round(Math.sin(f_angle) * i_disp10));
										var boundsDisplaced: Rectangle = new Rectangle(bounds.x + f_dx, bounds.y + f_dy, bounds.width, bounds.height);
										// quick check if resulting boundary is within the m_boundaryRect 
										if (checkObjectPlacement(lo, boundsDisplaced))
										{
											b_foundPlace = true;
											break outterCycle;
										}
									}
								}
								/*
										} else if (lo.displacementMode == AnticollisionDisplayMode.DISPLACE_AUTOMATIC_SIMPLE) {

											var dist: int = 100;
											var possiblePositions: Array = [new Point(dist,0), new Point(0,dist), new Point(0,-1*dist), new Point(-1*dist,0)]

											for each (var possiblePosition: Point in possiblePositions)
											{
												pass++;
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
								*/
							}
						}
						if (!b_foundPlace)
						{
							f_dx = f_dy = 0;
							lo.visible = false;
							lo.object.visible = false;
						}
						lo.object.x = lo.referenceLocation.x + f_dx;
						lo.object.y = lo.referenceLocation.y + f_dy;
						drawObjectPlacement(lo, f_dx, f_dy);
					}
				}
				currTime = ProfilerUtils.startProfileTimer();
				// now we can assume that all objects are laid out
				// draw anchors between 
				var g: Graphics = m_anchorsLayer.graphics;
				g.clear();
				for each (lo in currObjects)
				{
					pass++;
					if (lo.objectsToAnchor == null || lo.objectsToAnchor.length == 0)
						continue;
					if (lo.manageVisibilityWithAnchors)
						lo.object.visible = lo.visible;
					if (!lo.visible)
						continue;
					//if(lo.displacementMode != DISPLACE_AUTOMATIC)
					//	continue;
					for each (objectToAnchor in lo.objectsToAnchor)
					{
						pass++;
						loAnchored = getAnticollisionLayoutObjectForAnchor(objectToAnchor as IAnticollisionLayoutObject);
						if (loAnchored == null)
							continue;
						if (!loAnchored.visible)
							continue;
						var boundsFrom: Rectangle = lo.object.getBounds(this);
						var boundsTo: Rectangle = objectToAnchor.getBounds(this);
						if (boundsFrom.width < 10 && boundsFrom.height < 10)
						{
							//object is too small, do not do anticollision for it
							//trace("" + this + " object is too small, do not do anticollision for it");
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
						for each (var lineSegmentFrom: LineSegment in a_boundingLineSegmentsFrom)
						{
							pass++;
							for each (var lineSegmentTo: LineSegment in a_boundingLineSegmentsTo)
							{
								pass++;
								// approach: mid-points of 2 closest line segments
								var f_distance: Number = lineSegmentFrom.minimumDistanceToLineSegment(lineSegmentTo);
								if (f_distance < f_bestDistance)
								{
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
						drawAnnotationAnchorFunction(g, lo.drawAnchorArrow, bestPointFrom.x, bestPointFrom.y, bestPointTo.x, bestPointTo.y, clr, anchorAlpha);
					}
				}
				currTime = ProfilerUtils.startProfileTimer();
				_updateLocked = false;
			}
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
			if (object == null)
				return false;
			
			if (object is KMLLabel)
			{
				//if kml feature is not visible, label have to be invisible as well
				var kmlFeature: KMLFeature = (object as KMLLabel).kmlFeature;
//				trace("getAbsoluteVisibility " + object + " kmlFeature: " + kmlFeature + " vis: " + kmlFeature.visible);
				if (!kmlFeature.visible)
					return false;
			}
			
			// check if at least part of object is within m_boundaryRect
			var bounds: Rectangle = object.getBounds(this);
			
			if (bounds.width == 0 && bounds.height == 0)
				return true;
				
			if (bounds.right < m_boundaryRect.left)
				return false;
			if (bounds.left > m_boundaryRect.right)
				return false;
			if (bounds.bottom < m_boundaryRect.top)
				return false;
			if (bounds.top > m_boundaryRect.bottom)
				return false;
			// analyse chain of visibility flags
			while (object != null)
			{
				if (!object.visible && object != this)
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
		protected function drawApproximationFunction(graphics: Graphics, approx: Array, clr: int, thickness: int = 1): void
		{
			if (approx && approx.length > 0)
			{
				graphics.clear();
				graphics.lineStyle(thickness, clr);
				var cnt: int = 0;
				for each (var point: LineSegment in approx)
				{
					graphics.moveTo(point.x1, point.y1);
					graphics.lineTo(point.x2, point.y2);
					cnt++;
				}
			}
		}

		protected function drawAnnotationAnchorFunction(graphics: Graphics, b_drawArrow: Boolean, f_x1: Number, f_y1: Number, f_x2: Number, f_y2: Number, color: uint, alpha: Number): void
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
				var angle: Number = Math.atan2(h, w);
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
			if (lsab != null)
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
		private var m_makeRed: ColorTransform = new ColorTransform(1, 1, 1, 1, 255, -255, -255, 255);

		private function drawObjectPlacement(layoutObject: AnticollisionLayoutObject, f_dx: Number, f_dy: Number): void
		{
			var time: int = ProfilerUtils.startProfileTimer();
			var matrix: Matrix = new Matrix();
			matrix.translate(-m_boundaryRect.x, -m_boundaryRect.y);
			layoutObject.object.x = layoutObject.referenceLocation.x + f_dx;
			layoutObject.object.y = layoutObject.referenceLocation.y + f_dy;
			matrix.translate(layoutObject.object.x, layoutObject.object.y);
			if (layoutObject.object is UIComponent)
				UIComponent(layoutObject.object).validateNow();
			m_placementBitmap.draw(layoutObject.object, matrix, m_makeRed);
		}

		private function checkObjectPlacement(layoutObject: AnticollisionLayoutObject, bounds: Rectangle): Boolean
		{
			if (bounds.left < m_boundaryRect.left)
				return false;
			if (bounds.right > m_boundaryRect.right)
				return false;
			if (bounds.top < m_boundaryRect.top)
				return false;
			if (bounds.bottom > m_boundaryRect.bottom)
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
			if (mb_dirty)
			{
				if (getTimer() - mi_lastUpdate > m_updateInterval)
					update();
			}
		}

		public function get suspendAnticollisionProcessing(): Boolean
		{
			return m_suspendAnticollisionProcessing;
		}

		public function set suspendAnticollisionProcessing(value: Boolean): void
		{
			debug("suspendAnticollisionProcessing = " + value);
			if (m_suspendAnticollisionProcessing != value)
			{
				m_suspendAnticollisionProcessing = value;
				if (_areaChangedScheduled)
					areaChanged(_areaChangedScheduledBBox);
				update();
			}
		}

		public function get drawAnnotationAnchor(): Boolean
		{
			return m_drawAnnotationAnchor;
		}

		public function set drawAnnotationAnchor(value: Boolean): void
		{
			m_drawAnnotationAnchor = value;
		}

		public function get updateInterval(): int
		{
			return m_updateInterval;
		}

		public function set updateInterval(value: int): void
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
				debugConsole.print("AnticollisionLayout: " + txt, 'Info', 'AnticollisionLayout');
		}

		override public function toString(): String
		{
			return "AnticollistionLayout [" + _layoutName + " / " + id + "] parent: " + _parentContainer.id;
		}

		public function getAnticollisionLayoutObjectsForLayer(layer: InteractiveLayer): Array
		{
			var objects: Array = [];
			var currObjects: Array = ma_layoutObjects;
			var lo: AnticollisionLayoutObject;
			for each (lo in currObjects)
			{
				if (lo.layer == layer)
				{
					objects.push(lo);
				}
			}
			return objects;
		}
		private function getAnticollisionLayoutObjectFor(object: IAnticollisionLayoutObject): AnticollisionLayoutObject
		{
			if (!object || (!object is IAnticollisionLayoutObject))
			{
				trace("AnticollisionLayout.getAnticollisionLayoutObjectFor(): PROBLEM");
				return null;
			}
			return object.anticollisionLayoutObject;
		}

		private function getAnticollisionLayoutObjectForAnchor(anchor: IAnticollisionLayoutObject): AnticollisionLayoutObject
		{
			if (!anchor || (!anchor is IAnticollisionLayoutObject))
			{
				trace("AnticollisionLayout.getAnticollisionLayoutObjectForAnchor(): PROBLEM");
				return null;
			}
			return anchor.anticollisionLayoutObject;
		}

		public function updateObjectReferenceLocationWithCustomPosition(object: DisplayObject, rlX: Number, rlY: Number): Boolean
		{
			var lo: AnticollisionLayoutObject = getAnticollisionLayoutObjectFor(object as IAnticollisionLayoutObject);
			if (lo == null)
				return false;
			if (lo.referenceLocation.x != rlX || lo.referenceLocation.y != rlY)
			{
				setDirty();
				lo.referenceLocation = new Point(rlX, rlY);
			}
			return true;
		}

		public function updateObjectReferenceLocation(object: DisplayObject, bForceUpdate: Boolean = false): Boolean
		{
			bForceUpdate = true;
			if (!bForceUpdate)
				var canUpdate: Boolean = _updateLocationDictionary.updateLocation(object);
			if (bForceUpdate || (!bForceUpdate && canUpdate))
			{
				var lo: AnticollisionLayoutObject = getAnticollisionLayoutObjectFor(object as IAnticollisionLayoutObject);
				var loAnchor: AnticollisionLayoutObject = getAnticollisionLayoutObjectForAnchor(object as IAnticollisionLayoutObject);
				if (lo == null)
					return false;
				var refLocation: Point = lo.referenceLocation;
				var objX: Number = object.x;
				var objY: Number = object.y;
				if (refLocation.x != objX || refLocation.y != objY)
				{
					setDirty();
					lo.referenceLocation = new Point(objX, objY);
				}
				if (loAnchor == null)
					return false;
				var refAnchorLocation: Point = loAnchor.referenceLocation;
				if (refAnchorLocation.x != objX || refAnchorLocation.y != objY)
				{
					setDirty();
					loAnchor.referenceLocation = new Point(objX, objY);
				}
				return true;
			}
			return false;
		}

		public function drawDebugPlacementBitmap(g: Graphics): void
		{
			if (drawDebugMap)
			{
				g.beginBitmapFill(m_placementBitmap);
				g.drawRect(0, 0, m_placementBitmap.width, m_placementBitmap.height);
				g.endFill();
			}
		}
	}
}
import com.iblsoft.flexiweather.utils.anticollision.AnticollisionLayout;
import flash.display.DisplayObject;
import flash.events.TimerEvent;
import flash.utils.Dictionary;
import flash.utils.Timer;
import flash.utils.getTimer;
import mx.utils.object_proxy;

class UpdateLocationDictionary
{
	private var _maxObjectsUpdatePerTick: int = 50;
	private var _len: int = 0;
	private var _dictionary: Dictionary;
	private var _firstItem: UpdateLocationDictionaryItem;
	private var _lastItem: UpdateLocationDictionaryItem;
	private var _running: Boolean;
	private var _timer: Timer;
	private var _layout: AnticollisionLayout;

	public function UpdateLocationDictionary(layout: AnticollisionLayout)
	{
		_layout = layout;
		_dictionary = new Dictionary();
		_timer = new Timer(50);
		_timer.addEventListener(TimerEvent.TIMER, onTimer);
	}

	public function updateLocation(object: DisplayObject): Boolean
	{
		var item: UpdateLocationDictionaryItem;
		if (!_dictionary[object])
			item = new UpdateLocationDictionaryItem(object);
		else
			item = _dictionary[object] as UpdateLocationDictionaryItem;
		var canUpdate: Boolean = item.canUpdate();
		if (!canUpdate)
		{
			if (!_dictionary[object])
			{
				_dictionary[object] = item;
				_len++;
			}
			addItemOnWaitingList(item);
		}
		return canUpdate;
	}

	private function itemExists(item: UpdateLocationDictionaryItem): Boolean
	{
		var currItem: UpdateLocationDictionaryItem = _firstItem;
		if (!currItem)
			return false;
		while (currItem)
		{
			if (currItem == item)
				return true;
			if (currItem.nextItem == currItem)
				currItem = null
			else
				currItem = currItem.nextItem;
		}
		return false;
	}

	private function addItemOnWaitingList(item: UpdateLocationDictionaryItem): void
	{
		if (itemExists(item))
			return;
		if (!_firstItem)
		{
			_firstItem = item;
			_lastItem = item;
			item.previousItem = null;
			item.nextItem = null;
		}
		else
		{
			_lastItem.nextItem = item;
			item.previousItem = _lastItem;
			_lastItem = item;
		}
		if (!_timer.running)
			_timer.start();
	}

	private function updateItem(item: UpdateLocationDictionaryItem): void
	{
		//remove object from dictionary
		delete _dictionary[item.displayObject];
		_len--;
		//force update object reference location
		_layout.updateObjectReferenceLocation(item.displayObject, true);
	}

	private function debugDictionary(): void
	{
	}

	private function onTimer(event: TimerEvent): void
	{
		var ok: Boolean = true;
		var item: UpdateLocationDictionaryItem = _firstItem;
		var oldItem: UpdateLocationDictionaryItem = oldItem;
		if (!item)
		{
			ok = false;
			_timer.stop();
			return;
		}
		var cnt: int = 0;
		debugDictionary();
		while (ok)
		{
			if (item)
			{
				if (item.canUpdate())
				{
					updateItem(item);
					cnt++;
					if (item.previousItem)
					{
						item.previousItem.nextItem = item.nextItem;
						if (!item.previousItem.nextItem)
							_lastItem = item.previousItem;
					}
					if (item.nextItem)
					{
						item.nextItem.previousItem = item.previousItem;
						if (!item.previousItem)
							_firstItem = item.nextItem;
					}
					if (!item.previousItem && !item.nextItem)
						_firstItem = _lastItem = null;
				}
				oldItem = item;
				item = item.nextItem;
			}
			debugDictionary();
			if (!item)
			{
				ok = false;
				if (_firstItem)
					_lastItem = oldItem;
			}
			if (cnt >= _maxObjectsUpdatePerTick)
				ok = false;
		}
	}
}

class UpdateLocationDictionaryItem
{
	public static var uid: int = 0;
	public var previousItem: UpdateLocationDictionaryItem;
	public var nextItem: UpdateLocationDictionaryItem;
	public var displayObject: DisplayObject;
	private var _lastUpdate: Number;
	private var _minWaitingTime: int = 500;
	public var id: int;

	public function UpdateLocationDictionaryItem(object: DisplayObject)
	{
		uid++;
		id = uid;
		displayObject = object;
		_lastUpdate = getTimer();
	}

	public function canUpdate(): Boolean
	{
		var bool: Boolean = (timeFromLastUpdate() >= _minWaitingTime);
		if (bool)
			_lastUpdate = getTimer();
		return bool;
	}

	private function timeFromLastUpdate(): Number
	{
		return getTimer() - _lastUpdate;
	}
}
