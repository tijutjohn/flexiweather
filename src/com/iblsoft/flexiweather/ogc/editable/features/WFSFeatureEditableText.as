package com.iblsoft.flexiweather.ogc.editable.features
{
	import com.iblsoft.flexiweather.ogc.FeatureUpdateContext;
	import com.iblsoft.flexiweather.ogc.data.ReflectionData;
	import com.iblsoft.flexiweather.ogc.data.WFSEditableReflectionData;
	import com.iblsoft.flexiweather.ogc.editable.WFSFeatureEditableWithBaseTimeAndValidity;
	import com.iblsoft.flexiweather.ogc.wfs.IWFSFeatureWithReflection;
	import com.iblsoft.flexiweather.symbology.StyledLineCurveRenderer;
	import com.iblsoft.flexiweather.utils.NumberUtils;
	
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Sprite;
	import flash.filters.GlowFilter;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.text.TextFieldAutoSize;
	
	import mx.core.UITextField;
	
	public class WFSFeatureEditableText extends WFSFeatureEditableWithBaseTimeAndValidity
		implements IWFSFeatureWithReflection
	{
		public var type: String;
		public var pressure: int;
		
		public var text: String = 'Text';
		public var fontFace: String = 'Tahoma';
		public var fontColor: uint = 0x000000;
		public var fontSize: Number = 12;
		public var fontBold: Boolean = false;
		public var fontItalic: Boolean = false;
		public var fontUnderline: Boolean = false;
		
		public var useRectangle: Boolean = true;
		public var borderWidth: Number = 1;
		public var borderStyle: String = 'Solid';
		public var borderColor: uint = 0x00000000;
		
		public var fillStyle: String = 'Solid';
		public var fillColor: uint = 0xFFFFFFFF;
		
		public var textRotation: Number = 0;
		
		public static const smf_pxToPt: Number = 0.35277777910232544;
		
		/**
		 * 
		 */
		public function WFSFeatureEditableText(s_namespace: String, s_typeName: String, s_featureId: String)
		{
			super(s_namespace, s_typeName, s_featureId);
			
		}
	
		override public function update(changeFlag: FeatureUpdateContext): void
		{
			super.update(changeFlag);
	
			var pt: Point = getPoint(0);
			graphics.clear();
	
			var i_color: uint = fontColor;
			var i_borderColor: uint = borderColor;
			var i_fillColor: uint = fillColor;
			
			i_color = getCurrentColor(i_color);
			i_borderColor = getCurrentColor(i_borderColor);
			i_fillColor = getCurrentColor(i_fillColor);
			
			var s_color: String = i_color.toString(16);
			while(s_color.length < 6) s_color = '0' + s_color;
			
			var htmlTextInput: String = '<FONT face="' + fontFace + '" size="' + fontSize + '" color="#' + s_color + '">';
			if (fontBold) htmlTextInput = htmlTextInput + '<B>';
			if (fontItalic) htmlTextInput = htmlTextInput + '<I>';
			if (fontUnderline) htmlTextInput = htmlTextInput + '<U>';
			
			htmlTextInput = htmlTextInput + text;
			
			if (fontUnderline) htmlTextInput = htmlTextInput + '</U>';
			if (fontItalic) htmlTextInput = htmlTextInput + '</I>';
			if (fontBold) htmlTextInput = htmlTextInput + '</B>';
			
			htmlTextInput = htmlTextInput + '</FONT>';
			
			var textSprite: TextSprite;
			var reflection: WFSEditableReflectionData;
			
			//create sprites for reflections
			var totalReflections: uint = ml_movablePoints.totalReflections;
			var blackColor: uint = getCurrentColor(0x000000);
			for (var i: int = 0; i < totalReflections; i++)
			{
				reflection = ml_movablePoints.getReflection(i) as WFSEditableReflectionData;
				if (!reflection.displaySprite)
				{
					textSprite = new TextSprite(master.container); 
					reflection.displaySprite = textSprite;
					addChild(reflection.displaySprite);
				} else {
					textSprite = reflection.displaySprite as TextSprite;
				}
				
				textSprite.update(reflection.points[0], htmlTextInput, textRotation, useRectangle, borderStyle, i_borderColor, borderWidth, fillStyle, i_fillColor);
//				textSprite.x = Point(reflection.points[0]).x;
//				textSprite.y = Point(reflection.points[0]).y;
			}
		}
		
		
		override public function toInsertGML(xmlInsert: XML): void
		{
			var gml: Namespace = new Namespace("http://www.opengis.net/gml");
			super.toInsertGML(xmlInsert);
			
			xmlInsert.appendChild(<text xmlns={ms_namespace}>{text}</text>);
			
			if (useRectangle){
				xmlInsert.appendChild(
				<style xmlns={ms_namespace}>
					<font xmlns={ms_namespace} 
						size={fontSize}
						bold={fontBold}
						italic={fontItalic}
						underline={fontUnderline}
						color={NumberUtils.encodeHTMLColor(fontColor)}>{fontFace}</font>
					<border xmlns={ms_namespace}
						width={borderWidth * smf_pxToPt}
						style={borderStyle}
						color={NumberUtils.encodeHTMLColor(borderColor)}></border>
					<fill xmlns={ms_namespace}
						style={fillStyle}
						color={NumberUtils.encodeHTMLColor(fillColor)}></fill>
				</style>);
			} else {
				xmlInsert.appendChild(
				<style xmlns={ms_namespace}>
					<font xmlns={ms_namespace} 
						size={fontSize}
						bold={fontBold}
						italic={fontItalic}
						underline={fontUnderline}
						color={NumberUtils.encodeHTMLColor(fontColor)}>{fontFace}</font>
				</style>);
			}
			
			xmlInsert.appendChild(<rotation xmlns={ms_namespace}>{textRotation}</rotation>);
		}

		override public function toUpdateGML(xmlUpdate: XML): void
		{
			super.toUpdateGML(xmlUpdate);
			
			addUpdateGMLProperty(xmlUpdate, null, "text/", text);
			addUpdateGMLProperty(xmlUpdate, null, "rotation/", textRotation);
			
			/*
			<wfs:Property>
				<wfs:Name xmlns="http://www.iblsoft.com/wfs">style</wfs:Name>
				<wfs:Value>
				<font size="10" bold="true" italic="false" underline="false" color="#000000">Tahoma</font> 
				<border width="2" style="Dashed" color="#990000" />
				<fill style="BackwardDiagonalLines" color="#993300" />
				</wfs:Value>
			</wfs:Property>
			*/
			
			var borderWidth: Number = borderWidth * smf_pxToPt;
			
			var p: XML = <wfs:Property xmlns:wfs="http://www.opengis.net/wfs"/>;
			var name: XML = <wfs:Name xmlns:wfs="http://www.opengis.net/wfs">style</wfs:Name>;
			var value: XML = <wfs:Value xmlns:wfs="http://www.opengis.net/wfs" xmlns={ms_namespace}/>;
			var font: XML = <font size={fontSize} bold={fontBold} italic={fontItalic} underline={fontUnderline} color={NumberUtils.encodeHTMLColor(fontColor)}>{fontFace}</font> ;
			
			if (!useRectangle)
			{
				borderStyle = 'None';
				fillStyle = 'None';
			}
			var border: XML = <border width={borderWidth} style={borderStyle} color={NumberUtils.encodeHTMLColor(borderColor)} />;
			var fill: XML = <fill style={fillStyle} color={NumberUtils.encodeHTMLColor(fillColor)} />;
			
			
			value.appendChild(font);
			value.appendChild(border);
			value.appendChild(fill);
			
			p.appendChild(name);
			p.appendChild(value);
			
			xmlUpdate.appendChild(p);
			
//			addUpdateGMLProperty(xmlUpdate, null, "style/font/@size", fontSize);
//			addUpdateGMLProperty(xmlUpdate, null, "style/font/@bold", fontBold);
//			addUpdateGMLProperty(xmlUpdate, null, "style/font/@italic", fontItalic);
//			addUpdateGMLProperty(xmlUpdate, null, "style/font/@underline", fontUnderline);
//			addUpdateGMLProperty(xmlUpdate, null, "style/font/@color", NumberUtils.encodeHTMLColor(fontColor));
//			addUpdateGMLProperty(xmlUpdate, null, "style/font", fontFace);
//			
//			if (useRectangle)
//			{
//				addUpdateGMLProperty(xmlUpdate, null, "style/border/@width", borderWidth * smf_pxToPt);
//				addUpdateGMLProperty(xmlUpdate, null, "style/border/@style", borderStyle);
//				addUpdateGMLProperty(xmlUpdate, null, "style/border/@color", NumberUtils.encodeHTMLColor(borderColor));
//				
//				addUpdateGMLProperty(xmlUpdate, null, "style/fill/@style", fillStyle);
//				addUpdateGMLProperty(xmlUpdate, null, "style/fill/@color", NumberUtils.encodeHTMLColor(fillColor));
//			}
		}

		override public function fromGML(gml: XML): void
		{
			super.fromGML(gml);
			var ns: Namespace = new Namespace(ms_namespace);
			
			text = gml.ns::text.toString();
			
			if(gml.ns::style) {
				var style: XMLList = gml.ns::style;
				
				if(style.ns::font) {
					var font: XMLList = style.ns::font;
					
					if(font[0].@size) 
						fontSize = Number(font[0].@size);
					if(font[0].@bold)
						fontBold = (font[0].@bold == 'true') ? true : false;
					if(font[0].@italic)
						fontItalic = (font[0].@italic == 'true') ? true : false;
					if(font[0].@underline)
						fontUnderline = (font[0].@underline == 'true') ? true : false;
					if(font[0].@color) {
						fontColor = NumberUtils.decodeHTMLColor(String(font[0].@color), fontColor);
					}
					
					fontFace = font.toString();
					
					if (style.ns::border && style.ns::fill)
					{
						if (style.ns::border[0] && (String(style.ns::border[0].@width) != ''))
						{
							var xBorder: XMLList = style.ns::border;
							var xFill: XMLList = style.ns::fill;
							
							if(xBorder[0].@width) 
								borderWidth = Number(xBorder[0].@width) / smf_pxToPt;
							if(xBorder[0].@style)
								borderStyle = String(xBorder[0].@style);
							if(xBorder[0].@color)
								borderColor = NumberUtils.decodeHTMLColor(String(xBorder[0].@color), borderColor);
								
							if(xFill[0].@style)
								fillStyle = String(xFill[0].@style);
							if(xFill[0].@color)
								fillColor = NumberUtils.decodeHTMLColor(String(xFill[0].@color), fillColor);
								
							useRectangle = true;
						} else {
							useRectangle = false;
						}
					}
				}
			}
			
			if(gml.ns::rotation) {
				textRotation = Number(gml.ns::rotation[0]);
			}
			
			//type = gml.ns::type[0];
			//pressure = gml.ns::pressureValue[0];
		}
	}
}
import com.iblsoft.flexiweather.symbology.StyledLineCurveRenderer;
import com.iblsoft.flexiweather.utils.draw.DrawMode;
import com.iblsoft.flexiweather.widgets.InteractiveWidget;

