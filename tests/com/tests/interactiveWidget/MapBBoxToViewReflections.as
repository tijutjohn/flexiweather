package com.tests.interactiveWidget
{
	import com.iblsoft.flexiweather.ogc.BBox;
	import com.iblsoft.flexiweather.widgets.InteractiveWidget;
	import com.utils.ObjectSorter;
	
	import flash.geom.Point;
	
	import flexunit.framework.Assert;
	
	import org.flexunit.asserts.assertEquals;
	import org.flexunit.asserts.assertFalse;
	import org.flexunit.asserts.assertTrue;
	
	public class MapBBoxToViewReflections
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
		public function testMapBBoxToViewReflections():void
		{
			m_viewBBox = new BBox(-180,-90,180,90); 
			m_bbox1 = new BBox(20, -10, 40, 10);
			
			var boxes: Array;
			var b1: BBox;
			
			boxes = m_iw.mapBBoxToViewReflections(m_bbox1, false, m_viewBBox);
			b1 = boxes[0] as BBox;
			
			assertEquals(1, boxes.length);
			assertTrue(b1 is BBox);
			
			assertEquals(20, b1.xMin);
			assertEquals(40, b1.xMax);
			
			
			m_bbox2 = new BBox(-100, -10, -60, 10);
			boxes = m_iw.mapBBoxToViewReflections(m_bbox2, false, m_viewBBox);
			b1 = boxes[0] as BBox;
			
			assertEquals(1, boxes.length);
			assertTrue(b1 is BBox);
			
			assertEquals(-100, b1.xMin);
			assertEquals(-60, b1.xMax);
		}
		
		[Test]
		public function testMapBBoxToViewReflectionsLeft():void
		{
			m_viewBBox = new BBox(-180,-90,180,90); 
			m_bbox1 = new BBox(-200, -10, -160, 10);
			
			var boxes: Array;
			var b1: BBox;
			var b2: BBox;
			
			boxes = m_iw.mapBBoxToViewReflections(m_bbox1, false, m_viewBBox);
			ObjectSorter.sortBBoxesArray(boxes);
			b1 = boxes[0] as BBox;
			b2 = boxes[1] as BBox;
			
			assertEquals(2, boxes.length);
			assertTrue(b1 is BBox);
			assertTrue(b2 is BBox);
			
			assertEquals(-200, b1.xMin);
			assertEquals(-160, b1.xMax);
			assertEquals(160, b2.xMin);
			assertEquals(200, b2.xMax);
			
			
			boxes = m_iw.mapBBoxToViewReflections(m_bbox1, true, m_viewBBox);
			ObjectSorter.sortBBoxesArray(boxes);
			b1 = boxes[0] as BBox;
			b2 = boxes[1] as BBox;
			
			assertEquals(2, boxes.length);
			assertTrue(b1 is BBox);
			assertTrue(b2 is BBox);
			
			assertEquals(-180, b1.xMin);
			assertEquals(-160, b1.xMax);
			assertEquals(160, b2.xMin);
			assertEquals(180, b2.xMax);
		}
		
		[Test]
		public function testMapBBoxToViewReflectionsRight():void
		{
			m_viewBBox = new BBox(-180,-90,180,90); 
			m_bbox1 = new BBox(160, -10, 200, 10);
			
			var boxes: Array;
			var b1: BBox;
			var b2: BBox;
			
			boxes = m_iw.mapBBoxToViewReflections(m_bbox1, false, m_viewBBox);
			ObjectSorter.sortBBoxesArray(boxes);
			b1 = boxes[0] as BBox;
			b2 = boxes[1] as BBox;
			
			assertEquals(2, boxes.length);
			assertTrue(b1 is BBox);
			assertTrue(b2 is BBox);
			
			assertEquals(-200, b1.xMin);
			assertEquals(-160, b1.xMax);
			assertEquals(160, b2.xMin);
			assertEquals(200, b2.xMax);
			
			
			boxes = m_iw.mapBBoxToViewReflections(m_bbox1, true, m_viewBBox);
			ObjectSorter.sortBBoxesArray(boxes);
			b1 = boxes[0] as BBox;
			b2 = boxes[1] as BBox;
			
			assertEquals(2, boxes.length);
			assertTrue(b1 is BBox);
			assertTrue(b2 is BBox);
			
			assertEquals(-180, b1.xMin);
			assertEquals(-160, b1.xMax);
			assertEquals(160, b2.xMin);
			assertEquals(180, b2.xMax);
		}
		[Test]
		public function testMapBBoxToViewReflectionsMoveRight():void
		{
			m_viewBBox = new BBox(-180,-90,180,90); 
			m_bbox1 = new BBox(560, -10, 600, 10);
			
			var boxes: Array;
			var b1: BBox;
			var b2: BBox;
			
			boxes = m_iw.mapBBoxToViewReflections(m_bbox1, false, m_viewBBox);
			b1 = boxes[0] as BBox;
			
			assertEquals(1, boxes.length);
			assertTrue(b1 is BBox);
			
			assertEquals(-160, b1.xMin);
			assertEquals(-120, b1.xMax);
			assertEquals(-10, b1.yMin);
			assertEquals(10, b1.yMax);
			
			m_bbox1 = new BBox(520, -10, 560, 10);
			boxes = m_iw.mapBBoxToViewReflections(m_bbox1, false, m_viewBBox);
			ObjectSorter.sortBBoxesArray(boxes);
			b1 = boxes[0] as BBox;
			b2 = boxes[1] as BBox;
			
			assertEquals(2, boxes.length);
			assertTrue(b1 is BBox);
			assertTrue(b2 is BBox);
			
			assertEquals(-200, b1.xMin);
			assertEquals(-160, b1.xMax);
			assertEquals(160, b2.xMin);
			assertEquals(200, b2.xMax);
			
			
			m_bbox1 = new BBox(520, -10, 560, 10);
			boxes = m_iw.mapBBoxToViewReflections(m_bbox1, true, m_viewBBox);
			ObjectSorter.sortBBoxesArray(boxes);
			b1 = boxes[0] as BBox;
			b2 = boxes[1] as BBox;
			
			assertEquals(2, boxes.length);
			assertTrue(b1 is BBox);
			assertTrue(b2 is BBox);
			
			assertEquals(-180, b1.xMin);
			assertEquals(-160, b1.xMax);
			assertEquals(160, b2.xMin);
			assertEquals(180, b2.xMax);
		}
		[Test]
		public function testMapBBoxToViewReflectionsMoveLeft():void
		{
			m_viewBBox = new BBox(-180,-90,180,90); 
			m_bbox1 = new BBox(-600, -10, -560, 10);
			
			var boxes: Array;
			var b1: BBox;
			var b2: BBox;
			
			boxes = m_iw.mapBBoxToViewReflections(m_bbox1, false, m_viewBBox);
			b1 = boxes[0] as BBox;
			
			assertEquals(1, boxes.length);
			assertTrue(b1 is BBox);
			
			assertEquals(120, b1.xMin);
			assertEquals(160, b1.xMax);
			
			m_bbox1 = new BBox(-560, -10, -520, 10);
			boxes = m_iw.mapBBoxToViewReflections(m_bbox1, false, m_viewBBox);
			ObjectSorter.sortBBoxesArray(boxes);
			b1 = boxes[0] as BBox;
			b2 = boxes[1] as BBox;
			
			assertEquals(2, boxes.length);
			assertTrue(b1 is BBox);
			assertTrue(b2 is BBox);
			
			assertEquals(-200, b1.xMin);
			assertEquals(-160, b1.xMax);
			assertEquals(160, b2.xMin);
			assertEquals(200, b2.xMax);
			
			//clipped
			m_bbox1 = new BBox(-560, -10, -520, 10);
			boxes = m_iw.mapBBoxToViewReflections(m_bbox1, true, m_viewBBox);
			ObjectSorter.sortBBoxesArray(boxes);
			b1 = boxes[0] as BBox;
			b2 = boxes[1] as BBox;
			
			assertEquals(2, boxes.length);
			assertTrue(b1 is BBox);
			assertTrue(b2 is BBox);
			
			assertEquals(-180, b1.xMin);
			assertEquals(-160, b1.xMax);
			assertEquals(160, b2.xMin);
			assertEquals(180, b2.xMax);
		}
		
		
		[Test]
		public function testMapBBoxToViewReflectionsWideViewBBox():void
		{
			m_viewBBox = new BBox(-180,-90,540,90); 
			m_bbox1 = new BBox(20, -10, 40, 10);
			
			var boxes: Array;
			var b1: BBox;
			var b2: BBox;
			
			boxes = m_iw.mapBBoxToViewReflections(m_bbox1, false, m_viewBBox);
			ObjectSorter.sortBBoxesArray(boxes);
			b1 = boxes[0] as BBox;
			b2 = boxes[1] as BBox;
			
			assertEquals(2, boxes.length);
			assertTrue(b1 is BBox);
			assertTrue(b2 is BBox);
			
			assertEquals(20, b1.xMin);
			assertEquals(40, b1.xMax);
			assertEquals(380, b2.xMin);
			assertEquals(400, b2.xMax);
		}
		
		[Test]
		public function testMapBBoxToViewReflectionsWideViewBBoxNotClipped():void
		{
			
			var boxes: Array;
			var b1: BBox;
			var b2: BBox;
			var b3: BBox;
			
			m_viewBBox2 = new BBox(-180,-90,640,90);
			m_bbox2 = new BBox(-100, -10, -60, 10);
			
			boxes = m_iw.mapBBoxToViewReflections(m_bbox2, false, m_viewBBox2);
			ObjectSorter.sortBBoxesArray(boxes);
			b1 = boxes[0] as BBox;
			b2 = boxes[1] as BBox;
			b3 = boxes[2] as BBox;
			
			assertEquals(3, boxes.length);
			assertTrue(b1 is BBox);
			assertTrue(b2 is BBox);
			assertTrue(b3 is BBox);
			
			assertEquals(-100, b1.xMin);
			assertEquals(-60, b1.xMax);
			assertEquals(260, b2.xMin);
			assertEquals(300, b2.xMax);
			assertEquals(620, b3.xMin);
			
			//not clipped, because 2nd parameter is FALSE
			assertEquals(660, b3.xMax);
		}
		[Test]
		public function testMapBBoxToViewReflectionsViewBBoxWithWiderBBox():void
		{
			
			var boxes: Array;
			var b1: BBox;
			var b2: BBox;
			var b3: BBox;
			
			m_viewBBox2 = new BBox(-180,-90,180,90);
			m_bbox2 = new BBox(-200, -10, 200, 10);
			
			boxes = m_iw.mapBBoxToViewReflections(m_bbox2, false, m_viewBBox2);
			ObjectSorter.sortBBoxesArray(boxes);
			b1 = boxes[0] as BBox;
			b2 = boxes[1] as BBox;
			b3 = boxes[2] as BBox;
			
			assertEquals(3, boxes.length);
			assertTrue(b1 is BBox);
			assertTrue(b2 is BBox);
			assertTrue(b3 is BBox);
			
			assertEquals(-560, b1.xMin);
			assertEquals(-160, b1.xMax);
			assertEquals(-200, b2.xMin);
			assertEquals(200, b2.xMax);
			assertEquals(160, b3.xMin);
			assertEquals(560, b3.xMax);
			
			//clipped
			boxes = m_iw.mapBBoxToViewReflections(m_bbox2, true, m_viewBBox2);
			ObjectSorter.sortBBoxesArray(boxes);
			b1 = boxes[0] as BBox;
			b2 = boxes[1] as BBox;
			b3 = boxes[2] as BBox;
			
			assertEquals(3, boxes.length);
			assertTrue(b1 is BBox);
			assertTrue(b2 is BBox);
			assertTrue(b3 is BBox);
			
			assertEquals(-180, b1.xMin);
			assertEquals(-160, b1.xMax);
			assertEquals(-180, b2.xMin);
			assertEquals(180, b2.xMax);
			assertEquals(160, b3.xMin);
			assertEquals(180, b3.xMax);
			
		}
		
		/*
		[Test]
		public function testMapBBoxToViewReflectionsWideViewBBoxWithWiderBBox():void
		{
			var boxes: Array;
			var b1: BBox;
			var b2: BBox;
			var b3: BBox;
			
			m_viewBBox2 = new BBox(-180,-90,540,90);
			m_bbox2 = new BBox(-200, -10, 600, 10);
			
			boxes = m_iw.mapBBoxToViewReflections(m_bbox2, false, m_viewBBox2);
			b1 = boxes[0] as BBox;
			b2 = boxes[1] as BBox;
			b3 = boxes[2] as BBox;
			
			assertEquals(3, boxes.length);
			assertTrue(b1 is BBox);
			assertTrue(b2 is BBox);
			assertTrue(b3 is BBox);
			
			assertEquals(-100, b1.xMin);
			assertEquals(-60, b1.xMax);
			assertEquals(260, b2.xMin);
			assertEquals(300, b2.xMax);
			assertEquals(620, b3.xMin);
			
			//not clipped, because 2nd parameter is FALSE
			assertEquals(660, b3.xMax);
		}
		
		[Test]
		public function testMapBBoxToViewReflectionsWideViewBBoxClipped():void
		{	
			
			var boxes: Array;
			var b1: BBox;
			var b2: BBox;
			var b3: BBox;
			
			m_viewBBox2 = new BBox(-180,-90,640,90);
			m_bbox2 = new BBox(-200, -10, 700, 10);
			
			boxes = m_iw.mapBBoxToViewReflections(m_bbox2, true, m_viewBBox2);
			b1 = boxes[0] as BBox;
			
			assertEquals(3, boxes.length);
			assertTrue(b1 is BBox);
			
			assertEquals(-200, b1.xMin);
			assertEquals(700, b1.xMax);
			
			//clipped
			boxes = m_iw.mapBBoxToViewReflections(m_bbox2, true, m_viewBBox2);
			b1 = boxes[0] as BBox;
			
			assertEquals(3, boxes.length);
			assertTrue(b1 is BBox);
			
			assertEquals(-180, b1.xMin);
			assertEquals(640, b1.xMax);
		}
		*/
	}
}