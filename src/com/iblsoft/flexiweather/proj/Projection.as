package com.iblsoft.flexiweather.proj
{
	import com.iblsoft.flexiweather.ogc.ProjectionConfiguration;
	
	import flash.geom.Point;
	import flash.utils.Dictionary;
	
	import mx.logging.Log;
	
	import org.openscales.proj4as.ProjPoint;
	import org.openscales.proj4as.ProjProjection;

	public class Projection
	{
		public static const CRS_GEOGRAPHIC: String = "CRS:84";
		public static const CRS_EPSG_GEOGRAPHIC: String = "EPSG:4326";
		
		protected var m_proj: ProjProjection;

		protected static var m_cache: Dictionary = new Dictionary();
		
		Projection.addCRSByProj4("CRS:84", "+title=Geographic WGS84 +proj=longlat +ellps=WGS84 +datum=WGS84 +units=degrees");

		public function Projection(s_crs: String): void
		{
			// internally the proj4as creates a dictionary cache of CRS -> ProjProjection pairs
			m_proj = ProjProjection.getProjProjection(s_crs);
			if(m_proj == null)
				Log.getLogger("Projection").error("Unknown CRS '" + s_crs + "'");
		}
		
		public static function getByCRS(s_crs: String): Projection
		{
			if(s_crs in m_cache)
				return m_cache[s_crs];
			var prj: Projection = new Projection(s_crs);
			m_cache[s_crs] = prj;
			return prj;
		}
		
		public static function getByCfg(cfg: ProjectionConfiguration): Projection
		{
			return getByCRS(cfg.crs);
		}
		
		public static function addCRSByProj4(s_crs: String, s_proj4String: String): void
		{
			ProjProjection.defs[s_crs] = s_proj4String;
		}
		
		/**
		 * Converts [x,y] coordinates in this projections into to LaLo cordinates in radians.
		 **/
		public function prjXYToLaLoPt(f_prjX: Number, f_prjY: Number): Point
		{
			if(m_proj == null)
				return null;
			var ptDest: ProjPoint = m_proj.inverse(new ProjPoint(f_prjX, f_prjY));
			if(ptDest == null)
				return null;
			if(m_proj.projParams.units == "degrees")
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
			return new Coord(Projection.CRS_GEOGRAPHIC, laLoPt.x, laLoPt.y);
		}
		
		/**
		 * Alternative to prjXYToLaLoPt() accepting Point object at the input and returning a Coord CRS_GEOGRAPHIC.
		 **/
		public function prjPtToLaLoCoord(prjPt: Point): Coord
		{
			var laLoPt: Point = prjXYToLaLoPt(prjPt.x, prjPt.y);
			return new Coord(Projection.CRS_GEOGRAPHIC, laLoPt.x, laLoPt.y);
		}

		/**
		 * Converts [f_lo, f_la] coordinates in radians into coordinates in this projections.
		 **/
		public function laLoToPrjPt(f_longitudeRad: Number, f_latitudeRad: Number): Point
		{
			if(m_proj == null)
				return null;
			if(m_proj.projParams.units == "degrees") {
				f_longitudeRad *= 180.0 / Math.PI;
				f_latitudeRad *= 180.0 / Math.PI;
			}
			var ptDest: ProjPoint = m_proj.forward(new ProjPoint(f_longitudeRad, f_latitudeRad));
			if(ptDest == null)
				return null;
			return new Point(ptDest.x, ptDest.y);
		}

		/**
		 * Alternative to laLoToPrjPt() accepting Point object at the input.
		 **/
		public function laLoPtToPrjPt(laLoPt: Point): Point
		{
			return laLoToPrjPt(laLoPt.x, laLoPt.y);
		}

		public static function equalCRSs(s_crs1: String, s_crs2: String): Boolean
		{
			if(s_crs1 == CRS_EPSG_GEOGRAPHIC || s_crs1 == CRS_GEOGRAPHIC) {
				if(s_crs2 == CRS_EPSG_GEOGRAPHIC || s_crs2 == CRS_GEOGRAPHIC)
					return true;
			}
			return s_crs1 == s_crs2;
		}
		
		public function get crs(): String
		{
			if(m_proj == null)
				return "?";
			return m_proj.srsCode;
		}

		public function get name(): String
		{
			if(m_proj == null)
				return "?";
			return m_proj.projName;
		}

		public function get units(): String
		{
			if(m_proj == null)
				return "?";
			return m_proj.projParams.units;
		}
	}
}