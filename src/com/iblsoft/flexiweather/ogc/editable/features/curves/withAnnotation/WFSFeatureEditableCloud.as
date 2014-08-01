package com.iblsoft.flexiweather.ogc.editable.features.curves.withAnnotation
{
	import com.iblsoft.flexiweather.ogc.FeatureUpdateContext;
	import com.iblsoft.flexiweather.ogc.InteractiveLayerFeatureBase;
	import com.iblsoft.flexiweather.ogc.InteractiveLayerWFS;
	import com.iblsoft.flexiweather.ogc.data.ReflectionData;
	import com.iblsoft.flexiweather.ogc.editable.WFSFeatureEditable;
	import com.iblsoft.flexiweather.ogc.editable.WFSFeatureEditableClosableCurveWithBaseTimeAndValidity;
	import com.iblsoft.flexiweather.ogc.editable.WFSFeatureEditableClosableCurveWithBaseTimeAndValidityAndAnnotation;
	import com.iblsoft.flexiweather.ogc.editable.annotations.CloudAnnotation;
	import com.iblsoft.flexiweather.ogc.editable.data.FeatureDataReflection;
	import com.iblsoft.flexiweather.ogc.wfs.IWFSFeatureWithAnnotation;
	import com.iblsoft.flexiweather.ogc.wfs.WFSFeatureEditableSprite;
	import com.iblsoft.flexiweather.proj.Coord;
	import com.iblsoft.flexiweather.symbology.CloudCurveRenderer;
	import com.iblsoft.flexiweather.utils.AnnotationBox;
	import com.iblsoft.flexiweather.utils.CubicBezier;
	import com.iblsoft.flexiweather.utils.ICurveRenderer;
	import com.iblsoft.flexiweather.utils.draw.DrawMode;
	import com.iblsoft.flexiweather.utils.geometry.ILineSegmentApproximableBounds;
	import com.iblsoft.flexiweather.utils.geometry.LineSegment;
	
	import flash.display.Graphics;
	import flash.display.Sprite;
	import flash.geom.Point;
	import flash.text.TextFieldAutoSize;
	
	import mx.collections.ArrayCollection;

	public class WFSFeatureEditableCloud extends WFSFeatureEditableClosableCurveWithBaseTimeAndValidityAndAnnotation
			implements IWFSFeatureWithAnnotation
	{
		public var values: Object;
		
		public var ms_distribution: String;
		public var ms_type: String;
		public var mn_verticalExtentBase: Number = 0;
		public var mn_verticalExtentTop: Number = 0;
		
		public var mb_useTurbulence: Boolean = false;
		public var mn_turbulenceBase: Number;
		public var mn_turbulenceTop: Number;
		public var ms_turbulenceDegree: String;
		
		public var mb_useIcing: Boolean = false;
		public var mn_icingBase: Number;
		public var mn_icingTop: Number;
		public var ms_icingDegree: String;
		
		override public function set visible(value:Boolean):void
		{
			super.visible = value;
		}
		public function WFSFeatureEditableCloud(s_namespace: String, s_typeName: String, s_featureId: String)
		{
			super(s_namespace, s_typeName, s_featureId);
			
		}
	
		override public function getRenderer(reflection: int): ICurveRenderer
		{
			var i_color: uint = getCurrentColor(0x00ff00);
			var renderer: CloudCurveRenderer;
			
			var gr: Graphics = getRendererGraphics(reflection);
			
			renderer = new CloudCurveRenderer(gr, 2.0, i_color, 1);
			return renderer;
		}
		
		override public function getDisplaySpriteForReflection(id: int): WFSFeatureEditableSprite
		{
			return new CloudFeatureSprite(this);
		}
		
		override public function createAnnotation(): AnnotationBox
		{
			return new CloudAnnotation();
		}
		
		override public function updateAnnotation(annotation: AnnotationBox, annotationPosition: Point, text: String = ""): void
		{
			if (!annotationPosition)
				return;
			
			if (annotation is CloudAnnotation)
			{
				var cloudAnnotation: CloudAnnotation = annotation as CloudAnnotation;
				
				annotation = cloudAnnotation;
				
				var showAnnotations: Boolean = m_points && m_points.length > 1 && visible;
				
				cloudAnnotation.color = getCurrentColor(0x000000);
				cloudAnnotation.cloudData = this; //.label.text = "" + values.distribution + '\n' + values.type;
				cloudAnnotation.update();
				cloudAnnotation.visible = showAnnotations;
				cloudAnnotation.x = annotationPosition.x - cloudAnnotation.width / 2.0;
				cloudAnnotation.y = annotationPosition.y - cloudAnnotation.height / 2.0;
				cloudAnnotation.label.autoSize = TextFieldAutoSize.CENTER;
			}
		}
		
		public override function cleanup(): void
		{
			if (master && master.container && master.container.labelLayout)
			{
//				master.container.labelLayout.removeObject(this);
				
				var cloudTextInfo: CloudAnnotation;
				var reflection: FeatureDataReflection;
				
				
				for (var i: int = 0; i < totalReflections; i++)
				{
					reflection = m_featureData.getReflectionAt(i);
					if (reflection)
					{
						var reflectionDelta: int = reflection.reflectionDelta;
						
						cloudTextInfo = getAnnotationForReflectionAt(reflectionDelta) as CloudAnnotation;
						var displaySprite: WFSFeatureEditableSprite = getDisplaySpriteForReflection(reflectionDelta);
						
						master.container.labelLayout.removeObject(displaySprite);
						master.container.labelLayout.removeObject(cloudTextInfo);
					}
				}
			}
			
			super.cleanup();
		}

		override public function toInsertGML(xmlInsert: XML): void
		{
			super.toInsertGML(xmlInsert);
			addInsertGMLProperty(xmlInsert, null, "distribution", ms_distribution);
			addInsertGMLProperty(xmlInsert, null,"type", ms_type);
			xmlInsert.appendChild(<verticalExtent xmlns={ms_namespace} base={mn_verticalExtentBase} top={mn_verticalExtentTop}/>);
			
			if (mb_useTurbulence){
				xmlInsert.appendChild(<turbulence xmlns={ms_namespace} xmlns:wfs="http://www.opengis.net/wfs" xmlns:gml="http://www.opengis.net/gml" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" >
										<degree xmlns={ms_namespace}>
										{ms_turbulenceDegree}
										</degree>
										<verticalExtent xmlns={ms_namespace} xmlns:wfs="http://www.opengis.net/wfs" xmlns:gml="http://www.opengis.net/gml" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" base={mn_turbulenceBase} top={mn_turbulenceTop}/>
									  </turbulence>);
			} else {
				xmlInsert.appendChild(<turbulence xmlns={ms_namespace} />);
			}
			
			if (mb_useIcing){
				xmlInsert.appendChild(<icing xmlns={ms_namespace}>
										<degree>
										{ms_icingDegree}
										</degree>
										<verticalExtent base={mn_icingBase} top={mn_icingTop}/>
									  </icing>);
			} else {
				xmlInsert.appendChild(<icing xmlns={ms_namespace} />);
			}
			
			//xmlInsert.appendChild(<verticalExtent xmlns={ms_namespace} base={Cloud(values).verticalExtentBase} top={Cloud(values).verticalExtentTop}/>);
			
			//addInsertGMLProperty(xmlInsert, null,"verticalExtent", values.verticalExtent);
			//addInsertGMLProperty(xmlInsert, null,"turbulence", values.turbulence);
			//addInsertGMLProperty(xmlInsert, null,"icing", values.icing);
		}

		override public function toUpdateGML(xmlUpdate: XML): void
		{
			super.toUpdateGML(xmlUpdate);
			addUpdateGMLProperty(xmlUpdate, null,"distribution", ms_distribution);
			addUpdateGMLProperty(xmlUpdate, null,"type", ms_type);
			
			addUpdateGMLProperty(xmlUpdate, null,"verticalExtent/@base", mn_verticalExtentBase);
			addUpdateGMLProperty(xmlUpdate, null,"verticalExtent/@top", mn_verticalExtentTop);
			
			if (mb_useTurbulence) {
				
				var p: XML = <wfs:Property xmlns:wfs="http://www.opengis.net/wfs"/>;
				var name: XML = <wfs:Name xmlns:wfs="http://www.opengis.net/wfs">turbulence</wfs:Name>;
				var value: XML = <wfs:Value xmlns:wfs="http://www.opengis.net/wfs" xmlns={ms_namespace}/>;
				var degree: XML = <degree>{ms_turbulenceDegree}</degree>;
				var verticalExtent: XML = <verticalExtent base={mn_turbulenceBase} top={mn_turbulenceTop}/>;
				
				value.appendChild(degree);
				value.appendChild(verticalExtent);
				
				p.appendChild(name);
				p.appendChild(value);
				
				xmlUpdate.appendChild(p);
			} else {
				addUpdateGMLProperty(xmlUpdate, null,"turbulence", null);
			}
			
			if (mb_useIcing){
				
				var pIcing: XML = <wfs:Property xmlns:wfs="http://www.opengis.net/wfs"/>;
				var nameIcing: XML = <wfs:Name xmlns:wfs="http://www.opengis.net/wfs">icing</wfs:Name>;
				var valueIcing: XML = <wfs:Value xmlns:wfs="http://www.opengis.net/wfs" xmlns={ms_namespace}/>;
				var degreeIcing: XML = <degree>{ms_icingDegree}</degree>;
				var verticalExtentIcing: XML = <verticalExtent base={mn_icingBase} top={mn_icingTop}/>;
				
				valueIcing.appendChild(degreeIcing);
				valueIcing.appendChild(verticalExtentIcing);
				
				pIcing.appendChild(nameIcing);
				pIcing.appendChild(valueIcing);
				
				xmlUpdate.appendChild(pIcing)
					
			} else {
				addUpdateGMLProperty(xmlUpdate, null,"icing", null);
			}
		}

		override public function fromGML(gml: XML) :void
		{
			super.fromGML(gml);
			var ns: Namespace = new Namespace(ms_namespace);
			//TODO: add value object
			//var nCloudData: Cloud = new Cloud();
			ms_distribution = gml.ns::distribution[0].toString();
			ms_type = gml.ns::type[0];
			mn_verticalExtentBase = (gml.ns::verticalExtent[0].@base != '') ? Number(gml.ns::verticalExtent[0].@base) : 0;
			mn_verticalExtentTop = (gml.ns::verticalExtent[0].@top != '') ? Number(gml.ns::verticalExtent[0].@top) : 0;
			
			var turbulenceDef: XMLList = gml.ns::turbulence; 
			var icingDef: XMLList = gml.ns::icing; 

			if(turbulenceDef.ns::degree.toString().length) {
				mb_useTurbulence = true;
				mn_turbulenceBase = (turbulenceDef.ns::verticalExtent.@base != '') ? Number(turbulenceDef.ns::verticalExtent.@base) : 0; //gml.ns::turbulence[0].ns::verticalExtent.@base;
				mn_turbulenceTop = (turbulenceDef.ns::verticalExtent.@top != '') ? Number(turbulenceDef.ns::verticalExtent.@top) : 0; //gml.ns::turbulence[0].ns::verticalExtent.@top;
				ms_turbulenceDegree = turbulenceDef.ns::degree.toString();
			} else {
				mb_useTurbulence = false;
			}
			
			if(icingDef.ns::degree.toString().length) {
				mb_useIcing = true;
				mn_icingBase = (icingDef.ns::verticalExtent.@base != '') ? Number(icingDef.ns::verticalExtent.@base) : 0; //gml.ns::icing[0].ns::verticalExtent.@base;
				mn_icingTop = (icingDef.ns::verticalExtent.@top != '') ? Number(icingDef.ns::verticalExtent.@top) : 0; //gml.ns::icing[0].ns::verticalExtent.@top;
				ms_icingDegree = icingDef.ns::degree.toString();
			} else {
				mb_useIcing = false;
			}
			
			/*values = {
				distribution: gml.ns::distribution[0].toString(),
				type: gml.ns::type[0],
				verticalExtent: gml.ns::verticalExtent[0].@base,
				verticalExtentTop: gml.ns::verticalExtent[0].@top,
				turbulence: gml.ns::turbulence[0].verticalExtent.@base,
				turbulenceTop: gml.ns::turbulence[0].verticalExtent.@top,
				icing: gml.ns::icing[0].verticalExtent.@base,
				icingTop: gml.ns::icing[0].verticalExtent.@top
			};*/
			
			//values = nCloudData;
		}
		
		/**
		 * 
		 */
		override public function clone(): WFSFeatureEditable
		{
			var ret: WFSFeatureEditableCloud = super.clone() as WFSFeatureEditableCloud;
			
			for (var atr: String in values){
				ret.values[atr] = values[atr];
			}
			
			return(ret);
		}
		
		// distribution
		public function set distribution(val: String): void
		{ ms_distribution = val;}
		
		public function get distribution(): String
		{ return ms_distribution;}
		
		// type
		public function set type(val: String): void
		{ ms_type = val;}
		
		public function get type(): String
		{ return ms_type;}
		
		// verticalExtentBase
		public function set verticalExtentBase(val: Number): void
		{ mn_verticalExtentBase = val;}
		
		public function get verticalExtentBase(): Number
		{ return mn_verticalExtentBase;}
		
		// verticalExtentTop
		public function set verticalExtentTop(val: Number): void
		{ mn_verticalExtentTop = val;}
		
		public function get verticalExtentTop(): Number
		{ return mn_verticalExtentTop;}
		
		// useTurbulence
		public function set useTurbulence(val: Boolean): void
		{ mb_useTurbulence = val;}
		
		public function get useTurbulence(): Boolean
		{ return mb_useTurbulence;}
		
		// turbulenceBase
		public function set turbulenceBase(val: Number): void
		{ mn_turbulenceBase = val;}
		
		public function get turbulenceBase(): Number
		{ return mn_turbulenceBase;}
		
		// turbulenceTop
		public function set turbulenceTop(val: Number): void
		{ mn_turbulenceTop = val;}
		
		public function get turbulenceTop(): Number
		{ return mn_turbulenceTop;}
		
		// turbulenceDegree
		public function set turbulenceDegree(val: String): void
		{ ms_turbulenceDegree = val;}
		
		public function get turbulenceDegree(): String
		{ return ms_turbulenceDegree;}
		
		// useIcing
		public function set useIcing(val: Boolean): void
		{ mb_useIcing = val;}
		
		public function get useIcing(): Boolean
		{ return mb_useIcing;}
		
		// icingBase
		public function set icingBase(val: Number): void
		{ mn_icingBase = val;}
		
		public function get icingBase(): Number
		{ return mn_icingBase;}
		
		// icingTop
		public function set icingTop(val: Number): void
		{ mn_icingTop = val;}
		
		public function get icingTop(): Number
		{ return mn_icingTop;}
		
		// icingDegree
		public function set icingDegree(val: String): void
		{ ms_icingDegree = val;}
		
		public function get icingDegree(): String
		{ return ms_icingDegree;}
	}
}
import com.iblsoft.flexiweather.ogc.editable.WFSFeatureEditable;
import com.iblsoft.flexiweather.ogc.editable.features.curves.withAnnotation.WFSFeatureEditableCloud;
import com.iblsoft.flexiweather.ogc.wfs.WFSFeatureEditableSprite;
import com.iblsoft.flexiweather.ogc.wfs.WFSFeatureEditableSpriteWithAnnotation;
import com.iblsoft.flexiweather.utils.CubicBezier;
import com.iblsoft.flexiweather.utils.geometry.LineSegment;

import flash.geom.Point;

class CloudFeatureSprite extends WFSFeatureEditableSpriteWithAnnotation
{
	override public function set visible(value:Boolean):void
	{
		super.visible = value;
	}
	
	public function CloudFeatureSprite(feature: WFSFeatureEditable)
	{
		super(feature);
	}
	
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
