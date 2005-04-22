sub.GDROD = function(x, i, j, ... , drop = FALSE) {
	# x[rows, cols, bands, ...]
	if (!require(sp))
		stop("could not load package sp")
	n.args = nargs()
	dots = list(...)
	if (!missing(drop))
		stop("don't supply drop: it needs to be FALSE anyway")
	missing.i = missing(i)
	missing.j = missing(j)
	if (length(dots) > 0) {
		# fish for an unnamed argument, and rename it bands
		m  = match(names(dots),  c(""))
		if (any(!is.na(m))) 
			names(dots)[m[1]] = "band"
	}
	# process common arguments:
	gdal.args = dots
	gdal.args$dataset = x
	gdal.args$band = dots$band # NULL if not given
	if (is.null(gdal.args$offset))
		gdal.args$offset = c(0, 0)
	if (is.null(gdal.args$region.dim))
		gdal.args$region.dim = dim(x)
	
	# retrieve topology:
	gt = .Call('RGDAL_GetGeoTransform', x, PACKAGE="rgdal")
	# [1] 178400     40      0 334000      0    -40
	# retrieve data:
	if (any(gt[c(3,5)] != 0)) {
		warning("grid has an orientation which is not suitable for sp; returning points...")
		data = do.call(getRasterTable, gdal.args)
		coordinates(data) = c(1,2)
	} else {
		# further arguments to getRasterData:
		if (is.null(gdal.args$output.dim))
			gdal.args$output.dim = gdal.args$region.dim
		if (is.null(gdal.args$interleave))
			gdal.args$interleave = c(0, 0)
		if (is.null(gdal.args$as.is))
			gdal.args$as.is = FALSE
		data = do.call(getRasterData, gdal.args)
		# subset data:
		if (length(dim(data)) == 3)
			data = data[i,j,]
		else
			data = data[i,j]
		cellsize = abs(c(gt[2] * (1 + gdal.args$interleave[2]),
				gt[6] * (1 + gdal.args$interleave[1])))
		d = dim(data) # rows=nx, cols=ny
		cells.dim = c(d[1], d[2]) # c(d[2],d[1])
		cellcentre.offset = c(x = gt[1] + (0.5 + gdal.args$offset[2])* cellsize[1], 
			y = gt[4] - (d[2] - 0.5) * abs(cellsize[2]))
		grid = GridTopology(cellcentre.offset, cellsize, cells.dim)
		if (length(d) == 2)
			df = data.frame(band1 = as.vector(data))
		else {
			df = as.vector(data[,,1])
			for (band in 2:d[3])
				df = cbind(df, as.vector(data[,,band]))
			df = as.data.frame(df)
			names(df) = paste("band", 1:d[3], sep="")
		}
		data = SpatialGridDataFrame(grid, df)
	}
	return(data)
}
setMethod("[", "GDALReadOnlyDataset", sub.GDROD)
