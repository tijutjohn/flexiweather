package com.tests.wmts
{
	import com.iblsoft.flexiweather.ogc.BBox;
	import com.iblsoft.flexiweather.ogc.tiling.InteractiveLayerTiled;
	
	import org.flexunit.asserts.assertEquals;

	public class InteractiveLayerTiledTest
	{		
		private var m_tiledLayer: InteractiveLayerTiled;
		
		[Before]
		public function setUp():void
		{
			m_tiledLayer = new InteractiveLayerTiled();
		}
		
		[After]
		public function tearDown():void
		{
		}
		
		[BeforeClass]
		public static function setUpBeforeClass():void
		{
		}
		
		[AfterClass]
		public static function tearDownAfterClass():void
		{
		}
		
		[Test]
		public function coverageRatio(): void
		{
			var wholeWorld: BBox = new BBox(-180,-90,180,90);
			var halfWorld: BBox = new BBox(0,0,180,90);
			var wholeWorldMovedHalf: BBox = new BBox(0,-90,360,90);
			var wholeWorldMovedWhole: BBox = new BBox(180,-90,540,90);
			var bbox1: BBox = new BBox(0,0,360,180);
			
			var halfPerc: Number = wholeWorld.coverageRatio(halfWorld);
			var wholeWorldMovedhalfPerc: Number = wholeWorld.coverageRatio(wholeWorldMovedHalf);
			var wholeWorldMovedWholePerc: Number = wholeWorld.coverageRatio(wholeWorldMovedWhole);
			var bbox1Perc: Number = wholeWorld.coverageRatio(bbox1);
			
			assertEquals(halfPerc, 1);
			assertEquals(wholeWorldMovedhalfPerc, 0.5);
			assertEquals(wholeWorldMovedWholePerc, 0);
			assertEquals(bbox1Perc, 0.25);
		}
		
		[Test]
		public function normalizedBBoxToExtent(): void
		{
			var wholeWorld: BBox = new BBox(-180,-90,180,90);
			var bbox: BBox = new BBox(360,0,400,90);
			var bbox2: BBox = new BBox(540,0,560,90);
			var bbox3: BBox = new BBox(-560,0,-500,90);
			var bbox4: BBox = new BBox(-40,0,40,90);
			
			var halfPercBBox: BBox = m_tiledLayer.normalizedBBoxToExtent(bbox, wholeWorld);
			var halfPercBBox2: BBox = m_tiledLayer.normalizedBBoxToExtent(bbox2, wholeWorld);
			var halfPercBBox3: BBox = m_tiledLayer.normalizedBBoxToExtent(bbox3, wholeWorld);
			var halfPercBBox4: BBox = m_tiledLayer.normalizedBBoxToExtent(bbox4, wholeWorld);
			//			var wholeWorldMovedhalfPerc: Number = wholeWorld.coverageRatio(wholeWorldMovedHalf);
			//			var wholeWorldMovedWholePerc: Number = wholeWorld.coverageRatio(wholeWorldMovedWhole);
			//			var bbox1Perc: Number = wholeWorld.coverageRatio(bbox1);
			
			assertEquals(halfPercBBox.xMin, 0);
			assertEquals(halfPercBBox.xMax, 40);
			assertEquals(halfPercBBox2.xMin, -180);
			assertEquals(halfPercBBox2.xMax, -160);
			assertEquals(halfPercBBox3.xMin, -200);
			assertEquals(halfPercBBox3.xMax, -140);
			assertEquals(halfPercBBox4.xMin, -40);
			assertEquals(halfPercBBox4.xMax, 40);
		}
		
		
	}
}