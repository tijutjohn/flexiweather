package com.tests.utils
{
	import com.iblsoft.flexiweather.ogc.tiling.TilingUtils;
	
	import flexunit.framework.Assert;
	
	import org.flexunit.asserts.assertFalse;
	import org.flexunit.asserts.assertTrue;
	
	public class TilingUtilsTest
	{		
		[Before]
		public function setUp():void
		{
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
		
		/*
		[Test]
		public function testGetColTiles():void
		{
			Assert.fail("Test method Not yet implemented");
		}
		
		[Test]
		public function testGetMaxTileID():void
		{
			var tilingUtils: TilingUtils = new TilingUtils();
			
			//tiles 256 x 256
			var maxTileID: int = tilingUtils.getMaxTileID(0);			
			assertTrue(maxTileID == 0);
			
			maxTileID = tilingUtils.getMaxTileID(1);			
			assertTrue(maxTileID == 1);
			
			maxTileID = tilingUtils.getMaxTileID(2);			
			assertTrue(maxTileID == 3);
			
			
			//tiles 512 x 512
			maxTileID = tilingUtils.getMaxTileID(0, 512);			
			assertTrue(maxTileID == 0);
			
			maxTileID = tilingUtils.getMaxTileID(1, 512);			
			assertTrue(maxTileID == 0);
			
			maxTileID = tilingUtils.getMaxTileID(2, 512);			
			assertTrue(maxTileID == 1);
			
			//tiles 1024 x 1024
			maxTileID = tilingUtils.getMaxTileID(0, 1024);			
			assertTrue(maxTileID == 0);
			
			maxTileID = tilingUtils.getMaxTileID(1, 1024);			
			assertTrue(maxTileID == 1);
			
			maxTileID = tilingUtils.getMaxTileID(2, 1024);			
			assertTrue(maxTileID == 0);
			
			maxTileID = tilingUtils.getMaxTileID(3, 1024);			
			assertTrue(maxTileID == 1);
			
		}
		[Test]
		public function testGetTileSize():void
		{
			var tilingUtils: TilingUtils = new TilingUtils();
			
			
			//tiles 256 x 256
			var maxTileID: int = tilingUtils.getTileSize(0);			
			assertTrue(maxTileID == 256);
			
			maxTileID = tilingUtils.getTileSize(1);			
			assertTrue(maxTileID == 256);
			
			maxTileID = tilingUtils.getTileSize(2);			
			assertTrue(maxTileID == 256);
			
			
			//tiles 512 x 512
			maxTileID = tilingUtils.getTileSize(0, 512);			
			assertTrue(maxTileID == 256);
			
			maxTileID = tilingUtils.getTileSize(1, 512);			
			assertTrue(maxTileID == 512);
			
			maxTileID = tilingUtils.getTileSize(2, 512);			
			assertTrue(maxTileID == 512);
			
			//tiles 1024 x 1024
			maxTileID = tilingUtils.getTileSize(0, 1024);			
			assertTrue(maxTileID == 256);
			
			maxTileID = tilingUtils.getTileSize(1, 1024);			
			assertTrue(maxTileID == 256);
			
			maxTileID = tilingUtils.getTileSize(2, 1024);			
			assertTrue(maxTileID == 1024);
			
			maxTileID = tilingUtils.getTileSize(3, 1024);			
			assertTrue(maxTileID == 1024);
		}
		
		[Test]
		public function testGetRowTiles():void
		{
			Assert.fail("Test method Not yet implemented");
		}
		
		[Test]
		public function testGetTileWidth():void
		{
			Assert.fail("Test method Not yet implemented");
		}
		*/
	}
}