unreg.finalizer <- function(obj) reg.finalizer(obj, function(x) x)

assertClass <- function(object, class) {
  
  if (class %in% is(object))
    invisible(object)
  else
    stop(paste("Object is not a member of class", class))

}

.GDALDataTypes <- c("Unknown", "Byte", "UInt16", "Int16", "UInt32",
                    "Int32", "Float32", "Float64", "CInt16", "CInt32",
                    "CFloat32", "CFloat64")

setClass("GDALMajorObject",
         representation(handle = "externalptr"))
 
getDescription <- function(object) {

  assertClass(object, "GDALMajorObject")

  .Call("RGDAL_GetDescription", object, PACKAGE="rgdal")

}

getMetadata <- function(object, domain = "") {

  assertClass(object, "GDALMajorObject")

  metadata <- .Call("RGDAL_GetMetadata", object,
                    as.character(domain), PACKAGE="rgdal")

  if (is.null(metadata))
    metadata
  else
    noquote(metadata)

}

setMetadata <- function(object, metadata) {

  assertClass(object, "GDALMajorObject")

  metadata <- lapply(as.list(metadata), as.character)

  .Call("RGDAL_SetMetadata", object, metadata, PACKAGE="rgdal")

  invisible(object)
  
}

appendMetadata <- function(object, metadata) {

  assertClass(object, "GDALMajorObject")

  setMetadata(object, append(getMetadata(object), metadata))

}

setClass("GDALDriver", "GDALMajorObject")

setClass("GDALDataset", "GDALMajorObject")

setClass("GDALMutableDataset", "GDALDataset")

setClass("GDALTransientDataset", "GDALMutableDataset")
         
setClass("GDALRasterBand", "GDALMajorObject")

getGDALDriverNames <- function() .Call("RGDAL_GetDriverNames", PACKAGE="rgdal")

setMethod("initialize", "GDALDriver",
          def = function(.Object, name, handle = NULL) {
            if (is.null(handle))
              handle <- .Call("RGDAL_GetDriver",
                              as.character(name),
                              PACKAGE="rgdal")
            slot(.Object, "handle") <- handle
            .Object
          })

getDriverName <- function(driver) {

  assertClass(driver, "GDALDriver")

  .Call("RGDAL_GetDriverShortName", driver, PACKAGE="rgdal")

}

getDriverLongName <- function(driver) {

  assertClass(driver, "GDALDriver")

  .Call("RGDAL_GetDriverLongName", driver, PACKAGE="rgdal")

}

createHandle <- function(driver, rows, cols, bands = 1,
                         type = "Byte", file = NULL, options = NULL) {

  assertClass(driver, "GDALDriver")

  typeNum <- match(type, .GDALDataTypes, 1) - 1

  file <- if (is.null(file)) tempfile() else as.character(file)
  
  if (!is.null(options)) options <- as.character(options)
  
  dim <- as.integer(c(cols, rows, bands))
  
  .Call("RGDAL_CreateDataset", driver, dim, typeNum,
        options, file, PACKAGE="rgdal")

}

setMethod("initialize", "GDALDataset",
          def = function(.Object, handle = NULL) {
            if (is.null(handle))
              handle <- .Call("RGDAL_NullHandle", PACKAGE = "rgdal")
            slot(.Object, "handle") <- handle
            cfn <- function(handle)
              .Call("RGDAL_CloseHandle", handle, PACKAGE = "rgdal")
            reg.finalizer(slot(.Object, "handle"), cfn)
            .Object
          })

setMethod("initialize", "GDALMutableDataset",
          def = function(.Object, handle = NULL) {
            if (is.null(handle))
              handle <- .Call("RGDAL_NullHandle", PACKAGE = "rgdal")
            slot(.Object, "handle") <- handle
            cfn <- function(handle)
              .Call("RGDAL_CloseHandle", handle, PACKAGE = "rgdal")
            reg.finalizer(slot(.Object, "handle"), cfn)
            .Object
          })

setMethod("initialize", "GDALTransientDataset",
          def = function(.Object, handle = NULL) {
            if (is.null(handle))
              handle <- .Call("RGDAL_NullHandle", PACKAGE = "rgdal")
            slot(.Object, "handle") <- handle
            cfn <- function(handle)
              .Call("RGDAL_DeleteHandle", handle, PACKAGE = "rgdal")
            reg.finalizer(slot(.Object, "handle"), cfn)
            .Object
          })

createDataset <- function(driver, rows, cols,
                          bands = 1, type = "Byte",
                          file = NULL, options = NULL) {

  if (is.character(driver)) driver <- new("GDALDriver", driver)
  
  handle <- createHandle(driver, rows, cols, bands, type, file, options)

  if (is.null(file) && (getDriverName(driver) != "MEM"))
    new("GDALTransientDataset", handle)
  else
    new("GDALMutableDataset", handle)

}

