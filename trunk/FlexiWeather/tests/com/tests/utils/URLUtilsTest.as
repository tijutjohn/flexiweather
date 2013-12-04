package com.tests.utils
{
	import com.iblsoft.flexiweather.utils.URLUtils;
	
	import org.flexunit.asserts.assertEquals;

	public class URLUtilsTest
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
		
		[Test]
		public function joinPath1(): void
		{
			var path1: String = 'path1';
			var path2: String = 'path2';
			
			var result: String = URLUtils.pathJoiner(path1, path2);
			
			assertEquals('path1/path2', result);
		}
		
		[Test]
		public function joinPath2(): void
		{
			var path1: String = 'path1/';
			var path2: String = 'path2';
			
			var result: String = URLUtils.pathJoiner(path1, path2);
			
			assertEquals('path1/path2', result);
		}
		
		[Test]
		public function joinPath3(): void
		{
			var path1: String = 'path1/';
			var path2: String = '/path2';
			
			var result: String = URLUtils.pathJoiner(path1, path2);
			
			assertEquals('path1/path2', result);
		}
		
	}
}