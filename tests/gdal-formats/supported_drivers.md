# Supported GDAL Drivers



**Abbreviations:**

- `r`: Read support
- `w`: Write support
- `+`: Update (read/write) support
- `v`: Supports virtual IO operations (like reading from `/vsimem`, `/vsicurl`, etc.)
- `s`: Supports subdatasets
- `o`: Optional features

Combining these abbreviations, you get:

- `ro`: Read-only support
- `rw`: Read and write support
- `rw+`: Read, write, and update support
- `rovs`: Read-only support with virtual IO and subdataset support
- `rw+v`: Read, write, update support with virtual IO


|                 | osx (raster)   | unix (raster)   | win (raster)   | osx (vector)   | unix (vector)   | win (vector)   |
|:----------------|:---------------|:----------------|:---------------|:---------------|:----------------|:---------------|
| AAIGrid         | rwv            | rwv             | rwv            | ✗              | ✗               | ✗              |
| ACE2            | rov            | rov             | rov            | ✗              | ✗               | ✗              |
| ADRG            | rw+vs          | rw+vs           | rw+vs          | ✗              | ✗               | ✗              |
| AIG             | rov            | rov             | rov            | ✗              | ✗               | ✗              |
| AVCBin          | ✗              | ✗               | ✗              | rov            | rov             | rov            |
| AVCE00          | ✗              | ✗               | ✗              | rov            | rov             | rov            |
| AVIF            | rwvs           | ✗               | ✗              | ✗              | ✗               | ✗              |
| AirSAR          | rov            | rov             | rov            | ✗              | ✗               | ✗              |
| AmigoCloud      | ✗              | ✗               | ✗              | rw+            | rw+             | rw+            |
| BAG             | rw+v           | rw+v            | rw+v           | rw+v           | rw+v            | rw+v           |
| BIGGIF          | rov            | rov             | rov            | ✗              | ✗               | ✗              |
| BLX             | rwv            | rwv             | rwv            | ✗              | ✗               | ✗              |
| BMP             | rw+v           | rw+v            | rw+v           | ✗              | ✗               | ✗              |
| BSB             | rov            | rov             | rov            | ✗              | ✗               | ✗              |
| BT              | rw+v           | rw+v            | rw+v           | ✗              | ✗               | ✗              |
| BYN             | rw+v           | rw+v            | rw+v           | ✗              | ✗               | ✗              |
| CAD             | rovs           | rovs            | rovs           | rovs           | rovs            | rovs           |
| CALS            | rwv            | rwv             | rwv            | ✗              | ✗               | ✗              |
| CEOS            | rov            | rov             | rov            | ✗              | ✗               | ✗              |
| COASP           | ro             | ro              | ro             | ✗              | ✗               | ✗              |
| COG             | wv             | wv              | wv             | ✗              | ✗               | ✗              |
| COSAR           | rov            | rov             | rov            | ✗              | ✗               | ✗              |
| CPG             | rov            | rov             | rov            | ✗              | ✗               | ✗              |
| CSV             | ✗              | ✗               | ✗              | rw+v           | rw+v            | rw+v           |
| CSW             | ✗              | ✗               | ✗              | ro             | ro              | ro             |
| CTG             | rov            | rov             | rov            | ✗              | ✗               | ✗              |
| CTable2         | rw+v           | rw+v            | rw+v           | ✗              | ✗               | ✗              |
| Carto           | ✗              | ✗               | ✗              | rw+            | rw+             | rw+            |
| DAAS            | ro             | ro              | ro             | ✗              | ✗               | ✗              |
| DERIVED         | ro             | ro              | ro             | ✗              | ✗               | ✗              |
| DGN             | ✗              | ✗               | ✗              | rw+v           | rw+v            | rw+v           |
| DIMAP           | rovs           | rovs            | rovs           | ✗              | ✗               | ✗              |
| DIPEx           | rov            | rov             | rov            | ✗              | ✗               | ✗              |
| DOQ1            | rov            | rov             | rov            | ✗              | ✗               | ✗              |
| DOQ2            | rov            | rov             | rov            | ✗              | ✗               | ✗              |
| DTED            | rwv            | rwv             | rwv            | ✗              | ✗               | ✗              |
| DXF             | ✗              | ✗               | ✗              | rw+v           | rw+v            | rw+v           |
| ECRGTOC         | rovs           | rovs            | rovs           | ✗              | ✗               | ✗              |
| EDIGEO          | ✗              | ✗               | ✗              | rov            | rov             | rov            |
| EEDA            | ✗              | ✗               | ✗              | ro             | ro              | ro             |
| EEDAI           | ros            | ros             | ros            | ✗              | ✗               | ✗              |
| EHdr            | rw+v           | rw+v            | rw+v           | ✗              | ✗               | ✗              |
| EIR             | rov            | rov             | rov            | ✗              | ✗               | ✗              |
| ELAS            | rw+v           | rw+v            | rw+v           | ✗              | ✗               | ✗              |
| ENVI            | rw+v           | rw+v            | rw+v           | ✗              | ✗               | ✗              |
| ERS             | rw+v           | rw+v            | rw+v           | ✗              | ✗               | ✗              |
| ESAT            | rov            | rov             | rov            | ✗              | ✗               | ✗              |
| ESRIC           | rov            | rov             | rov            | ✗              | ✗               | ✗              |
| ESRIJSON        | ✗              | ✗               | ✗              | rov            | rov             | rov            |
| EXR             | rw+vs          | rw+vs           | ✗              | ✗              | ✗               | ✗              |
| Elasticsearch   | ✗              | ✗               | ✗              | rw+            | rw+             | rw+            |
| FAST            | rov            | rov             | rov            | ✗              | ✗               | ✗              |
| FIT             | rwv            | rwv             | rwv            | ✗              | ✗               | ✗              |
| FITS            | rw+            | rw+             | rw+            | rw+            | rw+             | rw+            |
| FlatGeobuf      | ✗              | ✗               | ✗              | rw+v           | rw+v            | rw+v           |
| GFF             | rov            | rov             | rov            | ✗              | ✗               | ✗              |
| GIF             | rwv            | rwv             | rwv            | ✗              | ✗               | ✗              |
| GML             | ✗              | ✗               | ✗              | rw+v           | rw+v            | rw+v           |
| GMLAS           | ✗              | ✗               | ✗              | rwv            | rwv             | rwv            |
| GPKG            | rw+vs          | rw+vs           | rw+vs          | rw+vs          | rw+vs           | rw+vs          |
| GPSBabel        | ✗              | ✗               | ✗              | rw+            | rw+             | rw+            |
| GPX             | ✗              | ✗               | ✗              | rw+v           | rw+v            | rw+v           |
| GRASSASCIIGrid  | rov            | rov             | rov            | ✗              | ✗               | ✗              |
| GRIB            | rwv            | rwv             | rwv            | ✗              | ✗               | ✗              |
| GS7BG           | rw+v           | rw+v            | rw+v           | ✗              | ✗               | ✗              |
| GSAG            | rwv            | rwv             | rwv            | ✗              | ✗               | ✗              |
| GSBG            | rw+v           | rw+v            | rw+v           | ✗              | ✗               | ✗              |
| GSC             | rov            | rov             | rov            | ✗              | ✗               | ✗              |
| GTFS            | ✗              | ✗               | ✗              | rov            | rov             | rov            |
| GTI             | rov            | rov             | rov            | ✗              | ✗               | ✗              |
| GTX             | rw+v           | rw+v            | rw+v           | ✗              | ✗               | ✗              |
| GTiff           | rw+vs          | rw+vs           | rw+vs          | ✗              | ✗               | ✗              |
| GXF             | rov            | rov             | rov            | ✗              | ✗               | ✗              |
| GenBin          | rov            | rov             | rov            | ✗              | ✗               | ✗              |
| GeoJSON         | ✗              | ✗               | ✗              | rw+v           | rw+v            | rw+v           |
| GeoJSONSeq      | ✗              | ✗               | ✗              | rw+v           | rw+v            | rw+v           |
| GeoRSS          | ✗              | ✗               | ✗              | rw+v           | rw+v            | rw+v           |
| Geoconcept      | ✗              | ✗               | ✗              | rw+v           | rw+v            | rw+v           |
| HDF4            | ros            | ros             | ros            | ✗              | ✗               | ✗              |
| HDF4Image       | rw+            | rw+             | rw+            | ✗              | ✗               | ✗              |
| HDF5            | rovs           | rovs            | rovs           | ✗              | ✗               | ✗              |
| HDF5Image       | rov            | rov             | rov            | ✗              | ✗               | ✗              |
| HF2             | rwv            | rwv             | rwv            | ✗              | ✗               | ✗              |
| HFA             | rw+v           | rw+v            | rw+v           | ✗              | ✗               | ✗              |
| HTTP            | ro             | ro              | ro             | ro             | ro              | ro             |
| ILWIS           | rw+v           | rw+v            | rw+v           | ✗              | ✗               | ✗              |
| IRIS            | rov            | rov             | rov            | ✗              | ✗               | ✗              |
| ISCE            | rw+v           | rw+v            | rw+v           | ✗              | ✗               | ✗              |
| ISG             | rov            | rov             | rov            | ✗              | ✗               | ✗              |
| ISIS2           | rw+v           | rw+v            | rw+v           | ✗              | ✗               | ✗              |
| ISIS3           | rw+v           | rw+v            | rw+v           | ✗              | ✗               | ✗              |
| Idrisi          | ✗              | ✗               | ✗              | rov            | rov             | rov            |
| JAXAPALSAR      | rov            | rov             | rov            | ✗              | ✗               | ✗              |
| JDEM            | rov            | rov             | rov            | ✗              | ✗               | ✗              |
| JML             | ✗              | ✗               | ✗              | rw+v           | rw+v            | rw+v           |
| JP2OpenJPEG     | rwv            | rwv             | rwv            | rwv            | rwv             | rwv            |
| JPEG            | rwv            | rwv             | rwv            | ✗              | ✗               | ✗              |
| JPEGXL          | rwv            | rwv             | rwv            | ✗              | ✗               | ✗              |
| JSONFG          | ✗              | ✗               | ✗              | rw+v           | rw+v            | rw+v           |
| KML             | ✗              | ✗               | ✗              | rw+v           | rw+v            | rw+v           |
| KMLSUPEROVERLAY | rwv            | rwv             | rwv            | ✗              | ✗               | ✗              |
| KRO             | rw+v           | rw+v            | rw+v           | ✗              | ✗               | ✗              |
| L1B             | rovs           | rovs            | rovs           | ✗              | ✗               | ✗              |
| LAN             | rw+v           | rw+v            | rw+v           | ✗              | ✗               | ✗              |
| LCP             | rwv            | rwv             | rwv            | ✗              | ✗               | ✗              |
| LIBKML          | ✗              | ✗               | ✗              | rw+v           | rw+v            | rw+v           |
| LOSLAS          | rov            | rov             | rov            | ✗              | ✗               | ✗              |
| LVBAG           | ✗              | ✗               | ✗              | rov            | rov             | rov            |
| Leveller        | rw+v           | rw+v            | rw+v           | ✗              | ✗               | ✗              |
| MAP             | rov            | rov             | rov            | ✗              | ✗               | ✗              |
| MBTiles         | rw+v           | rw+v            | rw+v           | rw+v           | rw+v            | rw+v           |
| MEM             | rw+            | rw+             | rw+            | ✗              | ✗               | ✗              |
| MFF             | rw+v           | rw+v            | rw+v           | ✗              | ✗               | ✗              |
| MFF2            | rw+            | rw+             | rw+            | ✗              | ✗               | ✗              |
| MRF             | rw+v           | rw+v            | rw+v           | ✗              | ✗               | ✗              |
| MSGN            | rov            | rov             | rov            | ✗              | ✗               | ✗              |
| MSSQLSpatial    | ✗              | ✗               | ✗              | rw+            | rw+             | rw+            |
| MVT             | ✗              | ✗               | ✗              | rw+v           | rw+v            | rw+v           |
| MapML           | ✗              | ✗               | ✗              | rw+v           | rw+v            | rw+v           |
| Memory          | ✗              | ✗               | ✗              | rw+            | rw+             | rw+            |
| MiraMonVector   | ✗              | ✗               | ✗              | rw+v           | rw+v            | rw+v           |
| MySQL           | ✗              | ✗               | ✗              | rw+            | rw+             | rw+            |
| NAS             | ✗              | ✗               | ✗              | rov            | rov             | rov            |
| NDF             | rov            | rov             | rov            | ✗              | ✗               | ✗              |
| NGSGEOID        | rov            | rov             | rov            | ✗              | ✗               | ✗              |
| NGW             | rw+s           | rw+s            | rw+s           | rw+s           | rw+s            | rw+s           |
| NITF            | rw+vs          | rw+vs           | rw+vs          | ✗              | ✗               | ✗              |
| NOAA_B          | rov            | rov             | rov            | ✗              | ✗               | ✗              |
| NSIDCbin        | rov            | rov             | rov            | ✗              | ✗               | ✗              |
| NTv2            | rw+vs          | rw+vs           | rw+vs          | ✗              | ✗               | ✗              |
| NWT_GRC         | rov            | rov             | rov            | ✗              | ✗               | ✗              |
| NWT_GRD         | rw+v           | rw+v            | rw+v           | ✗              | ✗               | ✗              |
| OAPIF           | ✗              | ✗               | ✗              | ro             | ro              | ro             |
| ODBC            | ✗              | ✗               | ✗              | ro             | ro              | ro             |
| ODS             | ✗              | ✗               | ✗              | rw+v           | rw+v            | rw+v           |
| OGCAPI          | rov            | rov             | rov            | rov            | rov             | rov            |
| OGR_GMT         | ✗              | ✗               | ✗              | rw+v           | rw+v            | rw+v           |
| OGR_PDS         | ✗              | ✗               | ✗              | rov            | rov             | rov            |
| OGR_SDTS        | ✗              | ✗               | ✗              | rov            | rov             | rov            |
| OGR_VRT         | ✗              | ✗               | ✗              | rov            | rov             | rov            |
| OSM             | ✗              | ✗               | ✗              | rov            | rov             | rov            |
| OZI             | rov            | rov             | rov            | ✗              | ✗               | ✗              |
| OpenFileGDB     | rw+v           | rw+v            | rw+v           | rw+v           | rw+v            | rw+v           |
| PAux            | rw+v           | rw+v            | rw+v           | ✗              | ✗               | ✗              |
| PCIDSK          | rw+v           | rw+v            | rw+v           | rw+v           | rw+v            | rw+v           |
| PCRaster        | rw+            | rw+             | rw+            | ✗              | ✗               | ✗              |
| PDF             | rw+vs          | rw+vs           | rw+vs          | rw+vs          | rw+vs           | rw+vs          |
| PDS             | rov            | rov             | rov            | ✗              | ✗               | ✗              |
| PDS4            | rw+vs          | rw+vs           | rw+vs          | rw+vs          | rw+vs           | rw+vs          |
| PGDUMP          | ✗              | ✗               | ✗              | w+v            | w+v             | w+v            |
| PGeo            | ✗              | ✗               | ✗              | ro             | ro              | ro             |
| PLMOSAIC        | ro             | ro              | ro             | ✗              | ✗               | ✗              |
| PLSCENES        | ro             | ro              | ro             | ro             | ro              | ro             |
| PMTiles         | ✗              | ✗               | ✗              | rw+v           | rw+v            | rw+v           |
| PNG             | rwv            | rwv             | rwv            | ✗              | ✗               | ✗              |
| PNM             | rw+v           | rw+v            | rw+v           | ✗              | ✗               | ✗              |
| PRF             | rov            | rov             | rov            | ✗              | ✗               | ✗              |
| PostGISRaster   | rws            | rws             | rws            | ✗              | ✗               | ✗              |
| PostgreSQL      | ✗              | ✗               | ✗              | rw+            | rw+             | rw+            |
| R               | rwv            | rwv             | rwv            | ✗              | ✗               | ✗              |
| RIK             | rov            | rov             | rov            | ✗              | ✗               | ✗              |
| RMF             | rw+v           | rw+v            | rw+v           | ✗              | ✗               | ✗              |
| ROI_PAC         | rw+v           | rw+v            | rw+v           | ✗              | ✗               | ✗              |
| RPFTOC          | rovs           | rovs            | rovs           | ✗              | ✗               | ✗              |
| RRASTER         | rw+v           | rw+v            | rw+v           | ✗              | ✗               | ✗              |
| RS2             | rovs           | rovs            | rovs           | ✗              | ✗               | ✗              |
| RST             | rw+v           | rw+v            | rw+v           | ✗              | ✗               | ✗              |
| Rasterlite      | rwvs           | rwvs            | rwvs           | ✗              | ✗               | ✗              |
| S102            | rovs           | rovs            | rovs           | ✗              | ✗               | ✗              |
| S104            | rov            | rov             | rov            | ✗              | ✗               | ✗              |
| S111            | rov            | rov             | rov            | ✗              | ✗               | ✗              |
| S57             | ✗              | ✗               | ✗              | rw+v           | rw+v            | rw+v           |
| SAFE            | rov            | rov             | rov            | ✗              | ✗               | ✗              |
| SAGA            | rw+v           | rw+v            | rw+v           | ✗              | ✗               | ✗              |
| SAR_CEOS        | rov            | rov             | rov            | ✗              | ✗               | ✗              |
| SDTS            | rov            | rov             | rov            | ✗              | ✗               | ✗              |
| SENTINEL2       | rovs           | rovs            | rovs           | ✗              | ✗               | ✗              |
| SGI             | rw+v           | rw+v            | rw+v           | ✗              | ✗               | ✗              |
| SIGDEM          | rwv            | rwv             | rwv            | ✗              | ✗               | ✗              |
| SNAP_TIFF       | rov            | rov             | rov            | ✗              | ✗               | ✗              |
| SNODAS          | rov            | rov             | rov            | ✗              | ✗               | ✗              |
| SQLite          | ✗              | ✗               | ✗              | rw+v           | rw+v            | rw+v           |
| SRP             | rovs           | rovs            | rovs           | ✗              | ✗               | ✗              |
| SRTMHGT         | rwv            | rwv             | rwv            | ✗              | ✗               | ✗              |
| STACIT          | rovs           | rovs            | rovs           | ✗              | ✗               | ✗              |
| STACTA          | rovs           | rovs            | rovs           | ✗              | ✗               | ✗              |
| SVG             | ✗              | ✗               | ✗              | rov            | rov             | rov            |
| SXF             | ✗              | ✗               | ✗              | rov            | rov             | rov            |
| Selafin         | ✗              | ✗               | ✗              | rw+v           | rw+v            | rw+v           |
| TGA             | rov            | rov             | rov            | ✗              | ✗               | ✗              |
| TIGER           | ✗              | ✗               | ✗              | rov            | rov             | rov            |
| TIL             | rov            | rov             | rov            | ✗              | ✗               | ✗              |
| TSX             | rov            | rov             | rov            | ✗              | ✗               | ✗              |
| Terragen        | rw+v           | rw+v            | rw+v           | ✗              | ✗               | ✗              |
| TopoJSON        | ✗              | ✗               | ✗              | rov            | rov             | rov            |
| USGSDEM         | rwv            | rwv             | rwv            | ✗              | ✗               | ✗              |
| VDV             | ✗              | ✗               | ✗              | rw+v           | rw+v            | rw+v           |
| VFK             | ✗              | ✗               | ✗              | ro             | ro              | ro             |
| VICAR           | rw+v           | rw+v            | rw+v           | rw+v           | rw+v            | rw+v           |
| VRT             | rw+v           | rw+v            | rw+v           | ✗              | ✗               | ✗              |
| WAsP            | ✗              | ✗               | ✗              | rw+v           | rw+v            | rw+v           |
| WCS             | rovs           | rovs            | rovs           | ✗              | ✗               | ✗              |
| WEBP            | rwv            | rwv             | rwv            | ✗              | ✗               | ✗              |
| WFS             | ✗              | ✗               | ✗              | rov            | rov             | rov            |
| WMS             | rwvs           | rwvs            | rwvs           | ✗              | ✗               | ✗              |
| WMTS            | rwv            | rwv             | rwv            | ✗              | ✗               | ✗              |
| XLS             | ✗              | ✗               | ✗              | ro             | ro              | ro             |
| XLSX            | ✗              | ✗               | ✗              | rw+v           | rw+v            | rw+v           |
| XPM             | rwv            | rwv             | rwv            | ✗              | ✗               | ✗              |
| XYZ             | rwv            | rwv             | rwv            | ✗              | ✗               | ✗              |
| ZMap            | rwv            | rwv             | rwv            | ✗              | ✗               | ✗              |
| Zarr            | rw+vs          | rw+vs           | rw+vs          | ✗              | ✗               | ✗              |
| netCDF          | rw+s           | rw+s            | rw+s           | rw+s           | rw+s            | rw+s           |