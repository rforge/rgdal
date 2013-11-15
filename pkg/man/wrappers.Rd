\name{GDALcall}
\alias{GDALcall}
\alias{rawTransform}

\title{Wrapper functions to allow more direct calling of rgdal C code}

\description{
These functions allow more direct access to some of the rgdal C API. These are advanced methods intended for package developers only. 
}


\usage{
GDALcall(object, option, ...)
rawTransform(projfrom, projto, n, x, y, z=NULL)
}


\arguments{
  \item{object}{GDALDataset}
  \item{option}{character. One of 'SetNoDataValue', 'SetGeoTransform', 'SetProject', 'SetStatistics', 'SetRasterColorTable' or 'SetCategoryNames') }
  \item{...}{additional arguments}
  \item{projfrom}{character. PROJ.4 CRS description}
  \item{projto}{character. PROJ.4 CRS description}
  \item{n}{number of coordinates}
  \item{x}{x coordinates}
  \item{y}{y coordinates}
  \item{z}{z coordinates}

}

\value{
GDALDataset
}

\author{Robert Hijmans}

\keyword{spatial}

