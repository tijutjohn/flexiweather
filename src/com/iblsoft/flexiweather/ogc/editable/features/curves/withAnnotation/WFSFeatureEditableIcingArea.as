package com.iblsoft.flexiweather.ogc.editable.features.curves.withAnnotation
{
	import com.iblsoft.flexiweather.ogc.FeatureUpdateContext;
	import com.iblsoft.flexiweather.ogc.InteractiveLayerFeatureBase;
	import com.iblsoft.flexiweather.ogc.InteractiveLayerWFS;
	import com.iblsoft.flexiweather.ogc.data.ReflectionData;
	import com.iblsoft.flexiweather.ogc.data.WFSEditableReflectionData;
	import com.iblsoft.flexiweather.ogc.editable.WFSFeatureEditableClosableCurveWithBaseTimeAndValidityAndAnnotation;
	import com.iblsoft.flexiweather.ogc.editable.annotations.IcingAreaAnnotation;
	import com.iblsoft.flexiweather.ogc.wfs.IWFSFeatureWithAnnotation;
	import com.iblsoft.flexiweather.ogc.wfs.IWFSFeatureWithReflection;
	import com.iblsoft.flexiweather.ogc.wfs.WFSFeatureEditableSprite;
	import com.iblsoft.flexiweather.proj.Coord;
	import com.iblsoft.flexiweather.symbology.IcingCurveRenderer;
	import com.iblsoft.flexiweather.utils.AnnotationBox;
	import com.iblsoft.flexiweather.utils.CubicBezier;
	import com.iblsoft.flexiweather.utils.ICurveRenderer;
	import com.iblsoft.flexiweather.utils.draw.DrawMode;
	import com.iblsoft.flexiweather.utils.geometry.ILineSegmentApproximableBounds;
	import com.iblsoft.flexiweather.utils.geometry.LineSegment;
	
	import flash.display.Graphics;
	import flash.geom.Point;
	
	import mx.collections.ArrayCollection;

	/**
	 * For front styles see for example http://en.wikipedia.org/wiki/Weather_front
	 **/	
	public class WFSFeatureEditableIcingArea extends WFSFeatureEditableClosableCurveWithBaseTimeAndValidityAndAnnotation
			implements IWFSFeatureWithReflection
	{
		public var values:Object;
		
		public var ms_type: String;
		public var ms_degree: String;
		public var mn_verticalExtentTop: Number;
		public var mn_verticalExtentBase: Number;
		
		public var ma_subranges: ArrayCollection = new ArrayCollection();
		
		public function WFSFeatureEditableIcingArea(s_namespace: String, s_typeName: String, s_featureId: String)
		{
			super(s_namespace, s_typeName, s_featureId);
		}
	
		override public function getRenderer(reflection: int): ICurveRenderer
		{
			var i_color: uint = getCurrentColor(0x884810);
			var renderer: IcingCurveRenderer;
			var gr: Graphics = graphics;
			
			var reflectionData: WFSEditableReflectionData = ml_movablePoints.getReflection(reflection) as WFSEditableReflectionData;
			if (reflectionData && reflectionData.displaySprite)
			{
				gr = reflectionData.displaySprite.graphics;
			}
			
			renderer = new IcingCurveRenderer(gr, i_color, i_color, IcingCurveRenderer.MARK_WARM);
			
			return renderer;
		}
		
		override public function getDisplaySpriteForReflection(id: int): WFSFeatureEditableSprite
		{
			return new IcingAreaSprite(this);
		}
		
		override public function createAnnotation(): AnnotationBox
		{
			return new IcingAreaAnnotation();
		}
		
		override public function updateAnnotation(annotation: AnnotationBox, annotationPosition: Point, text: String = ""): void
		{
			if (!annotationPosition)
				return;
			
			if (annotation is IcingAreaAnnotation)
			{
				var iceAreaAnnotation: IcingAreaAnnotation = annotation as IcingAreaAnnotation;
				
				var showAnnotations: Boolean = m_points && m_points.length > 1 && visible;
				
				
				iceAreaAnnotation.color = getCurrentColor(0x000000);
				iceAreaAnnotation.icingAreaData = this; //.label.text = "" + values.distribution + '\n' + values.type;
				iceAreaAnnotation.visible = showAnnotations;
				
				iceAreaAnnotation.x = annotationPosition.x - iceAreaAnnotation.width / 2.0;
				iceAreaAnnotation.y = annotationPosition.y - iceAreaAnnotation.height / 2.0;
				iceAreaAnnotation.update();
			}
		}
	
			
		
		
		private function drawFeature(g: IcingCurveRenderer, mPoints: Array): void
		{
			if (!g || !mPoints)
			{
				return;
			}
			var p: Point;
			
			var total: int = mPoints.length;
			if (total > 0)
			{
				p = mPoints[0] as Point;
				
				g.start(p.x, p.y);
				g.moveTo(p.x, p.y);
				
				for (var i: int = 1; i < total; i++)
				{
					p = mPoints[i] as Point;
					g.lineTo(p.x, p.y);
				}
				
				g.finish(p.x, p.y);
			}
			
		}

		private var _spritesAddedToLabelLayout: Boolean;
		
		public override function cleanup(): void
		{
			
			if (master && master.container && master.container.labelLayout)
			{
				master.container.labelLayout.removeObject(this);
				
				
				var icingAreaInfo: IcingAreaAnnotation;
				var reflection: WFSEditableReflectionData;
				
				var totalReflections: uint = ml_movablePoints.totalReflections;
				for (var i: int = 0; i < totalReflections; i++)
				{
					reflection = ml_movablePoints.getReflection(i) as WFSEditableReflectionData;
					icingAreaInfo = reflection.annotation as IcingAreaAnnotation;
					master.container.labelLayout.removeObject(reflection.displaySprite);
					master.container.labelLayout.removeObject(icingAreaInfo);
				}
			}
			
			super.cleanup();
		}

		override public function toInsertGML(xmlInsert: XML): void
		{
			var gml: Namespace = new Namespace("http://www.opengis.net/gml");
			super.toInsertGML(xmlInsert);
			
			xmlInsert.appendChild(<type xmlns={ms_namespace}>{ms_type}</type>);
			xmlInsert.appendChild(<degree xmlns={ms_namespace}>{ms_degree}</degree>);
			xmlInsert.appendChild(<verticalExtent xmlns={ms_namespace} base={mn_verticalExtentBase} top={mn_verticalExtentTop}/>);
		}

		override public function toUpdateGML(xmlUpdate: XML): void
		{
			// TODO: bind property from feature editor
			super.toUpdateGML(xmlUpdate);
			addUpdateGMLProperty(xmlUpdate, null, "type", ms_type);
			addUpdateGMLProperty(xmlUpdate, null, "degree", ms_degree);
			addUpdateGMLProperty(xmlUpdate, null,"verticalExtent/@base", mn_verticalExtentBase);
			addUpdateGMLProperty(xmlUpdate, null,"verticalExtent/@top", mn_verticalExtentTop);
		}

		override public function fromGML(gml: XML): void
		{
			super.fromGML(gml);
			var ns: Namespace = new Namespace(ms_namespace);
			//TODO: add value object
			values = {
				flightLevel: gml.ns::flightLevel[0],
				degree: gml.ns::degree[0]
			};
			
			ms_type = gml.ns::type;
			ms_degree = gml.ns::degree;
			if (gml.ns::verticalExtent){
				mn_verticalExtentBase = Number(gml.ns::verticalExtent.@base);
				mn_verticalExtentTop = Number(gml.ns::verticalExtent.@top);
			}
		}
		
		// type
		public function set type(val: String): void
		{ ms_type = val;}
			
		public function get type(): String
		{ return ms_type;}
		
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

class IcingAreaSubRange
{
	public var ms_type: String;
	public var ms_degree: String;
	public var mn_flightLevel: Number;
	
	public function IcingAreaSubRange(type: String, degree: String, flightLevel: Number): void
	{
		ms_type = type;
		ms_degree = degree;
		mn_flightLevel = flightLevel;
	}
	
	// type
	public function set type(val: String): void
	{ ms_type = val;}
		
	public function get type(): String
	{ return ms_type;}
	
	// degree
	public function set degree(val: String): void
	{ ms_degree = val;}
		
	public function get degree(): String
	{ return ms_degree;}
	
	// flightLevel
	public function set flightLevel(val: Number): void
	{ mn_flightLevel = val;}
		
	public function get flightLevel(): Number
	{ return mn_flightLevel;}
}


import com.iblsoft.flexiweather.ogc.editable.WFSFeatureEditable;
import com.iblsoft.flexiweather.ogc.editable.features.curves.withAnnotation.WFSFeatureEditableIcingArea;
import com.iblsoft.flexiweather.ogc.wfs.WFSFeatureEditableSprite;
import com.iblsoft.flexiweather.ogc.wfs.WFSFeatureEditableSpriteWithAnnotation;
import com.iblsoft.flexiweather.utils.CubicBezier;
import com.iblsoft.flexiweather.utils.geometry.LineSegment;

import flash.geom.Point;

class IcingAreaSprite extends WFSFeatureEditableSpriteWithAnnotation
{
	public function IcingAreaSprite(feature: WFSFeatureEditable)
	{
		super(feature);
	}
	
	override public function getLineSegmentApproximationOfBounds():Array
	{
		
		var a: Array = [];
		var ptFirst: Point = null;
		var ptPrev: Point = null;
		
		var icingArea: WFSFeatureEditableIcingArea = _feature as WFSFeatureEditableIcingArea;
		var pts: Array = CubicBezier.calculateHermitSpline(points, icingArea.isCurveClosed());
		
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
