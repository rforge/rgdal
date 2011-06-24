library(rgdal)
logo <- system.file("pictures/Rlogo.jpg", package="rgdal")[1]
x <- GDAL.open(logo)
try(getRasterData(x, band=4))
GDAL.close(x)
logoo <- paste(logo, "o", sep="")
try(GDAL.open(logo))
try(GDAL.close(x))
try(new('GDALDriver', "GeoTIFF"))
fn <- system.file("pictures/erdas_spnad83.tif", package = "rgdal")[1]
GDALinfo(fn)
try(erdas_spnad83 <- readGDAL(fn, offset=c(500, 1000), region.dim=c(400, 400)))
try(erdas_spnad83 <- readGDAL(fn, region.dim=c(4000, 400)))
x <- readGDAL(fn)
tf <- tempfile()
try(writeGDAL(x, tf, drivername="GTiff", type="Byte", options="INTERLEAVE=PIXIL"))
try(writeGDAL(x, tf, drivername="GeoTiff", type="Byte"))
dsn <- system.file("vectors", package = "rgdal")[1]
try(ogrInfo(dsn=dsn, layer="citis"))
try(OGRSpatialRef(dsn=dsn, layer="scot_BMG"))
dsn <- system.file("vectors/test_trk2.gpx", package = "rgdal")[1]
try(readOGR(dsn=dsn, layer="trucks"))
cities <- readOGR(system.file("vectors", package = "rgdal")[1], "cities")
td <- tempdir()
try(writeOGR(cities, td, "cities", driver="ESRI_Shapefile"))

