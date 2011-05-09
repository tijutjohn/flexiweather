package com.iblsoft.flexiweather.widgets.containers
{
	import mx.containers.BoxDirection;
	public class GroupVBox extends GroupBox
	{
		public function GroupVBox()
		{
			super();
			
		}
		
		override protected function childrenCreated():void
		{
			super.childrenCreated();	
			container.direction = BoxDirection.VERTICAL;
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