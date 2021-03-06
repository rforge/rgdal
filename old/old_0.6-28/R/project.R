# Copyright (c) 2003-8 by Barry Rowlingson, Roger Bivand, and Edzer Pebesma

getPROJ4VersionInfo <- function() {
    .Call("PROJ4VersionInfo", PACKAGE="rgdal")
}

getPROJ4libPath <- function() {
    res <- Sys.getenv("PROJ_LIB")
    res
}

projNAD <- function() {
    .Call("PROJ4NADsInstalled", PACKAGE="rgdal")
}

"project" <- function(xy, proj, inv=FALSE) {

    if (!is.numeric(xy)) stop("xy not numeric")
    if (is.matrix(xy)) nc <- dim(xy)[1]
    else if (length(xy) == 2) nc <- 1
    else stop("xy malformed")
    if(!inv) {
      res <- .C("project",
                as.integer(nc),
                as.double(xy[,1]),
                as.double(xy[,2]),
                x=double(nc),
                y=double(nc),
                proj,
                NAOK=TRUE,
                PACKAGE="rgdal")
    } else {
      res <- .C("project_inv",
                as.integer(nc),
                as.double(xy[,1]),
                as.double(xy[,2]),
                x=double(nc),
                y=double(nc),
                proj,
                NAOK=TRUE,
                PACKAGE="rgdal")
    }
    cbind(res$x, res$y)
}


if (!isGeneric("spTransform"))
	setGeneric("spTransform", function(x, CRSobj, ...)
		standardGeneric("spTransform"))

"spTransform.SpatialPoints" <-  function(x, CRSobj, ...) {
	if (is.na(proj4string(x))) 
		stop("No transformation possible from NA reference system")
	if (is.na(CRSargs(CRSobj))) 
		stop("No transformation possible to NA reference system")
	crds <- coordinates(x)
	crds.names <- dimnames(crds)[[2]] # crds is matrix
	if (ncol(crds) != 2) 	
		warning("Only x- and y-coordinates are being transformed")
	n <- nrow(crds)
	res <- .Call("transform", proj4string(x), CRSargs(CRSobj), n,
		as.double(crds[,1]), as.double(crds[,2]),
		PACKAGE="rgdal")
	if (any(!is.finite(res[[1]])) || any(!is.finite(res[[2]]))) {
		k <- which(!is.finite(res[[1]]) || !is.finite(res[[2]]))
		cat("non finite transformation detected:\n")
		print(cbind(crds, res[[1]], res[[2]])[k,])
		stop(paste("failure in points", paste(k, collapse=":")))
	}
	# make sure coordinate names are set back:
	crds[,1:2] <- cbind(res[[1]], res[[2]])
	dimnames(crds)[[2]] <- crds.names
	x <- SpatialPoints(coords=crds, proj4string=CRS(res[[4]]))
	x
}
setMethod("spTransform", signature("SpatialPoints", "CRS"), spTransform.SpatialPoints)



"spTransform.SpatialPointsDataFrame" <- function(x, CRSobj, ...) {
	xSP <- as(x, "SpatialPoints")
	resSP <- spTransform(xSP, CRSobj)
	# xDF <- as(x, "data.frame")
	xDF <- x@data # little need to add unique row.names here!
	res <- SpatialPointsDataFrame(coords=coordinates(resSP), data=xDF,
		coords.nrs = numeric(0), proj4string = CRS(proj4string(resSP)))
	res
}
setMethod("spTransform", signature("SpatialPointsDataFrame", "CRS"), 
	spTransform.SpatialPointsDataFrame)




setMethod("spTransform", signature("SpatialPixelsDataFrame", "CRS"), 
	function(x, CRSobj, ...) {
                warning("Grid warping not available, coercing to points")
		spTransform(as(x, "SpatialPointsDataFrame"), CRSobj, ...)})

setMethod("spTransform", signature("SpatialGridDataFrame", "CRS"), 
	function(x, CRSobj, ...) {
                warning("Grid warping not available, coercing to points")
		spTransform(as(x, "SpatialPixelsDataFrame"), CRSobj, ...)})


".spTransform_Line" <- function(x, to_args, from_args, ii, jj) {
	crds <- slot(x, "coords")
	n <- nrow(crds)
	res <- .Call("transform", from_args, to_args, n,
		as.double(crds[,1]), as.double(crds[,2]),
		PACKAGE="rgdal")
	if (any(!is.finite(res[[1]])) || any(!is.finite(res[[2]]))) {
		k <- which(!is.finite(res[[1]]) || !is.finite(res[[2]]))
		cat("non finite transformation detected:\n")
		print(cbind(crds, res[[1]], res[[2]])[k,])
		stop(paste("failure in Lines", ii, "Line", jj, 
			"points", paste(k, collapse=":")))
	}
	crds <- cbind(res[[1]], res[[2]])
	x <- Line(coords=crds)
	x
}

