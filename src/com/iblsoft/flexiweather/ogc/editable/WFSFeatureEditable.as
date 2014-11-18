package com.iblsoft.flexiweather.ogc.editable
{
	import com.iblsoft.flexiweather.ogc.FeatureUpdateContext;
	import com.iblsoft.flexiweather.ogc.InteractiveLayerFeatureBase;
	import com.iblsoft.flexiweather.ogc.InteractiveLayerWFS;
	import com.iblsoft.flexiweather.ogc.data.ReflectionData;
	import com.iblsoft.flexiweather.ogc.editable.data.FeatureData;
	import com.iblsoft.flexiweather.ogc.editable.data.FeatureDataPoint;
	import com.iblsoft.flexiweather.ogc.editable.data.FeatureDataReflection;
	import com.iblsoft.flexiweather.ogc.editable.data.MoveablePoint;
	import com.iblsoft.flexiweather.ogc.events.MoveablePointEvent;
	import com.iblsoft.flexiweather.ogc.wfs.IWFSFeatureWithReflection;
	import com.iblsoft.flexiweather.ogc.wfs.WFSFeatureBase;
	import com.iblsoft.flexiweather.ogc.wfs.WFSFeatureEditableSprite;
	import com.iblsoft.flexiweather.proj.Coord;
	import com.iblsoft.flexiweather.proj.Projection;
	import com.iblsoft.flexiweather.utils.AnnotationBox;
	import com.iblsoft.flexiweather.utils.ArrayUtils;
	import com.iblsoft.flexiweather.widgets.InteractiveWidget;

	import flash.display.DisplayObject;
	import flash.display.Sprite;
	import flash.events.KeyboardEvent;
	import flash.filters.GlowFilter;
	import flash.geom.Point;
	import flash.ui.Keyboard;
	import flash.utils.Dictionary;

	import mx.utils.ObjectUtil;

	public class WFSFeatureEditable extends WFSFeatureBase implements IEditableItem, IHighlightableItem, ISelectableItem, IWFSFeatureWithReflection
	{
		protected var mb_selected: Boolean;
		protected var mb_highlighted: Boolean;
		protected var mb_modified: Boolean = false;
		protected var m_editableSprite: Sprite = new Sprite();
//		protected var ml_movablePoints: WFSEditableReflectionDictionary;
		protected var mi_editMode: int = WFSFeatureEditableMode.ADD_POINTS_WITH_MOVE_POINTS;
		protected var mn_justSelectable: Boolean;
		protected var mb_useMonochrome: Boolean = false;
		protected var mi_monochromeColor: uint = 0x333333;
		protected var ma_points: Array;
		protected var m_editableItemManager: IEditableItemManager;
		protected var mi_actSelectedMoveablePointIndex: int = -1;
		protected var mi_actSelectedMoveablePointReflectionIndex: int = -1;
		protected var m_firstInit: Boolean = true;

		//new storage dictionaries for GFX (sprites and editable poitns
		private var _reflectionGFXAssets: Dictionary = new Dictionary();

		override public function set visible(value:Boolean):void
		{
			value = value && presentInViewBBox;

			if (super.visible != value)
			{
				super.visible = value;

				changeVisibilityForAnticollsionObjects(value);
			}
		}

		protected function changeVisibilityForAnticollsionObjects(value: Boolean): void
		{
				var iw: InteractiveWidget = m_master.container;
				//all reflection object should
				iw.anticollisionObjectVisible(getAnticollisionObject, value);
				iw.anticollisionObjectVisible(getAnticollisionObstacle, value);
				iw.anticollisionForcedUpdate();

				if (!value)
					editableSpriteVisible(false);
				else
					editableSpriteVisible(mb_selected);

		}
		public function get selectedMoveablePointIndex(): int
		{
			return mi_actSelectedMoveablePointIndex;
		}

		protected var m_featureData: FeatureData;

		public function WFSFeatureEditable(s_namespace: String, s_typeName: String, s_featureId: String)
		{
			super(s_namespace, s_typeName, s_featureId);
			initialize();
		}

		protected function initialize(): void
		{
			//initialize at least 1 reflection...this is temporary solution for creating first point of feature (there are no reflections yet)
			if (!m_featureData)
			{
				m_featureData = createFeatureData();
				m_featureData.getReflectionAt(0);

				editableSpriteVisible(false);
			} else {
				m_featureData.clear();
			}
		}
//		protected function createReflectionDirectory(): void
//		{
//			ml_movablePoints = new WFSEditableReflectionDictionary(master.container);
//		}

		override public function setMaster(master: InteractiveLayerFeatureBase): void
		{
			super.setMaster(master);
//			createReflectionDirectory();
			var masterEditable: InteractiveLayerWFSEditable = master as InteractiveLayerWFSEditable;
			if (masterEditable != null)
				masterEditable.editingComponentsContainer.addChild(m_editableSprite);
		}


		protected function createFeatureData(): FeatureData
		{
			return new FeatureData(this.toString() + " FeatureData");
		}
		/***************************************************************************************************************
		 *
		 * 	Commnon function for retrieving GFX parts needed for displaying features.
		 *
		 *  GFX stored in dictionary for each reflection are:
		 * 		* displaySprite
		 * 		* annotation (if needed)
		 * 		* editable points
		 *
		 *
		 ***************************************************************************************************************/

		private function createReflectionGFXAssetIfNeeded(reflectionDelta: int): void
		{
			if (!_reflectionGFXAssets[reflectionDelta])
				_reflectionGFXAssets[reflectionDelta] = new ReflectionGFXAsset(reflectionDelta);
		}
		/**
		 * This function returns stored WFSFeatureEditableSprite for each reflection. If WFSFeatureEditableSprite was not yet created, it will be created here.
		 *
		 * @param reflectionDelta
		 * @param bAddAsChild if true WFSFeatureEditableSprite will be added to displayList (if it is not there already)
		 * @return WFSFeatureEditableSprite for reflection
		 *
		 */
		public function getDisplaySpriteForReflectionAt(reflectionDelta: int, bAddAsChild: Boolean = true): WFSFeatureEditableSprite
		{
			createReflectionGFXAssetIfNeeded(reflectionDelta);
			var gfxAsset: ReflectionGFXAsset = _reflectionGFXAssets[reflectionDelta] as ReflectionGFXAsset;

			if (!gfxAsset.displaySprite)
			{
				gfxAsset.displaySprite = getDisplaySpriteForReflection(reflectionDelta);

				if (bAddAsChild)
				{
					if (!gfxAsset.displaySprite.parent)
						addChild(gfxAsset.displaySprite);
				}
			}
			return gfxAsset.displaySprite;
		}

		/**
		 * Function used to find out in which reflection (by reflectionDelta) is displaySprite drawn
		 * @param displaySprite
		 * @return
		 *
		 */
		public function getReflectionDeltaFromDisplaySprite(displaySprite: WFSFeatureEditableSprite): int
		{
			for each (var gfxAsset: ReflectionGFXAsset in _reflectionGFXAssets)
			{
				if (gfxAsset.displaySprite == displaySprite)
					return gfxAsset.reflectionDelta;
			}
			return 0;
		}

		public function addAnnotationForReflectionAt(reflectionDelta: int, annotation: AnnotationBox): void
		{
			createReflectionGFXAssetIfNeeded(reflectionDelta);
			var gfxAsset: ReflectionGFXAsset = _reflectionGFXAssets[reflectionDelta] as ReflectionGFXAsset;
			gfxAsset.annotation = annotation;
		}

		public function getAnnotationForReflectionAt(reflectionDelta: int): AnnotationBox
		{
			createReflectionGFXAssetIfNeeded(reflectionDelta);
			var gfxAsset: ReflectionGFXAsset = _reflectionGFXAssets[reflectionDelta] as ReflectionGFXAsset;

			return gfxAsset.annotation;
		}

		public function editablePointForReflectionExist(reflectionDelta: int, pointPosition: int): Boolean
		{
			var gfxAsset: ReflectionGFXAsset = _reflectionGFXAssets[reflectionDelta] as ReflectionGFXAsset;

			if (gfxAsset && gfxAsset.editablePoints && gfxAsset.editablePoints.length > pointPosition)
				return true;
			return false;
		}

		public function getEditablePointsForReflection(reflectionDelta: int): Array
		{
			createReflectionGFXAssetIfNeeded(reflectionDelta);
			var gfxAsset: ReflectionGFXAsset = _reflectionGFXAssets[reflectionDelta] as ReflectionGFXAsset;
			return gfxAsset.editablePoints;
		}

		public function removeAllEditablePointForReflection(reflectionDelta: int): void
		{
			var mp: MoveablePoint;
			var gfxAsset: ReflectionGFXAsset;

			createReflectionGFXAssetIfNeeded(reflectionDelta);
			{
				gfxAsset = _reflectionGFXAssets[reflectionDelta] as ReflectionGFXAsset;
				var editablePoints: Array = gfxAsset.editablePoints;
				if (editablePoints && editablePoints.length > 0)
				{
					while (editablePoints.length > 0)
					{
						mp = editablePoints.splice(0, 1);
						removeMoveablePointListeners(mp);

						m_editableSprite.removeChild(mp);

						var eim: IEditableItemManager = master as IEditableItemManager;
						if (eim != null)
							eim.removeEditableItem(mp);
					}
				}
			}
		}
		public function removeEditablePointForReflectionAt(reflectionDelta: int,  pointPosition: int): void
		{
			var mp: MoveablePoint;
			var gfxAsset: ReflectionGFXAsset;

			createReflectionGFXAssetIfNeeded(reflectionDelta);
			if (editablePointForReflectionExist(reflectionDelta, pointPosition))
			{
				//TODO remove editable point from reflection
				gfxAsset = _reflectionGFXAssets[reflectionDelta] as ReflectionGFXAsset;
				var editablePoints: Array = gfxAsset.editablePoints;
				if (editablePoints && editablePoints.length > pointPosition)
				{
					mp = editablePoints[pointPosition] as MoveablePoint;

					editablePoints.splice(pointPosition, 1);

					if (mp)
					{
						removeMoveablePointListeners(mp);
						m_editableSprite.removeChild(mp);

						var eim: IEditableItemManager = master as IEditableItemManager;
						if (eim != null)
							eim.removeEditableItem(mp);
					}
				}

			}
		}
		public function getEditablePointForReflectionAt(reflectionDelta: int, pointPosition: int): MoveablePoint
		{
			var mp: MoveablePoint;
			var gfxAsset: ReflectionGFXAsset;

			createReflectionGFXAssetIfNeeded(reflectionDelta);
			if (!editablePointForReflectionExist(reflectionDelta, pointPosition))
			{
				gfxAsset = _reflectionGFXAssets[reflectionDelta] as ReflectionGFXAsset;

				//add new MovablePoint (new point was added, so we need to create Movable point for it
				mp = createEditablePoint(this, pointPosition, reflectionDelta);
				//										reflection.addMoveablePoint(mp, i);
				m_editableSprite.addChild(mp);

				var eim: IEditableItemManager = master as IEditableItemManager;
				if (eim != null)
					eim.addEditableItem(mp);

				addMoveablePointListeners(mp);

				gfxAsset.editablePoints[pointPosition] = mp;

			}

			gfxAsset = _reflectionGFXAssets[reflectionDelta] as ReflectionGFXAsset;

			return gfxAsset.editablePoints[pointPosition] as MoveablePoint;
		}

		/**
		 * create new instance of Editable point, if feature needs different point, which extends MoveablePoint, overrie this protected method
		 * and return newly created Editable Point instance. See also WFSFeatureEditableJetStream for example
		 *
		 * @param feature
		 * @param i_pointIndex
		 * @param i_reflectionDelta
		 * @return
		 *
		 */
		protected function createEditablePoint(feature: WFSFeatureEditable, i_pointIndex: uint, i_reflectionDelta: int): MoveablePoint
		{
			return new MoveablePoint(feature, i_pointIndex, i_reflectionDelta);
		}

		/**
		 * This function should be override and return proper  WFSFeatureEditableSprite for each feature type
		 * @param id
		 * @return
		 *
		 */
		public function getDisplaySpriteForReflection(id: int): WFSFeatureEditableSprite
		{
			return null;
		}

		/*
		protected function updateCoordsReflections(): void
		{
			if (!master)
				return;
//			var reflections: Dictionary = new Dictionary();
//			ml_movablePoints.cleanup();
			var total: int = coordinates.length;
			var iw: InteractiveWidget = master.container;
			var crs: String = iw.getCRS();
			for (var i: int = 0; i < total; i++)
			{
				var coord: Coord = coordinates[i] as Coord;
				var pointReflections: Array = iw.mapCoordToViewReflections(coord);
				var reflectionsCount: int = pointReflections.length;
				for (var j: int = 0; j < reflectionsCount; j++)
				{
					var pointReflectedObject: Object = pointReflections[j];
					var pointReflected: Point = pointReflectedObject.point;
					var coordReflected: Coord = new Coord(crs, pointReflected.x, pointReflected.y);
//					trace(this + " updateCoordsReflections coordReflected: " + coordReflected);
					reflectionDictionary.addReflectedCoord(coordReflected, pointReflectedObject.reflection, iw);
				}
			}
		}
		*/

		protected function addMoveablePointListeners(mp: MoveablePoint): void
		{
			if (mp)
			{
				mp.addEventListener(MoveablePointEvent.MOVEABLE_POINT_SELECTION_CHANGE, redispatchMoveablePointEvent);
				mp.addEventListener(MoveablePointEvent.MOVEABLE_POINT_CLICK, redispatchMoveablePointEvent);
				mp.addEventListener(MoveablePointEvent.MOVEABLE_POINT_DOWN, redispatchMoveablePointEvent);
				mp.addEventListener(MoveablePointEvent.MOVEABLE_POINT_DRAG_END, redispatchMoveablePointEvent);
				mp.addEventListener(MoveablePointEvent.MOVEABLE_POINT_DRAG_START, redispatchMoveablePointEvent);
				mp.addEventListener(MoveablePointEvent.MOVEABLE_POINT_MOVE, redispatchMoveablePointEvent);
				mp.addEventListener(MoveablePointEvent.MOVEABLE_POINT_OUT, redispatchMoveablePointEvent);
				mp.addEventListener(MoveablePointEvent.MOVEABLE_POINT_OVER, redispatchMoveablePointEvent);
				mp.addEventListener(MoveablePointEvent.MOVEABLE_POINT_UP, redispatchMoveablePointEvent);
			}
		}

		protected function removeMoveablePointListeners(mp: MoveablePoint): void
		{
			if (mp)
			{
				mp.removeEventListener(MoveablePointEvent.MOVEABLE_POINT_SELECTION_CHANGE, redispatchMoveablePointEvent);
				mp.removeEventListener(MoveablePointEvent.MOVEABLE_POINT_CLICK, redispatchMoveablePointEvent);
				mp.removeEventListener(MoveablePointEvent.MOVEABLE_POINT_DOWN, redispatchMoveablePointEvent);
				mp.removeEventListener(MoveablePointEvent.MOVEABLE_POINT_DRAG_END, redispatchMoveablePointEvent);
				mp.removeEventListener(MoveablePointEvent.MOVEABLE_POINT_DRAG_START, redispatchMoveablePointEvent);
				mp.removeEventListener(MoveablePointEvent.MOVEABLE_POINT_MOVE, redispatchMoveablePointEvent);
				mp.removeEventListener(MoveablePointEvent.MOVEABLE_POINT_OUT, redispatchMoveablePointEvent);
				mp.removeEventListener(MoveablePointEvent.MOVEABLE_POINT_OVER, redispatchMoveablePointEvent);
				mp.removeEventListener(MoveablePointEvent.MOVEABLE_POINT_UP, redispatchMoveablePointEvent);
			}
		}

		private function redispatchMoveablePointEvent(event: MoveablePointEvent): void
		{
			dispatchEvent(event);
		}

		override protected function notifyCoordinateInside(coord: Coord, coordIndex: uint, coordReflection: uint): void
		{
			super.notifyCoordinateInside(coord, coordIndex, coordReflection);

			changeMoveablePointVisibility(coord, coordIndex, coordReflection, true);
		}

		override protected function notifyCoordinateOutside(coord: Coord, coordIndex: uint, coordReflection: uint): void
		{
			super.notifyCoordinateOutside(coord, coordIndex, coordReflection);

			changeMoveablePointVisibility(coord, coordIndex, coordReflection, false);
		}

		private function changeMoveablePointVisibility(coord: Coord, coordIndex: int, coordReflection: int, visible: Boolean): void
		{
			if ( !m_featureData)
				return;

			//hide correct moveable points
			var mp: MoveablePoint;
			var i: uint;

			var reflectionIDs: Array = m_featureData.reflectionsIDs;

			for (var r: int = 0; r < totalReflections; r++)
			{
				var reflectionDelta: int = reflectionIDs[r];
				var reflection: FeatureDataReflection = m_featureData.getReflectionAt(reflectionDelta);
				if (reflection)
				{
					var pTotal: int = reflection.editablePoints.length;
					//					trace("FeatureEditable upate: pTotal: " + pTotal);
					if (coordIndex < pTotal)
					{
//						mp = reflection.moveablePoints[coordIndex] as MoveablePoint;
						mp = getEditablePointForReflectionAt(reflection.reflectionDelta, coordIndex);
						if (mp)
						{
							if (mp.visible != visible)
							{
								mp.visible = visible;
							}
						}
					}
				}
			}
		}

		/**
		 * New implementation of update method through FeatureData
		 * @param changeFlag
		 *
		 */
		protected function updateNewImplementation(changeFlag: FeatureUpdateContext): void
		{
			if (m_featureData)
			{
//				trace("WFSFeatureEditable updateNewImplementation");

				var eim: IEditableItemManager = master as IEditableItemManager;
				var mp: MoveablePoint;
				var i: uint;

				var reflectionIDs: Array = m_featureData.reflectionsIDs;
				var viewBBoxReflections: Array = master.container.viewBBoxReflections();

				var isSame: int = ObjectUtil.compare(reflectionIDs, viewBBoxReflections, 0);

				if (isSame != 0)
				{
					reflectionIDs = m_featureData.updateReflectionIDsWith(viewBBoxReflections);

					//TODO check if featureData.reflections are changes
				}

				for (var r: int = 0; r < totalReflections; r++)
				{
					var reflectionDelta: int = reflectionIDs[r];
					var reflection: FeatureDataReflection = m_featureData.getReflectionAt(reflectionDelta);

					//FIXME needs to updated correctly between reflections, this is temporary solution
					reflection.setEditablePoints(m_points.getPointsForReflection(reflection.reflectionDelta));

					if (reflection)
					{
						var pTotal: int = reflection.editablePoints.length;
						//						var pMoveableTotal: int = reflection.moveablePoints.length;
						//						trace("FeatureEditable upate: pointsTotal: " + pTotal + "  pMoveableTotal: " + pMoveableTotal);
						var cnt: int = 0
						for (i = 0; i < pTotal; ++i)
						{
//							var pt: FeatureDataPoint = reflection.editablePoints[i] as FeatureDataPoint;
							var pt: Point = reflection.editablePoints[i] as Point;
							if (pt)
							{
								var isReflectionEdgePoint: Boolean = false; //pt.isReflectionEdgePoint
								if (!isReflectionEdgePoint)
								{
//									mp = getEditablePointForReflectionAt(reflectionDelta, cnt);
									mp = getEditablePointForReflectionAt(reflectionDelta, i);

										//add new MovablePoint (new point was added, so we need to create Movable point for it
//										mp = new MoveablePoint(this, cnt, r, reflection.reflectionDelta);
//										m_editableSprite.addChild(mp);
//									if (eim != null)
//										eim.addEditableItem(mp);
//										addMoveablePointListeners(mp);
//										continue;
//									mp = pt.movablePoint as MoveablePoint;

									if (pt == null || mp == null)
										continue; // TODO: check for CRS
									var p: Point = mp.getPoint();
									//						trace("WFSFeatureEditable update: pt: " + pt + " p: " + p + " for reflection r: " + r);
									if (p && !p.equals(pt))
									{
										// reuse MoveablePoint instance, just change it's location
										mp.setPoint(pt);
									}
								}
								cnt++;
							}
						}
					}
				}
				if (visible)
					editableSpriteVisible(mb_selected);
			}
		}

		/**
		 * New implementation of update method through FeatureDataReflection
		 * @param changeFlag
		 *
		 */
		/*
		private function updateOldImplementation(changeFlag: FeatureUpdateContext): void
		{
			//m_points is Array of Screen coordinates in pixels
			updateCoordsReflections();

			var eim: IEditableItemManager = master as IEditableItemManager;
			var mp: MoveablePoint;
			var i: uint;

			var reflectionsTotal: int = reflectionDictionary.totalReflections;
			for (var r: int = 0; r < totalReflections; r++)
			{
				var reflection: FeatureDataReflection = reflectionDictionary.getReflection(r) as FeatureDataReflection;
				if (reflection)
				{
					var pTotal: int = reflection.editablePoints.length;
					var pMoveableTotal: int = reflection.moveablePoints.length;
					trace("FeatureEditable upate: pointsTotal: " + pTotal + "  pMoveableTotal: " + pMoveableTotal);
					for (i = 0; i < pTotal; ++i)
					{
						var pt: Point = reflection.editablePoints[i] as Point;
						if (i >= reflection.moveablePoints.length)
						{
							//add new MovablePoint (new point was added, so we need to create Movable point for it
//							mp = new MoveablePoint(this, i, r, reflection.reflectionDelta);
							mp = new MoveablePoint(this, i, reflection.reflectionDelta);
							reflection.addMoveablePoint(mp, i);
							m_editableSprite.addChild(mp);
							if (eim != null)
								eim.addEditableItem(mp);
							addMoveablePointListeners(mp);
							continue;
						}
						mp = reflection.moveablePoints[i] as MoveablePoint;
						if (pt == null || mp == null)
							continue; // TODO: check for CRS
						var p: Point = mp.getPoint()
						//						trace("WFSFeatureEditable update: pt: " + pt + " p: " + p + " for reflection r: " + r);
						if (p && !p.equals(pt))
						{
							// reuse MoveablePoint instance, just change it's location
							mp.setPoint(pt);
						}
					}
				}
			}

			editableSpriteVisible(mb_selected);
		}
		*/

		override public function update(changeFlag: FeatureUpdateContext): void
		{
			super.update(changeFlag);
		}

		protected function updateEditablePoints(changeFlag: FeatureUpdateContext): void
		{
			//NEW IMPLEMENTATION
			updateNewImplementation(changeFlag);

			//OLD implementation
			//updateOldImplementation(changeFlag);
		}

		protected function editableSpriteVisible(bool: Boolean): void
		{
//			trace("WFSFeatureEditable editableSpriteVisible: " + bool);
			m_editableSprite.visible = bool;
			if (justSelectable)
				m_editableSprite.visible = false;
		}

		override public function cleanup(): void
		{
			var masterEditable: InteractiveLayerWFSEditable = master as InteractiveLayerWFSEditable;
			if (masterEditable != null)
				masterEditable.editingComponentsContainer.removeChild(m_editableSprite);
			var reflectionIDs: Array = m_featureData.reflectionsIDs;

			for (var i: int = 0; i < totalReflections; i++)
			{
				var reflectionDelta: int = reflectionIDs[i];
				removeEditablePointForReflectionAt(reflectionDelta, 0);
			}
//			reflectionDictionary.cleanup();
			super.cleanup();
		}

		public function get getAnticollisionObject(): DisplayObject
		{
			return null;
		}
		public function get getAnticollisionObstacle(): DisplayObject
		{
			return editableSprite;
		}

		public function get editableSprite(): WFSFeatureEditableSprite
		{
			if (totalReflections > 0)
			{
				return getDisplaySpriteForReflectionAt(0);
			}
			return null;
		}

		public function renderFallbackGraphics(i_preferredColor: uint = 0x5A90B1): void
		{
			graphics.clear();
			graphics.lineStyle(1, i_preferredColor);
			if (m_points.length == 1)
			{
				graphics.beginFill(i_preferredColor);
				graphics.drawRoundRect(m_points[0].x - 4, m_points[0].y - 4, 9, 9, 6, 6);
				graphics.endFill();
			}
			else
			{
				for (var i: uint = 0; i < m_points.length; ++i)
				{
					if (i == 0)
						graphics.moveTo(m_points[i].x, m_points[i].y);
					else
						graphics.lineTo(m_points[i].x, m_points[i].y);
				}
			}
		}

		public function toInsertGML(xmlInsert: XML): void
		{
		}

		public function toUpdateGML(xmlUpdate: XML): void
		{
		}

		public function fromGML(gml: XML): void
		{
			// IF I'M INPORTING FEATURE FROM SOME XML, THIS IS ALREADY FINISHED FIRST EDITING MODE
			m_firstInit = false;
		}

		public function isInternal(): Boolean
		{
			return false;
		}

		/**
		 * This method will be called when WFS feature will be created as result of split.
		 * Do whatever is needed after split in this method
		 *
		 */
		public function afterSplit(): void
		{

		}

		public function clone(): WFSFeatureEditable
		{
			var o: Object = this;
			var c: Class = o.constructor;
			var f: WFSFeatureEditable = new c(
					this.ms_namespace, this.ms_typeName, null);
			var xml: XML = <Feature/>
					;
			//var xml: XML = <Feature xmlns="http://www.iblsoft.com/wfs" xmlns:wfs="http://www.opengis.net/wfs" xmlns:gml="http://www.opengis.net/gml" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" />;
			this.toInsertGML(xml);
			f.fromGML(xml);
			return f;
		}

		// helper methods for GML serialisation
		public function addInsertGMLProperty(xmlInsert: XML,
				s_namespace: String, s_property: String, value: Object): void
		{
			if (s_namespace == null)
				s_namespace = ms_namespace;
			var p: XML = <{s_property} xmlns={s_namespace}/>
					;
			p.appendChild(value);
			xmlInsert.appendChild(p);
		}

		public function addUpdateGMLProperty(xmlUpdate: XML,
				s_namespace: String, s_property: String, value: Object): void
		{
			if (s_namespace == null)
				s_namespace = ms_namespace;
			var p: XML = <wfs:Property xmlns:wfs="http://www.opengis.net/wfs"/>;
			p.appendChild(<wfs:Name xmlns:wfs="http://www.opengis.net/wfs" xmlns={s_namespace}>{s_property}</wfs:Name>);

			if (value)
			{
				var v: XML = <wfs:Value xmlns:wfs="http://www.opengis.net/wfs"/>;
				v.appendChild(value);
				p.appendChild(v);
			}

			xmlUpdate.appendChild(p);
		}

		// point/location manipulation helpers
		public function setPoint(i_pointIndex: uint, pt: Point, i_reflectionDelta: int): IMouseEditableItem
		{
//			insertPointBefore(i_pointIndex, pt, i_reflectionDelta);

			//STEP 1 - add point to 0 reflection

			var reflectionWidth: Number = 0;
			if (i_reflectionDelta != 0)
				reflectionWidth = master.container.getExtentBBox().width * i_reflectionDelta;
			var c: Coord = m_master.container.pointToCoord(pt.x, pt.y);

			//need to move coord to 0 reflection
			var projection: Projection = m_master.container.getCRSProjection();
			c = projection.moveCoordToExtent(c);

			//and cound correct point position for 0 reflection
			var newPt: Point = m_master.container.coordToPoint(c);
			m_points.setPoint(newPt, i_pointIndex, 0)
			m_coordinates[i_pointIndex] = c;

//			trace("WFSFEatureEditable setPoint : from c: " + c.toLaLoCoord() + " to pt: " + newPt + " old pt: " + pt);



			var newPoint: IMouseEditableItem;
			//STEP 2 - add it to reflection, in which was added (if it was not added in 0th reflection)
//			if (i_reflectionDelta != 0)
//			{
//				var totalMoveablePoints: int = getEditablePointsForReflection(0).length;
//
//				var reflection: FeatureDataReflection = m_featureData.getReflectionAt(i_reflectionDelta);
//				newPoint = getEditablePointForReflectionAt(i_reflectionDelta, i_pointIndex) as IMouseEditableItem;
//			}

			update(FeatureUpdateContext.fullUpdate());
			modified = true;

			return newPoint;
		}

		public function selectPreviousMoveablePoint(): void
		{
			var newSelectionIndex: int = Math.max(0, mi_actSelectedMoveablePointIndex - 1);
			selectMoveablePoint(newSelectionIndex, mi_actSelectedMoveablePointReflectionIndex);
		}

		public function selectNextMoveablePoint(): void
		{
			var newSelectionIndex: int = Math.min(m_points.length - 1, mi_actSelectedMoveablePointIndex + 1);
			selectMoveablePoint(newSelectionIndex, mi_actSelectedMoveablePointReflectionIndex);
		}

		/**
		 *
		 */
		public function selectMoveablePoint(i_pointIndex: int, i_reflection: int): void
		{
			var actSelPoint: MoveablePoint;
			// DESELECT ALL POINT
			var i: int;
			var reflection: FeatureDataReflection;

			var reflectionIDs: Array = m_featureData.reflectionsIDs;


			for (i = 0; i < totalReflections; i++)
			{
				var reflectionDelta: int = reflectionIDs[i];
				reflection = m_featureData.getReflectionAt(reflectionDelta);
				if (reflection)
				{
					var editablePoints: Array = getEditablePointsForReflection(reflection.reflectionDelta);
					for each (var mp: MoveablePoint in editablePoints)
					{
						mp.selected = false;
					}
				}
			}
			if ((i_pointIndex >= 0) && (i_pointIndex < m_points.length))
			{ // IF SELECTED POINT IS IN m_points RANGE
				reflection = m_featureData.getReflectionAt(i_reflection) as FeatureDataReflection;
				if (reflection)
				{
					// SELECT NEW
					var selPoint: MoveablePoint = getEditablePointForReflectionAt(reflection.reflectionDelta, i_pointIndex);
					if (selPoint)
					{
						selPoint.selected = true;
						mi_actSelectedMoveablePointIndex = i_pointIndex;
						mi_actSelectedMoveablePointReflectionIndex = i_reflection;

						var mpe: MoveablePointEvent = new MoveablePointEvent(MoveablePointEvent.MOVEABLE_POINT_SELECTION_CHANGE, true);
						mpe.feature = this;
						mpe.point = selPoint;
						mpe.x = selPoint.x;
						mpe.y = selPoint.y;
						dispatchEvent(mpe);
					} else
					{
						mi_actSelectedMoveablePointIndex = -1;
						mi_actSelectedMoveablePointReflectionIndex = -1;
					}
				} else {
					mi_actSelectedMoveablePointIndex = -1;
					mi_actSelectedMoveablePointReflectionIndex = -1;
				}
			}
			else
			{
				mi_actSelectedMoveablePointIndex = -1;
				mi_actSelectedMoveablePointReflectionIndex = -1;
			}
		}

		override public function addPointAt(point: Point, index: uint, reflectionID: int = 0): void
		{
			insertPointBefore(index, point, reflectionID);
		}

		override public function addPoint(pt: Point, reflectionID: int = 0): void
		{
			insertPointBefore(m_points.length, pt, reflectionID);
		}

		override public function insertPointBefore(i_pointIndex: uint, pt: Point, reflectionID: int = 0): void
		{
			super.insertPointBefore(i_pointIndex, pt, reflectionID);
			modified = true;
		}

		public function removePointAt(i_pointIndex: uint, reflectionID: int = 0): void
		{
			m_points.removePointAt(i_pointIndex, reflectionID);
			m_coordinates.splice(i_pointIndex, 1);

			removeMoveablePointAt(i_pointIndex);
			if (mi_actSelectedMoveablePointIndex == i_pointIndex)
			{
				//point was selected, select other poin
				selectPreviousMoveablePoint();
			}
			invalidatePoints();
			update(FeatureUpdateContext.fullUpdate());
		}

		private function removeMoveablePointAt(i: int): void
		{
			var eim: IEditableItemManager = master as IEditableItemManager;
			var reflectionIDs: Array = m_featureData.reflectionsIDs;

			for (var r: int = 0; r < totalReflections; r++)
			{
				var reflectionDelta: int = reflectionIDs[r];
				var reflection: FeatureDataReflection = m_featureData.getReflectionAt(reflectionDelta);
				if (reflection)
				{
					removeEditablePointForReflectionAt(reflection.reflectionDelta, i);
				}
			}
		}

		public function deselect(): void
		{
			if (selected)
			{
				m_editableItemManager.selectItem(null);
				m_firstInit = false;
			}
		}

		public function snapPoint(ptClicked: Point, ignoredFeature: WFSFeatureEditable = null): Point
		{
			var ptClickedStage: Point = localToGlobal(ptClicked);
			var a_snapPoints: Array = m_editableItemManager.doHitTest(
					ptClickedStage.x, ptClickedStage.y, MoveablePoint, false);
			for each (var mp: MoveablePoint in a_snapPoints)
			{
				if (ignoredFeature != null && mp.getFeature() == ignoredFeature)
					continue;
				return mp.getPoint();
			}
			return ptClicked;
		}

		// IEditableItem implementation
		public function onRegisteredAsEditableItem(eim: IEditableItemManager): void
		{
			m_editableItemManager = eim;
			var reflectionIDs: Array = m_featureData.reflectionsIDs;

			for (var i: int = 0; i < totalReflections; i++)
			{
				var reflectionDelta: int = reflectionIDs[i];

				var reflection: FeatureDataReflection = m_featureData.getReflectionAt(reflectionDelta);
				if (reflection)
				{
					var editablePoints: Array = getEditablePointsForReflection(reflection.reflectionDelta);
					for each (var mp: MoveablePoint in editablePoints)
					{
						m_editableItemManager.addEditableItem(mp);
					}
				}
			}
		}

		public function onUnregisteredAsEditableItem(eim: IEditableItemManager): void
		{
			var reflectionIDs: Array = m_featureData.reflectionsIDs;

			for (var i: int = 0; i < totalReflections; i++)
			{
				var reflectionDelta: int = reflectionIDs[i];

				var reflection: FeatureDataReflection = m_featureData.getReflectionAt(reflectionDelta);
				if (reflection)
				{
					var editablePoints: Array = getEditablePointsForReflection(reflection.reflectionDelta);
					for each (var mp: MoveablePoint in editablePoints)
					{
						eim.removeEditableItem(mp);
					}
				}
			}
		}

		public function get editPriority(): int
		{
			return 50;
		}

		// IHighlightableItem implementation
		public function canReleaseHighlight(): Boolean
		{
			return true;
		}

		public function set highlighted(b: Boolean): void
		{
			if (mb_highlighted != b)
			{
				mb_highlighted = b;
				updateGlow();
			}
		}

		public function get highlighted(): Boolean
		{
			return mb_highlighted;
		}

		public function invalidateGlow(): void
		{
			updateGlow();
		}
		protected function updateGlow(): void
		{
			if (mb_selected != m_editableSprite.visible)
				editableSpriteVisible(mb_selected);
			if (!mb_highlighted && !mb_selected)
			{
				removeGlowFilter();
				return;
			}
			var i_innerGlowColor: uint = 0;
			var i_outterGlowColor: uint = 0;
			if (mb_highlighted)
				i_innerGlowColor = 0xffffff;
			if (mb_selected)
				i_outterGlowColor = 0xffff00;
			setGlowFilter(i_innerGlowColor, i_outterGlowColor);
		}

		protected function removeGlowFilter(): void
		{
			filters = null;
			var reflectionIDs: Array = m_featureData.reflectionsIDs;

			for (var r: int = 0; r < totalReflections; r++)
			{
				var reflectionDelta: int = reflectionIDs[r];
				var reflection: FeatureDataReflection = m_featureData.getReflectionAt(reflectionDelta);
				var displaySprite: WFSFeatureEditableSprite = getDisplaySpriteForReflectionAt(reflectionDelta);
				if (displaySprite)
					displaySprite.filters = null;
			}
		}

		/**
		 * Set glow filter to the feature, if you need to set glow to any other display objects override this function.
		 *
		 * @param i_innerGlowColor
		 * @param i_outterGlowColor
		 *
		 */
		protected function setGlowFilter(i_innerGlowColor: uint, i_outterGlowColor: uint): void
		{
			var filterArray: Array = [new GlowFilter(i_innerGlowColor, 1, 6, 6, 2), new GlowFilter(i_outterGlowColor, 1, 8, 8, 4)];

			var reflectionIDs: Array = m_featureData.reflectionsIDs;
			for (var r: int = 0; r < totalReflections; r++)
			{
				var reflectionDelta: int = reflectionIDs[r];
				var reflection: FeatureDataReflection = m_featureData.getReflectionAt(reflectionDelta) as FeatureDataReflection;
				if (reflection)
				{
					var displaySprite: WFSFeatureEditableSprite = getDisplaySpriteForReflectionAt(reflectionDelta);
					if (displaySprite)
						displaySprite.filters = filterArray;

					filters = null;
				}
				else
					filters = filterArray;
			}
		}

		/**
		 *
		 */
		public function onKeyDown(evt: KeyboardEvent): Boolean
		{
			if (evt.keyCode == Keyboard.DELETE)
			{
				if (mb_selected && (mi_actSelectedMoveablePointIndex > -1) && (m_points.length > 1) && (mi_actSelectedMoveablePointIndex < m_points.length))
				{
//					removeMoveablePointAt(mi_actSelectedMoveablePointIndex);
//
//					ml_movablePoints.removeReflectedCoordAt(mi_actSelectedMoveablePointIndex);
//					m_points.removeItemAt(mi_actSelectedMoveablePointIndex);
//
//					trace("FeatureEditable m_points: " + m_points.length + " ml_movablePoints: " + ml_movablePoints.totalMoveablePoints);
//
//					update(FeatureUpdateContext.fullUpdate());

					removePointAt(mi_actSelectedMoveablePointIndex);

					if ((mi_actSelectedMoveablePointIndex >= 0) && (mi_actSelectedMoveablePointIndex < m_points.length))
						selectMoveablePoint(mi_actSelectedMoveablePointIndex, mi_actSelectedMoveablePointReflectionIndex);
					else if (mi_actSelectedMoveablePointIndex >= m_points.length)
						selectMoveablePoint(m_points.length - 1, mi_actSelectedMoveablePointReflectionIndex);
					else
						selectMoveablePoint(-1, -1);
					return true;
				}
				else
					return false;
			}
			else
				return false;
		}

		/**
		 * It returns color, which was entered as clr parameter. If feature need to use monochromeColor (in Collaboration Feature Editor) it will return value of monochrome color.
		 * @param clr
		 * @return
		 *
		 */
		public function getCurrentColor(clr: uint): uint
		{
			if (useMonochrome)
				clr = monochromeColor;
			else if (master && master.useMonochrome)
				clr = master.monochromeColor;
			return clr;
		}

		public function set selected(b: Boolean): void
		{
			if (mb_selected != b)
			{
				mb_selected = b;
				updateGlow();
			}
		}

		public function get selected(): Boolean
		{
			return mb_selected;
		}

		public function set modified(b: Boolean): void
		{
			mb_modified = b;
		}

		public function get modified(): Boolean
		{
			return mb_modified;
		}

		public function set justSelectable(v: Boolean): void
		{
			mn_justSelectable = v;
		}

		public function get justSelectable(): Boolean
		{
			return mn_justSelectable;
		}

		public function set editMode(v: int): void
		{
			mi_editMode = v;
		}

		public function get editMode(): int
		{
			return mi_editMode;
		}

		public function set useMonochrome(val: Boolean): void
		{
			var b_needUpdate: Boolean = false;
			if (mb_useMonochrome != val)
				b_needUpdate = true;
			mb_useMonochrome = val;
			if (b_needUpdate)
				update(FeatureUpdateContext.fullUpdate());
		}

		public function get useMonochrome(): Boolean
		{
			return mb_useMonochrome;
		}

		public function set monochromeColor(i_color: uint): void
		{
			var b_needUpdate: Boolean = false;
			if (mb_useMonochrome && (mi_monochromeColor != i_color))
				b_needUpdate = true;
			mi_monochromeColor = i_color;
			if (b_needUpdate)
				update(FeatureUpdateContext.fullUpdate());
		}

		public function get monochromeColor(): uint
		{
			return mi_monochromeColor;
		}

		public function set firstInit(value: Boolean): void
		{
			m_firstInit = value;
		}

		public function get firstInit(): Boolean
		{
			return m_firstInit;
		}

		public function get featureData(): FeatureData
		{
			return m_featureData;
		}

		public function getReflection(id: int): FeatureDataReflection
		{
			if (m_featureData)
				return m_featureData.getReflectionAt(id) as FeatureDataReflection;
			return null;
		}

		public function get totalReflections(): int
		{
			if (m_featureData && m_featureData.reflections)
				return m_featureData.reflectionsLength;
			return 0;
		}
		public function totalReflectionEditablePoints(reflectionDelta: int): int
		{
			if (m_featureData)
			{
				var reflection: FeatureDataReflection = getReflection(reflectionDelta);
				if (reflection)
					return reflection.editablePoints.length;
			}
			return 0;
		}

//		public function get reflectionDictionary(): WFSEditableReflectionDictionary
//		{
//			return ml_movablePoints;
//		}
	}
}
import com.iblsoft.flexiweather.ogc.wfs.WFSFeatureEditableSprite;
import com.iblsoft.flexiweather.utils.AnnotationBox;

import flash.utils.Dictionary;

class ReflectionGFXAsset
{
	public var reflectionDelta: int;
	public var displaySprite: WFSFeatureEditableSprite;
	public var annotation: AnnotationBox;
	public var editablePoints: Array;

	public function ReflectionGFXAsset(reflectionDelta: int)
	{
		this.reflectionDelta = reflectionDelta;
		editablePoints = new Array();
	}
}