package com.tests.projection
{
	import com.iblsoft.flexiweather.ogc.BBox;
	import com.iblsoft.flexiweather.proj.Coord;
	import com.iblsoft.flexiweather.proj.Projection;
	
	import org.flexunit.asserts.assertEquals;
	import org.flexunit.asserts.assertTrue;

	public class ProjectionTest
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
			Projection.addCRSByProj4("ESRI:54004", "+title=World Mercator +proj=merc +lat_ts=0 +lon_0=0 +k=1.000000 +x_0=0 +y_0=0 +ellps=WGS84 +datum=WGS84 +units=m");
			Projection.addCRSByProj4("ESRI:102018", "+title=North Pole Stereographic +proj=stere +lat_0=90 +lon_0=0 +x_0=0 +y_0=0 +ellps=WGS84 +datum=WGS84 +units=m");
			Projection.addCRSByProj4("ESRI:102021", "+title=South Pole Stereographic +proj=stere +lat_0=-90 +lon_0=0 +x_0=0 +y_0=0 +ellps=WGS84 +datum=WGS84 +units=m");
			Projection.addCRSByProj4("EPSG:4326", "+title=WGS 84 +proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs", new BBox(-180, -90, 180, 90), true);
		}
		
		[AfterClass]
		public static function tearDownAfterClass():void
		{
		}
		
		
		[Test]
		public function testProjectionCRS84():void
		{
			var projectionString: String = 'CRS::84';
			
			var projectionCRS84Wrappable: Projection = new Projection(projectionString, new BBox(-180, -90, 180, 90), true);
			var coord1: Coord = new Coord(projectionString, 125, 40);
			
			var coord2: Coord = projectionCRS84Wrappable.moveCoordToExtent(coord1);
			
			assertTrue(coord2);
			assertTrue(coord2 is Coord);
			assertEquals(125, coord2.x);
			assertEquals(40, coord2.y);
			
			var coordOutsideExtent: Coord = new Coord(projectionString, 200, 40);
			var coord3: Coord = projectionCRS84Wrappable.moveCoordToExtent(coordOutsideExtent);
			
			assertTrue(coord3);
			assertTrue(coord3 is Coord);
			assertEquals(-160, coord3.x);
			assertEquals(40, coord3.y);
			
			coordOutsideExtent = new Coord(projectionString, 370, 40);
			coord3 = projectionCRS84Wrappable.moveCoordToExtent(coordOutsideExtent);
			
			assertTrue(coord3);
			assertTrue(coord3 is Coord);
			assertEquals(10, coord3.x);
			assertEquals(40, coord3.y);
			
			coordOutsideExtent = new Coord(projectionString, 530, 40);
			coord3 = projectionCRS84Wrappable.moveCoordToExtent(coordOutsideExtent);
			
			assertTrue(coord3);
			assertTrue(coord3 is Coord);
			assertEquals(170, coord3.x);
			assertEquals(40, coord3.y);
			
			coordOutsideExtent = new Coord(projectionString, 550, 40);
			coord3 = projectionCRS84Wrappable.moveCoordToExtent(coordOutsideExtent);
			
			assertTrue(coord3);
			assertTrue(coord3 is Coord);
			assertEquals(-170, coord3.x);
			assertEquals(40, coord3.y);
			
			// negative coordinates
			coordOutsideExtent = new Coord(projectionString, -160, 40);
			coord3 = projectionCRS84Wrappable.moveCoordToExtent(coordOutsideExtent);
			
			assertTrue(coord3);
			assertTrue(coord3 is Coord);
			assertEquals(-160, coord3.x);
			assertEquals(40, coord3.y);
			
			
			coordOutsideExtent = new Coord(projectionString, -190, 40);
			coord3 = projectionCRS84Wrappable.moveCoordToExtent(coordOutsideExtent);
			
			assertTrue(coord3);
			assertTrue(coord3 is Coord);
			assertEquals(170, coord3.x);
			assertEquals(40, coord3.y);
			
			
			coordOutsideExtent = new Coord(projectionString, -2650, 40);
			coord3 = projectionCRS84Wrappable.moveCoordToExtent(coordOutsideExtent);
			
			assertTrue(coord3);
			assertTrue(coord3 is Coord);
			assertEquals(-130, coord3.x);
			assertEquals(40, coord3.y);
			
			
			coordOutsideExtent = new Coord(projectionString, -720, 40);
			coord3 = projectionCRS84Wrappable.moveCoordToExtent(coordOutsideExtent);
			
			assertTrue(coord3);
			assertTrue(coord3 is Coord);
			assertEquals(0, coord3.x);
			assertEquals(40, coord3.y);
		}
		
		[Test]
		public function testProjectionEPSG4326():void
		{
			var projectionString: String = 'EPSG:4326';
			
			var projectionCRS84Wrappable: Projection = new Projection(projectionString, new BBox(-180, -90, 180, 90), true);
			var coord1: Coord = new Coord(projectionString, 125, 40);
			
			var coord2: Coord = projectionCRS84Wrappable.moveCoordToExtent(coord1);
			
			assertTrue(coord2);
			assertTrue(coord2 is Coord);
			assertEquals(125, coord2.x);
			assertEquals(40, coord2.y);
			
			var coordOutsideExtent: Coord = new Coord(projectionString, 200, 40);
			var coord3: Coord = projectionCRS84Wrappable.moveCoordToExtent(coordOutsideExtent);
			
			assertTrue(coord3);
			assertTrue(coord3 is Coord);
			assertEquals(-160, coord3.x);
			assertEquals(40, coord3.y);
			
			coordOutsideExtent = new Coord(projectionString, 370, 40);
			coord3 = projectionCRS84Wrappable.moveCoordToExtent(coordOutsideExtent);
			
			assertTrue(coord3);
			assertTrue(coord3 is Coord);
			assertEquals(10, coord3.x);
			assertEquals(40, coord3.y);
			
			coordOutsideExtent = new Coord(projectionString, 530, 40);
			coord3 = projectionCRS84Wrappable.moveCoordToExtent(coordOutsideExtent);
			
			assertTrue(coord3);
			assertTrue(coord3 is Coord);
			assertEquals(170, coord3.x);
			assertEquals(40, coord3.y);
			
			coordOutsideExtent = new Coord(projectionString, 550, 40);
			coord3 = projectionCRS84Wrappable.moveCoordToExtent(coordOutsideExtent);
			
			assertTrue(coord3);
			assertTrue(coord3 is Coord);
			assertEquals(-170, coord3.x);
			assertEquals(40, coord3.y);
			
			// negative coordinates
			coordOutsideExtent = new Coord(projectionString, -160, 40);
			coord3 = projectionCRS84Wrappable.moveCoordToExtent(coordOutsideExtent);
			
			assertTrue(coord3);
			assertTrue(coord3 is Coord);
			assertEquals(-160, coord3.x);
			assertEquals(40, coord3.y);
			
			
			coordOutsideExtent = new Coord(projectionString, -190, 40);
			coord3 = projectionCRS84Wrappable.moveCoordToExtent(coordOutsideExtent);
			
			assertTrue(coord3);
			assertTrue(coord3 is Coord);
			assertEquals(170, coord3.x);
			assertEquals(40, coord3.y);
			
			
			coordOutsideExtent = new Coord(projectionString, -2650, 40);
			coord3 = projectionCRS84Wrappable.moveCoordToExtent(coordOutsideExtent);
			
			assertTrue(coord3);
			assertTrue(coord3 is Coord);
			assertEquals(-130, coord3.x);
			assertEquals(40, coord3.y);
			
			
			coordOutsideExtent = new Coord(projectionString, -720, 40);
			coord3 = projectionCRS84Wrappable.moveCoordToExtent(coordOutsideExtent);
			
			assertTrue(coord3);
			assertTrue(coord3 is Coord);
			assertEquals(0, coord3.x);
			assertEquals(40, coord3.y);
		}
		
		/*
		[Test]
		public function testProjectionEPSG900913():void
		{
			var projectionString: String = 'EPSG:900913';
			
			var projectionCRS84Wrappable: Projection = new Projection(projectionString, new BBox(-180, -90, 180, 90), true);
			var coord1: Coord = new Coord(projectionString, 125, 40);
			
			var coord2: Coord = projectionCRS84Wrappable.moveCoordToExtent(coord1);
			
			assertTrue(coord2);
			assertTrue(coord2 is Coord);
			assertEquals(125, coord2.x);
			assertEquals(40, coord2.y);
			
			var coordOutsideExtent: Coord = new Coord(projectionString, 200, 40);
			var coord3: Coord = projectionCRS84Wrappable.moveCoordToExtent(coordOutsideExtent);
			
			assertTrue(coord3);
			assertTrue(coord3 is Coord);
			assertEquals(-160, coord3.x);
			assertEquals(40, coord3.y);
			
			coordOutsideExtent = new Coord(projectionString, 370, 40);
			coord3 = projectionCRS84Wrappable.moveCoordToExtent(coordOutsideExtent);
			
			assertTrue(coord3);
			assertTrue(coord3 is Coord);
			assertEquals(10, coord3.x);
			assertEquals(40, coord3.y);
			
			coordOutsideExtent = new Coord(projectionString, 530, 40);
			coord3 = projectionCRS84Wrappable.moveCoordToExtent(coordOutsideExtent);
			
			assertTrue(coord3);
			assertTrue(coord3 is Coord);
			assertEquals(170, coord3.x);
			assertEquals(40, coord3.y);
			
			coordOutsideExtent = new Coord(projectionString, 550, 40);
			coord3 = projectionCRS84Wrappable.moveCoordToExtent(coordOutsideExtent);
			
			assertTrue(coord3);
			assertTrue(coord3 is Coord);
			assertEquals(-170, coord3.x);
			assertEquals(40, coord3.y);
			
			// negative coordinates
			coordOutsideExtent = new Coord(projectionString, -160, 40);
			coord3 = projectionCRS84Wrappable.moveCoordToExtent(coordOutsideExtent);
			
			assertTrue(coord3);
			assertTrue(coord3 is Coord);
			assertEquals(-160, coord3.x);
			assertEquals(40, coord3.y);
			
			
			coordOutsideExtent = new Coord(projectionString, -190, 40);
			coord3 = projectionCRS84Wrappable.moveCoordToExtent(coordOutsideExtent);
			
			assertTrue(coord3);
			assertTrue(coord3 is Coord);
			assertEquals(170, coord3.x);
			assertEquals(40, coord3.y);
			
			
			coordOutsideExtent = new Coord(projectionString, -2650, 40);
			coord3 = projectionCRS84Wrappable.moveCoordToExtent(coordOutsideExtent);
			
			assertTrue(coord3);
			assertTrue(coord3 is Coord);
			assertEquals(-130, coord3.x);
			assertEquals(40, coord3.y);
			
			
			coordOutsideExtent = new Coord(projectionString, -720, 40);
			coord3 = projectionCRS84Wrappable.moveCoordToExtent(coordOutsideExtent);
			
			assertTrue(coord3);
			assertTrue(coord3 is Coord);
			assertEquals(0, coord3.x);
			assertEquals(40, coord3.y);
		}
		*/
	}
}