package com.iblsoft.flexiweather.ogc.editable.features
{
	import com.iblsoft.flexiweather.ogc.FeatureUpdateContext;
	import com.iblsoft.flexiweather.ogc.GMLUtils;
	import com.iblsoft.flexiweather.ogc.InteractiveLayerWFS;
	import com.iblsoft.flexiweather.ogc.data.ReflectionData;
	import com.iblsoft.flexiweather.ogc.editable.WFSFeatureEditableClosableCurveWithBaseTimeAndValidity;
	import com.iblsoft.flexiweather.ogc.editable.data.FeatureDataPoint;
	import com.iblsoft.flexiweather.ogc.editable.data.FeatureDataReflection;
	import com.iblsoft.flexiweather.ogc.net.loaders.WFSIconLoader;
	import com.iblsoft.flexiweather.ogc.wfs.IWFSFeatureWithReflection;
	import com.iblsoft.flexiweather.ogc.wfs.WFSFeatureEditableSprite;
	import com.iblsoft.flexiweather.proj.Coord;
	import com.iblsoft.flexiweather.proj.Projection;
	import com.iblsoft.flexiweather.utils.CubicBezier;
	import com.iblsoft.flexiweather.utils.GraphicsCurveRenderer;
	import com.iblsoft.flexiweather.utils.ISO8601Parser;
	import com.iblsoft.flexiweather.widgets.InteractiveWidget;
	
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Graphics;
	import flash.display.Sprite;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.utils.setTimeout;
	
	import mx.collections.ArrayCollection;
	import mx.core.Application;
	import mx.core.FlexGlobals;
	import mx.core.UITextField;
	import mx.graphics.ImageSnapshot;
	
	
	/**
	 * For front styles see for example http://en.wikipedia.org/wiki/Weather_front
	 **/	
	public class WFSFeatureEditableVolcanicAsh extends WFSFeatureEditableClosableCurveWithBaseTimeAndValidity
		implements IWFSFeatureWithReflection
	{
		private var mf_iconsWidth: Number = 48;
		
		private var ms_actIconLoaded: String = '';
		
		//TODO add better depedency on InteractiveWidget
		public var iw:InteractiveWidget;
//		public var iw:InteractiveWidget = (FlexGlobals.topLevelApplication as IBrowsingWeather).mainView.iw;
		
		public var values: Object = {
			smooth: false,
			size: 1.0,
			style: "Solid",
			color: 0x000000
		};
		
		public var volcano:Object = {
			number: 01,
			name: "blank",
			la: 0,
			lo: 0,
			coordinate: new Coord(Projection.CRS_EPSG_GEOGRAPHIC, 0,0),
			elev: 0,
			anotation: "none"
		};
		
			
		public function WFSFeatureEditableVolcanicAsh(s_namespace: String, s_typeName: String, s_featureId: String)
		{
			super(s_namespace, s_typeName, s_featureId);
		}
	
		override public function update(changeFlag: FeatureUpdateContext): void
		{
			if(m_coordinates.length != 1
					|| Coord(m_coordinates[0]).equalsCoord(volcano.coordinate)) {
				m_coordinates = [volcano.coordinate];
			}
			
			super.update(changeFlag);
			
			
			
			if (master)
			{
			// create volcano icon
				var pt: Point = master.container.coordToPoint(volcano.coordinate);
				
				var s_iconName: String = 'volcanic_eruption';
				
				// http://wms.iblsoft.com/ria/helpers/gpaint-macro/render/SIGWX/volcanic_eruption?width=24&height=24
				if (s_iconName != ms_actIconLoaded){
					ms_actIconLoaded = s_iconName;
					WFSIconLoader.getInstance().getIcon(s_iconName, this, onIconLoaded, 'SIGWX', mf_iconsWidth, mf_iconsWidth);
				}
				
				
				var volcanicAshSprite: VolcanicAshSprite;
				var reflection: FeatureDataReflection;
				
				//create sprites for reflections
				
				var blackColor: uint = getCurrentColor(0x000000);
				for (var i: int = 0; i < totalReflections; i++)
				{
					reflection = m_featureData.getReflectionAt(i);
					var reflectionDelta: int = reflection.reflectionDelta;
					
					volcanicAshSprite = getDisplaySpriteForReflectionAt(reflectionDelta) as VolcanicAshSprite;
					
					var fdpt: FeatureDataPoint = FeatureDataPoint(reflection.editablePoints[0]);
					
					volcanicAshSprite.update(blackColor);
					
					volcanicAshSprite.x = fdpt.x;
					volcanicAshSprite.y = fdpt.y;
				}
				
			} else {
				setTimeout(update, 1000);
			}
		}
		
		override public function getDisplaySpriteForReflection(id: int): WFSFeatureEditableSprite
		{
			return new VolcanicAshSprite(this, mf_iconsWidth, mf_iconsWidth);
		}
		
		public function onIconLoaded(mBitmap: Bitmap): void
		{
			if (master && mBitmap){
				
				var volcanicAshSprite: VolcanicAshSprite;
				var reflection: FeatureDataReflection;
				
				//create sprites for reflections
				
				var blackColor: uint = getCurrentColor(0x000000);
				for (var i: int = 0; i < totalReflections; i++)
				{
					reflection = m_featureData.getReflectionAt(i);
					var reflectionDelta: int = reflection.reflectionDelta;
					
					volcanicAshSprite = getDisplaySpriteForReflectionAt(reflectionDelta) as VolcanicAshSprite;
					
					volcanicAshSprite.setBitmap(mBitmap.bitmapData);
				}
				
				update(FeatureUpdateContext.fullUpdate());
				master.container.labelLayout.update();
			} else {
				setTimeout(onIconLoaded, 1000, mBitmap);
			}
		}

		/* uncoment if we want disable glow for volcano (only)
		override protected function updateGlow():void
		{
			// sprite1.filters = [ new GlowFilter(i_innerGlowColor, 1, 6, 6, 2), new GlowFilter(i_outterGlowColor, 1, 8, 8, 4) ];
		}
		*/
		
		/**
		 * create average point , then use this point to place anotation
		 * @param points ArrayCollection points
		 * @return calculated average Point
		 */ 
		private function createAveragePoint(points: Array):Point
		{
			var len: int = points.length;
			var ret:Point = new Point();
			for (var i:int = 0; i < len; i++) {
				ret.x = ret.x + points[i].x;
				ret.y = ret.y + points[i].y;
			}
			ret.x = ret.x / len;
			ret.y = ret.y / len;
			
			return ret;
		}
		
		// NOT Supported from webservice at this time
		/**
		 * creates anotation text and place it on average point
		 * @param calculated average Point
		 * @return void
		 */ 
		private function createAnotation(point:Point):void
		{
			var uit:UITextField = new UITextField();
	        uit.text = volcano.anotation; // current presure value
	        uit.width = String(volcano.anotation).length * 7; // calculating width
	        var textBitmapData:BitmapData = ImageSnapshot.captureBitmapData(uit);
	        var matrix:Matrix = new Matrix();
	        matrix.tx = point.x - (uit.width / 2);
	        matrix.ty = point.y + 18; // matrix position
	        graphics.beginBitmapFill(textBitmapData,matrix,false);
	        graphics.drawRect(point.x - (uit.width / 2), point.y+18, uit.measuredWidth, uit.measuredHeight);
		}

		override public function toInsertGML(xmlInsert: XML): void
		{
			var gml: Namespace = new Namespace("http://www.opengis.net/gml");
			addInsertGMLProperty(xmlInsert, null, "baseTime", ISO8601Parser.dateToString(m_baseTime)); 
			addInsertGMLProperty(xmlInsert, null, "validity", ISO8601Parser.dateToString(m_validity));
			xmlInsert.appendChild(<gml:location xmlns:gml="http://www.opengis.net/gml"><gml:Point><gml:pos srsName={volcano.crs}>{volcano.lo} {volcano.la}</gml:pos></gml:Point></gml:location>);
			addInsertGMLProperty(xmlInsert, null, "phenomenonName", volcano.name);
			xmlInsert.appendChild(<cloud><gml:LineString xmlns:gml="http://www.opengis.net/gml">{GMLUtils.encodeGML3Coordinates2D(coordinates)}</gml:LineString></cloud>);
		}

		override public function toUpdateGML(xmlUpdate: XML): void
		{
			var gml: Namespace = new Namespace("http://www.opengis.net/gml");
			addUpdateGMLProperty(xmlUpdate, null, "baseTime", ISO8601Parser.dateToString(m_baseTime)); 
			addUpdateGMLProperty(xmlUpdate, null, "validity", ISO8601Parser.dateToString(m_validity));
			
			var coord:Coord = new Coord(iw.getCRS(), volcano.lo, volcano.la);
			var point: XML = <gml:Point xmlns:gml="http://www.opengis.net/gml"/>;
			point.appendChild(GMLUtils.encodeGML3Coordinates2D([coord]));
			addUpdateGMLProperty(xmlUpdate, "http://www.opengis.net/gml", "location", point);
			
			var line: XML = <gml:LineString xmlns:gml="http://www.opengis.net/gml"></gml:LineString>;
			line.appendChild(GMLUtils.encodeGML3Coordinates2D(getEffectiveCoordinates()));
			addUpdateGMLProperty(xmlUpdate, null, "cloud", line);
			addUpdateGMLProperty(xmlUpdate, null, "phenomenonName", volcano.name);
		}

		override public function fromGML(gml: XML): void
		{
			var ns: Namespace = new Namespace(ms_namespace);
			var nsGML: Namespace = new Namespace("http://www.opengis.net/gml");
			
			m_baseTime = ISO8601Parser.stringToDate(gml.ns::baseTime);
			m_validity = ISO8601Parser.stringToDate(gml.ns::validity);
//			var xmlCurve: XML = gml.ns::cloud[0];
//			var xmlCoordinates: XML = xmlCurve.nsGML::LineString[0];
//			setEffectiveCoordinates(GMLUtils.parseGML3Coordinates2D(xmlCoordinates));
			
			// change color based on time or height
			values = {
				smooth: false,
				size: 1.0,
				style: "Solid",
				color: 0x000000
			};
			
			var xmlLocation: XML = gml.nsGML::location[0]; 
			var xmlPoint: XML = xmlLocation.nsGML::Point[0];
			for each(var node: XML in xmlPoint.children()) {
				var s_coords: String = String(node); 
				var a_bits: Array = s_coords.split(/\s/);
				var s_srs: String = node.@srsName;
			}

			var c: Coord = new Coord(iw.getCRS(), a_bits[0], a_bits[1]);
			var cooPoint:Point = iw.coordToPoint(c);
			
			volcano = {
				number: 01,
				name: gml.ns::phenomenonName[0].toString(),
				la: a_bits[1],
				lo: a_bits[0],
				coordinate: c,
				point: cooPoint,
				elev: 0,
				anotation: "none"
			};
		}
		
		override public function insertPointBefore(i_pointIndex:uint, pt:Point, reflectionID: int = 0):void
		{
			// volcano is a single point feature
			update(FeatureUpdateContext.fullUpdate());
		}
	}
}

