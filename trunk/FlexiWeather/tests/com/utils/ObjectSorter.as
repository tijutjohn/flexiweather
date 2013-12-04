package com.utils
{
	import com.iblsoft.flexiweather.ogc.BBox;

	public class ObjectSorter
	{
		public function ObjectSorter()
		{
		}
		
		static public function compareBBoxes(bbox1: BBox, bbox2: BBox): int
		{
			if (bbox1 && bbox2)
			{
				if (bbox1.xMin < bbox2.xMin)
					return -1;
				if (bbox1.xMin > bbox2.xMin)
					return 1;
				
				if (bbox1.xMax < bbox2.xMax)
					return -1;
				if (bbox1.xMax > bbox2.xMax)
					return 1;
				
			}
			return 0;
		}
		
		static public function sortBBoxesArray(arr: Array): void
		{
			arr.sort(ObjectSorter.compareBBoxes);
		}
	}
}