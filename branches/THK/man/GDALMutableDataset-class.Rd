\name{GDALMutableDataset-class}
\docType{class}
\alias{GDALMutableDataset-class}
\alias{putRasterData}
\alias{saveDataset}
\alias{copyDataset}
\alias{deleteDataset}
\alias{createDataset}
\alias{initialize,GDALMutableDataset-method}
\title{Class "GDALMutableDataset"}
\description{\code{GDALMutableDataset} extends \code{\link{GDALDataset-class}} with data update commands.
}
\section{Objects from the Class}{
  Object initialized with \code{new("GDALMutableDataset")} will contain
  a null external pointer. You must assign a valid GDAL dataset handle
  to slot handle. Users will generally use \code{createDataset}.}
\section{Slots}{
  \describe{
    \item{\code{handle}:}{Object of class \code{"externalptr", from class "GDALDataset"}, used internally; not for public consumption}
  }
}
\section{Extends}{
Class \code{"GDALDataset"}, directly.
Class \code{"GDALMajorObject"}, by class "GDALDataset".
}
\section{Methods}{
  \describe{
    \item{initialize}{\code{signature(.Object = "GDALMutableDataset")}: ... }
  }
}
\usage{
putRasterData(dataset, rasterData, band = 1, at = c(1, 1))
saveDataset(dataset, driver = NULL, file = NULL)
copyDataset(dataset, driver = NULL, file = NULL, strict = FALSE, options = "")
deleteDataset(dataset)
createDataset(driver, rows, cols, bands = 1, type = "Byte", file = NULL,
options = NULL)
}
\arguments{
  \item{dataset}{An object inheriting from class 'GDALMutableDataset'}
  \item{rasterData}{A data array with \code{length(dim(rasterData)) = 2}}
  \item{band}{The band number (1-based) to read from}
  \item{at}{Location of the origin (usually the
    upper left corner) to begin reading from}
  \item{driver}{GDAL driver name to use for saving raster data object}
  \item{strict}{Driver specific options (currently passed to GDAL)}
  \item{options}{Driver specific options (currently ignored)}
  \item{file}{Character string containing file name}
  \item{rows}{Number of rows}
  \item{cols}{Number of columns}
  \item{bands}{Number of raster bands}
  \item{type}{GDAL data type to use}
}
\details{
  \describe{
    
    \item{\code{putRasterData}:}{writes data contained in
      \code{rasterData} to the dataset, begining at the origin specified
      by \code{at}. Data type conversion is automatic.}
    \item{\code{saveDataset}:}{saves a raster data object in a file using the driver of the object}
    \item{\code{saveDatasetAs}:}{saves a raster data object in a file using the specified driver}
    \item{\code{copyDataset}:}{make a copy of raster data object in a file using the specified driver}
    \item{\code{deleteDataset}:}{delete the file from which the raster
      data object was read (should only delete files opened as
      GDALMutableDataset objects}
    \item{\code{createDataset}:}{creates a new dataset. \code{driver}
      can be a driver name or driver object. If \code{file} is
      \code{NULL}, then a file name is generated using \code{tempfile}.}
  }
}

\author{Timothy H. Keitt, Roger Bivand}

\seealso{\code{\link{GDALDriver-class}},
  \code{\link{GDALDataset-class}}, \code{\link{GDALTransientDataset-class}}}

\examples{
}
\keyword{classes}
