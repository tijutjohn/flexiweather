package com.iblsoft.flexiweather.ogc.editable.features.curves
{
	import com.iblsoft.flexiweather.ogc.FeatureUpdateContext;
	import com.iblsoft.flexiweather.ogc.InteractiveLayerFeatureBase;
	import com.iblsoft.flexiweather.ogc.data.ReflectionData;
	import com.iblsoft.flexiweather.ogc.data.WFSEditableReflectionData;
	import com.iblsoft.flexiweather.ogc.data.WFSEditableReflectionDictionary;
	import com.iblsoft.flexiweather.ogc.editable.IEditableItemManager;
	import com.iblsoft.flexiweather.ogc.editable.WFSFeatureEditableCurveWithBaseTimeAndValidity;
	import com.iblsoft.flexiweather.ogc.editable.WFSFeatureEditableMode;
	import com.iblsoft.flexiweather.ogc.editable.data.FeatureDataReflection;
	import com.iblsoft.flexiweather.ogc.editable.data.jetstream.MoveableWindPoint;
	import com.iblsoft.flexiweather.ogc.editable.data.jetstream.WindBarb;
	import com.iblsoft.flexiweather.ogc.editable.data.jetstream.WindMoveablePointsDictionary;
	import com.iblsoft.flexiweather.ogc.editable.data.jetstream.WindReflectionData;
	import com.iblsoft.flexiweather.ogc.editable.events.WindBarbChangeEvent;
	import com.iblsoft.flexiweather.ogc.wfs.IWFSFeatureWithReflection;
	import com.iblsoft.flexiweather.proj.Coord;
	import com.iblsoft.flexiweather.symbology.FrontCurveRenderer;
	import com.iblsoft.flexiweather.symbology.JetStreamCurveRenderer;
	import com.iblsoft.flexiweather.utils.CubicBezier;
	import com.iblsoft.flexiweather.utils.ICurveRenderer;
	import com.iblsoft.flexiweather.utils.draw.DrawMode;
	import com.iblsoft.flexiweather.widgets.InteractiveWidget;
	
	import flash.display.Graphics;
	import flash.display.Sprite;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.geom.ColorTransform;
	import flash.geom.Point;
	import flash.ui.Keyboard;
	
	import mx.collections.ArrayCollection;
	import mx.core.Application;
	import mx.core.FlexGlobals;
	
	/**
	 * For front styles see for example http://en.wikipedia.org/wiki/Weather_front
	 **/	
	public class WFSFeatureEditableJetStream extends WFSFeatureEditableCurveWithBaseTimeAndValidity implements IWFSFeatureWithReflection
	{
		public var values:Object;
		
		//TODO add better depedency on InteractiveWidget
		public var iw:InteractiveWidget;
//		public var iw:InteractiveWidget = (FlexGlobals.topLevelApplication as IBrowsingWeather).mainView.iw;
		
		
//		protected var m_windPointsOnCurve: ArrayCollection = new ArrayCollection();
//		protected var m_windCoordinates: ArrayCollection = new ArrayCollection();
		
		
		//collection of wind points (without any reflection)
		protected var m_windPoints: ArrayCollection = new ArrayCollection();
		
		//collection of WindBarbs (without any reflection)
		protected var ml_windBarbs: ArrayCollection = new ArrayCollection();
		
//		protected var ml_movablePoints: Array = new Array();
//		protected var ml_moveableWindPoints: WindMoveablePointsDictionary;
		
		
		protected var m_selectedWindPoint: MoveableWindPoint;
		protected var m_selectedWindPointIndex: int = -1;
		
		/**
		 * 
		 */
		public function WFSFeatureEditableJetStream(s_namespace: String, s_typeName: String, s_featureId: String)
		{
			super(s_namespace, s_typeName, s_featureId);
			
		}
		
		override protected function createReflectionDirectory(): void
		{
			ml_movablePoints = new WindMoveablePointsDictionary(master.container);
			
		}
		
		private function debug(): void
		{
//			return;
			var totalWindBarbs: int = m_windPoints.length;
			var r: uint;
			var reflection: WindReflectionData;
			for(var i: uint = 0; i < totalWindBarbs; ++i) 
			{
				for (r = 0; r < totalReflections; r++)
				{
					reflection = ml_movablePoints.getReflection(r) as WindReflectionData;
				}
			}
		}
	
		override public function getRenderer(reflection: int): ICurveRenderer
		{
//			updateFrontProperties();
//			jetStreamSprite.renderer = new JetStreamCurveRenderer(gr, 4, i_color, 1.0);
			var i_color: uint = getCurrentColor(0x000000);
			var gr: Graphics = graphics;
			
			var reflectionData: WFSEditableReflectionData = ml_movablePoints.getReflection(reflection) as WFSEditableReflectionData;
			if (reflectionData && reflectionData.displaySprite)
			{
				gr = reflectionData.displaySprite.graphics;
			}
			
			return new JetStreamCurveRenderer(gr, 4, i_color, 1.0);
		}
		
		override public function update(changeFlag: FeatureUpdateContext): void
		{
			if (!master)
				return;
			
			graphics.clear();
			super.update(changeFlag);
			
			updateWindPointsReflections();
			
			var windBarbsCanBeDrawed: Boolean = true;
			
			// WE NEED ALWAYS RECOMPUTE POINTS
			// RECOMPUTE WIND POINTS IF NEEDED

			var iw: InteractiveWidget = m_master.container;

			var r: uint;
			var reflection: WindReflectionData;
			var totalReflections: uint = ml_movablePoints.totalReflections;
			
			
			var totalWindBarbs: int = m_windPoints.length;
			for(var i: uint = 0; i < totalWindBarbs; ++i) 
			{
				var pt: Point = m_windPoints.getItemAt(i) as Point;
				var windbarb: WindBarb = ml_windBarbs.getItemAt(i) as WindBarb;
				var c: Coord = windbarb.coordinate;
				
				var pointReflections: Array = master.container.mapCoordToViewReflections(c);
				for (r = 0; r < totalReflections; r++)
				{
					reflection = ml_movablePoints.getReflection(r) as WindReflectionData;
				
					if (reflection && reflection.windbarbs && reflection.windbarbs.length > i)
					{
						var currWindbarb: WindBarb = WindBarb(reflection.windbarbs[i]);
						
						if (pointReflections.length > r)
						{
							var pReflected: Point = pointReflections[r].point as Point;
							var cReflected: Coord = new Coord(c.crs, pReflected.x, pReflected.y);
							WindBarb(reflection.windbarbs[i]).coordinate = cReflected;
							WindBarb(reflection.windbarbs[i]).point = iw.coordToPoint(cReflected);
						}
					}
				} 
			}
			
			debug();
			
			graphics.clear();
			var a_points: Array = getPoints();
			var i_color: uint = 0x000000;
			
			i_color = getCurrentColor(i_color);
			var featureReflections: Array;
			
			if(a_points.length > 1) { 
				
				graphics.lineStyle(1, i_color);
//				var splinePoints: Array = CubicBezier.calculateHermitSpline(a_points, false);
				var coords: Array = [];
				
				//what is the best way to check in which projection was front created? For now we check CRS of first coordinate
//				var crs: String = (coordinates[0] as Coord).crs;
//				
//				//convert points to Coords
//				for each (var p: Point in splinePoints)
//				{
//					coords.push(master.container.pointToCoord(p.x, p.y));	
//				}
				
				if (master)
				{
//					master.container.drawGeoPolyLine(getFontCurveRenderer, splinePoints, DrawMode.PLAIN);
					
//					featureReflections = master.container.getSplineReflections( coords);
//					createHitMask(featureReflections);
					
					
					// CREATE WIND BARBS
					var nColorTransform: ColorTransform;
					var gr: Graphics;
					var jetStreamSprite: JetStreamSprite;
					totalReflections = ml_movablePoints.totalReflections;
//					totalReflections = 1;
					
					for (r = 0; r < totalReflections; r++)
					{
						reflection = ml_movablePoints.getReflection(r) as WindReflectionData;
						a_points = reflection.points;
						
						if (!reflection.displaySprite)
						{
							reflection.displaySprite = new JetStreamSprite(this);
							addChild(reflection.displaySprite);
						}
						jetStreamSprite = reflection.displaySprite as JetStreamSprite;
						jetStreamSprite.points = a_points;
						
						
						gr = reflection.displaySprite.graphics;
						
						if (!jetStreamSprite.renderer)
						{
							
							jetStreamSprite.renderer = getRenderer(reflection.reflectionDelta) as JetStreamCurveRenderer;
						}
						jetStreamSprite.renderer.setColor(i_color);
//						if (featureReflections)
//						{
//							gr.clear();
//							var curvePoints: Array = featureReflections[r];
						var curvePoints: Array;
						
						if (m_featureData)
						{
							jetStreamSprite.clear();
							var reflectionData: FeatureDataReflection = m_featureData.getReflectionAt(reflection.reflectionDelta);
							if (reflectionData)
							{
								drawFeatureReflection(jetStreamSprite.renderer, reflectionData);
								curvePoints = reflectionData.points;
							}
//							
//							drawFeature(jetStreamSprite.renderer, curvePoints);
							
							//we store curvePoints for later usage (find reflected jetstream closest to the point in onMouseDown function)
							reflection.jetstreamCurvePoints = curvePoints;
							
							if(!createWindPoints(curvePoints, r))
							{
								// CREATE COLOR TRANSFORM
								nColorTransform = new ColorTransform(1, 0, 0, 1, 255, 0, 0, 0);
							} else {
								nColorTransform = new ColorTransform(1, 1, 1, 1, 0, 0, 0, 0);
								
								if (useMonochrome){
									nColorTransform.color = monochromeColor;
								}
							}
							if (nColorTransform)
								reflection.displaySprite.transform.colorTransform = nColorTransform;
						}
							
							
//						}
					}
					
				}
			} else {
				for (r = 0; r < totalReflections; r++)
				{
					reflection = ml_movablePoints.getReflection(r) as WindReflectionData;
					if (reflection.displaySprite)
					{
						(reflection.displaySprite as JetStreamSprite).clear();
					}
				}
				renderFallbackGraphics();
			}
		
			changeVisibility();
			
		}
		

		private function changeVisibility(): void
		{
			var r: uint;
			var reflection: WindReflectionData;
			var totalReflections: uint = ml_movablePoints.totalReflections;
			
			for (r = 0; r < totalReflections; r++)
			{
				reflection = ml_movablePoints.getReflection(r) as WindReflectionData;
				
				var jetStreamSprite: JetStreamSprite = reflection.displaySprite as JetStreamSprite;
				
				if (jetStreamSprite)
				{
					if ((editMode == WFSFeatureEditableMode.EDIT_WIND_BARBS_POINTS) && selected){
						// HIDE CURVE POINTS
						m_editableSprite.visible = false;
						jetStreamSprite.m_editableSignsSprite.visible = true;
					} else if (selected){
						m_editableSprite.visible = true;
						jetStreamSprite.m_editableSignsSprite.visible = false;
					} else {
						m_editableSprite.visible = false;
						jetStreamSprite.m_editableSignsSprite.visible = false;
					}
				}
			}
			
		}
		
		private function drawFeature(g: JetStreamCurveRenderer, mPoints: Array): void
		{
			if (!g || !mPoints)
			{
				return;
			}
			var p: Point;
			
			var total: int = mPoints.length;
			if (total > 0)
			{
				p = mPoints[0] as Point;
				
				g.start(p.x, p.y);
				g.moveTo(p.x, p.y);
				
				for (var i: int = 1; i < total; i++)
				{
					p = mPoints[i] as Point;
					g.lineTo(p.x, p.y);
				}
				
				g.finish(p.x, p.y);
			}
			
		}
		/**
		 * Returns true if all wind barbs can be drawed, false if some of windbar(s) can NOT be drawed
		 */
		protected function createWindPoints(curvePoints: Array, reflectionID: uint): Boolean
		{
			var ret: Boolean = true;
			var eim: IEditableItemManager = IEditableItemManager(m_master); 
			
			var mp: MoveableWindPoint;
			var cp: WFSFeatureEditableJetStreamWindBarb;
			var i: uint;
			var r: uint = reflectionID;
			
			var i_color: uint = 0x000000;
			
			i_color = getCurrentColor(i_color);

			
			var reflection: WindReflectionData;
			var totalReflections: uint = ml_movablePoints.totalReflections;
			
			totalReflections = 1;
			
			reflection = ml_movablePoints.getReflection(r) as WindReflectionData;
			var jetStreamSprite: JetStreamSprite = reflection.displaySprite as JetStreamSprite;
		
			var totalWindBarbs: int = reflection.windbarbs.length;
			var windbarb: WindBarb;
			
			for(i = 0; i < totalWindBarbs; ++i) 
			{
				if(i >= reflection.totalWindPoints) 
				{
					mp = new MoveableWindPoint(this, i, r, reflection.reflectionDelta);
					windbarb = WindBarb(reflection.windbarbs[i]);
					
					cp = new WFSFeatureEditableJetStreamWindBarb(curvePoints, findNearestCurvePoint(windbarb.point, curvePoints), windbarb, i_color);
				
					ret = ret && cp.canBeDrawed;
				
					reflection.addWindMoveablePoint(mp, i, cp);
					
					
					jetStreamSprite.m_editableSignsSprite.addChild(mp);
					jetStreamSprite.m_signsSprite.addChild(cp);
					eim.addEditableItem(mp);
					continue;
				}
			
				mp = reflection.windPoints[i] as MoveableWindPoint;
				cp = reflection.editableJetStreamWindbarbs[i] as WFSFeatureEditableJetStreamWindBarb;
				
				windbarb = reflection.windbarbs[i] as WindBarb; 
				var pt: Point = windbarb.point;
			
				mp.setPoint(pt);
				
				//TODO  curvePoints are currently pixels position, but "pt" is reflected "pt" => need to recount "pt" point to current screen pixel position
				if (ml_windBarbs.length > i)
				{
					var c1: Coord = (ml_windBarbs[i] as WindBarb).coordinate;
					
//					var wbCoordPoint: Point = new Point(c1.x, c1.y);
					//and we need "r"th reflection of it
					var reflectedPoints: Array = iw.mapCoordToViewReflections(c1);
					
					var wbPoint: Point;
					var cnt: uint = 0;
					for each (var refObj: Object in reflectedPoints)
					{
						if (cnt == r)
						{
							wbPoint = refObj.point as Point;
							break;
						}
						cnt++;
					}
					
					if (wbPoint)
					{
						var cReflected: Coord = new Coord(iw.crs, wbPoint.x, wbPoint.y);
						wbPoint = iw.coordToPoint(cReflected);
						var close: uint = findNearestCurvePoint(wbPoint, curvePoints);
					}
					cp.update(curvePoints, close, windbarb, i_color);
					
					ret = ret && cp.canBeDrawed;
				}
			}
			
			for(; i < reflection.totalWindPoints; ++i) 
			{
				mp = reflection.windPoints[i] as MoveableWindPoint;
				cp = reflection.editableJetStreamWindbarbs[i] as WFSFeatureEditableJetStreamWindBarb;
				eim.removeEditableItem(mp);
				jetStreamSprite.m_editableSignsSprite.removeChild(mp);
				jetStreamSprite.m_signsSprite.removeChild(cp);
			}
			while(reflection.windbarbs.length < reflection.totalWindPoints) {
				reflection.windPoints.pop();
			}
			
			return(ret);
			
		}
		
		private function removeWindbarbAt(position: int): void
		{
//			var i:int;
			var j:int;
			var reflection: WindReflectionData;
			
			var eim: IEditableItemManager = IEditableItemManager(m_master); 
			var mp: MoveableWindPoint;
			var cp: WFSFeatureEditableJetStreamWindBarb;
			
			var totalReflections: uint = ml_movablePoints.totalReflections;
			for (j = 0; j < totalReflections; j++)
			{
				reflection = ml_movablePoints.getReflection(j) as WindReflectionData;
				var jetStreamSprite: JetStreamSprite = reflection.displaySprite as JetStreamSprite;
				
//				for(; i < reflection.totalWindPoints; ++i) 
//				{
					mp = reflection.windPoints[position] as MoveableWindPoint;
					cp = reflection.editableJetStreamWindbarbs[position] as WFSFeatureEditableJetStreamWindBarb;
					eim.removeEditableItem(mp);
					
					jetStreamSprite.m_editableSignsSprite.removeChild(mp);
					jetStreamSprite.m_signsSprite.removeChild(cp);
//				}
//				while(reflection.windbarbs.length < reflection.totalWindPoints) {
//					reflection.windPoints.pop();
//				}
			}
		}
		private function cleanupWindbarbs(): void
		{
			var i:int;
			var j:int;
			var reflection: WindReflectionData;
			
			var eim: IEditableItemManager = IEditableItemManager(m_master); 
			var mp: MoveableWindPoint;
			var cp: WFSFeatureEditableJetStreamWindBarb;
			
			var totalReflections: uint = ml_movablePoints.totalReflections;
			for (j = 0; j < totalReflections; j++)
			{
				reflection = ml_movablePoints.getReflection(j) as WindReflectionData;
				var jetStreamSprite: JetStreamSprite = reflection.displaySprite as JetStreamSprite;
				
				for(; i < reflection.totalWindPoints; ++i) 
				{
					mp = reflection.windPoints[i] as MoveableWindPoint;
					cp = reflection.editableJetStreamWindbarbs[i] as WFSFeatureEditableJetStreamWindBarb;
					eim.removeEditableItem(mp);
					jetStreamSprite.m_editableSignsSprite.removeChild(mp);
					jetStreamSprite.m_signsSprite.removeChild(cp);
				}
				while(reflection.windbarbs.length < reflection.totalWindPoints) {
					reflection.windPoints.pop();
				}
			}
		}
		/**
		 * Function for creating jetstream  
		 * 
		 */		
		private function updateWindPointsReflections(): void
		{
			//clean everything only if we are not editing jet stream
			
			//FIXME problem is, that this is cleanuped on every update, so we lost all windbarbs and so on

			var recreateMode: Boolean = false; //editMode != WFSFeatureEditableMode.EDIT_WIND_BARBS_POINTS && editMode != WFSFeatureEditableMode.MOVE_POINTS;
			
			if (recreateMode)
			{
				cleanupWindbarbs();
				ml_movablePoints.cleanup();
			}
			
			var total: int = coordinates.length;
			var crs: String = master.container.getCRS();
			var i: uint;
			var j: uint;
			var reflection: WindReflectionData;
			var coord: Coord;
			var pointReflections: Array;
			var reflectionsCount: int;
			var pointReflectedObject: Object;
			var pointReflected: Point;
			var coordReflected: Coord;
			
			for (i = 0; i < total; i++)
			{
				coord = coordinates[i] as Coord;
				pointReflections = master.container.mapCoordToViewReflections(coord);
				reflectionsCount = pointReflections.length;
				
				for (j = 0; j < reflectionsCount; j++)
				{
					pointReflectedObject = pointReflections[j];
					pointReflected = pointReflectedObject.point;
					coordReflected = new Coord(crs, pointReflected.x, pointReflected.y);
					if (recreateMode)
					{
						ml_movablePoints.addReflectedCoordAt(coordReflected, i, j, pointReflectedObject.reflection);
					} else {
						ml_movablePoints.updateReflectedCoordAt(coordReflected, i, j, pointReflectedObject.reflection);
					}
				}
			}
			
			
			
//			recreate windbarbs
			var totalWindbarbs: int = ml_windBarbs.length;
			var cnt: int = -1;
			for (var w: int = 0; w < totalWindbarbs; w++)
			{
				var windbarb: WindBarb = ml_windBarbs.getItemAt(w) as WindBarb;
			
				coord = windbarb.coordinate;
				pointReflections = master.container.mapCoordToViewReflections(coord);
				reflectionsCount = pointReflections.length;
				
				if (reflectionsCount > 0)
				{
					cnt++;
					for (j = 0; j < reflectionsCount; j++)
					{
						pointReflectedObject = pointReflections[j];
						pointReflected = pointReflectedObject.point;
						coordReflected = new Coord(crs, pointReflected.x, pointReflected.y);
						
						var reflectionDelta: int = pointReflectedObject.reflection;
						
						var currReflectedWindbarb: WindBarb = windbarb.clone();
						currReflectedWindbarb.coordinate = coord;
						
						if (recreateMode)
						{
							(ml_movablePoints as WindMoveablePointsDictionary).addWindbarbAt(currReflectedWindbarb, cnt, j, reflectionDelta);
						} else {
							(ml_movablePoints as WindMoveablePointsDictionary).updateWindbarbAt(currReflectedWindbarb, cnt, j, reflectionDelta);
						}
						
					}
				}
			}

		}
		
		/**
		 * This method will be called when WFS feature will be created as result of split.
		 * Do whatever is needed after split in this method 
		 * 
		 */		
		override public function afterSplit(): void
		{
			//windbards was created by clone() method, so all windbarbs which are not part of this feature create by split, must be removed
			trace("Jet stream afterSplit");
			var totalWindbarbs: int = ml_windBarbs.length;
			var cnt: int = -1;
			for (var w: int = 0; w < totalWindbarbs; w++)
			{
				var windbarb: WindBarb = ml_windBarbs.getItemAt(w) as WindBarb;
				trace("\t after split wind barb " + w + " => " + windbarb);	
				
			}
		}
		
		/**
		 * 
		 */
		public function getWindPoint(i_pointIndex: int, reflectionID: int): Point
		{
			var reflection: WindReflectionData = ml_movablePoints.getReflection(reflectionID) as WindReflectionData;
			return(WindBarb(reflection.windbarbs[i_pointIndex]).point);
		}
		
		/**
		 * 
		 */
		public function set selectedWindPointIndex(i_pointIndex: int): void
		{
			if (m_selectedWindPoint){
				m_selectedWindPoint.selected = false;
			}
			
			m_selectedWindPointIndex = i_pointIndex;
			
			var reflection: WindReflectionData = ml_movablePoints.getReflection(0) as WindReflectionData;
			if (i_pointIndex > -1) 
			{
				if (reflection && reflection.windPoints && reflection.windPoints.length > i_pointIndex)
				{
					var mp: MoveableWindPoint = MoveableWindPoint(reflection.windPoints[i_pointIndex]);
					
					m_selectedWindPoint = mp;
					m_selectedWindPoint.selected = true;
					
					// SEND EVENT ABOUT CHANGE OF SELECTED WIND POINT
					var nEvent: WindBarbChangeEvent = new WindBarbChangeEvent(WindBarbChangeEvent.WIND_BARB_SELECTION_CHANGE, reflection.windbarbs[m_selectedWindPointIndex]);
						
					dispatchEvent(nEvent);
				} else {
					m_selectedWindPoint = null;
				}
				
			} else {
				m_selectedWindPoint = null;
			}
		}
		
		/**
		 * 
		 */
		public function setWindPoint(i_pointIndex: int, pt: Point, i_reflectionDelta: uint): void
		{
			
			//FIXME we need to know, for which reflection it was dragged
//			trace("SET WIND POINT for reflection: " + i_reflectionDelta);

			var iw: InteractiveWidget = m_master.container;
			
			var coord: Coord = iw.pointToCoord(pt.x, pt.y);
			
			if (i_reflectionDelta != 0)
			{
				//wind point of reflected jet stream was set, need to count original jet stream wind point position
				var deltas: Array = [-1*i_reflectionDelta];
				var p: Point = new Point(coord.x, coord.y);
				var reflectedCoords: Array = iw.mapCoordInCRSToViewReflectionsForDeltas(p, deltas);
				
				var reflectedPoint: Point =  reflectedCoords[0].point as Point;
				var cReflected: Coord = new Coord(iw.crs, reflectedPoint.x, reflectedPoint.y);
				WindBarb(ml_windBarbs[i_pointIndex]).coordinate = cReflected;
				WindBarb(ml_windBarbs[i_pointIndex]).point = iw.coordToPoint(cReflected);
			} else {
				
				//wind point on original jet stream was set
				
				WindBarb(ml_windBarbs[i_pointIndex]).point = pt.clone();
				WindBarb(ml_windBarbs[i_pointIndex]).coordinate = iw.pointToCoord(pt.x, pt.y);
			}
			
			update(FeatureUpdateContext.fullUpdate());
			modified = true;
		}
		
		/**
		 * 
		 */
		protected function findNearestCurvePoint(fPoint: Point, points: Array, type: String = 'index'): uint
		{
			var fIndex: int = 0;
			var fDist: Number = 10000000;
			var tDist: Number;
			
			var total: int = 0;
			if (points)
				total = points.length;
			
			for (var i: uint = 0; i < total; i++){
				tDist = Point.distance(fPoint, Point(points[i]));
				if (tDist <= fDist){
					fDist = tDist;
					fIndex = i;
				}
			} 
			
			if (type == 'distance')
				return fDist;
			
			return(fIndex);
		}

		private function getWindbarbsXML(nWindBarb: WindBarb): XML
		{
			var xml: XML = <maxWindPoint xmlns="http://www.iblsoft.com/wfs" xmlns:wfs="http://www.opengis.net/wfs" xmlns:gml="http://www.opengis.net/gml" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
					<gml:location xmlns:gml="http://www.opengis.net/gml">
						<gml:Point>
							<gml:pos srsName={nWindBarb.coordinate.crs}>{nWindBarb.coordinate.x} {nWindBarb.coordinate.y}</gml:pos>
						</gml:Point>
					</gml:location>
					<windSpeed>{nWindBarb.windSpeed * 0.514444}</windSpeed>
					<flightLevel below={nWindBarb.below} above={nWindBarb.above}>{nWindBarb.flightLevel}</flightLevel>
				</maxWindPoint>;
			
			return xml;
			
			
		}
		override public function toInsertGML(xmlInsert: XML): void
		{
			var gml: Namespace = new Namespace("http://www.opengis.net/gml");
			super.toInsertGML(xmlInsert);
			
			var profileXML: XML = <profile xmlns="http://www.iblsoft.com/wfs" xmlns:wfs="http://www.opengis.net/wfs" xmlns:gml="http://www.opengis.net/gml" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"/>;
			
			var reflection0: WindReflectionData = ml_movablePoints.getReflection(0) as WindReflectionData;
			// APPEND WIND BARBS
			var nWindBarb: WindBarb;
			for (var i: int = 0; i < reflection0.windbarbs.length; i++)
			{
				nWindBarb = WindBarb(reflection0.windbarbs[i]);
				
				profileXML.appendChild(getWindbarbsXML(nWindBarb));
			}
			
			xmlInsert.appendChild(profileXML);
		}

		override public function toUpdateGML(xmlUpdate: XML): void
		{
			// TODO: FIXME: No update serialisation of Jet Stream
			
			var gml: Namespace = new Namespace("http://www.opengis.net/gml");
			super.toUpdateGML(xmlUpdate);
			
			var reflection0: WindReflectionData = ml_movablePoints.getReflection(0) as WindReflectionData;
			// APPEND WIND BARBS
			var nWindBarb: WindBarb;
			var windbarbsXMLList: XMLList = new XMLList();
			
			for (var i: int = 0; i < reflection0.windbarbs.length; i++)
			{
				nWindBarb = WindBarb(reflection0.windbarbs[i]);
				
				windbarbsXMLList += (getWindbarbsXML(nWindBarb));
			}
			
			addUpdateGMLProperty(xmlUpdate, null,"profile", windbarbsXMLList);
		}

		override public function fromGML(gml: XML): void
		{
			super.fromGML(gml);
			var ns: Namespace = new Namespace(ms_namespace);
			var nsGML: Namespace = new Namespace("http://www.opengis.net/gml");
			
			var tmp: XMLList = gml.ns::profile;
			
			var maxWindPointsList: XMLList = gml.ns::profile.ns::maxWindPoint;
			
			
			
			values = {
				windPoints: new Array()
			};
			
			
			//FIXME fix fromGML for JetStream with reflections
			
			
			var nWindPointGML: XML;
			var nWindBarb: WindBarb;
			
			ml_windBarbs = new ArrayCollection();
			m_windPoints = new ArrayCollection();
//			m_windCoordinates = new ArrayCollection();
			for (var i: int; i < maxWindPointsList.length(); i++){
				nWindPointGML = maxWindPointsList[i];
				
				var xmlLocation: XML = nWindPointGML.nsGML::location[0]; 
				var xmlPoint: XML = xmlLocation.nsGML::Point[0];
				for each(var node: XML in xmlPoint.children()) {
					var s_coords: String = String(node); 
					var a_bits: Array = s_coords.split(/\s/);
					var s_srs: String = node.@srsName;
				}
				
				var coo: Coord = new Coord(iw.getCRS(), a_bits[0], a_bits[1]);
				
				nWindBarb = new WindBarb();
				nWindBarb.coordinate = new Coord(iw.getCRS(), a_bits[0], a_bits[1]);
				nWindBarb.windSpeed = int(Number(nWindPointGML.ns::windSpeed) / 0.514444);
				nWindBarb.flightLevel = int(nWindPointGML.ns::flightLevel);
				nWindBarb.below = (nWindPointGML.ns::flightLevel.@below == '1000000000000') ? 0: int(nWindPointGML.ns::flightLevel.@below);
				nWindBarb.above = (nWindPointGML.ns::flightLevel.@above == '1000000000000') ? 0: int(nWindPointGML.ns::flightLevel.@above);
				
				//windSpeed
				// flightLevel @below @above
				
				ml_windBarbs.addItem(nWindBarb);
				
				//m_windCoordinates.addItem(coo);
				
				var cooPoint: Point = iw.coordToPoint(coo);
				m_windPoints.addItem(cooPoint);
			}
			
		}
		
		private function findClosestReflectionToPoint(pt: Point): int
		{
			var reflection: WindReflectionData;
			var totalReflections: uint = ml_movablePoints.totalReflections;
			var distanceMax: Number = Number.MAX_VALUE;
			
			var closestReflection: int = 0
			
			for (var r: int = 0; r < totalReflections; r++)
			{
				reflection = ml_movablePoints.getReflection(r) as WindReflectionData;
				var dist: int = findNearestCurvePoint(pt, reflection.jetstreamCurvePoints, 'distance');
				
				if (dist < distanceMax)
				{
					closestReflection = reflection.reflectionDelta;
					distanceMax = dist;
				}
			}
			return closestReflection;
		}
		/**
		 * 
		 */
		override public function onMouseDown(pt:Point, event:MouseEvent):Boolean
		{
			if(!selected)
				return false;
				
			if (mi_editMode == WFSFeatureEditableMode.EDIT_WIND_BARBS_POINTS)
			{
				
				// WANT TO ADD NEW WIND POINT
				var gPt: Point = localToGlobal(pt);
				
				
				var reflection: WindReflectionData;
				var totalReflections: uint = ml_movablePoints.totalReflections;
				
				var bool: Boolean;
				
				var hitWindPointInAnyReflection: Boolean;
				var createNewPoint: Boolean;
				var createdInReflection: int = 0;
				
				for (var r: int = 0; r < totalReflections; r++)
				{
					reflection = ml_movablePoints.getReflection(r) as WindReflectionData;
					var jetStreamSprite: JetStreamSprite = reflection.displaySprite as JetStreamSprite;
						
					var b1: Boolean = jetStreamSprite.m_editableSignsSprite.hitTestPoint(gPt.x, gPt.y, true);
					var b2: Boolean = jetStreamSprite.hitTestPoint(gPt.x, gPt.y, true);
					var b3: Boolean = hitTestPoint(gPt.x, gPt.y, true);
					var b4: Boolean = m_editableSprite.hitTestPoint(gPt.x, gPt.y, true);
					
					if (b1 && b2)
					{
						hitWindPointInAnyReflection = true;
						continue;
					}
					
//					if (!b1 && b3 && b2)
					if (!b1 && b3)
					{
						createNewPoint = true;
					}
				}
			
				if (createNewPoint && !hitWindPointInAnyReflection)
				{
					//find reflection
					createdInReflection = findClosestReflectionToPoint(pt);
					
					var pIndex: uint = findNearestCurvePoint(pt, m_curvePoints);
					
					var iw: InteractiveWidget = m_master.container;
					
					// ADD NEW WIND BARB POINT
					var nWindBarb: WindBarb = new WindBarb();
					
					//FIXME all reflections have point in 0th reflection ---need to fix this in update() function
					nWindBarb.coordinate = iw.pointToCoord(pt.x, pt.y);
					
					nWindBarb.windSpeed = 85;
					nWindBarb.flightLevel = 0;
					nWindBarb.below = 0;
					nWindBarb.above = 0;
					
					
					
					/**
					 * we need to save this to local variables and not only to reflections to be able to recreate reflection in updateWindPointsReflections() function
					 */
					
					
					var coord: Coord = nWindBarb.coordinate;
					
					if (createdInReflection != 0)
					{
						//wind point of reflected jet stream was set, need to count original jet stream wind point position
						var deltas: Array = [-1*createdInReflection];
						var p: Point = new Point(coord.x, coord.y);
						var reflectedCoords: Array = iw.mapCoordInCRSToViewReflectionsForDeltas(p, deltas);
						
						var reflectedPoint: Point =  reflectedCoords[0].point as Point;
						var cReflected: Coord = new Coord(iw.crs, reflectedPoint.x, reflectedPoint.y);
						nWindBarb.coordinate = cReflected;
						nWindBarb.point = iw.coordToPoint(cReflected);
						
						m_windPoints.addItem(nWindBarb.point);
						
					} else {
						
						//wind point on original jet stream was set
						
//						WindBarb(ml_windBarbs[i_pointIndex]).point = pt.clone();
//						WindBarb(ml_windBarbs[i_pointIndex]).coordinates = iw.pointToCoord(pt.x, pt.y);
						m_windPoints.addItem(pt);
					}
					ml_windBarbs.addItem(nWindBarb);
					selectedWindPointIndex = ml_windBarbs.length - 1;
					
					
					for (r = 0; r < totalReflections; r++)
					{
						reflection = ml_movablePoints.getReflection(r) as WindReflectionData;
						reflection.windbarbs.addItem(nWindBarb.clone());
					}
					
					bool = true;
				}
				
				
				
				if (bool)
				{
					update(FeatureUpdateContext.fullUpdate());
					return(true);
				} else {
					return(false);
				}
				
			} else {
				return(super.onMouseDown(pt,event));
			}
		}
		
//		override protected function editableSpriteVisible(bool: Boolean): void
//		{
//			//it needs to be implemented here, because editableSprite is inside JetStreamSprite
//			if (justSelectable)
//				bool = false;
//			
//			m_editableSprite.visible = bool;
//		}
		/**
		 * 
		 */
		override protected function updateGlow():void
		{
			super.updateGlow();
			
			if (selected && (mi_editMode == WFSFeatureEditableMode.EDIT_WIND_BARBS_POINTS)){
				m_editableSprite.visible = false;
			}
		}
		
		/**
		 * 
		 */
		override public function set editMode(i_mode:int):void
		{
			super.editMode = i_mode;
			
			if (editMode != WFSFeatureEditableMode.EDIT_WIND_BARBS_POINTS){
				selectedWindPointIndex = -1;
			}
			
			update(FeatureUpdateContext.fullUpdate());
		}
		
		//TODO better implement JetStream bindable function to remove dependency on FeatureEditorWidget
		/*
		public function setBindableFunctions(content: FeatureEditorWidgetBase): void
		{
			if (!content.hasEventListener(WindBarbChangeEvent.WIND_BARB_CHANGE)){
				content.addEventListener(WindBarbChangeEvent.WIND_BARB_CHANGE, onChangeWindBarbContentValues);
			}
			
			addEventListener(WindBarbChangeEvent.WIND_BARB_SELECTION_CHANGE, content.onChangeWindBarbValues);
		}
		
		public function resetBindableFunctions(content: FeatureEditorWidgetBase): void
		{
			if (content.hasEventListener(WindBarbChangeEvent.WIND_BARB_CHANGE)){
				content.removeEventListener(WindBarbChangeEvent.WIND_BARB_CHANGE, onChangeWindBarbContentValues);
			}
			
			removeEventListener(WindBarbChangeEvent.WIND_BARB_SELECTION_CHANGE, content.onChangeWindBarbValues);
		}
		*/
		
		/**
		 * 
		 */
		public function onChangeWindBarbContentValues(evt: WindBarbChangeEvent): void
		{
			if (m_selectedWindPoint != null){
				var reflection: WindReflectionData;
				var totalReflections: uint = ml_movablePoints.totalReflections;
				
				var wb: WindBarb = ml_windBarbs.getItemAt(m_selectedWindPointIndex) as WindBarb; 
				
				wb.windSpeed = WindBarb(evt.data).windSpeed;
				wb.flightLevel = WindBarb(evt.data).flightLevel;
				wb.above = WindBarb(evt.data).above;
				wb.below = WindBarb(evt.data).below;
				
				
//				for (var r: int = 0; r < totalReflections; r++)
//				{
//					reflection = ml_movablePoints.getReflection(r) as WindReflectionData;
//					
//					var wb: WindBarb = WindBarb(reflection.windbarbs[m_selectedWindPointIndex]); 
//					
//					wb.windSpeed = WindBarb(evt.data).windSpeed;
//					wb.flightLevel = WindBarb(evt.data).flightLevel;
//					wb.above = WindBarb(evt.data).above;
//					wb.below = WindBarb(evt.data).below;
//				}
				update(FeatureUpdateContext.fullUpdate());
			}
		}
		
		/**
		 * 
		 */
		override public function set selected(b:Boolean):void
		{
			var needReset: Boolean = false;
			
			if (super.selected && !b){
				needReset = true;
			}
			
			if (needReset){
				selectedWindPointIndex = -1;
				editMode = WFSFeatureEditableMode.MOVE_POINTS;
			}
			
			super.selected = b;
		}
		
		/**
		 * 
		 */
		override public function onKeyDown(evt:KeyboardEvent):Boolean
		{
			if ((editMode == WFSFeatureEditableMode.EDIT_WIND_BARBS_POINTS) && (evt.keyCode == Keyboard.DELETE)){
				if (m_selectedWindPoint){
					
					removeWindbarbAt(m_selectedWindPointIndex);
					
					ml_windBarbs.removeItemAt(m_selectedWindPointIndex);
					m_windPoints.removeItemAt(m_selectedWindPointIndex);
					
					var reflection: WindReflectionData;
					var totalReflections: uint = ml_movablePoints.totalReflections;
					for (var r: int = 0; r < totalReflections; r++)
					{
						reflection = ml_movablePoints.getReflection(r) as WindReflectionData;
						// REMOVE SELECTED WIND BARB POINT
						reflection.removeWindbarbAt(m_selectedWindPointIndex);
					}					
					selectedWindPointIndex = -1;
					update(FeatureUpdateContext.fullUpdate());
				} else {
					return false;
				}
				
				return true;
			} else {
				return super.onKeyDown(evt);
			}
		}
		
		override public function get reflectionDictionary(): WFSEditableReflectionDictionary
		{
			return ml_movablePoints;
		}
	}
}

