package com.iblsoft.flexiweather.ogc.tiling
{
	import com.iblsoft.flexiweather.ogc.net.loaders.WMSImageLoader;
	import flash.net.URLRequest;
	import flash.utils.Dictionary;

	public class TileJobs
	{
		private var m_jobs: Dictionary;

		public function TileJobs()
		{
			m_jobs = new Dictionary();
		}

		public function addNewTileJobRequest(x: int, y: int, urlLoader: WMSImageLoader, urlRequest: URLRequest): void
		{
			var _existingJob: TileJob = m_jobs[x + "_" + y] as TileJob;
			if (_existingJob)
			{
				_existingJob.cancelRequests();
				_existingJob.urlLoader = urlLoader;
				_existingJob.urlRequest = urlRequest;
			}
			else
				m_jobs[x + "_" + y] = new TileJob(x, y, urlRequest, urlLoader);
		}
	}
}
import com.iblsoft.flexiweather.ogc.net.loaders.WMSImageLoader;
import flash.net.URLRequest;

class TileJob
{
	private var mi_x: int;
	private var mi_y: int;
	private var m_urlRequest: URLRequest;
	private var m_urlLoader: WMSImageLoader;

	public function set urlRequest(value: URLRequest): void
	{
		m_urlRequest = value;
	}

	public function set urlLoader(value: WMSImageLoader): void
	{
		m_urlLoader = value;
	}

	public function TileJob(x: int, y: int, request: URLRequest, loader: WMSImageLoader)
	{
		mi_x = x;
		mi_y = y;
		m_urlRequest = request;
		m_urlLoader = loader;
	}

	public function cancelRequests(): void
	{
		m_urlLoader.cancel(m_urlRequest);
	}
}
