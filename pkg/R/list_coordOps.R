list_coordOps <- function(src_crs, tgt_crs, area_of_interest=as.numeric(NA), strict_containment=FALSE, visualization_order=TRUE) {
    stopifnot(is.character(src_crs))
    stopifnot(length(src_crs) == 1L)
    stopifnot(is.character(tgt_crs))
    stopifnot(length(tgt_crs) == 1L)
    stopifnot(is.numeric(area_of_interest))
    stopifnot((length(area_of_interest) == 1L && is.na(area_of_interest)) ||
        (length(area_of_interest) == 4L))
    stopifnot(is.logical(strict_containment))
    stopifnot(length(strict_containment) == 1L)
    stopifnot(is.logical(visualization_order))
    stopifnot(length(visualization_order) == 1L)
    res <- .Call("list_coordinate_ops", src_crs, tgt_crs, area_of_interest, 
        strict_containment, visualization_order, PACKAGE="rgdal")
    if (is.null(res)) stop("function not available without PROJ 6")
    names(res) <- c("description", "definition", "accuracy", "instantiable", "ballpark", "number_grids")
    grids <- res[[7]]
    res[[7]] <- NULL
    res$definition <- unname(sapply(res$definition, function(x) gsub(" ",
        " +", paste0("+", x))))
    res <- as.data.frame(res)
    attr(res, "grids") <- grids
    res
}