import flash.display.Bitmap;
import flash.display.BitmapData;
import flash.display.Sprite;
import flash.geom.Point;
import flash.geom.Rectangle;
import flash.text.TextFieldAutoSize;

import mx.core.UITextField;

class TextSprite extends Sprite
{
	protected var ms_rectSprite: Sprite = new Sprite();
	protected var mtf_text: UITextField = new UITextField();
	
	protected var ms_textSprite: Sprite = new Sprite();
	protected var ms_textBitmap: Bitmap = new Bitmap();
	
	private var mi_borderWidth: int;
	private var mi_borderColor: uint;
	private var mi_fillColor: uint;
	private var ms_borderStyle: String;
	private var ms_fillStyle: String;
	
	private var m_container: InteractiveWidget;
	
	public function TextSprite(container: InteractiveWidget)
	{
		//var nBlur: BlurFilter = new BlurFilter(1.5, 1.5, BitmapFilterQuality.HIGH);
		//ms_textBitmap.filters = [nBlur];
	
		m_container = container;
		
		mtf_text.autoSize = TextFieldAutoSize.LEFT;
		//mtf_text.border = true;
		//mtf_text.background = true;
		//addChild(ms_rectSprite);
		
		ms_textSprite.addChild(ms_rectSprite);
		ms_textSprite.addChild(ms_textBitmap);
		addChild(ms_textSprite);
		//addChild(mtf_text);		
	}
	