getDriver <- function(dataset) {

  assertClass(dataset, "GDALDataset")

  new("GDALDriver",
      handle = .Call("RGDAL_GetDatasetDriver", dataset, PACKAGE="rgdal"))

}

copyDataset <- function(dataset, driver = NULL, file = NULL,
                        strict = FALSE, options = "") {

  assertClass(dataset, "GDALDataset")
  
  if (is.null(driver)) driver <- getDriver(dataset)
  if (is.character(driver)) driver <- new("GDALDriver", driver)

  if (is.null(file)) file <- tempfile()
  
  new.obj <- new("GDALTransientDataset",
                 handle = .Call("RGDAL_CopyDataset",
                   dataset, driver, strict, options,
                   file, PACKAGE="rgdal"))

  new.obj
  
}

saveDataset <- function(dataset, driver = NULL, file = NULL) {

  assertClass(dataset, "GDALDataset")
  
  if (is.null(driver)) driver <- getDriver(dataset)
  if (is.character(driver)) driver <- new("GDALDriver", driver)

  if (is.null(file)) file <- tempfile()
  
  new.obj <- new("GDALMutableDataset",
                 handle = .Call("RGDAL_CopyDataset",
                   dataset, getDriver(dataset),
                   FALSE, NULL, filename,
                   PACKAGE="rgdal"))

  putRasterData(new.obj, getRasterData(dataset))

  invisible(new.obj)
  
}

setGeneric("closeDataset", function(dataset) standardGeneric("closeDataset"))

"closeDataset.default" <- function(dataset) 
	stop("No default method for closeDataset")

setMethod("closeDataset", signature("ANY"), closeDataset.default)

setMethod("closeDataset", "GDALDataset",
          def = function(dataset) {
            unreg.finalizer(slot(dataset, "handle"))
            .Call("RGDAL_CloseDataset", dataset, PACKAGE="rgdal")
            invisible()
          })

setMethod("closeDataset", "GDALTransientDataset",
          def = function(dataset) {
            handle <- slot(dataset, "handle")
            unreg.finalizer(handle)
            .Call("RGDAL_DeleteHandle", handle, PACKAGE="rgdal")
            invisible()
          })

deleteDataset <- function(dataset) {

  assertClass(dataset, "GDALMutableDataset")

  if (is(dataset, "GDALMutableDataset")) {
  
    driver <- getDriver(dataset)
  
    filename <- getDescription(dataset)
  
    .Call("RGDAL_DeleteFile", driver, filename, PACKAGE="rgdal")

  }
  
  closeDataset(dataset)

}

openDataset <- function(filename, read.only = TRUE) {

  handle <- .Call("RGDAL_OpenDataset", filename,
                  read.only, PACKAGE="rgdal")

  if(read.only)
    new("GDALDataset", handle = handle)
  else
    new("GDALMutableDataset", handle = handle)
        
}

GDAL.open <- function(filename, read.only = TRUE)
  openDataset(filename, read.only)

GDAL.close <- function(dataset) closeDataset(dataset)

setMethod("dim", "GDALDataset",
          def = function(x) {
            nrows <- .Call("RGDAL_GetRasterYSize", x, PACKAGE="rgdal")
            ncols <- .Call("RGDAL_GetRasterXSize", x, PACKAGE="rgdal")
            nbands <- .Call("RGDAL_GetRasterCount", x, PACKAGE="rgdal")
            if (nbands > 1)
              c(nrows, ncols, nbands)
            else
              c(nrows, ncols)
          })

getProjectionRef <- function(dataset) {

  assertClass(dataset, "GDALDataset")

  noquote(.Call("RGDAL_GetProjectionRef", dataset, PACKAGE="rgdal"))

}

putRasterData <- function(dataset,
                          rasterData,
                          band = 1,
                          at = c(1, 1)) {

  assertClass(dataset, "GDALMutableDataset")

  at <- rep(at, length.out = 2)
  
  raster <- getRasterBand(dataset, band)
  
  .Call("RGDAL_PutRasterData", raster, rasterData, 
	as.integer(at), PACKAGE="rgdal")

}