import com.iblsoft.flexiweather.ogc.editable.WFSFeatureEditable;
import com.iblsoft.flexiweather.ogc.wfs.WFSFeatureEditableSprite;
import com.iblsoft.flexiweather.utils.ColorUtils;

import flash.display.Bitmap;
import flash.display.BitmapData;
import flash.display.Graphics;
import flash.display.Sprite;
import flash.geom.Point;

class VolcanicAshSprite extends WFSFeatureEditableSprite {
	
	private var m_iconBitmap: Bitmap = new Bitmap();
	private var m_iconBitmapOrig: Bitmap = new Bitmap();
	
	private var sprite1:Sprite;
	private var sprite2:Sprite;
	
	private var graphicsLine:Graphics;
	private var graphicsIcon:Graphics;
	
	public function VolcanicAshSprite(feature: WFSFeatureEditable, wIcon: Number, hIcon: Number)
	{
		super(feature);
		sprite1 = new Sprite();
		sprite2 = new Sprite();
		
		addChild(sprite1);
		addChild(sprite2);
		
		graphicsLine = sprite1.graphics;
		graphicsIcon = sprite2.graphics;
		
		var baseBitmapData: BitmapData = new BitmapData(wIcon, hIcon, true, 0xFFFFFF);
		m_iconBitmap.bitmapData = baseBitmapData;
		addChild(m_iconBitmap);
		
	}
	
	public function setBitmap(nBitmapData: BitmapData): void
	{
		
		m_iconBitmap.bitmapData = nBitmapData.clone();
		m_iconBitmapOrig = new Bitmap(nBitmapData.clone());
		
	}
	
	public function update(blackColor: uint): void
	{
		graphicsLine.clear();
		graphicsIcon.clear();
		
		if (m_iconBitmap)
		{
			m_iconBitmap.x = - m_iconBitmap.width / 2 - 1;
			m_iconBitmap.y = - m_iconBitmap.height / 2 - 20;
			ColorUtils.updateSymbolColor(blackColor, m_iconBitmap, m_iconBitmapOrig);
		}
		
		graphicsIcon.lineStyle(0, 0, 0); // volcano border
		graphicsIcon.beginFill(0xFFFFFF);
		graphicsIcon.drawRect(m_iconBitmap.x - 2, m_iconBitmap.y - 2, m_iconBitmap.width + 4, m_iconBitmap.height + 4);
		graphicsIcon.endFill();
		
		
	}
}