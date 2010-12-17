package com.iblsoft.flexiweather.proj
{
	import flash.geom.Point;
	
	import org.openscales.proj4as.ProjPoint;
	import org.openscales.proj4as.ProjProjection;

	public class Projection
	{
		public static const CRS_GEOGRAPHIC: String = "CRS:84";
		public static const CRS_EPSG_GEOGRAPHIC: String = "EPSG:4326";
		
		protected var m_proj: ProjProjection;
		
		public function Projection(): void
		{
		}

		public static function createByCRS(s_crs: String): Projection
		{
			var p: Projection = new Projection();
			p.m_proj = ProjProjection.getProjProjection(s_crs);
			return p;
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
			return new Coord(Projection.CRS_GEOGRAPHIC, laLoPt.x * 180.0 / Math.PI, laLoPt.y * 180.0 / Math.PI);
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
		
	}
}