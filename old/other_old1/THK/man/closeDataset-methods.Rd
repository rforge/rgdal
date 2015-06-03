\name{closeDataset-methods}
\docType{methods}
\title{closeDataset methods}
\alias{closeDataset-methods}
\alias{closeDataset}
\alias{closeDataset.default}
\alias{closeDataset,ANY-method}
\alias{closeDataset,GDALDataset-method}
\alias{closeDataset,GDALTransientDataset-method}
\description{Methods for closing GDAL datasets}
\usage{
	closeDataset(dataset)
	closeDataset.default(dataset)
}
\arguments{
\item{dataset}{GDAL dataset}
}
\section{Methods}{\describe{

\item{dataset = "ANY"}{default method, returns error}

\item{dataset = "GDALDataset"}{closes the "GDALDataset"}

\item{dataset = "GDALMutableDataset"}{closes the "GDALMutableDataset"}

\item{dataset = "GDALTransientDataset"}{closes the "GDALTransientDataset"}
}}
\keyword{methods}

