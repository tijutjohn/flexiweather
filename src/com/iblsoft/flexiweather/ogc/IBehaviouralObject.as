package com.iblsoft.flexiweather.ogc
{

	public interface IBehaviouralObject
	{
		function setBehaviourString(s_behaviourId: String, s_value: String): void;
		function getBehaviourString(s_behaviourId: String, s_default: String = null): String;
		function hasBehaviourString(s_behaviourId: String): Boolean;
	}
}
