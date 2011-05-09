package com.iblsoft.flexiweather.widgets.containers
{
	import mx.containers.BoxDirection;
	
	public class GroupHBox extends GroupBox
	{
		public function GroupHBox()
		{
			super();
		}
		
		override protected function childrenCreated():void
		{
			super.childrenCreated();	
			container.direction = BoxDirection.HORIZONTAL;
		}
		/**
		 *  @private
		 *  Don't allow user to change the direction
		 */
		override public function set direction(value:String):void
		{
		}

	}
}