	public function getRenderer(reflectionString: String): StyledLineCurveRenderer
	{
		var cr: StyledLineCurveRenderer = new StyledLineCurveRenderer(ms_rectSprite.graphics,
			mi_borderWidth, mi_borderColor, (ms_borderStyle == StyledLineCurveRenderer.STYLE_NONE) ? 0 : 5, ms_borderStyle, ms_fillStyle, mi_fillColor);
	
		return cr;
	}
	
	public function update(point: Point, htmlTextInput: String, textRotation: Number, useRectangle: Boolean, borderStyle: String, borderColor: uint, borderWidth: int, fillStyle: String, fillColor: uint): void
	{
		graphics.clear();
		
		mtf_text.htmlText = htmlTextInput;
		mtf_text.width = mtf_text.textWidth + 4;
		
		mtf_text.x = 0;// - (int(mtf_text.width / 2));
		mtf_text.y = 0;//- (int(mtf_text.height)) - 3;
		
		ms_textBitmap.bitmapData = new BitmapData(mtf_text.width, mtf_text.height, true, 0x00FFFFFF);
		ms_textBitmap.bitmapData.draw(mtf_text, null, null, null, null, true);
		
		//var nGlowFilter: GlowFilter = new GlowFilter(i_color, 1, 1, 1, 2);
		//ms_textBitmap.filters = [nGlowFilter];
		ms_textBitmap.smoothing = true;
		ms_textBitmap.x = - (int(mtf_text.width / 2));
		ms_textBitmap.y = - (int(mtf_text.height)) - 3;
		
		ms_textSprite.x = point.x;
		ms_textSprite.y = point.y;
		ms_textSprite.rotation = textRotation;
		
		ms_rectSprite.graphics.clear();
		
		if (useRectangle)
		{
			mi_borderWidth = borderWidth;
			mi_borderColor = borderColor;
			ms_borderStyle = borderStyle;
			mi_fillColor = fillColor;
			ms_fillStyle = fillStyle;
			
			var cr: StyledLineCurveRenderer = getRenderer('');
			
			var r_rect: Rectangle = new Rectangle(- int(mtf_text.width / 2), - (int(mtf_text.height)) - 3, mtf_text.width, mtf_text.height);
			
			var r_points: Array = new Array();
			r_points.push(new Point(r_rect.left, r_rect.top));
			r_points.push(new Point(r_rect.right, r_rect.top));
			r_points.push(new Point(r_rect.right, r_rect.bottom));
			r_points.push(new Point(r_rect.left, r_rect.bottom));
			r_points.push(new Point(r_rect.left, r_rect.top));
			
//			var coords: Array = [];
//			for each (var p: Point in r_points)
//			{
//				coords.push(m_container.pointToCoord(p.x, p.y));	
//			}	
//			
//			if (coords.length > 1)
//			{
//				m_container.drawGeoPolyLine(getRenderer, coords, DrawMode.GREAT_ARC, true);
//			}
			
//			beginFill(useRectangle, fillStyle, fillColor);
			cr.started(r_points[0].x, r_points[0].y);
			for(var i: uint = 0; i < r_points.length; ++i) {
				if(i == 0) {
					cr.moveTo(r_points[i].x, r_points[i].y);
				} else {
					cr.lineTo(r_points[i].x, r_points[i].y);
				}
			}	
			cr.finished(r_points[r_points.length - 1].x, r_points[r_points.length - 1].y);
//			endFill(useRectangle, fillStyle);
		}
	}
	
