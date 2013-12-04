package com.iblsoft.flexiweather.ogc
{
	import com.iblsoft.flexiweather.net.events.UniURLLoaderEvent;
	import mx.logging.ILogger;
	import mx.rpc.Fault;

	public class ExceptionUtils
	{
		/**
		 * Logs error into log, tranforming serviceResponse object (which should be XML with OGC
		 * ServiceException) into humand readable error message.
		*/
		public static function logError(
				logger: ILogger,
				serviceResponse: Object,
				s_messagePrefix: String = null): void
		{
			if (s_messagePrefix == null)
				s_messagePrefix = ""
			else
				s_messagePrefix = s_messagePrefix + ": ";
			var s_message: String;
			// if serviceResponse is UniURLLoaderEvent then take the "result" as serviceResponse
			if (serviceResponse is UniURLLoaderEvent)
				serviceResponse = UniURLLoaderEvent(serviceResponse).result;
			// now check type of serviceResponse
			if (serviceResponse is XML)
			{ // OGC Service Exception ?
				var s_code: String = "Unknown service exception";
				if (serviceResponse.ServiceException[0])
				{
					s_message = serviceResponse.ServiceException[0];
					if (serviceResponse.ServiceException[0].@code)
						s_code = serviceResponse.ServiceException[0].@code;
				}
				else
					s_message = String(serviceResponse);
				s_message = s_message.replace(/\n/, " ");
				s_message = s_messagePrefix + s_code + ": " + s_message;
			}
			else if (serviceResponse is Fault)
			{ // RPC Fault (generate by UniURLLoader)
				s_message = s_messagePrefix + "I/O fault: "
						+ Fault(serviceResponse).faultString;
				if (Fault(serviceResponse).faultString != null)
					s_message += "(" + Fault(serviceResponse).faultString + ")";
			}
			else
			{ // anything unknown
				s_message = String(serviceResponse);
				s_message = s_message.replace(/\n/, " ");
				s_message = s_messagePrefix + "Unexpected response type: " + s_message;
			}
			logger.error(s_message);
		}
	}
}
