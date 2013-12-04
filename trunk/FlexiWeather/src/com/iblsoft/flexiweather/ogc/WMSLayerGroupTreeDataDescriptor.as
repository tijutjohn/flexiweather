package com.iblsoft.flexiweather.ogc
{
	import mx.collections.ArrayCollection;
	import mx.collections.ICollectionView;
	import mx.controls.treeClasses.ITreeDataDescriptor;

	public class WMSLayerGroupTreeDataDescriptor implements ITreeDataDescriptor
	{
		public function WMSLayerGroupTreeDataDescriptor()
		{
		}

		public function getChildren(node: Object, model: Object = null): ICollectionView
		{
			return node is WMSLayerGroup ? new ArrayCollection(WMSLayerGroup(node).layers) : null;
		}

		public function hasChildren(node: Object, model: Object = null): Boolean
		{
			return node is WMSLayerGroup && WMSLayerGroup(node).layers.length > 0;
		}

		public function isBranch(node: Object, model: Object = null): Boolean
		{
			return node is WMSLayerGroup;
		}

		public function getData(node: Object, model: Object = null): Object
		{
			return node;
		}

		public function addChildAt(parent: Object, newChild: Object,
				index: int, model: Object = null): Boolean
		{
			return false;
		}

		public function removeChildAt(parent: Object, child: Object,
				index: int, model: Object = null): Boolean
		{
			return false;
		}
	}
}
