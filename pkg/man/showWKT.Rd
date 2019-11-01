\name{showWKT}
\alias{showWKT}
\alias{showEPSG}
\alias{showP4}
\alias{showSRID}
\alias{get_P6_datum_hard_fail}
\alias{set_P6_datum_hard_fail}
%- Also NEED an '\alias' for EACH other topic documented here.
\title{Show Well-Known Text spatial reference system metadata}
\description{
  Use GDAL/OGR spatial reference objects to convert a PROJ.4 representation to a Well-Known Text representation, and report an EPSG code if it can be determined by OGR SRS services.
}
\usage{
showWKT(p4s, file = NULL, morphToESRI = TRUE)
showP4(wkt, morphFromESRI=TRUE)
showEPSG(p4s)
showSRID(inSRID, format="WKT2", multiline="NO")
get_P6_datum_hard_fail()
set_P6_datum_hard_fail(value)
}
%- maybe also 'usage' for other objects documented here.
\arguments{
  \item{p4s}{A valid PROJ.4 string representing a spatial reference system}
  \item{file}{if not NULL, a file name to which the output Well-Known Text representation should be written}
  \item{morphToESRI}{default TRUE, morph the WKT string to the representation used by ESRI}
  \item{wkt}{A valid WKT character string representing a spatial reference system}
  \item{morphFromESRI}{default TRUE, morph the WKT string from the representation used by ESRI}
  \item{inSRID}{Input coordinate reference string (PROJ >= 6, GDAL <= 3)}
  \item{format}{Output format, default WKT2}
  \item{multiline}{Multiline output, either \code{"NO"} or \code{"YES"}}
  \item{value}{By default, a deprecated/ignored input DATUM key/value pair on reading a file with PROJ6 will give a warning (default FALSE); if TRUE, an error is triggered, which may be trapped using \code{try}}
}

\value{
  For \code{showWKT}, a character string containing the WKT representation of the PROJ.4 string.
}
\references{\url{https://gdal.org/tutorials/osr_api_tut.html}}
\author{Roger Bivand}

\seealso{\code{\link[sp]{is.projected}}, \code{\link[sp]{CRS-class}}}
\examples{
cities <- readOGR(system.file("vectors", package = "rgdal")[1], "cities")
readLines(system.file("vectors/cities.prj", package = "rgdal")[1])
showWKT(proj4string(cities))
showWKT("+init=epsg:28992")
showP4(showWKT("+init=epsg:28992"))
showEPSG("+proj=utm +zone=30")
showEPSG("+proj=longlat +ellps=WGS84")
exts <- rgdal_extSoftVersion()
run <- new_proj_and_gdal()
if (run) {
  cat(showSRID("EPSG:27700", multiline="YES"), "\n")
}
if (run) {
(prj <- showSRID("EPSG:27700", "PROJ"))
}
if (run) {
showSRID(paste0(prj, " +datum=OSGB36"), "WKT1")
}
if (run) {
showSRID(paste0(prj, " +towgs84=370.936,-108.938,435.682"), "WKT1")
}
if (run) {
showSRID(paste0(prj, " +nadgrids=OSTN15_NTv2_OSGBtoETRS.gsb"), "WKT1")
}
if (run) {
showSRID(paste0(prj, " +datum=OSGB36"), "WKT2")
}
if (run) {
showSRID(paste0(prj, " +towgs84=370.936,-108.938,435.682"), "WKT2")
}
if (run) {
showSRID(paste0(prj, " +nadgrids=OSTN15_NTv2_OSGBtoETRS.gsb"), "WKT2")
}
}
\keyword{spatial}

