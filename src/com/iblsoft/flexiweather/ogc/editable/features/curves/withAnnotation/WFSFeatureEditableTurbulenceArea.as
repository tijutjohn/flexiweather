package com.iblsoft.flexiweather.ogc.editable.features.curves.withAnnotation
{
	import com.iblsoft.flexiweather.ogc.FeatureUpdateContext;
	import com.iblsoft.flexiweather.ogc.InteractiveLayerFeatureBase;
	import com.iblsoft.flexiweather.ogc.InteractiveLayerWFS;
	import com.iblsoft.flexiweather.ogc.editable.WFSFeatureEditableClosableCurveWithBaseTimeAndValidity;
	import com.iblsoft.flexiweather.ogc.editable.WFSFeatureEditableClosableCurveWithBaseTimeAndValidityAndAnnotation;
	import com.iblsoft.flexiweather.ogc.editable.annotations.TurbulenceAreaAnnotation;
	import com.iblsoft.flexiweather.ogc.editable.data.FeatureDataReflection;
	import com.iblsoft.flexiweather.ogc.wfs.IWFSFeatureWithAnnotation;
	import com.iblsoft.flexiweather.ogc.wfs.IWFSFeatureWithReflection;
	import com.iblsoft.flexiweather.ogc.wfs.WFSFeatureEditableSprite;
	import com.iblsoft.flexiweather.proj.Coord;
	import com.iblsoft.flexiweather.symbology.TurbulenceCurveRenderer;
	import com.iblsoft.flexiweather.utils.AnnotationBox;
	import com.iblsoft.flexiweather.utils.CubicBezier;
	import com.iblsoft.flexiweather.utils.ICurveRenderer;
	import com.iblsoft.flexiweather.utils.draw.DrawMode;
	import com.iblsoft.flexiweather.utils.geometry.ILineSegmentApproximableBounds;
	import com.iblsoft.flexiweather.utils.geometry.LineSegment;
	
	import flash.display.Graphics;
	import flash.display.Sprite;
	import flash.geom.Point;
	
	import mx.collections.ArrayCollection;

	public class WFSFeatureEditableTurbulenceArea extends WFSFeatureEditableClosableCurveWithBaseTimeAndValidityAndAnnotation
			implements IWFSFeatureWithAnnotation, IWFSFeatureWithReflection
	{
		
		public var values:Object;
		
		public var ms_degree: String;
		public var mn_verticalExtentTop: Number;
		public var mn_verticalExtentBase: Number;
		
		public function WFSFeatureEditableTurbulenceArea(s_namespace: String, s_typeName: String, s_featureId: String)
		{
			super(s_namespace, s_typeName, s_featureId);
		}
	
//		private var _spritesAddedToLabelLayout: Boolean;
		
		override public function getRenderer(reflection: int): ICurveRenderer
		{
			var i_color: uint = getCurrentColor(0x000000);
			
			var gr: Graphics = getRendererGraphics(reflection);
			
			var renderer: TurbulenceCurveRenderer = new TurbulenceCurveRenderer(gr, 2, i_color, 1)
			return renderer;
		}
		
		override public function getDisplaySpriteForReflection(id: int): WFSFeatureEditableSprite
		{
			return new TurbulenceAreaSprite(this);
		}
		
		override public function createAnnotation(): AnnotationBox
		{
			return new TurbulenceAreaAnnotation();
		}
		
		override public function updateAnnotation(annotation: AnnotationBox, annotationPosition: Point, text: String = ""): void
		{
			if (!annotationPosition)
				return;
			
			if (annotation is TurbulenceAreaAnnotation)
			{
				var turbulenceAreaAnnotation: TurbulenceAreaAnnotation = annotation as TurbulenceAreaAnnotation;
				
				annotation = turbulenceAreaAnnotation;
				
				var showAnnotations: Boolean = m_points && m_points.length > 1 && visible;
				
				turbulenceAreaAnnotation.color = getCurrentColor(0x000000);
				turbulenceAreaAnnotation.turbulenceAreaData = this; //.label.text = "" + values.distribution + '\n' + values.type;
				turbulenceAreaAnnotation.update();
				turbulenceAreaAnnotation.visible = showAnnotations;
				turbulenceAreaAnnotation.x = annotationPosition.x - turbulenceAreaAnnotation.width / 2.0;
				turbulenceAreaAnnotation.y = annotationPosition.y - turbulenceAreaAnnotation.height / 2.0;
			}
		}
		
		public override function cleanup(): void
		{
			if (master && master.container && master.container.labelLayout)
			{
				
				var turbulenceAreaAnnotation: TurbulenceAreaAnnotation;
				var reflection: FeatureDataReflection;
				var displaySprite: WFSFeatureEditableSprite;
				
				var reflectionIDs: Array = m_featureData.reflectionsIDs;
				
				for (var i: int = 0; i < totalReflections; i++)
				{
					var reflectionDelta: int = reflectionIDs[i];
					
					reflection = m_featureData.getReflectionAt(reflectionDelta);
					
					displaySprite = getDisplaySpriteForReflectionAt(reflectionDelta);
					
					turbulenceAreaAnnotation = getAnnotationForReflectionAt(reflectionDelta) as TurbulenceAreaAnnotation;
					master.container.labelLayout.removeObject(turbulenceAreaAnnotation);
					master.container.labelLayout.removeObject(displaySprite);
				}
			}
			
			super.cleanup();
		}
		
		override public function toInsertGML(xmlInsert: XML): void
		{
			var gml: Namespace = new Namespace("http://www.opengis.net/gml");
			super.toInsertGML(xmlInsert);
//			xmlInsert.appendChild(<verticalExtent>test</verticalExtent>);
//			xmlInsert.appendChild(<subRange><flightLevel>{this.values.flightLevel}</flightLevel><degree>{this.values.degree}</degree></subRange>);
//			
//			xmlInsert.appendChild(<type xmlns={ms_namespace}>{ms_type}</type>);
			xmlInsert.appendChild(<degree xmlns={ms_namespace}>{ms_degree}</degree>);
			xmlInsert.appendChild(<verticalExtent xmlns={ms_namespace} base={mn_verticalExtentBase} top={mn_verticalExtentTop}/>);
		
		}

		override public function toUpdateGML(xmlUpdate: XML): void
		{
			super.toUpdateGML(xmlUpdate);
			
			addUpdateGMLProperty(xmlUpdate, null, "degree", ms_degree);
			addUpdateGMLProperty(xmlUpdate, null, "verticalExtent/@base", mn_verticalExtentBase);
			addUpdateGMLProperty(xmlUpdate, null, "verticalExtent/@top", mn_verticalExtentTop);
		}
		
		override public function fromGML(gml: XML): void
		{
			super.fromGML(gml);
			var ns: Namespace = new Namespace(ms_namespace);
			//TODO: add value object
//			values = {
//				flightLevel: gml.ns::flightLevel[0],
//				degree: gml.ns::degree[0]
//			};
			
			ms_degree = gml.ns::degree;
			if (gml.ns::verticalExtent){
				mn_verticalExtentBase = Number(gml.ns::verticalExtent.@base);
				mn_verticalExtentTop = Number(gml.ns::verticalExtent.@top);
			}
		}
		
		// degree
		public function set degree(val: String): void
		{ ms_degree = val;}
			
		public function get degree(): String
		{ return ms_degree;}
		
		// verticalExtentTop
		public function set verticalExtentTop(val: Number): void
		{ mn_verticalExtentTop = val;}
			
		public function get verticalExtentTop(): Number
		{ return mn_verticalExtentTop;}
		
		// verticalExtentBase
		public function set verticalExtentBase(val: Number): void
		{ mn_verticalExtentBase = val;}
			
		public function get verticalExtentBase(): Number
		{ return mn_verticalExtentBase;}
	}
}

import com.iblsoft.flexiweather.ogc.editable.WFSFeatureEditable;
import com.iblsoft.flexiweather.ogc.editable.features.curves.withAnnotation.WFSFeatureEditableTurbulenceArea;
import com.iblsoft.flexiweather.ogc.wfs.WFSFeatureEditableSprite;
import com.iblsoft.flexiweather.ogc.wfs.WFSFeatureEditableSpriteWithAnnotation;
import com.iblsoft.flexiweather.utils.CubicBezier;
import com.iblsoft.flexiweather.utils.geometry.LineSegment;

import flash.geom.Point;

class TurbulenceAreaSprite extends WFSFeatureEditableSpriteWithAnnotation
{
	public function TurbulenceAreaSprite(feature: WFSFeatureEditable)
	{
		super(feature);
	}
	
	override public function getLineSegmentApproximationOfBounds():Array
	{
		var a: Array = [];
		var ptFirst: Point = null;
		var ptPrev: Point = null;
		
		var turbulenceArea: WFSFeatureEditableTurbulenceArea = _feature as WFSFeatureEditableTurbulenceArea;
		var pts: Array = CubicBezier.calculateHermitSpline(points, turbulenceArea.isCurveClosed());
		
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