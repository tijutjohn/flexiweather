package com.iblsoft.flexiweather.ogc.editable.features.curves
{
	import com.iblsoft.flexiweather.ogc.FeatureUpdateContext;
	import com.iblsoft.flexiweather.ogc.InteractiveLayerFeatureBase;
	import com.iblsoft.flexiweather.ogc.data.ReflectionData;
	import com.iblsoft.flexiweather.ogc.editable.IEditableItemManager;
	import com.iblsoft.flexiweather.ogc.editable.WFSFeatureEditable;
	import com.iblsoft.flexiweather.ogc.editable.WFSFeatureEditableCurveWithBaseTimeAndValidity;
	import com.iblsoft.flexiweather.ogc.editable.WFSFeatureEditableMode;
	import com.iblsoft.flexiweather.ogc.editable.data.FeatureData;
	import com.iblsoft.flexiweather.ogc.editable.data.FeatureDataReflection;
	import com.iblsoft.flexiweather.ogc.editable.data.MoveablePoint;
	import com.iblsoft.flexiweather.ogc.editable.data.jetstream.JetStreamFeatureData;
	import com.iblsoft.flexiweather.ogc.editable.data.jetstream.JetStreamFeatureDataReflection;
	import com.iblsoft.flexiweather.ogc.editable.data.jetstream.MoveableWindPoint;
	import com.iblsoft.flexiweather.ogc.editable.data.jetstream.WindBarb;
	import com.iblsoft.flexiweather.ogc.editable.data.jetstream.WindMoveablePointsDictionary;
	import com.iblsoft.flexiweather.ogc.editable.data.jetstream.WindReflectionData;
	import com.iblsoft.flexiweather.ogc.editable.events.WindBarbChangeEvent;
	import com.iblsoft.flexiweather.ogc.wfs.IWFSFeatureWithReflection;
	import com.iblsoft.flexiweather.ogc.wfs.WFSFeatureEditableSprite;
	import com.iblsoft.flexiweather.proj.Coord;
	import com.iblsoft.flexiweather.proj.Projection;
	import com.iblsoft.flexiweather.symbology.FrontCurveRenderer;
	import com.iblsoft.flexiweather.symbology.JetStreamCurveRenderer;
	import com.iblsoft.flexiweather.utils.CubicBezier;
	import com.iblsoft.flexiweather.utils.Hemisphere;
	import com.iblsoft.flexiweather.utils.ICurveRenderer;
	import com.iblsoft.flexiweather.utils.draw.DrawMode;
	import com.iblsoft.flexiweather.widgets.InteractiveWidget;

	import flash.display.Graphics;
	import flash.display.Sprite;
	import flash.events.EventDispatcher;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.geom.ColorTransform;
	import flash.geom.Point;
	import flash.ui.Keyboard;
	import flash.utils.Dictionary;

	import mx.collections.ArrayCollection;
	import mx.core.Application;
	import mx.core.FlexGlobals;

	/**
	 * For front styles see for example http://en.wikipedia.org/wiki/Weather_front
	 **/
	public class WFSFeatureEditableJetStream extends WFSFeatureEditableCurveWithBaseTimeAndValidity implements IWFSFeatureWithReflection
	{
		public var values:Object;

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

		//on which hemisphere is JetStream (one of Hemisphere constansts). JetStream can not cross equator (physically)
		protected var m_hemisphere: String;

		/**
		 *
		 */
		public function WFSFeatureEditableJetStream(s_namespace: String, s_typeName: String, s_featureId: String)
		{
			super(s_namespace, s_typeName, s_featureId);

			m_hemisphere = Hemisphere.NORTHERN_HEMISPHERE;

		}

//		override protected function createReflectionDirectory(): void
//		{
//			ml_movablePoints = new WindMoveablePointsDictionary(master.container);
//
//		}

		private function debug(txt: String): void
		{
//			trace("JetStream: " + txt);
		}

		override public function getRenderer(reflection: int): ICurveRenderer
		{
			var i_color: uint = getCurrentColor(0x000000);
			var gr: Graphics = getRendererGraphics(reflection);

			return new JetStreamCurveRenderer(gr, 4, i_color, 1.0);
		}

		override protected function createFeatureData():FeatureData
		{
			return new JetStreamFeatureData(this.toString() + " JetStreamFeatureData");
		}

		private var _currentFeatureUpdateContext: FeatureUpdateContext;

		override public function update(changeFlag: FeatureUpdateContext): void
		{
			if (!master)
				return;

			if (mb_destroying)
				return;

			_currentFeatureUpdateContext = changeFlag;

			debug("\n\n WFSFeatureEditableCurveWithBaseTimeAndValidity update");
			super.update(changeFlag);
		}

		override protected function updateNewImplementation(changeFlag: FeatureUpdateContext): void
		{
//			debug(" updateNewImplementation");
			//Jet Stream needs its own editable points creation routine
			super.updateNewImplementation(changeFlag);
		}

//		override public function update(changeFlag: FeatureUpdateContext): void
//		{
//			if (!master)
//				return;
//		}

		override protected function computeCurve():void
		{
			debug(" computeCurve");

			if (!_currentFeatureUpdateContext.windbarbsChanged)
				super.computeCurve();

			invalidateWindbarbs();
			updateWindPointsReflections();

			var windBarbsCanBeDrawed: Boolean = true;

			// WE NEED ALWAYS RECOMPUTE POINTS
			// RECOMPUTE WIND POINTS IF NEEDED

			var iw: InteractiveWidget = m_master.container;

			var r: uint;
			var reflection: JetStreamFeatureDataReflection;

			var reflectionIDs: Array = m_featureData.reflectionsIDs;
			var totalWindBarbs: int = m_windPoints.length;

			var crsProjection: Projection = iw.getCRSProjection();
			var currentWindbarbPosition: int = 0;

			for(var i: uint = 0; i < totalWindBarbs; ++i)
			{
				var pt: Point = m_windPoints.getItemAt(i) as Point;
				var windbarb: WindBarb = ml_windBarbs.getItemAt(i) as WindBarb;
				var c: Coord = windbarb.coordinate;
				if (c.crs != crsProjection.crs)
					c = c.convertToProjection(crsProjection);

				var coordReflections: Array = master.container.mapCoordToViewReflections(c);
				debug("windbarb: ["+i+"]: " + windbarb);

				if (coordReflections && coordReflections.length > 0)
				{
					var mp: MoveableWindPoint = null;
					var reflectedMP: MoveableWindPoint = null;
					var reflectedWindbarb: WindBarb = null;
					var cancelDraggingMP: MoveableWindPoint = null;
					for (r = 0; r < totalReflections; r++)
					{
						var reflectionDelta: int = reflectionIDs[r];
						reflection = m_featureData.getReflectionAt(reflectionDelta) as JetStreamFeatureDataReflection;

						if (reflection && reflection.windbarbs && reflection.windbarbs.length > currentWindbarbPosition)
						{
							var currWindbarb: WindBarb = WindBarb(reflection.windbarbs[currentWindbarbPosition]);

							for each (var coordReflectionsObject: Object in coordReflections)
							{
								if (coordReflectionsObject.reflection == reflectionDelta)
								{
									reflectedMP = getEditableWindPointForReflectionAt(reflectionDelta, currentWindbarbPosition) as MoveableWindPoint;
									reflectedWindbarb = currWindbarb;
									var cReflected: Coord = new Coord(c.crs, coordReflectionsObject.point.x, coordReflectionsObject.point.y);
									reflectedWindbarb.coordinate = cReflected;
									reflectedWindbarb.point = iw.coordToPoint(cReflected);
									if (cancelDraggingMP)
									{
										reflectedMP.captureMouse();
										reflectedWindbarb.captureMouse();
									}
								} else {
									mp = getEditableWindPointForReflectionAt(reflectionDelta, currentWindbarbPosition) as MoveableWindPoint;
									if (mp && mp.isDragging)
									{
										// wind point, which was dragged lost it's
										cancelDraggingMP = mp;
										cancelDraggingMP.releaseMouse();
										if (reflectedMP)
										{
											reflectedMP.captureMouse();
											reflectedWindbarb.captureMouse();
										}
									}

								}
							}
							currentWindbarbPosition++;
						}
					}
				}
			}

			//remove windbarbs which was not updated...
			hideInvalidateWindbarbs();

		}


		override protected function drawCurve(): void
		{
//			debug(" drawCurve");
			graphics.clear();

			var r: uint;
			var reflection: JetStreamFeatureDataReflection;

			var coords: Array = [];
			var a_points: Array = getPoints();
			var featureReflections: Array;

			var i_color: uint = 0x000000;
			i_color = getCurrentColor(i_color);

			m_hemisphere = Hemisphere.hemisphereForCoord(m_coordinates[0] as Coord);

			if (master)
			{

				// CREATE WIND BARBS
				var nColorTransform: ColorTransform;
				var gr: Graphics;
				var jetStreamSprite: JetStreamSprite;
				var reflectionIDs: Array = m_featureData.reflectionsIDs;

				var bWindbarbsDrawn: Boolean = false;

				for (r = 0; r < totalReflections; r++)
				{
					reflection = m_featureData.getReflectionAt(reflectionIDs[r]) as JetStreamFeatureDataReflection;
					if (reflection)
					{
						var reflectionDelta: int = reflection.reflectionDelta;
						a_points = reflection.points;
//						a_points = reflection.editablePoints;

						jetStreamSprite = getDisplaySpriteForReflectionAt(reflectionDelta) as JetStreamSprite;
						gr = jetStreamSprite.graphics;

						jetStreamSprite.points = a_points;

						if (!jetStreamSprite.renderer)
						{

							jetStreamSprite.renderer = getRenderer(reflectionDelta) as JetStreamCurveRenderer;
						}
						jetStreamSprite.renderer.setColor(i_color);
						var curvePoints: Array;

						if (!_currentFeatureUpdateContext.windbarbsChanged)
						{
							jetStreamSprite.clear();
							gr.clear();

							if (m_featureData.reflectionDelta == reflectionDelta)
							{
								drawFeatureData(jetStreamSprite.renderer, m_featureData);
							} else {
								trace("\t\t Do not draw data for " + reflectionDelta + " Feature is drawn in " + m_featureData.reflectionDelta);
							}
						} else {
							trace("_currentFeatureUpdateContext.windbarbsChanged reflectionDelta: " + reflectionDelta)
						}
						curvePoints = reflection.points;

						//we store curvePoints for later usage (find reflected jetstream closest to the point in onMouseDown function)
						reflection.jetstreamCurvePoints = curvePoints;

						var windPointsCanBeCreated: Boolean = createWindPoints(m_featureData, reflectionDelta);
						if (m_featureData.reflectionDelta == reflectionDelta)
						{
							if(!windPointsCanBeCreated)
							{
								// CREATE COLOR TRANSFORM
								nColorTransform = new ColorTransform(1, 0, 0, 1, 255, 0, 0, 0);
							} else {
								bWindbarbsDrawn = true;
								nColorTransform = new ColorTransform(1, 1, 1, 1, 0, 0, 0, 0);

								if (useMonochrome){
									nColorTransform.color = monochromeColor;
								}
							}
							if (nColorTransform)
								jetStreamSprite.transform.colorTransform = nColorTransform;
						}


					}
				}
			}

			changeVisibility();
		}

		override public function getDisplaySpriteForReflection(id:int):WFSFeatureEditableSprite
		{
			return new JetStreamSprite(this);
		}

		private function changeVisibility(): void
		{
			var r: uint;

			var reflectionIDs: Array = m_featureData.reflectionsIDs;
			for (r = 0; r < totalReflections; r++)
			{
				var reflectionDelta: int = reflectionIDs[r];
				var reflection: JetStreamFeatureDataReflection = m_featureData.getReflectionAt(reflectionDelta) as JetStreamFeatureDataReflection;

				var jetStreamSprite: JetStreamSprite = getDisplaySpriteForReflectionAt(reflection.reflectionDelta) as JetStreamSprite;

				if (jetStreamSprite)
				{
					if ((editMode == WFSFeatureEditableMode.EDIT_WIND_BARBS_POINTS) && selected){
						// HIDE CURVE POINTS
						editableSpriteVisible(false);
						jetStreamSprite.m_editableSignsSprite.visible = true;
					} else if (selected){
						editableSpriteVisible(true);
						jetStreamSprite.m_editableSignsSprite.visible = false;
					} else {
						editableSpriteVisible(false);
						jetStreamSprite.m_editableSignsSprite.visible = false;
					}
				}
			}

		}

		override protected function editableSpriteVisible(bool: Boolean): void
		{
			if (editMode == WFSFeatureEditableMode.EDIT_WIND_BARBS_POINTS)
				bool = false;

			super.editableSpriteVisible(bool)
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
		protected function createWindPoints(featureData: FeatureData, reflectionDelta: int): Boolean
		{
			debug(" createWindPoints: " + reflectionDelta);
			var ret: Boolean = true;

			var eim: IEditableItemManager = IEditableItemManager(m_master);

			var mp: MoveableWindPoint;
			var cp: WFSFeatureEditableJetStreamWindBarb;
			var i: uint;
			var i_color: uint = 0x000000;

			i_color = getCurrentColor(i_color);

			var iw: InteractiveWidget = m_master.container;

//			totalReflections = 1;

			var reflection: JetStreamFeatureDataReflection = m_featureData.getReflectionAt(reflectionDelta) as JetStreamFeatureDataReflection;
			var curvePoints: Array = featureData.points; //reflection.points;
			reflection.jetstreamCurvePoints = curvePoints;

			var jetStreamSprite: JetStreamSprite = getDisplaySpriteForReflectionAt(reflectionDelta) as JetStreamSprite;

			var totalWindBarbs: int = reflection.windbarbs.length;
			var windbarb: WindBarb;
			var windbardCanBeDrawn: Boolean;

			for(i = 0; i < totalWindBarbs; ++i)
			{
				if(i >= reflection.totalWindPoints)
				{
//					mp = new MoveableWindPoint(this, i, reflection.reflectionDelta);
					mp = getEditableWindPointForReflectionAt(reflectionDelta, i) as MoveableWindPoint;
					if (mp)
					{
						windbarb = WindBarb(reflection.windbarbs[i]);

						if (windbarb.point)
						{
							var windbarPosition: int = findNearestCurvePoint(windbarb.point, curvePoints)
							cp = getWindbarbGFXAssetForReflectionAt(reflectionDelta, windbarPosition, curvePoints, windbarb, i_color, m_hemisphere);

							windbardCanBeDrawn = cp.canBeDrawed;

							ret = ret && windbardCanBeDrawn;

							reflection.addWindMoveablePoint(mp, i, cp);

							jetStreamSprite.m_editableSignsSprite.addChild(mp);
							eim.addEditableItem(mp);

							jetStreamSprite.m_signsSprite.addChild(cp);
							if (windbarb.needToCaptureMouse)
							{
								mp.captureMouse();
								windbarb.captureMouseDone();
							}
						} else {
							trace("Need to fix windbarb.point == null, i: " + i + " totalWindBarbs: " + totalWindBarbs);
						}
						continue;
					} else {
						trace("JetStream: mp == null");
					}
				}

				mp = reflection.windPoints[i] as MoveableWindPoint;
				cp = reflection.editableJetStreamWindbarbs[i] as WFSFeatureEditableJetStreamWindBarb;

				windbarb = reflection.windbarbs[i] as WindBarb;
				var pt: Point = windbarb.point;

				mp.setPoint(pt);

				//TODO  curvePoints are currently pixels position, but "pt" is reflected "pt" => need to recount "pt" point to current screen pixel position
//				if (ml_windBarbs.length > i)
//				{
					var c1: Coord = windbarb.coordinate;

//					var wbCoordPoint: Point = new Point(c1.x, c1.y);
					//and we need "r"th reflection of it
					var reflectedPoints: Array = iw.mapCoordToViewReflections(c1);

					var wbPoint: Point = null;
					for each (var refObj: Object in reflectedPoints)
					{
						if (refObj.reflection == reflectionDelta)
						{
							wbPoint = refObj.point as Point;
							break;
						}
					}

					if (wbPoint)
					{
						var cReflected: Coord = new Coord(iw.crs, wbPoint.x, wbPoint.y);
						wbPoint = iw.coordToPoint(cReflected);
						var close: uint = findNearestCurvePoint(wbPoint, curvePoints);

						cp.update(curvePoints, close, windbarb, i_color);
						ret = ret && cp.canBeDrawed;
					} else {
						//windbarb is not visible
						trace("How to find position for invisible (wbPoint == null) position");
						cp.update(curvePoints, close, windbarb, i_color);

					}
				}
//			}

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
			debug(" removeWindbarbAt: " + position);
			var j:int;
			var reflectionIDs: Array = m_featureData.reflectionsIDs;
			for (j = 0; j < totalReflections; j++)
			{
				removeWindbarbFromReflectionAt(reflectionIDs[j], position);
			}

		}

		private function removeWindbarbFromReflectionAt(reflectionDelta: int, position: int): void
		{
			var eim: IEditableItemManager = IEditableItemManager(m_master);
			var mp: MoveableWindPoint;
			var cp: WFSFeatureEditableJetStreamWindBarb;
			var reflection: JetStreamFeatureDataReflection = m_featureData.getReflectionAt(reflectionDelta) as JetStreamFeatureDataReflection;
			var jetStreamSprite: JetStreamSprite = getDisplaySpriteForReflectionAt(reflectionDelta) as JetStreamSprite;

//			for(; i < reflection.totalWindPoints; ++i)
//			{
			mp = reflection.windPoints[position] as MoveableWindPoint;
			cp = reflection.editableJetStreamWindbarbs[position] as WFSFeatureEditableJetStreamWindBarb;
			if (mp)
			{
				eim.removeEditableItem(mp);
				if (cp.parent && mp.parent == jetStreamSprite.m_editableSignsSprite)
					jetStreamSprite.m_editableSignsSprite.removeChild(mp);
			}
			if (cp && cp.parent && cp.parent == jetStreamSprite.m_signsSprite)
				jetStreamSprite.m_signsSprite.removeChild(cp);
//				}
//				while(reflection.windbarbs.length < reflection.totalWindPoints) {
//					reflection.windPoints.pop();
//				}
		}
		/*
		private function cleanupWindbarbs(): void
		{
			debug(" cleanupWindbarbs");
			var i:int;
			var j:int;
			var eim: IEditableItemManager = IEditableItemManager(m_master);
			var mp: MoveableWindPoint;
			var cp: WFSFeatureEditableJetStreamWindBarb;

			var reflectionIDs: Array = m_featureData.reflectionsIDs;
			for (j = 0; j < totalReflections; j++)
			{
				var reflection: JetStreamFeatureDataReflection = m_featureData.getReflectionAt(reflectionIDs[j]) as JetStreamFeatureDataReflection;
				var jetStreamSprite: JetStreamSprite = getDisplaySpriteForReflectionAt(reflection.reflectionDelta) as JetStreamSprite;

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
		*/
		/**
		 * Function for creating jetstream
		 *
		 */
		private function updateWindPointsReflections(): void
		{
//			debug("updateWindPointsReflections");

			var recreateMode: Boolean = false; //editMode != WFSFeatureEditableMode.EDIT_WIND_BARBS_POINTS && editMode != WFSFeatureEditableMode.MOVE_POINTS;

			var j: uint;
			var crs: String = master.container.getCRS();
			var coord: Coord;
			var coordReflections: Array;
			var reflectionsCount: int;
			var coordReflectedObject: Object;
			var coordReflected: Coord;

			var iw: InteractiveWidget = m_master.container;
			var reflection: JetStreamFeatureDataReflection;

//			recreate windbarbs
			var totalWindbarbs: int = ml_windBarbs.length;
			var cnt: int = -1;
			var crsProjection: Projection = iw.getCRSProjection();
			for (var w: int = 0; w < totalWindbarbs; w++)
			{
				var windbarb: WindBarb = ml_windBarbs.getItemAt(w) as WindBarb;

				coord = windbarb.coordinate;
				if (coord.crs != crsProjection.crs)
					coord = coord.convertToProjection(crsProjection);

				coordReflections = master.container.mapCoordToViewReflections(coord);
				reflectionsCount = coordReflections.length;

				if (reflectionsCount > 0)
				{
					cnt++;
					for (j = 0; j < reflectionsCount; j++)
					{
						coordReflectedObject = coordReflections[j];
						coordReflected = new Coord(crs, coordReflectedObject.point.x, coordReflectedObject.point.y);

						var reflectionDelta: int = coordReflectedObject.reflection;
						reflection = m_featureData.getReflectionAt(reflectionDelta) as JetStreamFeatureDataReflection;

						if (reflection)
						{
							var currReflectedWindbarb: WindBarb = windbarb.clone();
							currReflectedWindbarb.coordinate = coord;

							if (recreateMode)
							{
								reflection.addWindbarbAt(currReflectedWindbarb, cnt);//, j, reflectionDelta);
							} else {
								reflection.updateWindbarbAt(currReflectedWindbarb, cnt);//, j, reflectionDelta);
							}
						}

					}
				}
			}

		}

		private function hideInvalidateWindbarbs(): void
		{
			var r: uint;

			var reflectionIDs: Array = m_featureData.reflectionsIDs;
			for (r = 0; r < totalReflections; r++)
			{
				var reflectionDelta: int = reflectionIDs[r];
				var reflection: JetStreamFeatureDataReflection = m_featureData.getReflectionAt(reflectionDelta) as JetStreamFeatureDataReflection;
				var windbarbs: ArrayCollection = reflection.windbarbs;
				for (var i: int = 0; i < windbarbs.length;)
				{
					var windbarb: WindBarb = windbarbs.getItemAt(i) as WindBarb;
					if (!windbarb.isValid())
					{
						debug("Hide windbarb at position: " + i + " is invalid. Total windbarbs: " + windbarbs.length);
						removeWindbarbFromReflectionAt(reflectionDelta, i);
						reflection.removeWindbarbAt(i);
					} else {
						debug("show windbarb at position: " + i + " is valid. Total windbarbs: " + windbarbs.length);
						i++;
					}
				}
			}
		}
		private function invalidateWindbarbs(): void
		{
			if (!m_featureData)
				return;

			var r: uint;

			var reflectionIDs: Array = m_featureData.reflectionsIDs;
			for (r = 0; r < totalReflections; r++)
			{
				var reflectionDelta: int = reflectionIDs[r];
				var reflection: JetStreamFeatureDataReflection = m_featureData.getReflectionAt(reflectionDelta) as JetStreamFeatureDataReflection;
				var windbarbs: ArrayCollection = reflection.windbarbs;
				for each (var windbarb: WindBarb in windbarbs)
				{
					windbarb.invalidate();
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
			var reflection: JetStreamFeatureDataReflection = m_featureData.getReflectionAt(reflectionID) as JetStreamFeatureDataReflection;
			if (reflection && reflection.windbarbs && reflection.windbarbs.length > i_pointIndex)
				return (WindBarb(reflection.windbarbs[i_pointIndex]).point);
			return null;
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

			if (m_featureData)
			{
				if (i_pointIndex > -1)
				{
					var reflectionsIDs: Array = m_featureData.reflectionsIDs;
					for (var i: int = 0; i < totalReflections; i++)
					{
						var reflectionDelta: int = reflectionsIDs[i];
						var reflection: JetStreamFeatureDataReflection = m_featureData.getReflectionAt(reflectionDelta) as JetStreamFeatureDataReflection;

						if (reflection && reflection.windPoints && reflection.windPoints.length > i_pointIndex)
						{
							var mp: MoveableWindPoint = MoveableWindPoint(reflection.windPoints[i_pointIndex]);

							if (mp.position == null)
							{
								var windbarb: WindBarb = reflection.windbarbs.getItemAt(i_pointIndex) as WindBarb;
								if (windbarb.point)
								{
									mp.invalidatePosition();
								}
							}
							m_selectedWindPoint = mp;
							m_selectedWindPoint.selected = true;

							// SEND EVENT ABOUT CHANGE OF SELECTED WIND POINT
							var nEvent: WindBarbChangeEvent = new WindBarbChangeEvent(WindBarbChangeEvent.WIND_BARB_SELECTION_CHANGE, reflection.windbarbs[m_selectedWindPointIndex]);

							dispatchEvent(nEvent);
							return;
						}
					}
					m_selectedWindPoint = null;
				} else {
					m_selectedWindPoint = null;
				}
			}
		}

		/**
		 *
		 */
		public function setWindPoint(i_pointIndex: int, pt: Point, i_reflectionDelta: int): void
		{
			debug(" setWindPoint");
			//FIXME we need to know, for which reflection it was dragged
//			trace("SET WIND POINT for reflection: " + i_reflectionDelta);

			var iw: InteractiveWidget = m_master.container;

			var coord: Coord = iw.pointToCoord(pt.x, pt.y);

			if (i_reflectionDelta != 0)
			{
				//wind point of reflected jet stream was set, need to count original jet stream wind point position
//				var deltas: Array = [-1*i_reflectionDelta];
				var deltas: Array = [i_reflectionDelta];
				var p: Point = new Point(coord.x, coord.y);
				var reflectedCoords: Array = iw.mapCoordInCRSToViewReflectionsForDeltas(p, deltas);

				var reflectedCoordPoint: Point =  reflectedCoords[0].point as Point;
				var cReflected: Coord = new Coord(iw.crs, reflectedCoordPoint.x, reflectedCoordPoint.y);
				WindBarb(ml_windBarbs[i_pointIndex]).coordinate = cReflected;
				WindBarb(ml_windBarbs[i_pointIndex]).point = iw.coordToPoint(cReflected);
			} else {

				//wind point on original jet stream was set

				WindBarb(ml_windBarbs[i_pointIndex]).point = pt.clone();
				WindBarb(ml_windBarbs[i_pointIndex]).coordinate = iw.pointToCoord(pt.x, pt.y);
			}

			update(new FeatureUpdateContext(FeatureUpdateContext.WINDBARB_CHANGE));
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
				if (points[i])
				{
					tDist = Point.distance(fPoint, Point(points[i]));
					if (tDist <= fDist){
						fDist = tDist;
						fIndex = i;
					}
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

			var reflection0: JetStreamFeatureDataReflection = m_featureData.getReflectionAt(m_featureData.reflectionsIDs[0]) as JetStreamFeatureDataReflection;
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

			var reflection0: JetStreamFeatureDataReflection = m_featureData.getReflectionAt(m_featureData.reflectionsIDs[0]) as JetStreamFeatureDataReflection;
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

			var iw: InteractiveWidget = m_master.container;

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
			var distanceMax: Number = Number.MAX_VALUE;

			var closestReflection: int = 0

			var reflectionIDs: Array = m_featureData.reflectionsIDs;
			for (var r: int = 0; r < totalReflections; r++)
			{
				var reflectionDelta: int = reflectionIDs[r];
				var reflection: JetStreamFeatureDataReflection = m_featureData.getReflectionAt(reflectionDelta) as JetStreamFeatureDataReflection;
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


				var reflection: JetStreamFeatureDataReflection;
				var reflectionDelta: int;

				var bool: Boolean;

				var hitWindPointInAnyReflection: Boolean;
				var createNewPoint: Boolean;
				var createdInReflection: int = 0;

				var reflectionIDs: Array = m_featureData.reflectionsIDs;
				for (var r: int = 0; r < totalReflections; r++)
				{
					reflectionDelta = reflectionIDs[r];
					reflection = m_featureData.getReflectionAt(reflectionDelta) as JetStreamFeatureDataReflection;

					var jetStreamSprite: JetStreamSprite = getDisplaySpriteForReflectionAt(reflectionDelta) as JetStreamSprite;

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
						createdInReflection = reflectionDelta;
					}
				}

				if (createNewPoint && !hitWindPointInAnyReflection)
				{
					//find reflection
					var pIndex: uint = findNearestCurvePoint(pt, m_curvePoints);

					var iw: InteractiveWidget = m_master.container;

					// ADD NEW WIND BARB POINT
					var nWindBarb: WindBarb = new WindBarb();

					var coord: Coord = iw.pointToCoord(pt.x, pt.y);

					//FIXME all reflections have point in 0th reflection ---need to fix this in update() function
					nWindBarb.coordinate = coord;

					nWindBarb.windSpeed = 85;
					nWindBarb.flightLevel = 0;
					nWindBarb.below = 0;
					nWindBarb.above = 0;

					updateJetStreamWindBarbUI(nWindBarb);

					 //we need to save this to local variables and not only to reflections to be able to recreate reflection in updateWindPointsReflections() function
					if (createdInReflection != 0)
					{
						//wind point of reflected jet stream was set, need to count original jet stream wind point position
						var deltas: Array = [1*createdInReflection];
						var pCoord: Point = new Point(coord.x, coord.y);
						var reflectedCoords: Array = iw.mapCoordInCRSToViewReflectionsForDeltas(pCoord, deltas);

						var reflectedCoordPoint: Point =  reflectedCoords[0].point as Point;
						var cReflected: Coord = new Coord(iw.crs, reflectedCoordPoint.x, reflectedCoordPoint.y);
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

//					var reflectionIDs: Array = m_featureData.reflectionsIDs;
					for (r = 0; r < totalReflections; r++)
					{
						reflectionDelta = reflectionIDs[r];
						reflection = m_featureData.getReflectionAt(reflectionDelta) as JetStreamFeatureDataReflection;
						reflection.windbarbs.addItem(nWindBarb.clone());
					}

					//selectedWindPointIndex needs to be set after update() method when new windPoint is created
//					selectedWindPointIndex = ml_windBarbs.length - 1;
					bool = true;
				}



				if (bool)
				{
					update(FeatureUpdateContext.fullUpdate());
					//this is correct - selectedWindPointIndex needs to be set after update() method when new windPoint is created
					selectedWindPointIndex = ml_windBarbs.length - 1;
					return(true);
				} else {
					return(false);
				}

			} else {
				return(super.onMouseDown(pt,event));
			}
			return false;
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
			debug("editMode = " + i_mode);
			super.editMode = i_mode;

			if (editMode != WFSFeatureEditableMode.EDIT_WIND_BARBS_POINTS){
				selectedWindPointIndex = -1;
			}

//			update(FeatureUpdateContext.fullUpdate());
			update(new FeatureUpdateContext(FeatureUpdateContext.WINDBARB_CHANGE));
		}

		private var _editor: IJetStreamEditorGUI;

		//TODO better implement JetStream bindable function to remove dependency on FeatureEditorWidget
		public function setBindableFunctions(content: IJetStreamEditorGUI): void
		{
			_editor = content;
			if (!content.hasEventListener(WindBarbChangeEvent.WIND_BARB_CHANGE)){
				content.addEventListener(WindBarbChangeEvent.WIND_BARB_CHANGE, onChangeWindBarbContentValues);
			}

			addEventListener(WindBarbChangeEvent.WIND_BARB_SELECTION_CHANGE, updateJetStreamWindBarb);
		}

		public function resetBindableFunctions(content: IJetStreamEditorGUI): void
		{
			if (content.hasEventListener(WindBarbChangeEvent.WIND_BARB_CHANGE)){
				content.removeEventListener(WindBarbChangeEvent.WIND_BARB_CHANGE, onChangeWindBarbContentValues);
			}

			removeEventListener(WindBarbChangeEvent.WIND_BARB_SELECTION_CHANGE, updateJetStreamWindBarb);
		}

		private function updateJetStreamWindBarb(event: WindBarbChangeEvent): void
		{
			debug(" updateJetStreamWindBarb");
			updateJetStreamWindBarbUI(event.data as WindBarb);
		}

		private function updateJetStreamWindBarbUI(windBarb: WindBarb): void
		{
			debug(" updateJetStreamWindBarbUI");
			if (_editor)
				_editor.updateJetStreamWindBard(windBarb);
		}

		/**
		 *
		 */
		public function onChangeWindBarbContentValues(evt: WindBarbChangeEvent): void
		{
			if (m_selectedWindPoint != null){

				var wb: WindBarb = ml_windBarbs.getItemAt(m_selectedWindPointIndex) as WindBarb;

				wb.windSpeed = WindBarb(evt.data).windSpeed;
				wb.flightLevel = WindBarb(evt.data).flightLevel;
				wb.above = WindBarb(evt.data).above;
				wb.below = WindBarb(evt.data).below;


//				var reflectionIDs: Array = m_featureData.reflectionsIDs;
//				for (r = 0; r < totalReflections; r++)
//				{
//					var reflectionDelta: int = reflectionIDs[r];
//					var reflection: JetStreamFeatureDataReflection = m_featureData.getReflectionAt(reflectionDelta) as JetStreamFeatureDataReflection;
//
//					var wb: WindBarb = WindBarb(reflection.windbarbs[m_selectedWindPointIndex]);
//
//					wb.windSpeed = WindBarb(evt.data).windSpeed;
//					wb.flightLevel = WindBarb(evt.data).flightLevel;
//					wb.above = WindBarb(evt.data).above;
//					wb.below = WindBarb(evt.data).below;
//				}
				update(FeatureUpdateContext.fullUpdate());
				modified = true;
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

					var reflectionIDs: Array = m_featureData.reflectionsIDs;
					for (var r: int = 0; r < totalReflections; r++)
					{
						var reflectionDelta: int = reflectionIDs[r];
						var reflection: JetStreamFeatureDataReflection = m_featureData.getReflectionAt(reflectionDelta) as JetStreamFeatureDataReflection;
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

			return false;
		}


		/*************************************************************************************************
		 *
		 * 	GFX assets
		 *
		 * 	Specific GFX assets from JetStream. All other GFX assets functionality for editable Features
		 *  is in WFSFeatureEditable class
		 *
		 *************************************************************************************************/
		//new storage dictionaries for GFX (sprites and editable poitns
		private var _windbarbReflectionGFXAssets: Dictionary = new Dictionary();

		private function createReflectionGFXAssetIfNeeded(reflectionDelta: int): void
		{
			if (!_windbarbReflectionGFXAssets[reflectionDelta])
				_windbarbReflectionGFXAssets[reflectionDelta] = new WindBarbReflectionGFXAsset(reflectionDelta);
		}

		private function getEditableWindPointForReflectionAt(reflectionDelta: int, pointPosition: int): MoveableWindPoint
		{
//			debug(" getEditableWindPointForReflectionAt reflectionDelta: " + reflectionDelta + " pointPosition: " + pointPosition);

			var mp: MoveableWindPoint;
			var gfxAsset: WindBarbReflectionGFXAsset;

			createReflectionGFXAssetIfNeeded(reflectionDelta);
			if (!editableWindPointForReflectionExist(reflectionDelta, pointPosition))
			{
				gfxAsset = _windbarbReflectionGFXAssets[reflectionDelta] as WindBarbReflectionGFXAsset;

				//add new MovablePoint (new point was added, so we need to create Movable point for it
				mp = new MoveableWindPoint(this, pointPosition, reflectionDelta);
				//										reflection.addMoveablePoint(mp, i);
//				m_editableSprite.addChild(mp);
//
//				var eim: IEditableItemManager = master as IEditableItemManager;
//				if (eim != null)
//					eim.addEditableItem(mp);
//
//				addMoveablePointListeners(mp);
				gfxAsset.windPoints[pointPosition] = mp;

			}

			gfxAsset = _windbarbReflectionGFXAssets[reflectionDelta] as WindBarbReflectionGFXAsset;

			return gfxAsset.windPoints[pointPosition] as MoveableWindPoint;
		}

		private function editableWindPointForReflectionExist(reflectionDelta: int, pointPosition: int): Boolean
		{
			var gfxAsset: WindBarbReflectionGFXAsset = _windbarbReflectionGFXAssets[reflectionDelta] as WindBarbReflectionGFXAsset;

			if (gfxAsset && gfxAsset.windPoints && gfxAsset.windPoints.length > pointPosition)
				return true;
			return false;
		}
		private function editableWindBarbForReflectionExist(reflectionDelta: int, pointPosition: int): Boolean
		{
			var gfxAsset: WindBarbReflectionGFXAsset = _windbarbReflectionGFXAssets[reflectionDelta] as WindBarbReflectionGFXAsset;

			if (gfxAsset && gfxAsset.windbarbs)
				if (gfxAsset.windbarbs[pointPosition] != null)
					return true;
			return false;
		}

		private function getWindbarbGFXAssetForReflectionAt(reflectionDelta: int, pointPosition: int, points: Array, windBarbDef: WindBarb, i_color: uint, s_hemisphere: String): WFSFeatureEditableJetStreamWindBarb
		{
			debug(" getWindbarbGFXAssetForReflectionAt reflectionDelta: " + reflectionDelta + " pointPosition: " + pointPosition);

			var windBarbAsset: WFSFeatureEditableJetStreamWindBarb;
			var gfxAsset: WindBarbReflectionGFXAsset;

			createReflectionGFXAssetIfNeeded(reflectionDelta);
			if (!editableWindBarbForReflectionExist(reflectionDelta, pointPosition))
			{
				gfxAsset = _windbarbReflectionGFXAssets[reflectionDelta] as WindBarbReflectionGFXAsset;

				//add new MovablePoint (new point was added, so we need to create Movable point for it
				windBarbAsset = new WFSFeatureEditableJetStreamWindBarb(points, pointPosition, windBarbDef, i_color, s_hemisphere);
				//										reflection.addMoveablePoint(mp, i);
//				m_editableSprite.addChild(mp);
//
//				var eim: IEditableItemManager = master as IEditableItemManager;
//				if (eim != null)
//					eim.addEditableItem(mp);
//
//				addMoveablePointListeners(mp);

				gfxAsset.windbarbs[pointPosition] = windBarbAsset;

			}

			gfxAsset = _windbarbReflectionGFXAssets[reflectionDelta] as WindBarbReflectionGFXAsset;

			return gfxAsset.windbarbs[pointPosition] as WFSFeatureEditableJetStreamWindBarb;
		}

//		override protected function createEditablePoint(feature: WFSFeatureEditable, i_pointIndex: uint, i_reflectionDelta: int): MoveablePoint
//		{
//			return new MoveableWindPoint(feature, i_pointIndex, i_reflectionDelta);
//		}

	}
}

import com.iblsoft.flexiweather.ogc.editable.WFSFeatureEditable;
import com.iblsoft.flexiweather.ogc.editable.features.curves.WFSFeatureEditableJetStream;
import com.iblsoft.flexiweather.ogc.editable.features.curves.WFSFeatureEditableJetStreamWindBarb;
import com.iblsoft.flexiweather.ogc.wfs.WFSFeatureEditableSprite;
import com.iblsoft.flexiweather.symbology.JetStreamCurveRenderer;
import com.iblsoft.flexiweather.utils.CubicBezier;
import com.iblsoft.flexiweather.utils.geometry.LineSegment;
import com.iblsoft.flexiweather.widgets.InteractiveWidget;

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

	override public function getPointsForLineSegmentApproximationOfBounds(): Array
	{
		var jetStreamFeature: WFSFeatureEditableJetStream = _feature as WFSFeatureEditableJetStream;
		var iw: InteractiveWidget = jetStreamFeature.master.container;

		//distanceValidator, pixelDistanceValidator, datelineBetweenPixelPositions
		var pts: Array = CubicBezier.calculateHermitSpline(points, false, iw.pixelDistanceValidator, iw.datelineBetweenPixelPositions);

		return pts;
	}
}

class WindBarbReflectionGFXAsset
{
	public var reflectionDelta: int;
	public var windbarbs: Array;
	public var windPoints: Array;

	public function WindBarbReflectionGFXAsset(reflectionDelta: int)
	{
		this.reflectionDelta = reflectionDelta;
		this.windbarbs = [];
		this.windPoints = [];
	}
}