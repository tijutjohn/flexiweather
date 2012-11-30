package com.tests.interactiveWidget
{
	import com.iblsoft.flexiweather.ogc.BBox;
	import com.iblsoft.flexiweather.widgets.InteractiveWidget;

	import org.flexunit.asserts.assertEquals;
	import org.flexunit.asserts.assertFalse;
	import org.flexunit.asserts.assertTrue;
	
	public class MapBBoxToProjectionExtentParts
	{		
		
		private var m_iw: InteractiveWidget;
		private var m_viewBBox: BBox;
		private var m_viewBBox2: BBox;
		private var m_viewBBox3: BBox;
		
		private var m_bbox1: BBox;
		private var m_bbox2: BBox;
		
		[Before]
		public function setUp():void
		{
			m_iw = new InteractiveWidget();
			
			m_viewBBox = new BBox(-180,-90,180,90); 
			m_viewBBox2 = new BBox(-180,-90,540,90);
			
			m_viewBBox3 = new BBox(100,-80,240,80);
			
			m_bbox1 = new BBox(20, -10, 40, 10);
			m_bbox2 = new BBox(-100, -10, -60, 10);
			
			m_iw.setCRS('CRS:84', false);
			m_iw.setExtentBBox(m_viewBBox, true);
			
			m_iw.setViewBBox(m_viewBBox, true);
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
		public function testMapBBoxToProjectionExtentPartsRight():void
		{
			var bbox1: BBox = new BBox(100, -80, 240, 80);
			var parts: Array = m_iw.mapBBoxToProjectionExtentParts(bbox1);
			
			var b1: BBox = parts[0] as BBox;
			var b2: BBox = parts[1] as BBox;
			
			assertEquals(2, parts.length);
			assertTrue(b1 is BBox);
			assertTrue(b2 is BBox);
			assertEquals(100, b1.xMin);
			assertEquals(180, b1.xMax);
			assertEquals(-180, b2.xMin);
			assertEquals(-120, b2.xMax);
		}
		
		[Test]
		public function testMapBBoxToProjectionExtentPartsMoveRight():void
		{
			//140, 200
			var bbox1: BBox = new BBox(500, -80, 560, 80);
			var parts: Array = m_iw.mapBBoxToProjectionExtentParts(bbox1);
			
			var b1: BBox = parts[0] as BBox;
			var b2: BBox = parts[1] as BBox;
			
			assertEquals(2, parts.length);
			assertTrue(b1 is BBox);
			assertTrue(b2 is BBox);
			assertEquals(140, b1.xMin);
			assertEquals(180, b1.xMax);
			assertEquals(-180, b2.xMin);
			assertEquals(-160, b2.xMax);
			
			
			bbox1 = new BBox(500, -80, 540, 80);
			parts = m_iw.mapBBoxToProjectionExtentParts(bbox1);
			
			b1 = parts[0] as BBox;
			b2= parts[1] as BBox;
			
			assertEquals(1, parts.length);
			assertTrue(b1 is BBox);
			assertTrue(!b2);
			assertEquals(140, b1.xMin);
			assertEquals(180, b1.xMax);
			
		}
		
		[Test]
		public function testMapBBoxToProjectionExtentPartsMoveLeft():void
		{
			//140, 200
			var bbox1: BBox = new BBox(-580, -80, -520, 80);
			var parts: Array = m_iw.mapBBoxToProjectionExtentParts(bbox1);
			
			var b1: BBox = parts[0] as BBox;
			var b2: BBox = parts[1] as BBox;
			
			assertEquals(2, parts.length);
			assertTrue(b1 is BBox);
			assertTrue(b2 is BBox);
			assertEquals(-180, b1.xMin);
			assertEquals(-160, b1.xMax);
			assertEquals(140, b2.xMin);
			assertEquals(180, b2.xMax);
			
			
			bbox1 = new BBox(-520, -80, -480, 80);
			parts = m_iw.mapBBoxToProjectionExtentParts(bbox1);
			
			b1 = parts[0] as BBox;
			b2= parts[1] as BBox;
			
			assertEquals(1, parts.length);
			assertTrue(b1 is BBox);
			assertTrue(!b2);
			assertEquals(-160, b1.xMin);
			assertEquals(-120, b1.xMax);
			
		}
		
		[Test]
		public function testMapBBoxToProjectionExtentPartsLeft():void
		{
			var bbox1: BBox = new BBox(-240, -80, -100, 80);
			var parts: Array = m_iw.mapBBoxToProjectionExtentParts(bbox1);
			
			var b1: BBox = parts[0] as BBox;
			var b2: BBox = parts[1] as BBox;
			
			assertEquals(2, parts.length);
			assertTrue(b1 is BBox);
			assertTrue(b2 is BBox);
			assertEquals(-180, b1.xMin);
			assertEquals(-100, b1.xMax);
			assertEquals(120, b2.xMin);
			assertEquals(180, b2.xMax);
		}
		[Test]
		public function testMapBBoxToProjectionExtentPartsWide():void
		{
			var bbox1: BBox = new BBox(-240, -80, 240, 80);
			var parts: Array = m_iw.mapBBoxToProjectionExtentParts(bbox1);
			
			var b1: BBox = parts[0] as BBox;
			
			assertEquals(1, parts.length);
			assertTrue(b1 is BBox);
			assertEquals(-180, b1.xMin);
			assertEquals(180, b1.xMax);
		}
		[Test]
		public function testMapBBoxToProjectionExtentPartsNarrow():void
		{
			var bbox1: BBox = new BBox(-60, -80, 60, 80);
			var parts: Array = m_iw.mapBBoxToProjectionExtentParts(bbox1);
			
			var b1: BBox = parts[0] as BBox;
			
			assertEquals(1, parts.length);
			assertTrue(b1 is BBox);
			assertEquals(-60, b1.xMin);
			assertEquals(60, b1.xMax);
		}

		
	}
}