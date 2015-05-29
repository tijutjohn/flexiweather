**All source code has been moved to Git. Code examples and Adobe AIR extensions are now in separated Git repositories:**
  * https://code.google.com/p/flexiweather/ - main Flexi Weather library.
  * https://code.google.com/p/flexiweather.air/ - Adobe AIR extensions of Flexi Weather.
  * https://code.google.com/p/flexiweather.examples/ - demos & examples.

Flexi Weather is a geospatial mapping and data visualisation library for Adobe Flex with strong focus on the presentation of meteorological data (typically provided through OpenGIS web services). It also includes various useful general purpose Flex UI components. Flexi Weather does not have ambition to fight with other Flex GIS/mapping libraries (such as Open Scales or Google Maps). Rather it tries to integrate with them and provide more generic and more comprehensive solution where the "solid-earth-GIS" libraries don't cope well with the rapidly dynamic world (as is it seen by meteorologists, where datasets change even on per-minute basis) with the world which presented in conformal (metric preserving) projections rather then in rectangular CRS:84/EPSG:4326 only.

Flexi Weather is actively developed by [IBL Software Engineering](http://www.iblsoft.com) company which can also provide commercial support for this library. Even if most of the code is generally usable to consume any standard services (see features section below), this library also supports proprietary APIs available out of [IBL Visual Weather](http://www.iblsoft.com/products/visualweather).

Flexi Weather does not only run in a Web browser, the code also includes special tunings for the in Flex Mobile applications running in Google Android or Apple iOS.

# General targets and plans #
  * support for OGC protocols and [MetOceanDWG](http://external.opengis.org/twiki_public/MetOceanDWG) formats
  * extended OGC Web Feature Service (WFS-T) based editor of meteorological weather features (SigWX)
  * implement rendering of in-situ data fetched from WFS services (such as observations)
  * implement Web Coverage Service client layer
  * include supporting classes for geospatial abstractions

# Current major features #
  * support for OpenGIS WMS 1.1.0-1.3.0 with dimensions (TIME, sample DIM`_`ensions) and WMS layer styles
  * simple support for OpenGIS WFS 1.0/1.1
  * rendering of various meteorological symbols (starting from dashed line up to front and clouds curves - see Example 2)
  * interactive component for geospatial "layering" (InteractiveWidget) allowing easy development of new visualisation layers or layers with user interaction (editors, geodata selectors).
  * easy-to-use reprojection capability from the screen space to any projections coordinates
  * classes for building plug-in-able applications (plugin registry, capability objects)
  * general purpose tiling layer (for example for Open Street Map or Google Maps Enteprise integration)
  * layer for the Flex Google Maps API.

# Projects using this library #
## <a href='http://www.iblsoft.com/products/onlineweather'>IBL Online Weather</a> ##
IBL Software engineering build the FlexiWeather as the core library for the 3rd generation of IBL Online Weather system. See IBL online <a href='https://ogcie.iblsoft.com/FlexiWeather'>demo page</a> for more details.