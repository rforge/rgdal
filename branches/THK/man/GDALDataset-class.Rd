\name{GDALDataset-class}
\docType{class}
\alias{GDALDataset-class}
\alias{getDriver}
\alias{displayDataset}
\alias{RGB2PCT}
\alias{openDataset}
\alias{GDAL.close}
\alias{GDAL.open}
\alias{getColorTable}
\alias{getGeoTransFunc}
\alias{initialize,GDALDataset-method}
\alias{dim,GDALDataset-method}
\title{Class "GDALDataset"}
\description{\code{GDALDataset} is the base class for a GDAL Dataset
  classes. Only read operations are supported. Both \code{GDALMutableDataset}
  and \code{GDALTransientDataset} inherit these read operations while
  providing additional write operations (see
  \code{\link{GDALMutableDataset-class}}). \code{GDALDataset-class} inherits
  from \code{\link{GDALMajorObject-class}}.}

\section{Objects from the Class}{
Objects can be created by calls of the form \code{new("GDALDataset",
  handle)} where handle is an external pointer to a GDAL dataset. To
open an existing dataset, use \code{\link{openDataset}}.
}
\section{Slots}{
  \describe{
    \item{\code{handle}:}{Object of class \code{"externalptr", from class "GDALMajorObject"}}
  }
}
\section{Extends}{
Class \code{"GDALMajorObject"}, directly.
}
\section{Methods}{
  \describe{
    \item{dim}{\code{signature(x = "GDALDataset")}: ... }
    \item{initialize}{\code{signature(.Object = "GDALDataset")}: ... }

  }
}
\usage{
GDAL.close(dataset)
openDataset(filename, read.only = TRUE)
GDAL.open(filename, read.only = TRUE)
getDriver(dataset)
RGB2PCT(x, band, driver.name = 'MEM', ncolors = 256, set.ctab = TRUE)
displayDataset(x, at = c(1, 1), region.dim = dim(x),
                           reduction = 1, band = 1, col = NULL,
                           reset.par = TRUE, max.dim = 500, ...)
getColorTable(dataset, band = 1)
getGeoTransFunc(dataset)
}
\arguments{
 \item{dataset}{An object inheriting from class 'GDALDataset'}
 \item{filename}{A string giving the file to read from}
 \item{x}{An object inheriting from class 'GDALDataset'}
 \item{at}{Location of the origin (usually the
    upper left corner) to begin reading from}
 \item{region.dim}{The number of rows and columns to read from the
    dataset}
 \item{reduction}{scaling parameter for region.dim}
 \item{band}{The band number (1-based) to read from}
 \item{col}{a vector of colours or a colour function such as rainbow}
 \item{reset.par}{logical indicating whether to reset graphical
   parameters on exit. Set to FALSE for futher graphical overlays.}
 \item{max.dim}{another scaling parameter}
 \item{...}{other plotting parameters passed through}
 \item{driver.name}{A string containing a GDAL driver name}
 \item{ncolors}{number of colors to generate}
 \item{set.ctab}{set GDAL dataset color table. Not supported by all drivers.}
\item{read.only}{A logical flag indicating whether to open the file as a
  \code{GDALDataset} or as a writable \code{GDALMutableDataset}}
}
\details{
\code{GDAL.open} and \code{GDAL.close} are wrappers for
\code{openDataset} and \code{closeDataset}. They will be deprecated in
future releases.
\code{getDriver} returns an object inheriting from class 'GDALDriver'.
\code{RGB2PCT} returns a 1-band pseudocolor GDALTransientDataset. If
\code{set.ctab} is FALSE, then a list will be returned with the dataset
and an R color table. 
\code{displayDataset} returns a list with the image data, the color
table used and the input graphical parameters.
\code{getColorTable} returns the dataset colour table (currently does not support RGB imaging).
\code{getGeoTransFunc} returns a warping function.
  
}
\references{\url{http://keittlab.bio.sunysb.edu/R/GDAL/}, \url{http://www.remotesensing.org/gdal/}}

\author{Timothy H. Keitt, modified by Roger Bivand}

\seealso{See also \code{\link{GDALDriver-class}}, \code{\link{GDALMutableDataset-class}}, \code{\link{GDALTransientDataset-class}}.}

\examples{
logo <- system.file("pictures/logo.jpg", package="rgdal")[1]
x <- openDataset(logo)
dim(x)
plot(density(getRasterTable(x)$band1))
displayDataset(x)
displayDataset(x, col=rev(cm.colors(256)))
im <- displayDataset(x, col=rev(cm.colors(256)), reset.par=FALSE)$image.data
contour(1:nrow(im), 1:ncol(im),im, nlevels = 1,
 levels = 100, col = 'black', add = TRUE)
closeDataset(x)
logo <- system.file("pictures/Rlogo.jpg", package="rgdal")[1]
x <- openDataset(logo)
dim(x)
displayDataset(x)
closeDataset(x)
}
\keyword{classes}
