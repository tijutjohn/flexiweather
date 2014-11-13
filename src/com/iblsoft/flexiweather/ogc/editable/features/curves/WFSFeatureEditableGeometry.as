package com.iblsoft.flexiweather.ogc.editable.features.curves
{
	import com.iblsoft.flexiweather.ogc.FeatureUpdateContext;
	import com.iblsoft.flexiweather.ogc.editable.WFSFeatureEditable;
	import com.iblsoft.flexiweather.ogc.editable.WFSFeatureEditableClosableCurveWithBaseTimeAndValidity;
	import com.iblsoft.flexiweather.ogc.wfs.IWFSCurveFeature;
	import com.iblsoft.flexiweather.ogc.wfs.IWFSFeatureWithReflection;
	import com.iblsoft.flexiweather.ogc.wfs.WFSFeatureEditableSprite;
	import com.iblsoft.flexiweather.proj.Coord;
	import com.iblsoft.flexiweather.symbology.StyledLineCurveRenderer;
	import com.iblsoft.flexiweather.utils.CubicBezier;
	import com.iblsoft.flexiweather.utils.ICurveRenderer;
	import com.iblsoft.flexiweather.utils.NumberUtils;
	import com.iblsoft.flexiweather.utils.draw.DrawMode;
	import com.iblsoft.flexiweather.utils.draw.FillStyle;

	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Graphics;
	import flash.geom.Point;
	import flash.geom.Rectangle;

	import mx.collections.ArrayCollection;
	import mx.managers.CursorManager;

	public class WFSFeatureEditableGeometry extends WFSFeatureEditableClosableCurveWithBaseTimeAndValidity implements IWFSFeatureWithReflection
	{
		public var mf_size: Number = 1.0;
		public var ms_style: String = "Solid";
		public var mi_color: uint = 0x000000;

		public var ms_fillStyle: String = "None";
		public var mi_fillColor: uint = 0x000000;

		[Embed(source="/assets/cursors/cursor_default.png")]
		public var defCursor:Class;


		public static const smf_pxToPt: Number = 0.35277777910232544;

		public function WFSFeatureEditableGeometry(s_namespace: String, s_typeName: String, s_featureId: String)
		{
			super(s_namespace, s_typeName, s_featureId);

			//CursorManager.setCursor(defCursor);

		}

		override public function isCurveFilled(): Boolean
		{
			return ms_fillStyle != StyledLineCurveRenderer.FILL_STYLE_NONE;
		}

//		override public function isCurveClosed(): Boolean
//		{
//			return mb_closed || (ms_fillStyle != StyledLineCurveRenderer.FILL_STYLE_NONE);
//		}
		override public function getRenderer(reflection: int): ICurveRenderer
		{
			var i_color: uint = getCurrentColor(mi_color);
			var i_fillColor: uint = getCurrentColor(mi_fillColor);

			var gr: Graphics = getRendererGraphics(reflection);

			var cr: StyledLineCurveRenderer = new StyledLineCurveRenderer(gr,
				mf_size, i_color, 5, ms_style, ms_fillStyle, i_fillColor);

			return cr;
		}

		override public function getDisplaySpriteForReflection(id: int): WFSFeatureEditableSprite
		{
			return new GeometryFeatureSprite(this);
		}



		override public function toInsertGML(xmlInsert: XML): void
		{
			super.toInsertGML(xmlInsert);

			var ns: Namespace = new Namespace(ms_namespace);

			xmlInsert.appendChild(
				<style xmlns={ms_namespace} smooth={smooth ? "true" : "false"}>
					<pen xmlns={ms_namespace} width={mf_size * smf_pxToPt} style={ms_style} color={NumberUtils.encodeHTMLColor(mi_color)}/>
					<fill xmlns={ms_namespace} style={ms_fillStyle} color={NumberUtils.encodeHTMLColor(mi_fillColor)}/>
				</style>);
		}

		override public function toUpdateGML(xmlUpdate: XML): void
		{
			super.toUpdateGML(xmlUpdate);

			addUpdateGMLProperty(xmlUpdate, null, "style/@smooth", smooth ? "true" : "false");
			addUpdateGMLProperty(xmlUpdate, null, "style/pen/@width", mf_size * smf_pxToPt);
			addUpdateGMLProperty(xmlUpdate, null, "style/pen/@style",ms_style);
			addUpdateGMLProperty(xmlUpdate, null, "style/pen/@color",NumberUtils.encodeHTMLColor(mi_color));
			addUpdateGMLProperty(xmlUpdate, null, "style/fill/@style",ms_fillStyle);
			addUpdateGMLProperty(xmlUpdate, null, "style/fill/@color",NumberUtils.encodeHTMLColor(mi_fillColor));


//			xmlUpdate.appendChild(
//				<wfs:Property xmlns:wfs="http://www.opengis.net/wfs">
//					<wfs:Name>style</wfs:Name>
//					<wfs:Value>
//						<style smooth={smooth ? "true" : "false"}>
//							<pen width={mf_size * smf_pxToPt} style={ms_style} color={NumberUtils.encodeHTMLColor(mi_color)}/>
//							<fill xmlns={ms_namespace} style={ms_fillStyle} color={NumberUtils.encodeHTMLColor(mi_fillColor)}/>
//						</style>
//					</wfs:Value>
//				</wfs:Property>);
		}

		override public function fromGML(gml: XML): void
		{
			super.fromGML(gml);
			var ns: Namespace = new Namespace(ms_namespace);
			smooth = true;
			mf_size = 1.0;
			ms_style = "Solid";
			mi_color = 0x000000;

			ms_fillStyle = "None";
			mi_fillColor = 0x000000;

			if(gml.ns::style) {
				var style: XMLList = gml.ns::style;
				smooth = Boolean(style.@smooth == "true");
				if(style.ns::pen) {
					var pen: XMLList = style.ns::pen;
					if(pen[0].@width)
						mf_size = Number(pen[0].@width) / smf_pxToPt;
					if(pen[0].@style)
						ms_style = String(pen[0].@style);
					if(pen[0].@color) {
						mi_color = NumberUtils.decodeHTMLColor(String(pen[0].@color), mi_color);
					}
				}
				if(style.ns::fill) {
					var fill: XMLList = style.ns::fill;
					if(fill[0].@style)
						ms_fillStyle = String(fill[0].@style);
					if(fill[0].@color) {
						mi_fillColor = NumberUtils.decodeHTMLColor(String(fill[0].@color), mi_fillColor);
					}
				}
			};
		}



		override public function clone(): WFSFeatureEditable
		{
			var ret: WFSFeatureEditableGeometry = super.clone() as WFSFeatureEditableGeometry;
			ret.smooth = smooth;
			ret.mf_size = mf_size;
			ret.ms_style = ms_style;
			ret.mi_color = mi_color;
			return ret;
		}
	}
}

