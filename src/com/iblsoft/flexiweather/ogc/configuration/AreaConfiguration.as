package com.iblsoft.flexiweather.ogc.configuration
{
	import com.iblsoft.flexiweather.net.loaders.AbstractURLLoader;
	import com.iblsoft.flexiweather.net.loaders.UniURLLoader;
	import com.iblsoft.flexiweather.utils.Serializable;
	import com.iblsoft.flexiweather.utils.Storage;
	import flash.geom.Rectangle;
	import flash.net.URLRequest;
	import flash.net.URLVariables;
	import com.iblsoft.flexiweather.ogc.managers.ProjectionConfigurationManager;
	import com.iblsoft.flexiweather.ogc.BBox;

	public class AreaConfiguration implements Serializable
	{
		public static const AREA_ICON_WIDTH: int = 60;

		public static const AREA_ICON_HEIGHT: int = 60;

		public var projection: ProjectionConfiguration;

		private var ms_default_area: Boolean;

		public function get isDefaultArea(): Boolean
		{
			return ms_default_area;
		}

		public function set isDefaultArea(value: Boolean): void
		{
			if (value != ms_default_area)
				ms_default_area = value;
		}

		private var ms_name: String;

		public function get name(): String
		{
			return ms_name;
		}

		public function set name(value: String): void
		{
			if (value != ms_name)
				ms_name = value;
		}

		public function get icon(): String
		{
			if (!_thumbBBox)
				createThumbnailBBox();
			var w: int = AREA_ICON_WIDTH;
			var h: int = AREA_ICON_WIDTH;
			var rect: Rectangle = projection.bbox.toRectangle();
			var aspectRatio: Number = rect.width / rect.height;
			if (aspectRatio > 1)
				w *= aspectRatio;
			else
				h /= aspectRatio;
			var url: String;
			url = "${BASE_URL}/ria?SERVICE=WMS&VERSION=1.3.0&REQUEST=GetMap&LAYERS=background-dem,foreground-lines&STYLES=bright-colours,black-lines-dotted&CRS=" + projection.crs;
			if (!_thumbBBox)
				url += "&BBOX=" + projection.bbox.toBBOXString();
			else
				url += "&BBOX=" + _thumbBBox.toBBOXString();
			url += "&WIDTH=" + w + "&HEIGHT=" + h + "&FORMAT=image/png&TRANSPARENT=TRUE";
			url = AbstractURLLoader.fromBaseURL(url);
//			trace("AreaConfiguration icon ["+w+","+h+"] url : " + url);
			return url;
		}

		public function AreaConfiguration()
		{
		}

		public function serialize(storage: Storage): void
		{
			if (storage.isLoading())
				projection = new ProjectionConfiguration();
			ms_name = storage.serializeString(
					"name", ms_name, null);
			ms_default_area = storage.serializeBool(
					"default", ms_default_area, false);
			var _crs: String = storage.serializeString("crs", projection.crs, null);
			var xMin: Number = storage.serializeNumber("min-x", projection.bbox.xMin, 0);
			var yMin: Number = storage.serializeNumber("min-y", projection.bbox.yMin, 0);
			var xMax: Number = storage.serializeNumber("max-x", projection.bbox.xMax, 0);
			var yMax: Number = storage.serializeNumber("max-y", projection.bbox.yMax, 0);
			var newProjectionBBox: BBox = new BBox(xMin, yMin, xMax, yMax);
			if (storage.isLoading())
				projection = new ProjectionConfiguration(_crs, newProjectionBBox);
			createThumbnailBBox();
		}

		private var _thumbBBox: BBox;

		public function update(): void
		{
			createThumbnailBBox();
		}

		public function get maxExtent(): BBox
		{
			var maxExtent: BBox = ProjectionConfigurationManager.getInstance().getMaxExtentForProjection(projection);
			if (maxExtent)
				return maxExtent;
			if (projection && projection.bbox)
				return projection.bbox;
			return null;
		}

		private function createThumbnailBBox(): void
		{
			return;
			if (projection && projection.bbox)
			{
				return;
				if (maxExtent.equals(projection.bbox))
					return;
				var rect: Rectangle = projection.bbox.toRectangle();
				var aspectRatio: Number = rect.width / rect.height;
				if (aspectRatio > 1)
					_thumbBBox = projection.bbox.scaled(1, aspectRatio);
				else
					_thumbBBox = projection.bbox.scaled(1 / aspectRatio, 1);
				debugBBoxes()
			}
		}

		private function debugBBoxes(): void
		{
			var rect: Rectangle = projection.bbox.toRectangle();
			var aspectRatio: Number = rect.width / rect.height;
//			trace("AREA ["+name+"] projection BBOX aspectRatio: " + aspectRatio);
			if (_thumbBBox)
			{
				rect = _thumbBBox.toRectangle();
				aspectRatio = rect.width / rect.height;
//				trace("AREA ["+name+"] _thumbBBox aspectRatio: " + aspectRatio);
			}
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
			var r: URLRequest = toRequest("GetMap");
			//add background and lines
			r.data.LAYERS = "background-dem,foreground-lines";
//			if(m_service.m_version.isLessThan(1, 3, 0)) 
//				r.data.SRS = s_crs;
//			else 
			r.data.CRS = projection.crs;
			r.data.BBOX = projection.bbox.toBBOXString();
			r.data.WIDTH = AREA_ICON_WIDTH;
			r.data.HEIGHT = AREA_ICON_HEIGHT;
//			if(s_stylesList != null)
//				r.data.STYLES = s_stylesList;
			r.data.FORMAT = "image/png";
			r.data.TRANSPARENT = "TRUE";
			return r;
		}

		public function get label(): String
		{
			return ms_name;
		}
	}
}
