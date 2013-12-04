package tiled {
    import com.iblsoft.flexiweather.ogc.BBox;
    import com.iblsoft.flexiweather.ogc.CRSWithBBox;
    import com.iblsoft.flexiweather.ogc.InteractiveLayerQTTMS;
    import com.iblsoft.flexiweather.ogc.configuration.layers.QTTMSLayerConfiguration;
    import com.iblsoft.flexiweather.ogc.tiling.TileMatrix;
    import com.iblsoft.flexiweather.ogc.tiling.TileMatrixLimits;
    import com.iblsoft.flexiweather.ogc.tiling.TileMatrixSet;
    import com.iblsoft.flexiweather.ogc.tiling.TileMatrixSetLimits;
    import com.iblsoft.flexiweather.ogc.tiling.TileMatrixSetLink;
    import com.iblsoft.flexiweather.ogc.tiling.TiledTilingInfo;
    import com.iblsoft.flexiweather.widgets.InteractiveWidget;
    import flash.geom.Point;

    //TODO implement IPreloadable
    public class LargeTiledLayer extends InteractiveLayerQTTMS {

        // Zoom level is intended for 1024 tiles rather than 256
        private static const overriddenMinZoom:int = 4;
        
        public function LargeTiledLayer(container: InteractiveWidget = null, cfg: QTTMSLayerConfiguration = null) {
            super(container, cfg);
        }
        
        override public function addCRSWithTilingExtent(s_urlPattern:String, s_tilingCRS:String, crsTilingExtent:BBox, tileSize:uint, minimumZoomLevel:int, maximumZoomLevel:int): void {
            var tileMatrixSet: TileMatrixSet = new TileMatrixSet();
            tileMatrixSet.id = s_tilingCRS;
            tileMatrixSet.supportedCRS = s_tilingCRS;
            
            for (var i: int = overriddenMinZoom; i <= 18; i++) {
                
                var matrix: TileMatrix = new TileMatrix();
                matrix.id = s_tilingCRS + ':' + i;
                
                matrix.topLeftCorner = new Point(-180, -180);
                matrix.tileWidth = 1024; 
                matrix.tileHeight = 1024;
                matrix.matrixWidth = Math.pow(2, i-2);
                matrix.matrixHeight = Math.pow(2, i-2);
                
                matrix.scaleDenominator = 360 / (matrix.tileWidth * matrix.matrixWidth);
                tileMatrixSet.addTileMatrix(matrix);
            }
            var tileMatrixSetLink: TileMatrixSetLink = new TileMatrixSetLink();
            tileMatrixSetLink.tileMatrixSet = tileMatrixSet;
            
            var tileMatrixSetLimitsArray: TileMatrixSetLimits = new TileMatrixSetLimits();
            for (var l: int = overriddenMinZoom; l <= 18; l++) {
                var limit: TileMatrixLimits = new TileMatrixLimits();
                limit.tileMatrix = s_tilingCRS + ':' + l;
                limit.minTileRow = 0;//Math.pow(2, l - 4);
                limit.maxTileRow = Math.pow(2, l-2) - 1;//limit.minTileRow + Math.pow(2, l - 3) - 1;
                limit.minTileColumn = 0;
                limit.maxTileColumn = Math.pow(2, l-2) - 1;
                tileMatrixSetLimitsArray.addTileMatrixLimits(limit);
            }
            tileMatrixSetLink.tileMatrixSetLimitsArray = tileMatrixSetLimitsArray;
            
            addTileMatrixSetLink(tileMatrixSetLink);
            
            var crsWithBBox: CRSWithBBox = new CRSWithBBox(s_tilingCRS, crsTilingExtent);
            var tilingInfo: TiledTilingInfo = new TiledTilingInfo(s_urlPattern, crsWithBBox);
            (m_cfg as QTTMSLayerConfiguration).addTiledTilingInfo(tilingInfo);
        }

        override public function baseURLPatternForCRS(crs: String): String {
            var baseURL:String = super.baseURLPatternForCRS(crs);
            baseURL = removeBBOXWidthAndHeightFromBaseURL(baseURL);
            return baseURL;
        }

        private static function removeBBOXWidthAndHeightFromBaseURL(baseURL:String):String {
            var splitUpURL:Array = baseURL.split("&");
            var param:String;
            for (var i:int = 0; i < splitUpURL.length; i++) {
                param = splitUpURL[i];
                if (isBBOXWidthOrHeight(param)) {
                    splitUpURL.splice(splitUpURL.indexOf(param), 1);
                    i--;
                }
            }
            return splitUpURL.join("&");
        }

        private static function isBBOXWidthOrHeight(param:String):Boolean {
            return (param.substr(0,5).toUpperCase() == "BBOX="
                || param.substr(0,6).toUpperCase() == "WIDTH="
                || param.substr(0,7).toUpperCase() == "HEIGHT=");
        }

        public function testTriggerFindZoom():void {
            trace("Do not use function in production code");
            _layerInitialized = true;
            initializeLayerAfterAddToStage();
            super.findZoom();
        }
    }
}