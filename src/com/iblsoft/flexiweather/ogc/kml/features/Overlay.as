package com.iblsoft.flexiweather.ogc.kml.features
{
	import com.iblsoft.flexiweather.ogc.kml.controls.KMLBitmapLoader;
	import com.iblsoft.flexiweather.ogc.kml.events.KMLBitmapEvent;
	import com.iblsoft.flexiweather.syndication.ParsingTools;
	import flash.display.Bitmap;
	import flash.display.BitmapData;

	/**
	*	Class that represents an Entry element within an Atom feed
	*
	* 	@langversion ActionScript 3.0
	*	@playerversion Flash 8.5
	*	@tiptext
	*
	* 	@see http://www.atomenabled.org/developers/syndication/atom-format-spec.php#rfc.section.4.1.2
	*/
	public class Overlay extends KMLFeature
	{
//		private var atom:Namespace = Namespaces.ATOM_NS;
//		private var georss:Namespace = Namespaces.GEORSS_NS;
		private var _color: String;
		private var _drawOrder: Number;
		private var _icon: Icon;
		private var _loader: KMLBitmapLoader;

		/**
		*	Constructor for class.
		*
		*	@param x An XML document that contains an individual Entry element from
		*	an Aton XML feed.
		*
		* 	@langversion ActionScript 3.0
		*	@playerversion Flash 8.5
		*	@tiptext
		*/
		public function Overlay(kml: KML, s_namespace: String, x: XMLList)
		{
			super(kml, s_namespace, x);
			var kmlns: Namespace = new Namespace(s_namespace);
			this._color = ParsingTools.nullCheck(this.xml.kmlns::color);
			this._drawOrder = ParsingTools.nanCheck(this.xml.kmlns::drawOrder);
			if (ParsingTools.nullCheck(this.xml.kmlns::Icon))
				this._icon = new Icon(s_namespace, this.xml.kmlns::Icon);
		}

		public override function cleanup(): void
		{
			super.cleanup();
			if (_icon)
			{
				_icon.cleanupKML();
				_icon = null;
			}
		}

		/**
		*	A String that contains the title for the entry.
		*
		* 	@langversion ActionScript 3.0
		*	@playerversion Flash 8.5
		*	@tiptext
		*/
		public function get color(): String
		{
			return this._color;
		}

		/**
		*	A String that contains the title for the entry.
		*
		* 	@langversion ActionScript 3.0
		*	@playerversion Flash 8.5
		*	@tiptext
		*/
		public function get drawOrder(): Number
		{
			return this._drawOrder;
		}

		/**
		  *	A String that contains the title for the entry.
		  *
		  * 	@langversion ActionScript 3.0
		  *	@playerversion Flash 8.5
		  *	@tiptext
		  */
		public function get icon(): Icon
		{
			return this._icon;
		}

		public override function toString(): String
		{
			return "Overlay: " + "color: " + this._color + "drawOrder: " + this._drawOrder + "icon: " + this._icon;
		}
	}
}
