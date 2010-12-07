package com.iblsoft.flexiweather.ogc
{
	import com.iblsoft.flexiweather.utils.Serializable;
	import com.iblsoft.flexiweather.utils.Storage;
	import com.iblsoft.flexiweather.utils.UniURLLoader;
	
	import flash.net.URLRequest;
	import flash.net.URLVariables;

	public class AreaConfiguration implements Serializable
	{
		public static const AREA_ICON_WIDTH: int = 60;
		public static const AREA_ICON_HEIGHT: int = 60;
		
		public var crsWithBBox: CRSWithBBox;
		
		internal var ms_default_area: Boolean;
		internal var ms_name: String;
		internal var ms_group_name: String;

		public function get icon(): String
		{
			var url:String = "${BASE_URL}ria?SERVICE=WMS&VERSION=1.3.0&REQUEST=GetMap&LAYERS=background-dem,foreground-lines&STYLES=bright-colours,black-lines-dotted&CRS="+crsWithBBox.crs+"&BBOX="+crsWithBBox.bbox.toBBOXString();
			url += "&WIDTH=" + AREA_ICON_WIDTH + "&HEIGHT=" + AREA_ICON_HEIGHT + "&FORMAT=image/png&TRANSPARENT=TRUE";
			url = UniURLLoader.fromBaseURL(url);
			
			trace("AreaConfiguration icon url : " + url);
			return url;
		}
		public function AreaConfiguration()
		{
		}

		public function serialize(storage: Storage): void
		{
			if(storage.isLoading())
			{
				crsWithBBox = new CRSWithBBox('');
				crsWithBBox.bbox = new BBox(0,0,0,0);
			}
			
			ms_name = storage.serializeString(
					"name", ms_name, null);
			ms_group_name = storage.serializeString(
					"group-name", ms_group_name, null);
			ms_default_area = storage.serializeBool(
					"default", ms_default_area, false);
					
			crsWithBBox.crs = storage.serializeString("crs", crsWithBBox.crs, null);
			
			crsWithBBox.bbox.mf_xMin = storage.serializeInt("min-x", crsWithBBox.bbox.mf_xMin, 0);
			crsWithBBox.bbox.mf_xMax = storage.serializeInt("max-x", crsWithBBox.bbox.mf_xMax, 0);
			crsWithBBox.bbox.mf_yMin = storage.serializeInt("min-y", crsWithBBox.bbox.mf_yMin, 0);
			crsWithBBox.bbox.mf_yMax = storage.serializeInt("max-y", crsWithBBox.bbox.mf_yMax, 0);
		}
		
		public function toRequest(s_request: String): URLRequest
		{
			var r: URLRequest = new URLRequest('${BASE_URL}/ria');
			r.data = new URLVariables();
//			else
//				r.data = new URLVariables(m_data.toString());
			r.data.SERVICE = "WMS";
			r.data.VERSION = "1.3.0";
			r.data.REQUEST = s_request;
			return r;
		}
		
		public function toGetMapURL(): URLRequest
		{
//			var url="{$BASE_URL}/ria?SERVICE=WMS&VERSION=1.3.0&REQUEST=GetMap&LAYERS=background-dem,foreground-lines&CRS="+crsWithBBox.crs+"&BBOX="+crsWithBBox.bbox.toBBOXString();
//			url += "WIDTH=48&HEIGHT=48&FORMAT=image/png&TRANSPARENT=TRUE";
			
			var r: URLRequest = toRequest("GetMap");
			//add background and lines
			r.data.LAYERS = "background-dem,foreground-lines";
//			if(m_service.m_version.isLessThan(1, 3, 0)) 
//				r.data.SRS = s_crs;
//			else 
				r.data.CRS = crsWithBBox.crs; 
			r.data.BBOX = crsWithBBox.bbox.toBBOXString(); 
			r.data.WIDTH = AREA_ICON_WIDTH;
			r.data.HEIGHT = AREA_ICON_HEIGHT;
//			if(s_stylesList != null)
//				r.data.STYLES = s_stylesList;
			r.data.FORMAT = "image/png"; 
			r.data.TRANSPARENT = "TRUE";
			return r;
		}
		
		public function get label(): String
		{ return ms_name; }
		
	}
}