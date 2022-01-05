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





#' Given an igraph object and vertex attribute create a list of subgraphs of
#' within-group graphs
#' 
#' @export

split_graph <- function(g, ...) UseMethod("split_graph")

#' @export
split_graph.igraph <- function(g, vattr) {
  box::use(
    igraph[vertex_attr, V, induced_subgraph]
  )
  v <- vertex_attr(g, vattr)
  lapply(
    sort(unique(v)),
    function(x) {
      induced_subgraph(g, v = which(v == x))
    }
  )
}

#' @export
split_graph.network <- function(g, ...) {
  box::use(
    intergraph[asNetwork, asIgraph]
  )
  g |>
    asIgraph() |>
    split_graph.igraph(...) |>
    lapply(asNetwork)
}


# -------------------------------------------------------------------------


#' Converting arrays to tibbles with or without dimnames
#' 
#' @export
asdf <- function(x, responseName="n", add_dimnames=FALSE,
                 retval=c("tibble", "df"), ...) {
  stopifnot(is.array(x))
  retval <- match.arg(retval)
  # construct df building call
  ex <- quote(
    data.frame(
      do.call("expand.grid", c(
        structure(
          lapply(dim(x), seq),
          names = paste0(".dim", seq(1, length(dim(x))))
        ),
        KEEP.OUT.ATTRS = FALSE,
        stringsAsFactors=FALSE
      ) ),
      Freq = c(x) )
  )
  names(ex)[3L] <- responseName
  rval <- eval(ex)
  if(add_dimnames) {
    ex <- quote(
      data.frame(do.call("expand.grid", c(
        dimnames(provideDimnames(x, ...)),
        KEEP.OUT.ATTRS = FALSE,
        stringsAsFactors=FALSE
      ) ) )
    )
    dnames <- eval(ex)
    rval <- cbind(rval, dnames)
  }
  
  switch(retval,
         tibble = tibble::tibble(rval),
         df = rval
  )
}