getRasterTable <- function(dataset,
                           band = NULL,
                           at = c(1, 1),
                           region.dim = dim(dataset)) {

  assertClass(dataset, "GDALDataset")

  at <- rep(at, length.out = 2)
  region.dim <- rep(region.dim, length.out = 2)

  rasterData <- getRasterData(dataset, band, at = at,
                              region.dim = region.dim)

  if (is.null(band)) {

    nbands <- .Call("RGDAL_GetRasterCount", dataset, PACKAGE="rgdal")
    band <- 1:nbands

  } else {

    nbands <- length(band)

  }

  dim(rasterData) <- c(region.dim, nbands)

  geoTrans <- getGeoTransFunc(dataset)

  y.i <- 1:region.dim[1] - 1.5 + at[1]
  x.i <- 1:region.dim[2] - 1.5 + at[2]

  y.i <- rep(y.i, each = length(x.i))
  x.i <- rep(x.i, len = prod(region.dim))

  out <- geoTrans(x.i, y.i)

  out <- cbind(out$x, out$y)
  
  for (b in band) { 
    vec <- as.numeric(rasterData[, , b])
    out <- cbind(out, vec)
  }

  out <- as.data.frame(out)
    
  names(out) <- c("x", "y", paste("band", 1:nbands, sep = ""))

  out

}
                           
getRasterData <- function(dataset,
                          band = NULL,
                          at = c(1, 1),
                          region.dim = dim(dataset),
                          output.dim = region.dim,
                          interleave = c(0, 0),
                          as.is = FALSE, drop = TRUE) {

  assertClass(dataset, "GDALDataset")

  at <- rep(at, length.out = 2)
  region.dim <- rep(region.dim, length.out = 2)
  output.dim <- rep(output.dim, length.out = 2)
  interleave <- rep(interleave, length.out = 2)

  nbands <- .Call("RGDAL_GetRasterCount", dataset, PACKAGE="rgdal")

  if (is.null(band)) band <- 1:nbands
  
  x <- array(dim = as.integer(c(rev(output.dim), length(band))))

  for (i in seq(along = band)) {

    raster <- getRasterBand(dataset, band[i])

    x[,,i] <- .Call("RGDAL_GetRasterData", raster,
                      as.integer(c(at, region.dim)),
                      as.integer(output.dim),
                      as.integer(interleave), PACKAGE="rgdal")
  
  }

  if (drop) x <- drop(x)

  if (!as.is) {
  
    scale <- .Call("RGDAL_GetScale", raster, PACKAGE="rgdal")
    offset <- .Call("RGDAL_GetOffset", raster, PACKAGE="rgdal")

    if (scale != 1) x <- x * scale
    if (offset != 0) x <- x + offset
    
    catNames <- .Call("RGDAL_GetCategoryNames", raster, PACKAGE="rgdal")
  
    if (!is.null(catNames)) {
      levels <- rep(min(x):max(x), len = length(catNames))
      x <- array(factor(x, levels, catNames), dim = dim(x),
                 dimnames = dimnames(x))
    }

  }

  x

}

getColorTable <- function(dataset, band = 1) {

  assertClass(dataset, "GDALDataset")

  raster <- getRasterBand(dataset, band)
  
  ctab <- .Call("RGDAL_GetColorTable", raster, PACKAGE="rgdal") / 255

  if (length(ctab) == 0) return(NULL)

  if (.Call("RGDAL_GetColorInterp", raster, PACKAGE="rgdal") == "Palette")
    switch(.Call("RGDAL_GetPaletteInterp", raster, PACKAGE="rgdal"),  
           RGB = rgb(ctab[,1], ctab[,2], ctab[,3]),
           HSV = hsv(ctab[,1], ctab[,2], ctab[,3]), # Doesn"t actually exist
           Gray = gray(ctab[,1]),
           gray(apply(ctab, 2, mean)))
  else
    gray(ctab[,1])

}

RGB2PCT <- function(x, band, driver.name = "MEM",
                    ncolors = 256, set.ctab = TRUE) {
  
  assertClass(x, "GDALDataset")

  band <- rep(band, length.out = 3)

  dithered <- createDataset(driver.name, nrow(x), ncol(x))

  ctab <- .Call("RGDAL_GenCMap",
                getRasterBand(x, band[1]),
                getRasterBand(x, band[2]),
                getRasterBand(x, band[3]),
                getRasterBand(dithered),
                ncolors, set.ctab, package = "rgdal") / 255

  if (set.ctab)
    dithered
  else
    list(dataset = dithered,
         pct = rgb(ctab[,1], ctab[,2], ctab[,3]))

}  

