package com.iblsoft.flexiweather.ogc
{
	import com.iblsoft.flexiweather.proj.Coord;
	import com.iblsoft.flexiweather.widgets.InteractiveWidget;
	
	import flash.display.Sprite;
	import flash.geom.Point;
	
	import mx.collections.ArrayCollection;
	
	public class WFSFeatureBase extends Sprite
	{
		protected var ms_namespace: String;
		protected var ms_typeName: String;
		protected var ms_featureId: String;
		protected var ms_internalFeatureId: String;

		protected var m_master: InteractiveLayerWFS;

		protected var m_coordinates: ArrayCollection = new ArrayCollection();
		protected var m_points: ArrayCollection = new ArrayCollection();
		protected var mb_pointsDirty: Boolean = false;
		
		public function WFSFeatureBase(s_namespace: String, s_typeName: String, s_featureId: String)
		{
			super();
			ms_namespace = s_namespace;
			ms_typeName = s_typeName;
			ms_featureId = s_featureId;
			mouseEnabled = false;
			mouseChildren = false;
			doubleClickEnabled = false;
		}

		public function getPoints(): ArrayCollection
		{ return m_points; }
		
		public function getPoint(i_pointIndex: uint): Point
		{
			if (m_points && m_points.length > i_pointIndex)
				return m_points[i_pointIndex];
			
			return null;
		}

		/** Called after the feature is added to master, before first call to update(). */
		public function setMaster(master: InteractiveLayerWFS): void
		{
			m_master = master;
		}

		/** Called after the feature is added to master or after any change (e.g. area change). */
		public function update(): void
		{
			if(mb_pointsDirty) {
				mb_pointsDirty = false;
				m_points = new ArrayCollection();
				if(m_coordinates.length) {
					var iw: InteractiveWidget = m_master.container;
					for(var i: uint = 0; i < m_coordinates.length; ++i) {
						var c: Coord = m_coordinates[i];
						var pt: Point = iw.coordToPoint(c);
						m_points.addItem(pt);
					}
				}
			}
		}

		/** Called internally before the feature is removed from the master. */ 
		public function cleanup(): void
		{
			m_master = null;
			m_coordinates.removeAll();
			m_points.removeAll();
		}

		public function invalidatePoints(): void
		{ mb_pointsDirty = true; }
		
		// helpers methods

		// event handlers
		
		// getters & setters
		public function get coordinates(): Array
		{ return m_coordinates.toArray(); }  		

		public function set coordinates(a: Array): void
		{
			m_coordinates = new ArrayCollection(a);
			mb_pointsDirty = true;
		}  		

		public function get typeName(): String
		{ return ms_typeName; }

		public function get namespaceURI(): String
		{ return ms_namespace; }

		public function set featureId(s: String): void
		{ ms_featureId = s; }

		public function get featureId(): String
		{ return ms_featureId; }
		
		public function set internalFeatureId(s: String): void
		{ ms_internalFeatureId = s; }

		public function get internalFeatureId(): String
		{ return ms_internalFeatureId; }

		public function get master(): InteractiveLayerWFS
		{ return m_master; }
	}
}
