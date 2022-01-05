#' Determine the number of cores to run on based on R_CORES
#' 
#' @param envar character; name of the variable to inspect
#' 
#' @return Integer number of cores. [control.ergm()] expects 0 for no parallel estimation.

get_r_cores <- function(envar = "R_CORES") {
  v <- Sys.getenv(envar)
  if(v == "") return(0)
  vn <- as.integer(v)
  if(is.na(vn) || vn < 0 ) stop("Bad value of ", envar, ": ", v, call.=FALSE)
  vn
}