# Copyright 2003 (c) Barry Rowlingson
# Modified 2006 Roger Bivand
###
###
###  Routines for ogr layer data source 
###
###

#
ogrInfo <- function(dsn, layer){
# a list with various ogr data source information
  ogrinfo <- .Call("ogrInfo",as.character(dsn),as.character(layer), PACKAGE = "rgdal")
  
  names(ogrinfo) <- c("nrows","nitems","iteminfo","driver")
  names(ogrinfo$iteminfo) <- c("name","precision","length")
  ogrinfo
}

ogrFIDs <- function(dsn, layer){
  fids <- .Call("ogrFIDs",as.character(dsn),as.character(layer), PACKAGE = "rgdal")
  fids
}