	/*
	protected function beginFill(useRectangle: Boolean, fillStyle: String, fillColor: uint): void
	{
		if (useRectangle && (fillStyle != StyledLineCurveRenderer.FILL_STYLE_NONE)){
			ms_rectSprite.graphics.beginBitmapFill(createFillBitmap(fillStyle, fillColor), null, true, false);
		}
	}
	
	protected function endFill(useRectangle: Boolean, fillStyle: String): void
	{
		if (useRectangle && (fillStyle != StyledLineCurveRenderer.FILL_STYLE_NONE)){
			ms_rectSprite.graphics.endFill();
		}
	}
	
	protected function createFillBitmap(fillStyle: String, i_fillColor: uint): BitmapData
	{
		var fillBitmapData: BitmapData = new BitmapData(16, 16, true, 0x00FFFFFF);//, 0x00000000);
		var ix: int;
		var iy: int;
		
		var nBitmap: Bitmap = new Bitmap(fillBitmapData);
		
		switch (fillStyle){
			case StyledLineCurveRenderer.FILL_STYLE_SOLID:
				fillBitmapData.fillRect(new Rectangle(0, 0, 16, 16), getHexARGB(i_fillColor)); //mi_fillColor);
				break;
			case StyledLineCurveRenderer.FILL_STYLE_HORIZONTAL_LINES:
				for (ix = 0; ix < 16; ix++){
					for (iy = 0; iy < 16; iy = iy + 8){
						fillBitmapData.setPixel32(ix, iy, getHexARGB(i_fillColor)); //mi_fillColor);
						//fillBitmapData.setPixel(ix, iy, mi_fillColor);
					}
				}
				break;
			
			case StyledLineCurveRenderer.FILL_STYLE_VERTICAL_LINES:
				for (ix = 0; ix < 16; ix = ix + 8){
					for (iy = 0; iy < 16; iy++){
						fillBitmapData.setPixel32(ix, iy, getHexARGB(i_fillColor));
					}
				}
				break;
			
			case StyledLineCurveRenderer.FILL_STYLE_CROSING_LINES:
				for (ix = 0; ix < 16; ix++){
					for (iy = 0; iy < 16; iy = iy + 8){
						fillBitmapData.setPixel32(ix, iy, getHexARGB(i_fillColor));
					}
				}
				for (ix = 0; ix < 16; ix = ix + 8){
					for (iy = 0; iy < 16; iy++){
						fillBitmapData.setPixel32(ix, iy, getHexARGB(i_fillColor));
					}
				}
				break;
			case StyledLineCurveRenderer.FILL_STYLE_BACKWARD_DIAGONAL_LINES:
				for (ix = 15; ix >= 0; ix--){
					if (ix < 8){
						fillBitmapData.setPixel32(ix, 7 - ix, getHexARGB(i_fillColor));
					}
					fillBitmapData.setPixel32(ix, 15 - ix, getHexARGB(i_fillColor));
					if ((15 - ix + 7) < 16){
						fillBitmapData.setPixel32(ix, 15 - ix + 7, getHexARGB(i_fillColor));
					}
				}
				break;
			case StyledLineCurveRenderer.FILL_STYLE_FORWARD_DIAGONAL_LINES:
				for (ix = 0; ix < 16; ix++){
					if ((ix + 7) < 16){
						fillBitmapData.setPixel32(ix, ix + 7, getHexARGB(i_fillColor));
					}
					fillBitmapData.setPixel32(ix, ix, getHexARGB(i_fillColor));
					if (ix > 7){
						fillBitmapData.setPixel32(ix, 8 - ix, getHexARGB(i_fillColor));
					}
				}
				break;
			case StyledLineCurveRenderer.FILL_STYLE_CROSSING_DIAGONAL_LINES:
				for (ix = 15; ix >= 0; ix--){
					if (ix < 8){
						fillBitmapData.setPixel32(ix, 7 - ix, getHexARGB(i_fillColor));
					}
					fillBitmapData.setPixel32(ix, 15 - ix, getHexARGB(i_fillColor));
					if ((15 - ix + 7) < 16){
						fillBitmapData.setPixel32(ix, 15 - ix + 7, getHexARGB(i_fillColor));
					}
				}
				for (ix = 0; ix < 16; ix++){
					if ((ix + 7) < 16){
						fillBitmapData.setPixel32(ix, ix + 7, getHexARGB(i_fillColor));
					}
					fillBitmapData.setPixel32(ix, ix, getHexARGB(i_fillColor));
					if (ix > 7){
						fillBitmapData.setPixel32(ix, 8 - ix, getHexARGB(i_fillColor));
					}
				}
				break;
		}
		
		return(nBitmap.bitmapData);
	}
	
	protected function getHexARGB(color: uint, n_alpha: Number = 255): uint
	{
		var r: uint = ((color & 0xFF0000) >> 16);
		var g: uint = ((color & 0x00FF00) >> 8);
		var b: uint = ((color & 0x0000FF));
		
		var ret: uint = n_alpha << 24;
		ret += (r << 16);
		ret += (g << 8);
		ret += (b);
		
		return(ret);
	}
	*/
}
