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
		
		
	}
}