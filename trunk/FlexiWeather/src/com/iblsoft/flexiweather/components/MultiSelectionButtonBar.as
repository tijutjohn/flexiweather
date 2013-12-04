package com.iblsoft.flexiweather.components
{
	import mx.collections.ArrayCollection;
	import spark.components.HGroup;

	/**
	 * This class handles ButtonBar with multiple selections, which is not supported by default spark ButtonBar
	 * @author fkormanak
	 *
	 */
	public class MultiSelectionButtonBar extends HGroup
	{
		public function get dataProvider(): ArrayCollection
		{
			return null;
		}

		public function set dataProvider(value: ArrayCollection): void
		{
		}

		public function MultiSelectionButtonBar()
		{
			super();
		}
	}
}
