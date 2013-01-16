package com.iblsoft.flexiweather.ogc.kml.managers
{
	import com.iblsoft.flexiweather.ogc.kml.controls.KMLInfoWindow;
	import com.iblsoft.flexiweather.ogc.kml.events.KMLFeatureEvent;
	import com.iblsoft.flexiweather.ogc.kml.features.KMLFeature;
	import com.iblsoft.flexiweather.utils.ScreenUtils;
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.Sprite;
	import flash.display.Stage;
	import flash.geom.Point;
	import flash.utils.Dictionary;
	import mx.controls.IFlexContextMenu;
	import mx.core.IFlexDisplayObject;
	import mx.events.CloseEvent;
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
			popUp.visible = true;
			var featureParent: DisplayObjectContainer = feature.parent;
			var stage: Stage = feature.stage;
			if (stage)
			{
				var xDiff: int = -1 * popUp.width / 2;
//				var yDiff: int = -1 * (popUp.height + feature.kmlIcon.height);
				var yDiff: int = -1 * (popUp.height + displaySprite.height);
				if (popUp is KMLInfoWindow)
					xDiff = -1 * (popUp as KMLInfoWindow).arrowPointerX
				//				var position: Point = new Point(feature.x + xDiff, feature.y + yDiff);
				var position: Point = new Point(displaySprite.x + xDiff, displaySprite.y + yDiff);
				var stagePosition: Point = stage.globalToLocal(featureParent.localToGlobal(position));
				ScreenUtils.moveSpriteToButHideWhenNotFullOnScreen(popUp as DisplayObject, stagePosition);
//				ScreenUtils.moveSpriteToButKeepFullyOnScreen(popUp as DisplayObject, stagePosition);
			}
		}

		public function addPopUp(popUp: IFlexDisplayObject, parent: DisplayObject, feature: KMLFeature): IFlexDisplayObject
		{
			var window: IFlexDisplayObject = getPopUpForFeature(feature);
			if (window)
			{
				//window is already opened, do not do anything
				return window;
			}
			PopUpManager.addPopUp(popUp, parent);
			feature.addEventListener(KMLFeatureEvent.KML_FEATURE_POSITION_CHANGE, onKMLFeaturePositionChange);
			feature.addEventListener(KMLFeatureEvent.KML_FEATURE_VISIBILITY_CHANGE, onKMLFeatureVisibilityChange);
			popUp.addEventListener(CloseEvent.CLOSE, onInfoWindowClose);
			windowsDictionary[popUp] = {feature: feature, window: popUp};
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
					if (window.hasEventListener(CloseEvent.CLOSE))
						window.removeEventListener(CloseEvent.CLOSE, onInfoWindowClose);
					var feature: KMLFeature = winObject.feature as KMLFeature;
					feature.removeEventListener(KMLFeatureEvent.KML_FEATURE_POSITION_CHANGE, onKMLFeaturePositionChange);
					feature.removeEventListener(KMLFeatureEvent.KML_FEATURE_VISIBILITY_CHANGE, onKMLFeatureVisibilityChange);
					delete windowsDictionary[window];
				}
			}
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

		public function getPopUpForFeature(feature: KMLFeature): IFlexDisplayObject
		{
			for each (var winObject: Object in windowsDictionary)
			{
				var currFeature: KMLFeature = winObject.feature as KMLFeature;
				if (feature == currFeature)
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

		private function onKMLFeatureVisibilityChange(event: KMLFeatureEvent): void
		{
			var window: IFlexDisplayObject = getPopUpForFeature(event.kmlFeature);
			window.visible = event.kmlFeature.visible;
			bringToFront(window);
		}

		private function onKMLFeaturePositionChange(event: KMLFeatureEvent): void
		{
			var window: IFlexDisplayObject = getPopUpForFeature(event.kmlFeature);
			centerPopUpOnFeature(window);
			bringToFront(window);
		}
	}
}