#setMethod("spTransform", signature("Sline", "CRS"), spTransform.Sline)

".spTransform_Lines" <- function(x, to_args, from_args, ii) {
	ID <- slot(x, "ID")
	input <- slot(x, "Lines")
	n <- length(input)
	output <- vector(mode="list", length=n)
	for (i in 1:n) output[[i]] <- .spTransform_Line(input[[i]], 
		to_args=to_args, from_args=from_args, ii=ii, jj=i)
	x <- Lines(output, ID)
	x
}

#setMethod("spTransform", signature("Slines", "CRS"), spTransform.Slines)

"spTransform.SpatialLines" <- function(x, CRSobj, ...) {
	from_args <- proj4string(x)
	if (is.na(from_args)) 
		stop("No transformation possible from NA reference system")
	to_args <- CRSargs(CRSobj)
	if (is.na(to_args)) 
		stop("No transformation possible to NA reference system")
	input <- slot(x, "lines")
	n <- length(input)
	output <- vector(mode="list", length=n)
	for (i in 1:n) output[[i]] <- .spTransform_Lines(input[[i]], 
		to_args=to_args, from_args=from_args, ii=i)
	res <- SpatialLines(output, proj4string=CRS(to_args))
	res
}
setMethod("spTransform", signature("SpatialLines", "CRS"), spTransform.SpatialLines)
"spTransform.SpatialLinesDataFrame" <- function(x, CRSobj, ...) {
	xSP <- as(x, "SpatialLines")
	resSP <- spTransform(xSP, CRSobj)
	xDF <- as(x, "data.frame")
	res <- SpatialLinesDataFrame(sl=resSP, data=xDF, match.ID = FALSE)
	res
}
setMethod("spTransform", signature("SpatialLinesDataFrame", "CRS"), spTransform.SpatialLinesDataFrame)




".spTransform_Polygon" <- function(x, to_args, from_args, ii, jj) {
	crds <- slot(x, "coords")
	n <- nrow(crds)
	res <- .Call("transform", from_args, to_args, n,
		as.double(crds[,1]), as.double(crds[,2]),
		PACKAGE="rgdal")
	if (any(!is.finite(res[[1]])) || any(!is.finite(res[[2]]))) {
		k <- which(!is.finite(res[[1]]) || !is.finite(res[[2]]))
		cat("non finite transformation detected:\n")
		print(cbind(crds, res[[1]], res[[2]])[k,])
		stop(paste("failure in Polygons", ii, "Polygon", jj, 
			"points", paste(k, collapse=":")))
	}
	crds <- cbind(res[[1]], res[[2]])
	x <- Polygon(coords=crds)
	x
}


".spTransform_Polygons" <- function(x, to_args, from_args, ii) {
	ID <- slot(x, "ID")
	input <- slot(x, "Polygons")
	n <- length(input)
	output <- vector(mode="list", length=n)
	for (i in 1:n) output[[i]] <- .spTransform_Polygon(input[[i]], 
		to_args=to_args, from_args=from_args, ii=ii, jj=i)
	res <- Polygons(output, ID)
	res
}


"spTransform.SpatialPolygons" <- function(x, CRSobj, ...) {
	from_args <- proj4string(x)
	if (is.na(from_args)) 
		stop("No transformation possible from NA reference system")
	to_args <- CRSargs(CRSobj)
	if (is.na(to_args)) 
		stop("No transformation possible to NA reference system")
	input <- slot(x, "polygons")
	n <- length(input)
	output <- vector(mode="list", length=n)
	for (i in 1:n) output[[i]] <- .spTransform_Polygons(input[[i]], 
		to_args=to_args, from_args=from_args, ii=i)
	res <- SpatialPolygons(output, pO=slot(x, "plotOrder"), 
		proj4string=CRSobj)
	res
}
setMethod("spTransform", signature("SpatialPolygons", "CRS"), spTransform.SpatialPolygons)

"spTransform.SpatialPolygonsDataFrame" <- function(x, CRSobj, ...) {
	xSP <- as(x, "SpatialPolygons")
	resSP <- spTransform(xSP, CRSobj)
	xDF <- as(x, "data.frame")
	res <- SpatialPolygonsDataFrame(Sr=resSP, data=xDF, match.ID = FALSE)
	res
}
setMethod("spTransform", signature("SpatialPolygonsDataFrame", "CRS"), spTransform.SpatialPolygonsDataFrame)

projInfo <- function(type="proj") {
    opts <- c("proj", "ellps", "datum")
    if (!(type %in% opts)) stop("unknown type")
    t <- as.integer(match(type[1], opts) - 1)
    if (is.na(t)) stop("unknown type")
    res <- .Call("projInfo", t, PACKAGE="rgdal")
    if (type == "proj") res$description <- sapply(strsplit(as.character(
        res$description), "\n"), function(x) x[1])
    res <- data.frame(res)
    res
}
