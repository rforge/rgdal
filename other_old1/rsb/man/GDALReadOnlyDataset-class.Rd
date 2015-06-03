\name{GDALReadOnlyDataset-class}
\docType{class}
\alias{GDALReadOnlyDataset-class}
\alias{getDriver}
\alias{displayDataset}
\alias{GDAL.close}
\alias{GDAL.open}
\alias{getColorTable}
\alias{getGeoTransFunc}
\title{Class "GDALReadOnlyDataset"}
\description{\code{GDALReadOnlyDataset} is the base class for a GDAL Dataset
  classes. Only read operations are supported. Both \code{GDALDataset}
  and \code{GDALTransientDataset} inherit these read operations while
  providing additional write operations (see
  \code{\link{GDALDataset-class}}). \code{GDALReadOnlyDataset-class} inherits
  from \code{\link{GDALMajorObject-class}}.}

\section{Objects from the Class}{
Objects can be created by calls of the form \code{new("GDALReadOnlyDataset", filename, handle)}.
    ~~ describe objects here ~~ 
}
\section{Slots}{
  \describe{
    \item{\code{handle}:}{Object of class \code{"externalptr", from class "GDALMajorObject"} ~~ }
  }
}
\section{Extends}{
Class \code{"GDALMajorObject"}, directly.
}
\section{Methods}{
  \describe{
    \item{closeDataset}{\code{signature(dataset = "GDALReadOnlyDataset")}: ... }
    \item{dim}{\code{signature(x = "GDALReadOnlyDataset")}: ... }
    \item{image}{\code{signature(x = "GDALReadOnlyDataset")}: ... }
    \item{initialize}{\code{signature(.Object = "GDALReadOnlyDataset")}: ... }
  }
}
\usage{
GDAL.close(dataset)
GDAL.open(filename)
getDriver(dataset)
displayDataset(x, offset = c(0, 0), region.dim = dim(x),
                           reduction = 1, band = NULL, col = NULL,
                           reset.par = TRUE, max.dim = 500, ...)
getColorTable(dataset, band = NULL)
getGeoTransFunc(dataset)
}
\arguments{
 \item{dataset}{An object inheriting from class 'GDALReadOnlyDataset'}
 \item{filename}{A string giving the file to read from}
 \item{x}{An object inheriting from class 'GDALReadOnlyDataset'}
 \item{offset}{Number of rows and columns from the origin (usually the
    upper left corner) to begin reading from}
 \item{region.dim}{The number of rows and columns to read from the
    dataset}
 \item{reduction}{scaling parameter for region.dim}
 \item{band}{The band number (1-based) to read from}
 \item{col}{a list of colors}
 \item{reset.par}{since \code{displayDataset()} and \code{image} for these objects resets par() internally, this logical flag can be set to prevent resetting, so that other objects may be over-plotted}
 \item{max.dim}{another scaling parameter}
 \item{...}{other plotting parameters passed through}
 \item{}{}
 \item{}{}
}
\details{
\code{GDAL.open} and \code{GDAL.close} are shorter versions of \code{new("GDALReadOnlyDataset", ...)} and \code{closeDataset()}. Because \code{GDAL.close} through \code{closeDataset()} uses the finalization mechanism to destroy the handles to the dataset and its driver, messages such as:

"Closing GDAL dataset handle 0x8ff7900...  destroyed ... done."

may appear when \code{GDAL.close} is run, or at some later stage. 
\code{getDriver} returns an object inheriting from class 'GDALDriver'.
\code{displayDataset} and its use in \code{image} produce a plot of the dataset, returning an array of image data.
\code{getColorTable} returns the dataset colour table (currently does not support RGB imaging).
\code{getGeoTransFunc} returns a warping function.
  
}
\references{\url{http://keittlab.bio.sunysb.edu/R/GDAL/}, \url{http://www.remotesensing.org/gdal/}}

\author{Timothy H. Keitt, modified by Roger Bivand}

\seealso{See also \code{\link{GDALDriver-class}}, \code{\link{GDALDataset-class}}, \code{\link{GDALTransientDataset-class}}.}

\examples{
logo <- system.file("pictures/logo.jpg", package="rgdal")[1]
x <- new("GDALReadOnlyDataset", logo)
dim(x)
plot(density(getRasterTable(x)$band1))
displayDataset(x)
displayDataset(x, col=rev(cm.colors(25)))
oldpar <- par(no.readonly = TRUE)
im <- displayDataset(x, col=rev(cm.colors(25)), reset.par=FALSE)
contour(im, nlevels = 1, levels = 100, col = 'black', add = TRUE)
par(oldpar)
GDAL.close(x)
}
\keyword{classes}
