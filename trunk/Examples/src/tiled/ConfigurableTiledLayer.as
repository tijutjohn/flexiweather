package tiled {
    
    import com.iblsoft.flexiweather.ogc.InteractiveLayerQTTMS;
    import com.iblsoft.flexiweather.ogc.configuration.layers.QTTMSLayerConfiguration;
    import com.iblsoft.flexiweather.ogc.configuration.layers.WMSWithQTTLayerConfiguration;
    import com.iblsoft.flexiweather.ogc.tiling.InteractiveLayerTiled;
    import com.iblsoft.flexiweather.ogc.tiling.InteractiveLayerWMSWithQTT;
    import com.iblsoft.flexiweather.widgets.InteractiveDataLayer;
    import com.iblsoft.flexiweather.widgets.InteractiveWidget;
    
    public class ConfigurableTiledLayer extends InteractiveLayerWMSWithQTT {
        
        public function ConfigurableTiledLayer(container:InteractiveWidget, cfg:WMSWithQTTLayerConfiguration) {
            super(container, cfg);
        }
        
        override protected function createTiledLayer():InteractiveLayerQTTMS {
            var tiledLayerConfig: QTTMSLayerConfiguration = new QTTMSLayerConfiguration();
            return new LargeTiledLayer(container, tiledLayerConfig);
        }
    }
}