import com.iblsoft.flexiweather.ogc.editable.WFSFeatureEditable;
import com.iblsoft.flexiweather.ogc.editable.features.curves.WFSFeatureEditableJetStream;
import com.iblsoft.flexiweather.ogc.wfs.WFSFeatureEditableSprite;
import com.iblsoft.flexiweather.symbology.JetStreamCurveRenderer;
import com.iblsoft.flexiweather.utils.CubicBezier;
import com.iblsoft.flexiweather.utils.geometry.LineSegment;

import flash.display.Sprite;
import flash.geom.Point;

class JetStreamSprite extends WFSFeatureEditableSprite
{
	public var renderer: JetStreamCurveRenderer;
	
	public var m_signsSprite: Sprite = new Sprite();
	public var m_editableSignsSprite: Sprite = new Sprite();
	
	public function JetStreamSprite(feature: WFSFeatureEditable)
	{
		super(feature);
		
		addChild(m_signsSprite);
		addChild(m_editableSignsSprite);
	}
	
	override public function clear(): void
	{
		graphics.clear();
		if (m_signsSprite)
		{
			m_signsSprite.graphics.clear();
		}
		if (m_editableSignsSprite) 
		{
			m_editableSignsSprite.graphics.clear();
		}
	}
	override public function getLineSegmentApproximationOfBounds():Array
	{
		var a: Array = [];
		var ptFirst: Point = null;
		var ptPrev: Point = null;
		
		var jetStreamFeature: WFSFeatureEditableJetStream = _feature as WFSFeatureEditableJetStream;
		var pts: Array = CubicBezier.calculateHermitSpline(points, false);
		
		var useEvery: int = 1;
		if (pts.length > 100){
			useEvery = int(pts.length / 20);
		} else if (pts.length > 50){
			useEvery = int(pts.length / 10);
		}
		
		var actPUse: int = 0;
		for each(var pt: Point in pts) {
			if ((actPUse % useEvery) == 0){
				if(ptPrev != null)
					a.push(new LineSegment(ptPrev.x, ptPrev.y, pt.x, pt.y));
				ptPrev = pt;
			}
			actPUse++;
		}
		
		return a;		
	}
}