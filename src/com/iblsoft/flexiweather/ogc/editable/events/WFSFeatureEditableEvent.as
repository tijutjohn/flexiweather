/***********************************************************************************************
 *
 *	Created:	14.04.2015
 *	Authors:	Franto Kormanak
 *
 *	Copyright (c) 2015, IBL Software Engineering spol. s r. o., <escrow@iblsoft.com>.
 *	All rights reserved. Unauthorised use, modification or redistribution is prohibited.
 *
 ***********************************************************************************************/

package com.iblsoft.flexiweather.ogc.editable.events
{
	import com.iblsoft.flexiweather.ogc.editable.WFSFeatureEditable;

	import flash.events.Event;

	public class WFSFeatureEditableEvent extends Event
	{
		/**
		 * Dispatch, when feature is closed by used.
		 */
		public static const FEATURE_CLOSED: String = "featureClosed";

		private var m_feature: WFSFeatureEditable;

		public function get feature(): WFSFeatureEditable
		{
			return m_feature;
		}

		public function WFSFeatureEditableEvent(type:String, feature: WFSFeatureEditable, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			super(type, bubbles, cancelable);

			m_feature = feature;
		}

		override public function clone():Event
		{
			var wfee: WFSFeatureEditableEvent = new WFSFeatureEditableEvent(type, m_feature, bubbles, cancelable);
			return wfee;
		}
	}
}