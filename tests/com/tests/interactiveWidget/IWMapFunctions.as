package com.tests.interactiveWidget
{
	import com.iblsoft.flexiweather.ogc.BBox;
	import com.iblsoft.flexiweather.widgets.InteractiveWidget;
	
	import flash.geom.Point;
	
	import flexunit.framework.Assert;
	
	import org.flexunit.asserts.assertEquals;
	import org.flexunit.asserts.assertFalse;
	import org.flexunit.asserts.assertTrue;
	
	public class IWMapFunctions
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
		public function testMapCoordInCRSToViewReflections():void
		{
			var p: Point = new Point(10, 0);
			
			var reflections: Array = m_iw.mapCoordInCRSToViewReflections(p, m_viewBBox);
			
			assertEquals(reflections.length, 1);
			assertEquals(reflections[0].reflection, 0);
			assertEquals(reflections[0].point.x, 10);
			
			var p2: Point = new Point(-190, 0);
			var reflections2: Array = m_iw.mapCoordInCRSToViewReflections(p2, m_viewBBox);
			
			assertEquals(reflections2.length, 1);
			assertEquals(reflections2[0].reflection, 0);
			assertEquals(reflections2[0].point.x, 170);
			
		}
		
		[Test]
		public function testMapCoordInCRSToViewReflections2():void
		{
			var p3: Point = new Point(-190, 0);
			var reflections2: Array = m_iw.mapCoordInCRSToViewReflections(p3, m_viewBBox2);
			
			assertEquals(2, reflections2.length);
			
			assertEquals(0, reflections2[0].reflection);
			assertEquals(reflections2[1].reflection, 1);
			
			assertEquals(170, reflections2[0].point.x);
			assertEquals(reflections2[1].point.x, 530);
		}
		[Test]
		public function testMapCoordInCRSToViewReflections3():void
		{
			var p3: Point = new Point(550, 0);
			var reflections2: Array = m_iw.mapCoordInCRSToViewReflections(p3, m_viewBBox2);
			
			assertEquals(2, reflections2.length);
			
			assertEquals(0, reflections2[0].reflection);
			assertEquals(1,reflections2[1].reflection);
			
			assertEquals(-170, reflections2[0].point.x);
			assertEquals(190, reflections2[1].point.x);
			
			
			p3 = new Point(370, 0);
			reflections2 = m_iw.mapCoordInCRSToViewReflections(p3, m_viewBBox2);
			
			assertEquals(2, reflections2.length);
			
			assertEquals(0, reflections2[0].reflection);
			assertEquals(1,reflections2[1].reflection);
			
			assertEquals(10, reflections2[0].point.x);
			assertEquals(370, reflections2[1].point.x);
		}
		
		[Test]
		public function testMapCoordInCRSToViewReflectionsForDeltas():void
		{
			var p3: Point = new Point(-550, 0);
			var reflections2: Array = m_iw.mapCoordInCRSToViewReflectionsForDeltas(p3, [0,1,3]);
			
			assertEquals(3, reflections2.length);
			assertEquals(0, reflections2[0].reflection);
			assertEquals(1, reflections2[1].reflection);
			assertEquals(3, reflections2[2].reflection);
			assertEquals(170, reflections2[0].point.x);
			assertEquals(530, reflections2[1].point.x);
			assertEquals(1250, reflections2[2].point.x);
		}
	}
}