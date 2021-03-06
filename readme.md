# POI+
#### iOS App

POI+ is a simple and straightforward iPhone app that can add or edit exisiting nodes, ways and relations in [OpenStreetMap](http://openstreetmap.org)

[![App Store](http://linkmaker.itunes.apple.com/htmlResources/assets/images/web/linkmaker/badge_appstore-lrg.svg)](https://itunes.apple.com/us/app/poi+-open-street-map-poi-editor/id518401562?mt=8&uo=4)

## Project Setup

`git clone git@github.com:davidchiles/osm-poi-editor-iOS.git --recursive`

change `OPEAPIConstants_example.h` to `OPEAPIConstants.h`

To use bing as a tile source or make edits to OpenStreetMap fill in the necessary fields in `OPEAPIConstants.h`

## Localization

Translate at [Transifex](https://www.transifex.com/projects/p/poi/resource/localizablestrings/)

![localization Progress](https://www.transifex.com/projects/p/poi/resource/localizablestrings/chart/image_png)

## Third Party Libraries

- [MBProgressHUD](https://github.com/jdg/MBProgressHUD)
- [AFNetworking](https://github.com/AFNetworking/AFNetworking)
- [gtm-oauth2](http://code.google.com/p/gtm-oauth2/)
- [TBXML](https://github.com/71squared/TBXML)
- [MapBox iOS SDK](https://github.com/mapbox/mapbox-ios-sdk)
- [FMDB](https://github.com/ccgus/fmdb)

## License
This software is available under the terms of the GNU GPLv3. [Full license terms](http://www.gnu.org/licenses/gpl.html)