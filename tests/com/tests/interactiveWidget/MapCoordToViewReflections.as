package com.tests.interactiveWidget
{
	import com.iblsoft.flexiweather.ogc.BBox;
	import com.iblsoft.flexiweather.proj.Coord;
	import com.iblsoft.flexiweather.widgets.InteractiveWidget;

	import flash.geom.Point;

	import org.flexunit.asserts.assertEquals;
	import org.flexunit.asserts.assertTrue;

	public class MapCoordToViewReflections
	{
		private var m_iw: InteractiveWidget;
		private var m_viewBBox: BBox;

		[Before]
		public function setUp():void
		{
			m_viewBBox = new BBox(-441, -90, -134, 90);

			m_iw = new InteractiveWidget();
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
		public function testMapCoordToViewReflections():void
		{
			m_viewBBox = new BBox(-441, -90, -134, 90);

			var pointsObject: Array;
			var p: Point;
			var refl: int;

			var coord: Coord = new Coord("CRS:84", 3.9, 30);
			pointsObject = m_iw.mapCoordToViewReflections(coord, m_viewBBox);

			p = pointsObject[0].point as Point;
			refl = pointsObject[0].reflection as int;

			assertEquals(1, pointsObject.length);
			assertTrue(p is Point);
			assertTrue(p.x == -356.1);
			assertTrue(refl == -1);


			var coord: Coord = new Coord("CRS:84", -140, 30);
			pointsObject = m_iw.mapCoordToViewReflections(coord, m_viewBBox);

			p = pointsObject[0].point as Point;
			refl = pointsObject[0].reflection as int;

			assertEquals(1, pointsObject.length);
			assertTrue(p is Point);
			assertTrue(p.x == -140);
			assertTrue(refl == 0);

			var coord: Coord = new Coord("CRS:84", -200, 30);
			pointsObject = m_iw.mapCoordToViewReflections(coord, m_viewBBox);

			p = pointsObject[0].point as Point;
			refl = pointsObject[0].reflection as int;

			assertEquals(1, pointsObject.length);
			assertTrue(p is Point);
			assertTrue(p.x == -200);
			assertTrue(refl == -1);


			var coord: Coord = new Coord("CRS:84", 200, 30);
			pointsObject = m_iw.mapCoordToViewReflections(coord, m_viewBBox);

			p = pointsObject[0].point as Point;
			refl = pointsObject[0].reflection as int;

			assertEquals(1, pointsObject.length);
			assertTrue(p is Point);
			assertTrue(p.x == -160);
			assertTrue(refl == 0);
		}

	}
}