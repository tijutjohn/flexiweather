package com.iblsoft.flexiweather.ogc.editable.features.curves.withAnnotation
{
	import com.iblsoft.flexiweather.ogc.FeatureUpdateContext;
	import com.iblsoft.flexiweather.ogc.InteractiveLayerFeatureBase;
	import com.iblsoft.flexiweather.ogc.InteractiveLayerWFS;
	import com.iblsoft.flexiweather.ogc.editable.IClosableCurve;
	import com.iblsoft.flexiweather.ogc.editable.WFSFeatureEditable;
	import com.iblsoft.flexiweather.ogc.editable.WFSFeatureEditableClosableCurveWithBaseTimeAndValidityAndAnnotation;
	import com.iblsoft.flexiweather.ogc.editable.WFSFeatureEditableCurveWithBaseTimeAndValidity;
	import com.iblsoft.flexiweather.ogc.editable.WFSFeatureEditableCurveWithBaseTimeAndValidityAndAnnotation;
	import com.iblsoft.flexiweather.ogc.editable.data.FeatureData;
	import com.iblsoft.flexiweather.ogc.editable.data.FeatureDataReflection;
	import com.iblsoft.flexiweather.ogc.wfs.IWFSFeatureWithAnnotation;
	import com.iblsoft.flexiweather.ogc.wfs.IWFSFeatureWithReflection;
	import com.iblsoft.flexiweather.ogc.wfs.WFSFeatureEditableSprite;
	import com.iblsoft.flexiweather.proj.Coord;
	import com.iblsoft.flexiweather.symbology.IcingCurveRenderer;
	import com.iblsoft.flexiweather.symbology.StyledLineCurveRenderer;
	import com.iblsoft.flexiweather.utils.AnnotationBox;
	import com.iblsoft.flexiweather.utils.AnnotationTextBox;
	import com.iblsoft.flexiweather.utils.CubicBezier;
	import com.iblsoft.flexiweather.utils.ICurveRenderer;
	import com.iblsoft.flexiweather.utils.NumberUtils;
	import com.iblsoft.flexiweather.utils.anticollision.AnticollisionLayout;
	import com.iblsoft.flexiweather.utils.anticollision.AnticollisionLayoutObject;
	import com.iblsoft.flexiweather.utils.anticollision.IAnticollisionLayoutObject;
	import com.iblsoft.flexiweather.utils.draw.DrawMode;
	import com.iblsoft.flexiweather.utils.geometry.ILineSegmentApproximableBounds;
	import com.iblsoft.flexiweather.utils.geometry.LineSegment;
	
	import flash.display.DisplayObject;
	import flash.display.Graphics;
	import flash.geom.Point;
	import flash.text.TextFormat;
	
	import mx.collections.ArrayCollection;
	import mx.controls.Text;
	import mx.controls.TextArea;
	import mx.controls.ToolTip;
	import mx.managers.ToolTipManager;

	public class WFSFeatureEditableAnnotation extends WFSFeatureEditableClosableCurveWithBaseTimeAndValidityAndAnnotation
			implements IWFSFeatureWithAnnotation, IWFSFeatureWithReflection, IClosableCurve
	{
		public static const ANNOTATION_PIN: String = "pin";
		public static const ANNOTATION_POLYLINE: String = "polyline";
		public static const ANNOTATION_POLYGON: String = "polygon";
		public static const ANNOTATION_SMOOTH_CURVE: String = "smooth-curve";
		public static const ANNOTATION_SMOOTH_AREA: String = "smooth-area";
		
		public var ms_type: String = ANNOTATION_POLYLINE;
		public var ms_text: String = "";
		public var mi_lineColor: uint = 0xff0000;
		
		override public function set visible(value:Boolean):void
		{
			super.visible = value;
			
//			if(ma_activeLabels.length) {
//				for each(var dispObject: DisplayObject in ma_activeLabels) {
//					dispObject.visible = value;
//				}
//			}
		}
		
		private var ma_activeLabels: Array = [];
		
		public static const smf_pxToPt: Number = 0.35277777910232544;
		
		public function WFSFeatureEditableAnnotation(s_namespace: String, s_typeName: String, s_featureId: String)
		{
			super(s_namespace, s_typeName, s_featureId);
		}
		
		override public function getRenderer(reflection: int): ICurveRenderer
		{
			var i_color: uint = getCurrentColor(mi_lineColor);
			
			var renderer: StyledLineCurveRenderer;
			var gr: Graphics = getRendererGraphics(reflection);
			
			renderer = new StyledLineCurveRenderer(gr, 3.0, i_color, 1.0, "Solid", "None", i_color);
			
			return renderer;
		}
		
		override public function getDisplaySpriteForReflection(id: int): WFSFeatureEditableSprite
		{
			return new AnnotationSprite(this);
		}
		
		override public function createAnnotation(): AnnotationBox
		{
			return new AnnotationTextBox();
		}
		protected function addLabel(master: InteractiveLayerWFS, reflection: FeatureDataReflection, s_text: String, pt: Point, rlX: Number, rlY: Number): void
		{
			//just to add sprite to array to let it removed in update() function
			if (!reflection)
				return;
			if (!visible)
				return;
			
			var displaySprite: WFSFeatureEditableSprite = getDisplaySpriteForReflection(reflection.reflectionDelta);
			
			ma_activeLabels.push(displaySprite);
			
			if(s_text.length > 0) {
				var i_color: uint = getCurrentColor(0x000000);
				
				var label: AnnotationTextBox = new AnnotationTextBox();
				ma_activeLabels.push(label);
				label.label.text = s_text;
				label.color = i_color;
				label.update();
				label.width = label.measuredWidth;
				label.height = label.measuredHeight;
				label.x = pt.x - label.width / 2.0;
				label.y = pt.y - label.height / 2.0;
				var format: TextFormat = label.label.getTextFormat();
				format.color = i_color;
				label.label.setTextFormat(format);
				
				addAnnotationForReflectionAt(reflection.reflectionDelta, label);
				
				var anticollisionLayoutObject: AnticollisionLayoutObject = master.container.labelLayout.addObject(label, master, [displaySprite]);
				
				//				label.anticollisionLayoutObject = anticollisionLayoutObject;
				if (displaySprite is IAnticollisionLayoutObject)
					IAnticollisionLayoutObject(displaySprite).anticollisionLayoutObject = anticollisionLayoutObject;
				//				master.container.labelLayout.addObject(label, [this]);
				//				master.container.labelLayout.updateObjectReferenceLocationWithCustomPosition(this, rlX, rlY);
			}
		}
		
	
		override protected function drawFeatureReflection(g: ICurveRenderer, m_featureDataReflection: FeatureDataReflection): void
		{
			if (!g || !m_featureDataReflection || !m_featureDataReflection.lines)
			{
				return;
			}
			
			if (ms_type != ANNOTATION_PIN)
				super.drawFeatureReflection(g, m_featureDataReflection);
			else {
				//TODO finish drawing of PIN
				
				var gr: Graphics = graphics;
				gr.clear();
			
				var a_points: Array = getPoints();
				var pt: Point;
				var lineRenderer: StyledLineCurveRenderer = g as StyledLineCurveRenderer;
				
				for each(pt in a_points) { 
					gr.lineStyle(lineRenderer.thickness, lineRenderer.color);
					gr.beginFill(lineRenderer.fillColor);
					gr.drawRoundRect(pt.x - 4, pt.y - 4, 9, 9, 6, 6);
					gr.endFill();
//					addLabel(master as InteractiveLayerWFS, reflection, ms_text, pt, 0, 0);
					break;
				}
			}
		}
		
		override public function updateAnnotation(annotation: AnnotationBox, annotationPosition: Point, text: String = ""): void
		{
			if (!annotationPosition)
				return;
			
			if (annotation is AnnotationTextBox)
			{
				var txtAnnotation: AnnotationTextBox = annotation as AnnotationTextBox;
				
				var showAnnotations: Boolean = m_points && m_points.length > 1 && visible;
				var i_color: uint = getCurrentColor(0x000000);
				
				text = ms_text;
				
				txtAnnotation.label.text = text;
				txtAnnotation.color = i_color;
				txtAnnotation.update();
				txtAnnotation.width = txtAnnotation.measuredWidth;
				txtAnnotation.height = txtAnnotation.measuredHeight;
				txtAnnotation.x = annotationPosition.x - txtAnnotation.width / 2.0;
				txtAnnotation.y = annotationPosition.y - txtAnnotation.height - 5// / 2.0;
				var format: TextFormat = txtAnnotation.label.getTextFormat();
				format.color = i_color;
				txtAnnotation.label.setTextFormat(format);
					
			}
		}
		
		private function updateAnnotationPin(): void
		{
			var i: int;
			var gr: Graphics;
			var pt: Point;
			var annotationSprite: AnnotationSprite;
			var renderer: ICurveRenderer;
			var reflection: FeatureDataReflection;
			
			var a_points: Array = getPoints();
			var i_color: uint = getCurrentColor(mi_lineColor);
			var displaySprite: WFSFeatureEditableSprite;
			
			// single point feature
			
			for (i = 0; i < totalReflections; i++)
			{
				reflection = m_featureData.getReflectionAt(i);
				if (reflection)
				{
					var reflectionDelta: int = reflection.reflectionDelta;
					a_points = reflection.editablePoints;
					
					displaySprite = getDisplaySpriteForReflectionAt(reflectionDelta);
					gr = displaySprite.graphics;
					
					annotationSprite = displaySprite as AnnotationSprite;
					annotationSprite.points = a_points;
					
					if (!annotationSprite.renderer)
					{
						renderer = getRenderer(reflection.reflectionDelta);
						annotationSprite.renderer = renderer as StyledLineCurveRenderer;
					}
					
					gr.clear();
					
					for each(pt in a_points) { 
						graphics.lineStyle(1, i_color);
						graphics.beginFill(i_color);
						graphics.drawRoundRect(pt.x - 4, pt.y - 4, 9, 9, 6, 6);
						graphics.endFill();
						addLabel(master as InteractiveLayerWFS, reflection, ms_text, pt, 0, 0);
						break;
					}
				}
			}
		}
		
		override public function get smooth():Boolean
		{
			var b_smooth: Boolean = ms_type == ANNOTATION_SMOOTH_CURVE || ms_type == ANNOTATION_SMOOTH_AREA; 
			return b_smooth;
		}
		override public function isCurveClosed():Boolean
		{
			var b_closed: Boolean = ms_type == ANNOTATION_POLYGON || ms_type == ANNOTATION_SMOOTH_AREA || ms_type == ANNOTATION_PIN; 
			return b_closed;
		}
		
		override public function getPoints(reflectionID: int = 0): Array
		{
			var points: Array = m_points.getPointsForReflection(reflectionID);
			if (ms_type == ANNOTATION_PIN)
			{
				if (reflectionID && points.length > 0)
				{
					var arr: Array = []
					var firstItem: Point = points[0] as Point;
					arr.push(firstItem);
					arr.push(firstItem);
					return arr;
				}
				return points;
			} 
			return points;
		}
		
		override public function cleanup(): void
		{
			
/*			
			if(ma_activeLabels.length) {
				var label: AnnotationTextBox;
				for each(label  in ma_activeLabels) {
					m_master.container.labelLayout.removeObject(label);
				}
			}
			ma_activeLabels = [];
			master.container.labelLayout.removeObject(this);
			super.cleanup();
*/			
			
			
			
			if(ma_activeLabels.length) {
				for each(var dispObject: DisplayObject  in ma_activeLabels) {
					if (m_master && m_master.container && m_master.container.labelLayout)
						m_master.container.labelLayout.removeObject(dispObject);
				}
			}
			ma_activeLabels = [];
			
			if (master && master.container && master.container.labelLayout)
			{
				var annotation: AnnotationBox;
				var reflection: FeatureDataReflection;
				
				for (var i: int = 0; i < totalReflections; i++)
				{
					reflection = m_featureData.getReflectionAt(i)
					annotation = getAnnotationForReflectionAt(reflection.reflectionDelta);
					var displaySprite: WFSFeatureEditableSprite = getDisplaySpriteForReflection(reflection.reflectionDelta);
					master.container.labelLayout.removeObject(annotation);
					master.container.labelLayout.removeObject(displaySprite);
				}
			}
			
			super.cleanup();
		}

		override public function toInsertGML(xmlInsert: XML): void
		{
			super.toInsertGML(xmlInsert);
			addInsertGMLProperty(xmlInsert, null, "type", ms_type); 
			addInsertGMLProperty(xmlInsert, null, "text", ms_text); 
			addInsertGMLProperty(xmlInsert, null, "lineColor", NumberUtils.encodeHTMLColor(mi_lineColor)); 
		}

		override public function toUpdateGML(xmlUpdate: XML): void
		{
			super.toUpdateGML(xmlUpdate);
			addUpdateGMLProperty(xmlUpdate, null, "type", ms_type); 
			addUpdateGMLProperty(xmlUpdate, null, "text", ms_text); 
			addUpdateGMLProperty(xmlUpdate, null, "lineColor", NumberUtils.encodeHTMLColor(mi_lineColor)); 
		}

		override public function fromGML(gml: XML): void
		{
			super.fromGML(gml);
			var ns: Namespace = new Namespace(ms_namespace);
			ms_type = ANNOTATION_POLYLINE;
			ms_text = "";
			mi_lineColor = 0xff0000;
			
			if(gml.ns::type[0]) 
				ms_type = String(gml.ns::type[0]);
			if(gml.ns::text[0])
				ms_text = String(gml.ns::text[0]);
			if(gml.ns::lineColor[0])
				mi_lineColor = NumberUtils.decodeHTMLColor(String(gml.ns::lineColor[0]), mi_lineColor);
		}
		
		override public function isInternal(): Boolean
		{ return true; }

		
		override public function clone(): WFSFeatureEditable
		{
			var ret: WFSFeatureEditableAnnotation = super.clone() as WFSFeatureEditableAnnotation;
			ret.ms_type = ms_type;
			ret.ms_text = ms_text;
			ret.mi_lineColor = mi_lineColor;
			return ret;
		}
		
		
	}
}
import com.iblsoft.flexiweather.ogc.InteractiveLayerWFS;
import com.iblsoft.flexiweather.ogc.editable.WFSFeatureEditable;
import com.iblsoft.flexiweather.ogc.editable.features.curves.withAnnotation.WFSFeatureEditableAnnotation;
import com.iblsoft.flexiweather.ogc.wfs.WFSFeatureEditableSprite;
import com.iblsoft.flexiweather.symbology.StyledLineCurveRenderer;
import com.iblsoft.flexiweather.utils.AnnotationBox;
import com.iblsoft.flexiweather.utils.CubicBezier;
import com.iblsoft.flexiweather.utils.geometry.LineSegment;

