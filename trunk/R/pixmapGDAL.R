getPixmapGDAL <- function(dataset,
                          band = NULL,
                          offset = c(0, 0),
                          region.dim = dim(dataset),
                          output.dim = region.dim,
                          interleave = c(0, 0),
                          set.dimnames = FALSE,
                          as.is = FALSE) {
	.assertClass(dataset, 'GDALReadOnlyDataset')
	require(pixmap)
	nbands <- .Call('RGDAL_GetRasterCount', dataset, PACKAGE="rgdal")
	if (is.null(band)) band <- 1:nbands
	if (nbands == 1) {
		res <- pixmapGrey(t(getRasterData(dataset=dataset, band=1,
				offset=offset, region.dim=region.dim,
				output.dim=output.dim, interleave=interleave,
				as.is=as.is)))
	} else if (nbands == 3) {
		require(abind)
		bb <- vector(mode="list", length=3)
		for (i in 1:3) {
			bb[[i]] <- t(getRasterData(dataset=dataset, band=i,
				offset=offset, region.dim=region.dim,
				output.dim=output.dim, interleave=interleave,
				as.is=as.is))
		}
		res <- abind(bb[[1]], bb[[2]], bb[[3]], along=3)
		res <- pixmapRGB(res)
	} else stop (paste("Number of bands", nbands, "neither 1 nor 3"))
	res
}