import com.iblsoft.flexiweather.ogc.editable.WFSFeatureEditable;
import com.iblsoft.flexiweather.ogc.editable.features.curves.withAnnotation.WFSFeatureEditableCloud;
import com.iblsoft.flexiweather.ogc.wfs.WFSFeatureEditableSprite;
import com.iblsoft.flexiweather.utils.CubicBezier;
import com.iblsoft.flexiweather.utils.geometry.LineSegment;

import flash.geom.Point;

class GeometryFeatureSprite extends WFSFeatureEditableSprite
{
	override public function set visible(value:Boolean):void
	{
		super.visible = value;
	}

	public function GeometryFeatureSprite(feature: WFSFeatureEditable)
	{
		super(feature);
	}

//	public override function getLineSegmentApproximation(): Array
//	{
//		if(smooth)
//			return createSmoothLineSegmentApproximation();
//		else
//			return createStraightLineSegmentApproximation();
//	}

	override public function getLineSegmentApproximationOfBounds():Array
	{
		var a: Array = [];
		var ptFirst: Point = null;
		var ptPrev: Point = null;

		var cloudFeature: WFSFeatureEditableCloud = _feature as WFSFeatureEditableCloud;
		var pts: Array = CubicBezier.calculateHermitSpline(points, cloudFeature.isCurveClosed());

		var useEvery: int = 1;
		if (pts.length > 100){
			useEvery = int(pts.length / 20);
		} else if (pts.length > 50){
			useEvery = int(pts.length / 10);
		}

		var actPUse: int = 0;
		for each(var pt: Point in pts) {
			if ((actPUse % useEvery) == 0){
				if(ptPrev != null)
					a.push(new LineSegment(ptPrev.x, ptPrev.y, pt.x, pt.y));
				ptPrev = pt;
			}
			actPUse++;
		}

		return a;
	}
}
