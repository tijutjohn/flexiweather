package com.iblsoft.flexiweather.proj
{
	import com.iblsoft.flexiweather.ogc.BBox;
	import com.iblsoft.flexiweather.ogc.Version;
	import com.iblsoft.flexiweather.ogc.configuration.ProjectionConfiguration;
	
	import flash.geom.Point;
	import flash.utils.Dictionary;
	
	import mx.logging.Log;
	
	import org.openscales.proj4as.ProjConstants;
	import org.openscales.proj4as.ProjPoint;
	import org.openscales.proj4as.ProjProjection;

	public class Projection
	{
		public static const CRS_GEOGRAPHIC: String = "CRS:84";
		public static const CRS_EPSG_GEOGRAPHIC: String = "EPSG:4326";
		
		public static var AVOID_HORIZONTAL_WRAPPING: Boolean;
		
		protected var m_proj: ProjProjection;
		protected var m_extentBBox: BBox;
		protected var mb_wrapsHorizontally: Boolean;
		protected static var m_cache: Dictionary = new Dictionary();
		protected static var md_crsToDetails: Dictionary = new Dictionary();
		
		Projection.addCRSByProj4(
				"CRS:84",
				"+title=Geographic WGS84 +proj=longlat +ellps=WGS84 +datum=WGS84 +units=degrees",
				new BBox(-180, -90, 180, 90), true);
		Projection.addCRSByProj4(
				"EPSG:4326", 
				"+title=WGS 84 +proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs +units=degrees", 
				new BBox(-180, -90, 180, 90), true);
		
//		Projection.setCRSExtentBBox(
//				'EPSG:900913',
//				new BBox(-20037508.34, -20037508.34, 20037508.34, 20037508.34), true);
		Projection.setCRSExtentBBox(
				'CRS:84',
				new BBox(-180, -90, 180, 90), true);

		public function Projection(s_crs: String, extentBBox: BBox, b_wrapsHorizontally: Boolean): void
		{
//			if (s_crs.indexOf("PROJ4:proj=stere +lat_0=90 +lon") >= 0)
//			{
//				trace("PROJ4:proj=stere +lat_0=90 +lon");
//				var obj: Object = ProjProjection.defs;
//				for (var key: String in obj)
//				{
//					var proj: String = ProjProjection.defs[key];
//					trace(key + " = " + proj);
//				}
//			}
			// internally the proj4as creates a dictionary cache of CRS -> ProjProjection pairs
			s_crs = updateCRS(s_crs);
			m_proj = ProjProjection.getProjProjection(s_crs);
			if (m_proj == null)
				Log.getLogger("Projection").error("Unknown CRS '" + s_crs + "'");
			if (extentBBox == null)
				extentBBox = new BBox(-NaN, -NaN, NaN, NaN);
			m_extentBBox = extentBBox;
			mb_wrapsHorizontally = b_wrapsHorizontally;
		}

		static public function hasCRSAxesFlippedByISO(crs: String, version: Version): Boolean
		{
			if (crs == CRS_EPSG_GEOGRAPHIC && (version.equals(1,3,0) || !version.isLessThan(1,3,0)))
				return true;
			
			return false;
				
		}
		public static function isValidProjection(projection: Projection): Boolean
		{
			if (projection && projection.m_proj)
			{
				if (projection.extentBBox && projection.extentBBox.center)
				{
					if (isNaN(projection.extentBBox.width) || isNaN(projection.extentBBox.height))
						return false;
					if (isNaN(projection.extentBBox.center.x) || isNaN(projection.extentBBox.center.y))
						return false;
					return true;
				}
			}
			return false;
		}

		/**
		 * Return Projection defined by CRS String
		 *
		 * @param s_crs
		 * @return
		 *
		 */
		public static function getByCRS(s_crs: String): Projection
		{
			s_crs = updateCRS(s_crs);
			
			var prj: Projection;
			if (s_crs in m_cache)
			{
				prj = m_cache[s_crs];
				if (isValidProjection(prj))
					return prj;
			}
			var extentBBox: BBox = null;
			var b_wrapsHorizontally: Boolean = false;
			if (s_crs in md_crsToDetails)
			{
				extentBBox = md_crsToDetails[s_crs].extentBBox;
				b_wrapsHorizontally = md_crsToDetails[s_crs].b_wrapsHorizontally;
			}
			prj = new Projection(s_crs, extentBBox, b_wrapsHorizontally);
			m_cache[s_crs] = prj;
			return prj;
		}

		/**
		 * Return projection defined by Projection configuration
		 *
		 * @param cfg
		 * @return
		 *
		 */
		public static function getByCfg(cfg: ProjectionConfiguration): Projection
		{
			return getByCRS(cfg.crs);
		}

		private static function updateCRS(s_crs: String): String
		{
			s_crs = s_crs.toUpperCase();
			while(s_crs.search(" ") != -1)
			{
				s_crs = (s_crs as String).replace(" ", "");
			}
			
			return s_crs;
		}
		/**
		 * @param s_crs
		 * @param s_proj4String
		 * @param crsExtentBBox
		 * @param b_crsWrapsHorizontally
		 *
		 */
		public static function addCRSByProj4(
				s_crs: String, s_proj4String: String,
				crsExtentBBox: BBox = null, b_crsWrapsHorizontally: Boolean = false): void
		{
			s_crs = updateCRS(s_crs);
			ProjProjection.defs[s_crs] = s_proj4String;
			md_crsToDetails[s_crs] = {
						extentBBox: crsExtentBBox,
						b_wrapsHorizontally: b_crsWrapsHorizontally
					};
		}

		public static function setCRSExtentBBox(
				s_crs: String, crsExtentBBox: BBox, b_crsWrapsHorizontally: Boolean = false): void
		{
			s_crs = updateCRS(s_crs);
			
			if (!(s_crs in md_crsToDetails))
				md_crsToDetails[s_crs] = {};
			md_crsToDetails[s_crs].extentBBox = crsExtentBBox;
			md_crsToDetails[s_crs].b_wrapsHorizontally = b_crsWrapsHorizontally;
		}

		/** Converts Coord into screen point (pixels) with current CRS. */
		public function prjXYToOtherPrjPt(f_prjX: Number, f_prjY: Number, other: Projection): Point
		{
			var ptInLaLo: Point = prjXYToLaLoPt(f_prjX, f_prjY);
			return other.laLoPtToPrjPt(ptInLaLo);
		}

		public function moveCoordToExtent(coord: Coord): Coord
		{
			if (!m_extentBBox || !m_extentBBox.isValid)
				return coord;
			
			if (coord.x >= m_extentBBox.xMin && coord.x <= m_extentBBox.xMax)
			{
				return coord;
			}
			
			var cx: Number = coord.x;
			
			if (cx < m_extentBBox.xMin)
			{
				cx += Math.ceil((m_extentBBox.xMin - cx) / m_extentBBox.width) * m_extentBBox.width;
			}
				
				
			cx = cx % m_extentBBox.width;
			if (m_extentBBox.xMin < 0 && cx > m_extentBBox.xMax)
				cx -= m_extentBBox.width;
			
				
			if (cx != coord.x)
				coord = new Coord(coord.crs, cx, coord.y);
			
			return coord;
		}
		/**
		 * Converts [x,y] coordinates in this projections into to LaLo cordinates in radians.
		 **/
		public function prjXYToLaLoPt(f_prjX: Number, f_prjY: Number): Point
		{
			if (m_proj == null)
				return null;
			
			var origPoint: ProjPoint = new ProjPoint(f_prjX, f_prjY);
//			trace(" origPoint: " + origPoint);
			var ptDest: ProjPoint = m_proj.inverse(origPoint);
			if (m_proj.projParams.longZero && m_proj.projParams.longZero != 0)
			{
				ptDest.x += m_proj.projParams.longZero
				if (ptDest.x > ProjConstants.PI)
				{
					ptDest.x -= ProjConstants.PI * 2;
					//							trace("ProjStere fixed1: " + p.x);
				}
				if (ptDest.x < (-1 *ProjConstants.PI))
				{
					ptDest.x += ProjConstants.PI * 2;
					//							trace("ProjStere fixed2: " + p.x);
				}
			}
//			trace(" dest: " + ptDest);
			if (ptDest == null)
				return null;
			if (m_proj.projParams.units == "degrees")
				return new Point(ptDest.x / 180.0 * Math.PI, ptDest.y / 180.0 * Math.PI);
			else
				return new Point(ptDest.x, ptDest.y);
		}

		/**
		 * Alternative to prjXYToLaLoPt() accepting Point object at the input.
		 **/
		public function prjPtToLaLoPt(prjPt: Point): Point
		{
			return prjXYToLaLoPt(prjPt.x, prjPt.y);
		}

		/**
		 * Alternative to prjXYToLaLoPt() returning a Coord CRS_GEOGRAPHIC.
		 **/
		public function prjXYToLaLoCoord(f_prjY: Number, f_prjX: Number): Coord
		{
			var laLoPt: Point = prjXYToLaLoPt(f_prjY, f_prjX);
			if (laLoPt)
				return new Coord(Projection.CRS_GEOGRAPHIC, laLoPt.x * 180.0 / Math.PI, laLoPt.y * 180.0 / Math.PI);
			return null;
		}

		/**
		 * Alternative to prjXYToLaLoPt() accepting Point object at the input and returning a Coord CRS_GEOGRAPHIC.
		 **/
		public function prjPtToLaLoCoord(prjPt: Point): Coord
		{
			var laLoPt: Point = prjXYToLaLoPt(prjPt.x, prjPt.y);
			return new Coord(Projection.CRS_GEOGRAPHIC, laLoPt.x * 180.0 / Math.PI, laLoPt.y * 180.0 / Math.PI);
		}

		/**
		 * Converts [f_lo, f_la] coordinates in radians into coordinates in this projections.
		 **/
		public function laLoToPrjPt(f_longitudeRad: Number, f_latitudeRad: Number): Point
		{
			if (m_proj == null)
				return null;
			if (m_proj.projParams.units == "degrees")
			{
				f_longitudeRad *= 180.0 / Math.PI;
				f_latitudeRad *= 180.0 / Math.PI;
			}
			try {
				if (m_proj.projParams.longZero && m_proj.projParams.longZero != 0)
				{
					f_longitudeRad -= m_proj.projParams.longZero;
				}
				var ptDest: ProjPoint = m_proj.forward(new ProjPoint(f_longitudeRad, f_latitudeRad));
			} catch (error: Error) {
				return null;
			}
			if (ptDest == null)
				return null;
			return new Point(ptDest.x, ptDest.y);
		}

		/**
		 * Alternative to laLoToPrjPt() accepting Point object (in radians) as the input.
		 **/
		public function laLoPtToPrjPt(laLoPtRad: Point): Point
		{
			return laLoToPrjPt(laLoPtRad.x, laLoPtRad.y);
		}
		
		/**
		 * Alternative to laLoToPrjPt() accepting Coord object as the input.
		 * 
		 * @param laLoCoord - lalo coord input
		 * @return - Coord in this projection
		 * 
		 */		
		public function laLoCoordToPrjCoord(laLoCoord: Coord): Coord
		{
			if (laLoCoord)
			{
				var toRadiansConst: Number = Math.PI / 180;
				var p: Point = laLoToPrjPt(laLoCoord.x * toRadiansConst, laLoCoord.y * toRadiansConst);
				return new Coord(crs, p.x, p.y);
			}
			return null;
		}

		public static function equalCRSs(s_crs1: String, s_crs2: String): Boolean
		{
			if (s_crs1 == CRS_EPSG_GEOGRAPHIC || s_crs1 == CRS_GEOGRAPHIC)
			{
				if (s_crs2 == CRS_EPSG_GEOGRAPHIC || s_crs2 == CRS_GEOGRAPHIC)
					return true;
			}
			return s_crs1 == s_crs2;
		}

		// getters and setters
		public function get crs(): String
		{
			if (m_proj == null)
				return "?";
			return m_proj.srsCode;
		}

		public function get extentBBox(): BBox
		{
			return m_extentBBox;
		}

		public function get wrapsHorizontally(): Boolean
		{
			if (AVOID_HORIZONTAL_WRAPPING)
				return false;
			
			return mb_wrapsHorizontally;
		}

		public function get name(): String
		{
			if (m_proj == null)
				return "?";
			return m_proj.projName;
		}

		public function get units(): String
		{
			if (m_proj == null)
				return "?";
			return m_proj.projParams.units;
		}

		public function toString(): String
		{
			return "Projection " + name + " units: " + units + " crs: " + crs + " extentBBox: " + extentBBox + " wrap horizontally: " + wrapsHorizontally
		}
	}
}
