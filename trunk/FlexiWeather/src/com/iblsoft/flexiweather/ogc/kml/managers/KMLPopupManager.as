package com.iblsoft.flexiweather.ogc.kml.managers
{
	import com.iblsoft.flexiweather.ogc.events.FeatureEvent;
	import com.iblsoft.flexiweather.ogc.kml.controls.KMLInfoWindow;
	import com.iblsoft.flexiweather.ogc.kml.controls.KMLInfoWindowArrowPosition;
	import com.iblsoft.flexiweather.ogc.kml.events.KMLFeatureEvent;
	import com.iblsoft.flexiweather.ogc.kml.features.KML;
	import com.iblsoft.flexiweather.ogc.kml.features.KMLFeature;
	import com.iblsoft.flexiweather.ogc.kml.features.ScreenOverlay;
	import com.iblsoft.flexiweather.proj.Coord;
	import com.iblsoft.flexiweather.utils.ScreenUtils;
	import com.iblsoft.flexiweather.widgets.InteractiveWidget;
	
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.Sprite;
	import flash.display.Stage;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.utils.Dictionary;
	
	import mx.controls.IFlexContextMenu;
	import mx.core.IFlexDisplayObject;
	import mx.events.CloseEvent;
	import mx.events.ResizeEvent;
	import mx.managers.PopUpManager;

	public class KMLPopupManager
	{
		private static var instance: KMLPopupManager;

		public static function getInstance(): KMLPopupManager
		{
			if (!instance)
				instance = new KMLPopupManager();
			return instance;
		}
		private var windowsDictionary: Dictionary;

		public function KMLPopupManager()
		{
			windowsDictionary = new Dictionary();
		}

		public function centerPopUpOnFeature(popUp: IFlexDisplayObject): void
		{
			var feature: KMLFeature = getFeatureForPopUp(popUp);
			var displaySprite: Sprite = feature.visibleDisplaySprite;
			if (!displaySprite)
			{
				popUp.visible = false;
				return;
			}
			var windObject: Object = getDictionaryItemForPopUp(popUp);
			popUp.visible = true;
			var featureParent: DisplayObjectContainer = feature.parent;
			var stage: Stage = feature.stage;
			
			var popupDisp: DisplayObject = popUp as DisplayObject;
			
			_checkFeatureVisibilityChange = true;
			
			if (stage)
			{
				var xDiff: int = -1 * popUp.width / 2;
				var yDiff: int = -1 * (popUp.height + displaySprite.height);
				if (popUp is KMLInfoWindow)
					xDiff = -1 * (popUp as KMLInfoWindow).arrowPointerX;
						
//				var position: Point = new Point(displaySprite.x + xDiff, displaySprite.y + yDiff);
//				var stagePosition: Point = stage.globalToLocal(featureParent.localToGlobal(position));
				
				var position: Point = new Point(displaySprite.x, displaySprite.y);
				var stagePosition: Point = stage.globalToLocal(featureParent.localToGlobal(position));
//				var stagePosition: Point = position;
				
				
				//find correct position
//				var bounds: Dictionary = new Dictionary();
				var willBeVisible: Boolean;
				var direction: String;
				var kmlInfoWindow: KMLInfoWindow = popUp as KMLInfoWindow;
				var directions: Array = [kmlInfoWindow.arrowPosition, KMLInfoWindowArrowPosition.BOTTOM_CENTER, KMLInfoWindowArrowPosition.TOP_CENTER, KMLInfoWindowArrowPosition.BOTTOM_LEFT, KMLInfoWindowArrowPosition.BOTTOM_RIGHT, KMLInfoWindowArrowPosition.TOP_LEFT, KMLInfoWindowArrowPosition.TOP_RIGHT ];
				
				while (directions.length > 0)
				{
					direction = directions.shift();
					var rectangle: Rectangle = kmlInfoWindow.getBoundsForPosition(stagePosition.x, stagePosition.y, direction);
					
					willBeVisible = ScreenUtils.willBeFullVisible(popupDisp, new Point(rectangle.x, rectangle.y), windObject.container);
//					trace("centerPopUpOnFeature direction: " + direction + " check for position: " + stagePosition.x +  ", " + stagePosition.y + " Will Be Visible: " + willBeVisible + "  rect: " + rectangle);
					if (willBeVisible)
					{
						kmlInfoWindow.arrowPosition = direction;
						break;
					}
						
				}
				
				if (willBeVisible)
				{
					position = new Point(rectangle.x, rectangle.y);
					ScreenUtils.moveSpriteToButHideWhenNotFullOnScreen(popUp as DisplayObject, position, windObject.container);
				} else {
					kmlInfoWindow.visible = false;
				}
			}
			
			_checkFeatureVisibilityChange = false;
		}
		
		private var _checkFeatureVisibilityChange: Boolean;

		public function addPopUp(popUp: IFlexDisplayObject, parent: DisplayObject, feature: KMLFeature, container: InteractiveWidget, reflectionID: uint): IFlexDisplayObject
		{
			var window: IFlexDisplayObject = getPopUpForFeature(feature, reflectionID);
			if (window)
			{
				//window is already opened, do not do anything
				return window;
			}
			PopUpManager.addPopUp(popUp, parent);
			feature.addEventListener(KMLFeatureEvent.KML_FEATURE_POSITION_CHANGE, onKMLFeaturePositionChange);
			feature.addEventListener(KMLFeatureEvent.KML_FEATURE_VISIBILITY_CHANGE, onKMLFeatureVisibilityChange);
			feature.addEventListener(FeatureEvent.COORDINATE_INVISIBLE, onCoordinateInvisible);
			feature.addEventListener(FeatureEvent.COORDINATE_VISIBLE, onCoordinateVisible);
			popUp.addEventListener(ResizeEvent.RESIZE, onPopupResize);
			popUp.addEventListener(CloseEvent.CLOSE, onInfoWindowClose);
			windowsDictionary[popUp] = {feature: feature, window: popUp, container: container, reflection: reflectionID};
			return popUp;
		}

		public function removePopUp(popUp: IFlexDisplayObject): void
		{
			PopUpManager.removePopUp(popUp);
			//remove popup from dictionary
			for each (var winObject: Object in windowsDictionary)
			{
				var window: IFlexDisplayObject = winObject.window as IFlexDisplayObject;
				if (window == popUp)
				{
					if (window.hasEventListener(ResizeEvent.RESIZE))
						window.addEventListener(ResizeEvent.RESIZE, onPopupResize);
					if (window.hasEventListener(CloseEvent.CLOSE))
						window.removeEventListener(CloseEvent.CLOSE, onInfoWindowClose);
					var feature: KMLFeature = winObject.feature as KMLFeature;
					feature.removeEventListener(KMLFeatureEvent.KML_FEATURE_POSITION_CHANGE, onKMLFeaturePositionChange);
					feature.removeEventListener(KMLFeatureEvent.KML_FEATURE_VISIBILITY_CHANGE, onKMLFeatureVisibilityChange);
					feature.removeEventListener(FeatureEvent.COORDINATE_INVISIBLE, onCoordinateInvisible);
					feature.removeEventListener(FeatureEvent.COORDINATE_VISIBLE, onCoordinateVisible);
					delete windowsDictionary[window];
				}
			}
		}

		private function getDictionaryItemForPopUp(popUp: IFlexDisplayObject): Object
		{
			for each (var winObject: Object in windowsDictionary)
			{
				var window: IFlexDisplayObject = winObject.window as IFlexDisplayObject;
				if (window == popUp)
				{
					return winObject;
				}
			}
			return null;
		}
		private function getFeatureForPopUp(popUp: IFlexDisplayObject): KMLFeature
		{
			for each (var winObject: Object in windowsDictionary)
			{
				var window: IFlexDisplayObject = winObject.window as IFlexDisplayObject;
				if (window == popUp)
				{
					var feature: KMLFeature = winObject.feature as KMLFeature;
					return feature;
				}
			}
			return null;
		}

		public function getPopUpForFeature(feature: KMLFeature, reflectionID: uint): IFlexDisplayObject
		{
			for each (var winObject: Object in windowsDictionary)
			{
				var currFeature: KMLFeature = winObject.feature as KMLFeature;
				var currReflectionID: uint = winObject.reflection as uint;
				if (feature == currFeature && reflectionID == currReflectionID)
				{
					var window: IFlexDisplayObject = winObject.window as IFlexDisplayObject;
					return window;
				}
			}
			return null;
		}

		public function bringToFront(popUp: IFlexDisplayObject): void
		{
			PopUpManager.bringToFront(popUp);
		}

		private function onInfoWindowClose(event: CloseEvent): void
		{
			var window: IFlexDisplayObject = event.currentTarget as IFlexDisplayObject;
			window.removeEventListener(CloseEvent.CLOSE, onInfoWindowClose);
			removePopUp(window);
		}

		private function onCoordinateVisible(event: FeatureEvent): void
		{
			var feature: KMLFeature = event.target as KMLFeature
			var window: IFlexDisplayObject = getPopUpForFeature(feature, event.coordinateReflection);
			window.visible = event.insideViewBBox; //feature.visible;
		}
		
		private function onCoordinateInvisible(event: FeatureEvent): void
		{
			var feature: KMLFeature = event.target as KMLFeature
			var window: IFlexDisplayObject = getPopUpForFeature(feature, event.coordinateReflection);
			window.visible = event.insideViewBBox; //feature.visible;
		}
		
		private function onKMLFeatureVisibilityChange(event: KMLFeatureEvent): void
		{
//				var window: IFlexDisplayObject = getPopUpForFeature(event.kmlFeature);
//				window.visible = event.kmlFeature.visible;
//				bringToFront(window);
//				
//				trace("onKMLFeatureVisibilityChange window.visible: " + window.visible);
		}

		private function onPopupResize(event: ResizeEvent): void
		{
			var window: IFlexDisplayObject = event.target as IFlexDisplayObject;
			centerPopUpOnFeature(window);
			bringToFront(window);
		}
		
		private function onKMLFeaturePositionChange(event: KMLFeatureEvent): void
		{
			var window: IFlexDisplayObject = getPopUpForFeature(event.kmlFeature, event.reflectionID);
			
			var p: Point = event.kmlFeature.getPoint(0);
			var c: Coord = event.kmlFeature.coordinates[0];
			var iw: InteractiveWidget = event.kmlFeature.master.container;
			if (iw && c)
			{
				var isInside: Boolean = iw.coordInside(c);
			}
			
			centerPopUpOnFeature(window);
			bringToFront(window);
		}
	}
}