import flash.display.Graphics;
import flash.geom.Point;

class AnnotationSprite extends WFSFeatureEditableSprite
{
	public var renderer: StyledLineCurveRenderer
	public function AnnotationSprite(feature: WFSFeatureEditable)
	{
		super(feature);	
		
	}
	
	public function clearPin(): void
	{
		clearPin();
	}
		
	public function drawPin(): void
	{
		var gr: Graphics = graphics;
		clearPin();
		gr.lineStyle(1,0);
		gr.beginFill(_feature.getCurrentColor(0xffcc00));
		gr.drawCircle(0,0, 20);
	}
	
	public function update(type: String, master: InteractiveLayerWFS, a_points: Array, i_color: uint): void
	{
		
	}
	
	public function getLineSegmentApproximation(): Array
	{
		var annotationFeature: WFSFeatureEditableAnnotation = _feature as WFSFeatureEditableAnnotation;
		var type: String = annotationFeature.ms_type;
		
		if(type == WFSFeatureEditableAnnotation.ANNOTATION_PIN)
			return [];
		var b_smooth: Boolean = type ==  WFSFeatureEditableAnnotation.ANNOTATION_SMOOTH_CURVE || type ==  WFSFeatureEditableAnnotation.ANNOTATION_SMOOTH_AREA; 
		if(b_smooth)
			return createSmoothLineSegmentApproximation();
		else
			return createStraightLineSegmentApproximation();
	}
	
	override public function getLineSegmentApproximationOfBounds(): Array
	{
		if(!points || points.length == 0)
			return [];
		var a: Array = [];
		
		var annotationFeature: WFSFeatureEditableAnnotation = _feature as WFSFeatureEditableAnnotation;
		var type: String = annotationFeature.ms_type;
		
		if(type ==  WFSFeatureEditableAnnotation.ANNOTATION_PIN) {
			a.push(new LineSegment(points[0].x, points[0].y, points[0].x, points[0].y));
		}
		else {
			var b_smooth: Boolean = type ==  WFSFeatureEditableAnnotation.ANNOTATION_SMOOTH_CURVE || type ==  WFSFeatureEditableAnnotation.ANNOTATION_SMOOTH_AREA; 
			if(b_smooth)
				return createSmoothLineSegmentApproximation(false);
			else
				return createStraightLineSegmentApproximation(false);
		}
		return a;
	}
}
