package com.iblsoft.flexiweather.ogc.wfs
{
	import com.iblsoft.flexiweather.ogc.data.WFSEditableReflectionData;
	import com.iblsoft.flexiweather.ogc.data.WFSEditableReflectionDictionary;
	
	import flash.display.DisplayObject;

	public interface IWFSFeatureWithReflection
	{
		function get getAnticollisionObject(): DisplayObject;
		function get getAnticollisionObstacle(): DisplayObject;
		
		function get totalReflections(): int;
		function get reflectionDictionary(): WFSEditableReflectionDictionary;
		function getReflection(id: int): WFSEditableReflectionData;
		function getDisplaySpriteForReflection(id: int): WFSFeatureEditableSprite;
	}
}