displayDataset <- function(x, at = c(1, 1), region.dim = dim(x),
                           reduction = 1, band = 1, col = NULL,
                           reset.par = TRUE, max.dim = 500, ...) {

  assertClass(x, "GDALDataset")

  at <- rep(at, length.out = 2)
  region.dim <- rep(region.dim, length.out = 2)
  reduction <- rep(reduction, length.out = 2)

  at <- at %% dim(x)[1:2]
  
  oob <- (region.dim + at) > dim(x)[1:2]
  
  if (any(oob)) region.dim[oob]  <-  dim(x)[oob] - at[oob]

  reduction[reduction < 1] <- 1

  plot.dim <- region.dim / reduction
            
  if (any(plot.dim > max.dim))
    plot.dim <- max.dim * plot.dim / max(plot.dim)

  image.data <- getRasterData(x, band[1], at,
                              region.dim, plot.dim,
                              as.is = TRUE)

  if (is.null(col)) {
    
    max.val <- max(image.data, na.rm = TRUE)

    if (!is.finite(max.val)) {
      image.data[] <- 2
      max.val <- 2
    }

    col <- getColorTable(x, band)[1:(max.val + 1)]
      
  }

  if (is.null(col)) col <- gray(seq(0, 1, len = 256))
  
  par.in <- par(no.readonly = TRUE)

  if (reset.par) on.exit(par(par.in))

  par(pin = max(par.in$pin)
      * par.in$fin / max(par.in$fin)
      * rev(plot.dim) / max(plot.dim))
  
  image.data <- image.data[, ncol(image.data):1]

  image.default(image.data + 1, col = col, axes = FALSE, ...)
            
  invisible(list(image.data = image.data, col = col, par.in = par.in))

}

image.GDALDataset <- function(x, ...) displayDataset(x, ...)

setMethod("initialize", "GDALRasterBand",
          def =  function(.Object, dataset, band = 1) {
            assertClass(dataset, "GDALDataset")
            slot(.Object, "handle") <- .Call("RGDAL_GetRasterBand",
                                            dataset, as.integer(band), 
					    PACKAGE="rgdal")
            .Object
          })

setMethod("dim", "GDALRasterBand",
          def = function(x) {
            c(.Call("RGDAL_GetYSize", x, PACKAGE="rgdal"),
              .Call("RGDAL_GetXSize", x, PACKAGE="rgdal"))
          })

getGeoTransFunc <- function(dataset) {

  assertClass(dataset, "GDALDataset")

  geoTrans <- .Call("RGDAL_GetGeoTransform", dataset, PACKAGE="rgdal")

  rotMat <- matrix(geoTrans[c(2, 3, 5, 6)], 2)

  at <- geoTrans[c(1, 4)]

  function(x, y) {

    x <- cbind(x, y)

    x <- x %*% rotMat

    list(x = x[,1] + at[1],
         y = x[,2] + at[2])

  }

}

getRasterBand <- function(dataset, band = 1) {

  assertClass(dataset, "GDALDataset")

  new("GDALRasterBand", dataset, band)

}

getRasterBlockSize <- function(raster) {

  assertClass(raster, "GDALRasterBand")
  
  .Call("RGDAL_GetRasterBlockSize", raster, PACKAGE="rgdal")
  
}

blockApply <- function(x, fun, ..., block.size = NULL,
                       file = NULL, driver = NULL) {

  assertClass(x, "GDALDataset")

  fun <- match.fun(fun)

  if (is.null(block.size))
    block.size <- getRasterBlockSize(getRasterBand(x))

  if (is.null(driver)) driver <- getDriver(x)

  block.size <- rep(block.size, length.out = 2)

  block <- getRasterData(x, region = block.size)

  res <- fun(block, ...)

  type <- switch(storage.mode(res),
                 logical = "Byte",
                 integer = "Int32",
                 double = "Float64",
                 complex = "CFloat64",
                 stop("Unsupported data type"))

  if (is.array(res)) {

    if (any(dim(res)[1:2] != dim(block)[1:2]))
      stop("Function result does not match block dimensions")

    nband <- if(is.matrix(res)) 1 else dim(res)[3]

    out <- createDataset(driver, nrow(x), ncol(x), nband, type, file)

    writeRes <- function(x, at)
      for (b in 1:nband) putRasterData(out, x[,,b], b, at)

  } else {

    nBlocksY <- ceiling(nrow(x) / nrow(block))
    nBlocksX <- ceiling(ncol(x) / ncol(block))

    nband <- length(res)
    
    out <- createDataset(driver, nBlocksY, nBlocksX, nband, type, file)

    writeRes <- function(x, at)
      for (b in 1:nband) putRasterData(out, x[b], b, at)

  }

  writeRes(res, c(1, 1))

  row <- 1
  col <- block.size[2] + 1

  while (row <= nrow(x)) {

    while (col <= ncol(x)) {

      region <- c(min(block.size[1], nrow(x) - row + 1),
                  min(block.size[2], ncol(x) - col + 1))

      cat(row, col, region, "\n")

      block <- getRasterData(x,
                             at = c(row, col),
                             region = region)
      
      writeRes(fun(block, ...), c(row, col))      

      col <- col + block.size[2]

    }

    col <- 1
    row <- row + block.size[1]
    
  }
  
  out

}


