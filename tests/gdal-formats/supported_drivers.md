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
| ADBC            | ✗              | ✗               | ✗              | ro             | ro              | ro             |
| ADRG            | rovs           | rovs            | rovs           | ✗              | ✗               | ✗              |
| AIG             | rov            | rov             | rov            | ✗              | ✗               | ✗              |
| AIVector        | ✗              | ✗               | ✗              | ro             | ro              | ro             |
| AVCBin          | ✗              | ✗               | ✗              | rov            | rov             | rov            |
| AVCE00          | ✗              | ✗               | ✗              | rov            | rov             | rov            |
| AVIF            | ✗              | ✗               | ✗              | ✗              | ✗               | ✗              |
| AirSAR          | rov            | rov             | rov            | ✗              | ✗               | ✗              |
| AmigoCloud      | ✗              | ✗               | ✗              | rw+            | rw+             | rw+            |
| BAG             | rw+v           | rw+v            | rw+v           | rw+v           | rw+v            | rw+v           |
| BIGGIF          | rov            | rov             | rov            | ✗              | ✗               | ✗              |
| BMP             | rw+v           | rw+v            | rw+v           | ✗              | ✗               | ✗              |
| BSB             | rov            | rov             | rov            | ✗              | ✗               | ✗              |
| BT              | rw+v           | rw+v            | rw+v           | ✗              | ✗               | ✗              |
| BYN             | rov            | rov             | rov            | ✗              | ✗               | ✗              |
| CAD             | rovs           | rovs            | rovs           | rovs           | rovs            | rovs           |
| CALS            | rwv            | rwv             | rwv            | ✗              | ✗               | ✗              |
| CEOS            | rov            | rov             | rov            | ✗              | ✗               | ✗              |
| COASP           | ro             | ro              | ro             | ✗              | ✗               | ✗              |
| COG             | wv             | wv              | wv             | ✗              | ✗               | ✗              |
| COSAR           | rov            | rov             | rov            | ✗              | ✗               | ✗              |
| CPG             | rov            | rov             | rov            | ✗              | ✗               | ✗              |
| CSV             | ✗              | ✗               | ✗              | rw+uv          | rw+uv           | rw+uv          |
| CSW             | ✗              | ✗               | ✗              | ro             | ro              | ro             |
| CTG             | rov            | rov             | rov            | ✗              | ✗               | ✗              |
| Carto           | ✗              | ✗               | ✗              | rw+            | rw+             | rw+            |
| DAAS            | ro             | ro              | ro             | ✗              | ✗               | ✗              |
| DERIVED         | ro             | ro              | ro             | ✗              | ✗               | ✗              |
| DGN             | ✗              | ✗               | ✗              | rw+v           | rw+v            | rw+v           |
| DIMAP           | rovs           | rovs            | rovs           | ✗              | ✗               | ✗              |
| DOQ1            | rov            | rov             | rov            | ✗              | ✗               | ✗              |
| DOQ2            | rov            | rov             | rov            | ✗              | ✗               | ✗              |
| DTED            | rwv            | rwv             | rwv            | ✗              | ✗               | ✗              |
| DXF             | ✗              | ✗               | ✗              | rw+v           | rw+v            | rw+v           |
| ECRGTOC         | rovs           | rovs            | rovs           | ✗              | ✗               | ✗              |
| EDIGEO          | ✗              | ✗               | ✗              | rov            | rov             | rov            |
| EEDA            | ✗              | ✗               | ✗              | ro             | ro              | ro             |
| EEDAI           | ros            | ros             | ros            | ✗              | ✗               | ✗              |
| EHdr            | rw+uv          | rw+uv           | rw+uv          | ✗              | ✗               | ✗              |
| EIR             | rov            | rov             | rov            | ✗              | ✗               | ✗              |
| ENVI            | rw+uv          | rw+uv           | rw+uv          | ✗              | ✗               | ✗              |
| ERS             | rw+v           | rw+v            | rw+v           | ✗              | ✗               | ✗              |
| ESAT            | rov            | rov             | rov            | ✗              | ✗               | ✗              |
| ESRIC           | rov            | rov             | rov            | ✗              | ✗               | ✗              |
| ESRIJSON        | ✗              | ✗               | ✗              | rov            | rov             | rov            |
| EXR             | rw+vs          | rw+vs           | ✗              | ✗              | ✗               | ✗              |
| Elasticsearch   | ✗              | ✗               | ✗              | rw+            | rw+             | rw+            |
| FAST            | rov            | rov             | rov            | ✗              | ✗               | ✗              |
| FITS            | rw+            | rw+             | rw+            | rw+            | rw+             | rw+            |
| FlatGeobuf      | ✗              | ✗               | ✗              | rw+v           | rw+v            | rw+v           |
| GDALG           | rov            | rov             | rov            | rov            | rov             | rov            |
| GFF             | rov            | rov             | rov            | ✗              | ✗               | ✗              |
| GIF             | rwv            | rwv             | rwv            | ✗              | ✗               | ✗              |
| GML             | ✗              | ✗               | ✗              | rw+v           | rw+v            | rw+v           |
| GMLAS           | ✗              | ✗               | ✗              | rwv            | rwv             | rwv            |
| GPKG            | rw+uvs         | rw+uvs          | rw+uvs         | rw+uvs         | rw+uvs          | rw+uvs         |
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
| GTiff           | rw+uvs         | rw+uvs          | rw+uvs         | ✗              | ✗               | ✗              |
| GXF             | rov            | rov             | rov            | ✗              | ✗               | ✗              |
| GenBin          | rov            | rov             | rov            | ✗              | ✗               | ✗              |
| GeoJSON         | ✗              | ✗               | ✗              | rw+uv          | rw+uv           | rw+uv          |
| GeoJSONSeq      | ✗              | ✗               | ✗              | rw+v           | rw+v            | rw+v           |
| GeoRSS          | ✗              | ✗               | ✗              | rw+v           | rw+v            | rw+v           |
| HDF4            | ros            | ros             | ros            | ✗              | ✗               | ✗              |
| HDF4Image       | rw+            | rw+             | rw+            | ✗              | ✗               | ✗              |
| HDF5            | rovs           | rovs            | rovs           | ✗              | ✗               | ✗              |
| HDF5Image       | rov            | rov             | rov            | ✗              | ✗               | ✗              |
| HF2             | rwv            | rwv             | rwv            | ✗              | ✗               | ✗              |
| HFA             | rw+uv          | rw+uv           | rw+uv          | ✗              | ✗               | ✗              |
| HTTP            | ro             | ro              | ro             | ro             | ro              | ro             |
| ILWIS           | rw+v           | rw+v            | rw+v           | ✗              | ✗               | ✗              |
| IRIS            | rov            | rov             | rov            | ✗              | ✗               | ✗              |
| ISCE            | rw+v           | rw+v            | rw+v           | ✗              | ✗               | ✗              |
| ISG             | rov            | rov             | rov            | ✗              | ✗               | ✗              |
| ISIS2           | rov            | rov             | rov            | ✗              | ✗               | ✗              |
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
| LAN             | rov            | rov             | rov            | ✗              | ✗               | ✗              |
| LCP             | rwv            | rwv             | rwv            | ✗              | ✗               | ✗              |
| LIBERTIFF       | rov            | rov             | rov            | ✗              | ✗               | ✗              |
| LIBKML          | ✗              | ✗               | ✗              | rw+uv          | rw+uv           | rw+uv          |
| LOSLAS          | rov            | rov             | rov            | ✗              | ✗               | ✗              |
| LVBAG           | ✗              | ✗               | ✗              | rov            | rov             | rov            |
| Leveller        | rw+v           | rw+v            | rw+v           | ✗              | ✗               | ✗              |
| MAP             | rov            | rov             | rov            | ✗              | ✗               | ✗              |
| MBTiles         | rw+v           | rw+v            | rw+v           | rw+v           | rw+v            | rw+v           |
| MEM             | rw+            | rw+             | rw+            | rw+            | rw+             | rw+            |
| MFF             | rov            | rov             | rov            | ✗              | ✗               | ✗              |
| MFF2            | ro             | ro              | ro             | ✗              | ✗               | ✗              |
| MRF             | rw+v           | rw+v            | rw+v           | ✗              | ✗               | ✗              |
| MSGN            | rov            | rov             | rov            | ✗              | ✗               | ✗              |
| MSSQLSpatial    | ✗              | ✗               | ✗              | rw+u           | rw+u            | rw+u           |
| MVT             | ✗              | ✗               | ✗              | rw+v           | rw+v            | rw+v           |
| MapML           | ✗              | ✗               | ✗              | rw+v           | rw+v            | rw+v           |
| MiraMonVector   | ✗              | ✗               | ✗              | rw+v           | rw+v            | rw+v           |
| MySQL           | ✗              | ✗               | ✗              | rw+u           | rw+u            | rw+u           |
| NAS             | ✗              | ✗               | ✗              | rov            | rov             | rov            |
| NDF             | rov            | rov             | rov            | ✗              | ✗               | ✗              |
| NGSGEOID        | rov            | rov             | rov            | ✗              | ✗               | ✗              |
| NGW             | rw+s           | rw+s            | rw+s           | rw+s           | rw+s            | rw+s           |
| NITF            | rw+uvs         | rw+uvs          | rw+uvs         | ✗              | ✗               | ✗              |
| NOAA_B          | rov            | rov             | rov            | ✗              | ✗               | ✗              |
| NSIDCbin        | rov            | rov             | rov            | ✗              | ✗               | ✗              |
| NTv2            | rovs           | rovs            | rovs           | ✗              | ✗               | ✗              |
| NWT_GRC         | rov            | rov             | rov            | ✗              | ✗               | ✗              |
| NWT_GRD         | rw+v           | rw+v            | rw+v           | ✗              | ✗               | ✗              |
| OAPIF           | ✗              | ✗               | ✗              | ro             | ro              | ro             |
| ODBC            | ✗              | ✗               | ✗              | ro             | ro              | ro             |
| ODS             | ✗              | ✗               | ✗              | rw+uv          | rw+uv           | rw+uv          |
| OGCAPI          | rov            | rov             | rov            | rov            | rov             | rov            |
| OGR_GMT         | ✗              | ✗               | ✗              | rw+v           | rw+v            | rw+v           |
| OGR_PDS         | ✗              | ✗               | ✗              | rov            | rov             | rov            |
| OGR_VRT         | ✗              | ✗               | ✗              | rov            | rov             | rov            |
| OSM             | ✗              | ✗               | ✗              | rov            | rov             | rov            |
| OpenFileGDB     | rw+uv          | rw+uv           | rw+uv          | rw+uv          | rw+uv           | rw+uv          |
| PAux            | rov            | rov             | rov            | ✗              | ✗               | ✗              |
| PCIDSK          | rw+uv          | rw+uv           | rw+uv          | rw+uv          | rw+uv           | rw+uv          |
| PCRaster        | rw+            | rw+             | rw+            | ✗              | ✗               | ✗              |
| PDF             | rw+uvs         | rw+uvs          | rw+uvs         | rw+uvs         | rw+uvs          | rw+uvs         |
| PDS             | rov            | rov             | rov            | ✗              | ✗               | ✗              |
| PDS4            | rw+uvs         | rw+uvs          | rw+uvs         | rw+uvs         | rw+uvs          | rw+uvs         |
| PGDUMP          | ✗              | ✗               | ✗              | w+v            | w+v             | w+v            |
| PGeo            | ✗              | ✗               | ✗              | ro             | ro              | ro             |
| PLMOSAIC        | ro             | ro              | ro             | ✗              | ✗               | ✗              |
| PLSCENES        | ro             | ro              | ro             | ro             | ro              | ro             |
| PMTiles         | ✗              | ✗               | ✗              | rw+v           | rw+v            | rw+v           |
| PNG             | rwv            | rwv             | rwv            | ✗              | ✗               | ✗              |
| PNM             | rw+v           | rw+v            | rw+v           | ✗              | ✗               | ✗              |
| PRF             | rov            | rov             | rov            | ✗              | ✗               | ✗              |
| PostGISRaster   | rws            | rws             | rws            | ✗              | ✗               | ✗              |
| PostgreSQL      | ✗              | ✗               | ✗              | rw+u           | rw+u            | rw+u           |
| RCM             | rovs           | rovs            | rovs           | ✗              | ✗               | ✗              |
| RIK             | rov            | rov             | rov            | ✗              | ✗               | ✗              |
| RMF             | rw+v           | rw+v            | rw+v           | ✗              | ✗               | ✗              |
| ROI_PAC         | rw+v           | rw+v            | rw+v           | ✗              | ✗               | ✗              |
| RPFTOC          | rovs           | rovs            | rovs           | ✗              | ✗               | ✗              |
| RRASTER         | rw+uv          | rw+uv           | rw+uv          | ✗              | ✗               | ✗              |
| RS2             | rovs           | rovs            | rovs           | ✗              | ✗               | ✗              |
| RST             | rw+v           | rw+v            | rw+v           | ✗              | ✗               | ✗              |
| S102            | rovs           | rovs            | rovs           | ✗              | ✗               | ✗              |
| S104            | rov            | rov             | rov            | ✗              | ✗               | ✗              |
| S111            | rov            | rov             | rov            | ✗              | ✗               | ✗              |
| S57             | ✗              | ✗               | ✗              | rw+v           | rw+v            | rw+v           |
| SAFE            | rov            | rov             | rov            | ✗              | ✗               | ✗              |
| SAGA            | rw+v           | rw+v            | rw+v           | ✗              | ✗               | ✗              |
| SAR_CEOS        | rov            | rov             | rov            | ✗              | ✗               | ✗              |
| SENTINEL2       | rovs           | rovs            | rovs           | ✗              | ✗               | ✗              |
| SIGDEM          | rwv            | rwv             | rwv            | ✗              | ✗               | ✗              |
| SNAP_TIFF       | rov            | rov             | rov            | ✗              | ✗               | ✗              |
| SNODAS          | rov            | rov             | rov            | ✗              | ✗               | ✗              |
| SQLite          | ✗              | ✗               | ✗              | rw+uv          | rw+uv           | rw+uv          |
| SRP             | rovs           | rovs            | rovs           | ✗              | ✗               | ✗              |
| SRTMHGT         | rwv            | rwv             | rwv            | ✗              | ✗               | ✗              |
| STACIT          | rovs           | rovs            | rovs           | ✗              | ✗               | ✗              |
| STACTA          | rovs           | rovs            | rovs           | ✗              | ✗               | ✗              |
| SXF             | ✗              | ✗               | ✗              | rov            | rov             | rov            |
| Selafin         | ✗              | ✗               | ✗              | rw+v           | rw+v            | rw+v           |
| TGA             | rov            | rov             | rov            | ✗              | ✗               | ✗              |
| TIL             | rov            | rov             | rov            | ✗              | ✗               | ✗              |
| TSX             | rov            | rov             | rov            | ✗              | ✗               | ✗              |
| Terragen        | rw+v           | rw+v            | rw+v           | ✗              | ✗               | ✗              |
| TopoJSON        | ✗              | ✗               | ✗              | rov            | rov             | rov            |
| USGSDEM         | rov            | rov             | rov            | ✗              | ✗               | ✗              |
| VDV             | ✗              | ✗               | ✗              | rw+v           | rw+v            | rw+v           |
| VFK             | ✗              | ✗               | ✗              | ro             | ro              | ro             |
| VICAR           | rw+v           | rw+v            | rw+v           | rw+v           | rw+v            | rw+v           |
| VRT             | rw+uv          | rw+uv           | rw+uv          | ✗              | ✗               | ✗              |
| WAsP            | ✗              | ✗               | ✗              | rw+v           | rw+v            | rw+v           |
| WCS             | rovs           | rovs            | rovs           | ✗              | ✗               | ✗              |
| WEBP            | rwv            | rwv             | rwv            | ✗              | ✗               | ✗              |
| WFS             | ✗              | ✗               | ✗              | rov            | rov             | rov            |
| WMS             | rwvs           | rwvs            | rwvs           | ✗              | ✗               | ✗              |
| WMTS            | rwv            | rwv             | rwv            | ✗              | ✗               | ✗              |
| XLS             | ✗              | ✗               | ✗              | ro             | ro              | ro             |
| XLSX            | ✗              | ✗               | ✗              | rw+uv          | rw+uv           | rw+uv          |
| XYZ             | rwv            | rwv             | rwv            | ✗              | ✗               | ✗              |
| ZMap            | rwv            | rwv             | rwv            | ✗              | ✗               | ✗              |
| Zarr            | rw+uvs         | rw+uvs          | rw+uvs         | ✗              | ✗               | ✗              |
| netCDF          | rw+us          | rw+us           | rw+us          | rw+us          | rw+us           | rw+us          |