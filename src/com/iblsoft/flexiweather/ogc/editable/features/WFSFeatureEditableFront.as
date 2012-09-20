package com.iblsoft.flexiweather.ogc.editable.features
{
	import com.iblsoft.flexiweather.ogc.FeatureUpdateContext;
	import com.iblsoft.flexiweather.ogc.InteractiveLayerWFS;
	import com.iblsoft.flexiweather.ogc.editable.WFSFeatureEditableCurveWithBaseTimeAndValidity;
	import com.iblsoft.flexiweather.ogc.wfs.IWFSFeatureWithReflection;
	import com.iblsoft.flexiweather.proj.Coord;
	import com.iblsoft.flexiweather.symbology.FrontCurveRenderer;
	import com.iblsoft.flexiweather.utils.CubicBezier;
	
	import flash.geom.Point;
	
	import mx.collections.ArrayCollection;

	/**
	 * For front styles see for example http://en.wikipedia.org/wiki/Weather_front
	 **/	
	public class WFSFeatureEditableFront extends WFSFeatureEditableCurveWithBaseTimeAndValidity implements IWFSFeatureWithReflection
	{
		public var type: String;
		
		public function WFSFeatureEditableFront(s_namespace: String, s_typeName: String, s_featureId: String)
		{
			super(s_namespace, s_typeName, s_featureId);
			
			type = FrontType.WARM;
		}
	
		override public function update(changeFlag: FeatureUpdateContext): void
		{
			super.update(changeFlag);
			graphics.clear();
			var i_color: uint = 0x00000;
			var i_colorSecondary: uint = 0x00000;
			var i_markType: uint = 0;
			if(type.substr(0, 4) == FrontType.WARM) {
				if (useMonochrome){
					i_color = mi_monochromeColor;
				} else if (master && master.useMonochrome){
					i_color = master.monochromeColor;
				} else {
					i_color = 0xff0000;
				}
				i_markType = 1;
			}
			else if(type.substr(0, 4) == FrontType.COLD) {
				if (useMonochrome){
					i_color = mi_monochromeColor;
				} else if (master && master.useMonochrome){
					i_color = master.monochromeColor;
				} else {
					i_color = 0x0000ff;
				}
				i_markType = 0;
			}
			else if(type.substr(0, 8) == FrontType.OCCLUDED) {
				if (useMonochrome){
					i_color = mi_monochromeColor;
				} else if (master && master.useMonochrome){
					i_color = master.monochromeColor;
				} else {
					i_color = 0xff00ff; // 0x800080
				}
				i_markType = 2;
			}
			else if(type.substr(0, 10) == FrontType.STATIONARY) {
				if (useMonochrome){
					i_color = mi_monochromeColor;
					i_colorSecondary = mi_monochromeColor;
				} else if (master && master.useMonochrome){
					i_color = master.monochromeColor;
					i_colorSecondary = master.monochromeColor;
				} else {
					i_color = 0xff0000;
					i_colorSecondary = 0x0000ff;
				}
				
				i_markType = 3;
			}
			else if(type.substr(0, 10) == "Cloud") {
				if (useMonochrome){
					i_color = monochromeColor;
				} else if (master && master.useMonochrome){
					i_color = master.monochromeColor;
				} else {
					i_color = 0xcccccc;
				}
				i_markType = 1;
			}
			else if(type.substr(0, 10) == "Storm") {
				if (useMonochrome){
					i_color = monochromeColor;
				} else if (master && master.useMonochrome){
					i_color = master.monochromeColor;
				} else {
					i_color = 0xE4DD0F;
				}
				i_markType = 1;
			}
			var a_points: ArrayCollection = getPoints();
			if(a_points.length > 1) { 
				//CubicBezier.curveThroughPoints(
				//		new FrontCurveRenderer(graphics, i_color, i_colorSecondary, i_markType),
				//		a_points.toArray());
						
//				m_curvePoints = CubicBezier.drawHermitSpline(new FrontCurveRenderer(graphics, i_color, i_colorSecondary, i_markType),
//							a_points.toArray());
				var splinePoints: Array = CubicBezier.calculateHermitSpline(a_points.toArray(), false);
				
				var coords: Array = [];
				
				//what is the best way to check in which projection was front created? For now we check CRS of first coordinate
				var crs: String = (coordinates[0] as Coord).crs;
				
				//convert points to Coords
				for each (var p: Point in splinePoints)
				{
					coords.push(master.container.pointToCoord(p.x, p.y));	
				}
				
				if (master)
				{
//					m_iw.drawPolyline(new FrontCurveRenderer(canvas.graphics, 0x880000, 0x0000ff, FrontCurveRenderer.MARK_WARM), coords);
					 var featureReflections: Array = master.container.drawPolyline(new FrontCurveRenderer(graphics, i_color, i_colorSecondary, i_markType),
						 coords);
				}
				
				createHitMask(featureReflections);
			}
			else
				renderFallbackGraphics(i_color);
		}
	}

}

