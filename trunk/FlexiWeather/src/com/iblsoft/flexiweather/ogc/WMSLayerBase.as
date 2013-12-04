package com.iblsoft.flexiweather.ogc
{
	import com.iblsoft.flexiweather.ogc.configuration.services.WMSServiceParsingManager;
	import com.iblsoft.flexiweather.proj.Projection;
	
	import flash.utils.getTimer;
	
	public class WMSLayerBase extends GetCapabilitiesXMLItem
	{
		protected var m_parent: WMSLayerGroup;
		protected var ms_title: String;
		
		protected var ma_crsWithBBoxes: Array;
		protected var ma_dimensions: Array;
			
		public function WMSLayerBase(parent: WMSLayerGroup, xml: XML, wmsNamespace: Namespace, version: Version)
		{
            if (!wmsNamespace) {
                wmsNamespace = version.isLessThan(1, 3, 0)
                        ? new Namespace() : new Namespace("http://www.opengis.net/wms");
            }
			super(xml, wmsNamespace, version);
			
			m_parent = parent;
			ms_name = String(xml.wms::Name);
			ms_title = String(xml.wms::Title);
		}
		
		override public function initialize(parsingManager: WMSServiceParsingManager = null): void
		{
			super.initialize(parsingManager);
			
			ma_dimensions = new Array(); 
			ma_crsWithBBoxes = new Array();
			
		}
		
		public function toString(): String
		{
			return "WMSLayer: "+ ms_name + " title: "+ ms_title;
		}
		
		private var _parsed: Boolean;
		
		public function invalidateParsing(): void
		{
			_parsed = false;	
		}
		
//		override public function initialize(bParse: Boolean = false): void
//		{
//			super.initialize(bParse);
//			
//			
//		}
		
		override public function parse(parsingManager: WMSServiceParsingManager = null): void
		{
//			trace("\n\n *******************************************************");
//			trace(this + " size: "+ (m_itemXML.toXMLString()).length);
			
			var currTime: Number = getTimer();
			
			// parse bounding box extents
			if (m_version.isLessThan(1, 3, 0))
			{
				parseOlderVersion();
			}
			else
			{
				parseWMS130();
			}
			
			
			var time1: Number = (getTimer() - currTime);
//			if (time1 >= 5)
//			{
//				trace("\n\n" + this + " parse 1 time: " + time1 + "ms");
//			}
			
			var afterParseTime: Number = getTimer();
			
			if (parent)
			{
				var parentDimensions: Array = parent.dimensions;
				if (parentDimensions && parentDimensions.length > 0)
				{
					// inherit dimensions
//					ma_dimensions.addAll(parent.dimensions);
					ma_dimensions = addAllArrayItems(ma_dimensions, parent.dimensions);
				}
			}
			
			var time2: Number = (getTimer() - afterParseTime);
//			if (time2 >= 5)
//			{
//				trace("\n\n" + this + " parse 2 time: " + time2 + "ms");
//			}
			var afterParseTime2: Number = getTimer();
			
			
			if (parent && parent.crsWithBBoxes && parent.crsWithBBoxes.length > 0)
			{
				var parentCrsWithBBoxes: Array = parent.crsWithBBoxes;
				if (parentCrsWithBBoxes && parentCrsWithBBoxes.length > 0)
				{
					// inherit CRSs and bounding boxes, this may create some duplication (same CRS defined multiple times)
					// but this is not a big problem because if search for bounding box we take the first found item. 
//					ma_crsWithBBoxes.addAll(parent.crsWithBBoxes);
					ma_crsWithBBoxes = addAllArrayItems(ma_crsWithBBoxes, parent.crsWithBBoxes);
					
				}
			}
			
			var time3: Number = (getTimer() - afterParseTime2);
//			if (time3 >= 5)
//			{
//				trace("\n\n" + this + " parse 3 time: " + time3 + "ms");
//			}
				
			var afterParseTime3: Number = getTimer();
			
			parseDimensions();
			
			var time4: Number = (getTimer() - afterParseTime3);
//			if (time4 >= 5)
//			{
//				trace("\n\n" + this + " parse 4 time: " + time4 + "ms");
//			}
			
//			trace(this + " parse total time: " + (getTimer() - currTime) + "ms");
			
			_parsed = true;
//			trace("*******************************************************\n\n");
		}
		
		public function parseDimensions(): void
		{
//			trace("Parse dimension for layer: " + name);
//			if (name.indexOf('temper') >= 0)
//			{
//			trace("TEMPERATURE Parse dimension for layer: " + name);
//				
//			}
			for each (var elemDim: XML in m_itemXML.wms::Dimension)
			{
				var dim: WMSDimension = new WMSDimension(elemDim, wms, m_version);
				dim.parse();
				ma_dimensions.push(dim);
			}
		}
		
		/**
		 * Parsing of layers from GetCapabilities request which is older then 1.3.0 version  
		 * 
		 */		
		protected function parseOlderVersion(): void
		{
			var s_srs: String;
			var srsBBox: BBox = null;
			var bboxXML: XML;
			var a_detectedSRSs: Array = [];
			var boundingBoxList: XMLList = m_itemXML.wms::BoundingBox;
			var i: int 
			var total: int = boundingBoxList.length();
			
			// <BoundingBox SRS=... minx=...
			for (i = 0; i < total; ++i)
			{
				bboxXML = boundingBoxList[i] as XML;
				s_srs = String(bboxXML.@SRS);
				ma_crsWithBBoxes.push(new CRSWithBBox(s_srs, BBox.fromXML_WMS(bboxXML)));
				a_detectedSRSs.push(s_srs);
			}
			// <LatLonBoundingBox minx=...
			if (m_itemXML.wms::LatLonBoundingBox.length() != 0)
			{
				srsBBox = BBox.fromXML_WMS(m_itemXML.wms::LatLonBoundingBox[0]);
				if (a_detectedSRSs.indexOf(Projection.CRS_EPSG_GEOGRAPHIC) < 0)
				{
					ma_crsWithBBoxes.push(new CRSWithBBox(Projection.CRS_EPSG_GEOGRAPHIC, srsBBox));
					a_detectedSRSs.push(Projection.CRS_EPSG_GEOGRAPHIC);
				}
				if (a_detectedSRSs.indexOf(Projection.CRS_EPSG_GEOGRAPHIC) < 0)
				{
					ma_crsWithBBoxes.push(new CRSWithBBox(Projection.CRS_GEOGRAPHIC, srsBBox));
					a_detectedSRSs.push(Projection.CRS_GEOGRAPHIC);
				}
			}
			
			var srsList: XMLList = m_itemXML.wms::SRS;
			var srs: XML;
			total = srsList.length();
			
			// <SRS>
			for (i = 0; i < total; ++i)
			{
				srs = srsList[i] as XML;
				s_srs = String(srs);
				if (a_detectedSRSs.indexOf(s_srs) < 0)
					ma_crsWithBBoxes.push(new CRSWithBBox(s_srs));
			}
			
		}
		
		protected function parseWMS130(): void
		{
			var s_crs: String;
			var crsBBox: BBox = null;
			var bboxXML: XML;
			var a_detectedCRSs: Array = [];
			
			// <BoundingBox CRS=... minx=...
			parseWMS130CRSWithBBoxes(a_detectedCRSs);
			
			// <EX_GeographicBoundingBox minx=...
			if (m_itemXML.wms::EX_GeographicBoundingBox.length() != 0)
			{
				parseWMS130EXGeographicBoundingBox(a_detectedCRSs);
			}
			
			// <Identifier authority=...
			if (m_itemXML.wms::Identifier.@authority == 'http://www.iblsoft.com/wms/ext/getgtile')
			{
				var identifierString: String = m_itemXML.wms::Identifier[0];
				parseWMS130Identifier(identifierString);
			}
			// <CRS>
			parseWMS130CRSs(a_detectedCRSs);
		}
		
		private function parseWMS130CRSWithBBoxes(a_detectedCRSs: Array): void
		{
			var bboxXML: XML;
			
			var boundingBoxList: XMLList = m_itemXML.wms::BoundingBox;
			var i: int 
			var total: int = boundingBoxList.length();
			
			var localArr: Array = ma_crsWithBBoxes;
			
			// <BoundingBox SRS=... minx=...
			for (i = 0; i < total; ++i)
			{
				bboxXML = boundingBoxList[i] as XML;
				
				var s_crs: String = String(bboxXML.@CRS);
				if (Projection.hasCRSAxesFlippedByISO(s_crs, m_version))
				{
					var bbox: BBox = new BBox(bboxXML.@miny, bboxXML.@minx, bboxXML.@maxy, bboxXML.@maxx);
					localArr.push(new CRSWithBBox(s_crs, bbox));
				} else
					localArr.push(new CRSWithBBox(s_crs, BBox.fromXML_WMS(bboxXML)));
				a_detectedCRSs.push(s_crs);
			}

		}
		
		private function parseWMS130EXGeographicBoundingBox(a_detectedCRSs: Array): void
		{
			var crsBBox: BBox = BBox.fromXML_WMS(m_itemXML.wms::EX_GeographicBoundingBox[0]);
			if (a_detectedCRSs.indexOf(Projection.CRS_EPSG_GEOGRAPHIC) < 0)
			{
				ma_crsWithBBoxes.push(new CRSWithBBox(Projection.CRS_EPSG_GEOGRAPHIC, crsBBox));
				a_detectedCRSs.push(Projection.CRS_EPSG_GEOGRAPHIC);
			}
			if (a_detectedCRSs.indexOf(Projection.CRS_GEOGRAPHIC) < 0)
			{
				ma_crsWithBBoxes.push(new CRSWithBBox(Projection.CRS_GEOGRAPHIC, crsBBox));
				a_detectedCRSs.push(Projection.CRS_GEOGRAPHIC);
			}
		}
		
		private function parseWMS130CRSs(a_detectedCRSs: Array): void
		{
			var crsList: XMLList = m_itemXML.wms::CRS
			var crs: XML;
			var total: int = crsList.length();
			var i: int;
			var localArr: Array = ma_crsWithBBoxes;
			for (i = 0; i < total; i++)
			{
				crs = crsList[i] as XML;
				var s_crs: String = String(crs);
				if (a_detectedCRSs.indexOf(s_crs) < 0)
				{
					var crsWithBBox: CRSWithBBox = new CRSWithBBox(s_crs)
//					ma_crsWithBBoxes.push(crsWithBBox);
					localArr.push(crsWithBBox);
				}
			}
//			addAllArrayItems(ma_crsWithBBoxes, localArr);
		}
		
		private function parseWMS130Identifier(identifierString: String): void
		{
			var originalCRSWithBBox: CRSWithBBox;
			
			var identifierArray: Array = identifierString.split(';');
			var tileWidth: int = 0;
			var tileHeight: int = 0;
			var arr: Array;
			var crsBBoxTiled: CRSWithBBoxAndTilingInfo;
			
			var item: String;
			var total: int = identifierArray.length;
			var i: int;
			var j: int;
			for (j = 0; j < total; j++)
			{
				item = identifierArray[j] as String;
				
				if (item.indexOf('size:') == 0)
				{
					arr = item.split(':');
					arr = (arr[1] as String).split('x');
					tileWidth = arr[0];
					tileHeight = arr[1];
				}
				if (item.indexOf('crs-boundary:') == 0)
				{
					item = item.substring('crs-boundary:'.length, item.length);
					arr = item.split('[');
					var s_tilingCRS: String = arr[0];
					var s_tilingExtent: String = (arr[1] as String);
					s_tilingExtent = s_tilingExtent.substr(0, s_tilingExtent.length - 1);
					arr = s_tilingExtent.split(',');
					
					var tilingExtent: BBox;
					if (Projection.hasCRSAxesFlippedByISO(s_tilingCRS, m_version))
					 	tilingExtent = new BBox(Number(arr[1]), Number(arr[0]), Number(arr[3]), Number(arr[2]));
					else
					 	tilingExtent = new BBox(Number(arr[0]), Number(arr[1]), Number(arr[2]), Number(arr[3]));
						
					var b_crsFound: Boolean = false;
					
					var crsWithBBoxesTotal: int = ma_crsWithBBoxes.length;
					for (i = 0; i < crsWithBBoxesTotal; i++)
					{
						originalCRSWithBBox = ma_crsWithBBoxes[i] as CRSWithBBox;
						if (originalCRSWithBBox.crs == s_tilingCRS)
						{
							b_crsFound = true;
							if (originalCRSWithBBox is CRSWithBBoxAndTilingInfo)
								trace("WMSLayerBase.WMSLayerBase(): already having CRSWithBBoxAndTilingInfo for " + s_tilingCRS);
							else
							{
								//TODO we support just tileSize... if you need support tileWidth and tileHeight, change it here as well
								crsBBoxTiled = new CRSWithBBoxAndTilingInfo(
									originalCRSWithBBox.crs, originalCRSWithBBox.bbox,
									tilingExtent, tileWidth);
								ma_crsWithBBoxes[i] = crsBBoxTiled;
							}
							break;
						}
					}
					//there is no such crs already defined, add it as new CRS
					if (!b_crsFound)
					{
						//TODO we support just tileSize... if you need support tileWidth and tileHeight, change it here as well
						crsBBoxTiled = new CRSWithBBoxAndTilingInfo(
							s_tilingCRS, null,
							tilingExtent, tileWidth);
						ma_crsWithBBoxes.push(crsBBoxTiled);
					}
				}
			}
		}
		

		private function getCRSWithBBox(crs: String): CRSWithBBox
		{
			
			if (!_parsed)
			{
				parse();
			}
			
			var i: int;
			var crsWithBBox: CRSWithBBox;
			var crsWithBBoxesTotal: int = ma_crsWithBBoxes.length;
			for (i = 0; i < crsWithBBoxesTotal; i++)
			{
				crsWithBBox = ma_crsWithBBoxes[i] as CRSWithBBox;
				
				if (crsWithBBox.crs == crs)
					return crsWithBBox;
			}
			return null;
		}

		public function equals(other: WMSLayer): Boolean
		{
			if (!_parsed)
			{
				parse();
			}
			if (other == null)
				return false;
			if (ms_name != other.name)
				return false;
			if (ms_title != other.title)
				return false;
			if (!ma_crsWithBBoxes || !other.crsWithBBoxes || ma_crsWithBBoxes.length != other.crsWithBBoxes.length)
				return false;
			
			var i: int;
			var total: int = ma_crsWithBBoxes.length; 
			for (i = 0; i < total; ++i)
			{
				var cb: CRSWithBBox = ma_crsWithBBoxes[i] as CRSWithBBox;
				if (!cb.equals(other.crsWithBBoxes[i] as CRSWithBBox))
					return false;
			}
			if (ma_dimensions.length != other.dimensions.length)
				return false;
			
			var dimTotal: int = ma_dimensions.length;
			for (i = 0; i < dimTotal ; ++i)
			{
				if (!ma_dimensions[i].equals(other.dimensions[i]))
					return false;
			}
			return true;
		}

		public function enumerateAllCRSs(a_out: Array): void
		{
			if (!_parsed)
			{
				parse();
			}
			
			var i: int;
			var total: int = ma_crsWithBBoxes.length;
			var crsBBox: CRSWithBBox;
			
			// <BoundingBox SRS=... minx=...
			for (i = 0; i < total; ++i)
			{
				crsBBox = ma_crsWithBBoxes[i] as CRSWithBBox
				if (!a_out.contains(crsBBox.crs))
					a_out.push(crsBBox.crs);
			}
			parent.enumerateAllCRSs(a_out);
		}

		public function getBBoxForCRS(s_crs: String): BBox
		{
			if (!_parsed)
			{
				parse();
			}
			
			var i: int;
			var total: int = ma_crsWithBBoxes.length;
			var crsBBox: CRSWithBBox;
			
			// <BoundingBox SRS=... minx=...
			for (i = 0; i < total; ++i)
			{
				crsBBox = ma_crsWithBBoxes[i] as CRSWithBBox;
				if (Projection.equalCRSs(s_crs, crsBBox.crs))
				{
					if (crsBBox.bbox != null)
						return crsBBox.bbox;
				}
			}
			if (parent == null)
				return null;
			return parent.getBBoxForCRS(s_crs);
		}
		
		public function destroy(): void
		{
			if (ma_crsWithBBoxes && ma_crsWithBBoxes.length > 0)
			{
				var i: int;
				var total: int = ma_crsWithBBoxes.length;
				var crsBBox: CRSWithBBox;
				
				// <BoundingBox SRS=... minx=...
				for (i = 0; i < total; ++i)
				{
					crsBBox = ma_crsWithBBoxes[i] as CRSWithBBox;
					crsBBox.destroy();
				}
				removeAllArrayItems(ma_crsWithBBoxes);
			}
			ma_crsWithBBoxes = null;
			if (ma_dimensions && ma_dimensions.length > 0)
			{
				var wmsDimension: WMSDimension;
				total = ma_dimensions.length;
				for (i = 0; i < total; ++i)
				{
					wmsDimension = ma_dimensions[i] as WMSDimension;
					wmsDimension.destroy();
				}
				removeAllArrayItems(ma_dimensions);
			}
			ma_dimensions = null;
			if (m_parent)
				m_parent.destroy();
		}
		
		public function get parent(): WMSLayerGroup
		{
			return m_parent;
		}
		public function set parent(value: WMSLayerGroup): void
		{
			m_parent = value;
		}

		public function get title(): String
		{
			return ms_title;
		}

		public function get crsWithBBoxes(): Array
		{
			if (!_parsed)
			{
				parse();
			}
			return ma_crsWithBBoxes;
		}

		public function get dimensions(): Array
		{
			if (!_parsed)
			{
				parse();
			}
			return ma_dimensions;
		}
		
		public function get parsedDimensions(): Array
		{
			return ma_dimensions;
		}

		public function get label(): String
		{
			if (ms_title == null || ms_title.length == 0)
			{
				if (ms_name == null || ms_name.length == 0)
					return "[unnamed layer]";
				return ms_name;
			}
			if (ms_name == null || ms_name.length == 0)
				return ms_title;
			return ms_title + " (" + ms_name + ")";
		}
	}
}
