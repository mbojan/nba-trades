#' GOF of valued ERGM: degree distribution
#' 
#' Calculate data necessary for degree distribution GOF plot of a valued ERGM.
#' 
#' @param fit fitted model object
#' @param sims list of simulated networks from the `fit` (as returned by [ergm::simulate()])
#' 
#' @details Vertex degrees are calculated as the sum of weights.
#' 
#' @return A list with elements:
#' - `observed` - tibble with columns `season`, `deg` (degree), and `n` (counts)
#' - `simulated` - tibble with columns `sim`, `season`, `deg` and `n`
#' 
#' @note This implementation is not generic, i.e. it is tailored to NBA trades
#' project.
#' 
#' @export
gofplot_degrees <- function(fit, sims) {
  box::use(
    ergm[is.valued],
    igraph[strength, degree],
    intergraph[asIgraph],
    network[`%v%`],
    tibble[enframe],
    dplyr[...],
    stringi
  )
  # Argument checks
  stopifnot(inherits(fit, "ergm"))
  stopifnot(is.valued(fit))
  stopifnot(inherits(sims, "network.list"))
  
  # Observed
  obs <- fit$network |>
    asIgraph() |>
    strength() |>
    tibble::enframe(value = "degree") |>
    mutate(
      vnames = fit$network %v% "vertex.names",
      season = stringi::stri_extract_first_regex(vnames, "[0-9]{4}-[0-9]{4}"),
      team = stringi::stri_extract_first_regex(vnames, "[0-9A-Za-z]+$")
    ) |>
    group_by(season, .drop = TRUE) |>
    count(deg=degree) |>
    ungroup()
  
  # Simulated
  simed <- lapply(sims, function(n) {
    strength(asIgraph(n))
  }) |>
    lapply(function(x) { tibble::tibble(deg = x, team = fit$network %v% "vertex.names")}) |>
    dplyr::bind_rows(.id = "sim") |>
    dplyr::mutate(
      season = stringi::stri_extract_first_regex(team, "[0-9]{4}-[0-9]{4}"),
      team = stringi::stri_extract_first_regex(team, "[0-9A-Za-z]+$")
    ) |>
    dplyr::group_by(sim, season, .drop = TRUE) |>
    dplyr::count(deg) |>
    ungroup()
  
  list(
    observed = obs,
    simulated = simed
  )
}


#' GOF of valued ERGM: mixing matrix
#' 
#' Calculate data necessary for mixing matrix GOF plot of a valued ERGM.
#' 
#' @param fit fitted model object
#' @param sims list of simulated networks from the `fit` (as returned by [ergm::simulate()])
#' @param vattr character; name of the vertex attribute of interest
#' 
#' @return TODO
#' 
#' @note  This implementation is not generic, i.e. it is tailored to NBA trades
#'   project.
#' 
#' @export
gofplot_mixingmatrix <- function(fit, sims, vattr) {
  box::use(
    ./utils[...],
    igraph,
    intergraph[asIgraph],
    ergm[is.valued],
    network[get.vertex.attribute, mixingmatrix],
    dplyr[...]
  )
  # Argument checks
  stopifnot(inherits(fit, "ergm"))
  stopifnot(is.valued(fit))
  stopifnot(inherits(sims, "network.list"))
  
  # Observed
  obs <- asIgraph(fit$network) |>
    split_graph("season")
    
  
  # Simulated
  # simed <- sims |>
  #   lapply(function(nt) {
  #     mixingmatrix(nt, vattr) |>
  #       asdf(add_dimnames = TRUE) |>
  #       filter(From <= To) |>
  #       mutate(
  #         season = get.vertex.attribute(nt, "season")[1],
  #         label = paste0(From, "-", To)
  #       )
  #   }) |>
  #   bind_rows(.id = "sim")
  
  list(
    # simulated = simed,
    observed = obs
  )
}




#' Custom summary_formula()
#' 
#' @param object ERGM formula
#' @param parallel `NULL` or integer or cluster object as returned by [parallel::makeCluster()]
#' 
#' @return A tibble.
#' 
#' @export

nba_summary <- function(object, parallel=NULL) {
  box::use(
    ./utils[...],
    statnet.common[eval_lhs.formula,nonsimp_update.formula],
    network[get.vertex.attribute],
    ergm[summary_formula],
    stats[update],
    prl = parallel
  )
  # stopifnot(is.formula(object))
  nets <- eval_lhs.formula(object) |>
    split_graph(vattr="season")
  if(!is.null(parallel)) {
    stopifnot(is.integer(parallel) | inherits(parallel, "cluster"))
    cl <- if(is.integer(parallel)) {
      on.exit(parallel::stopCluster(cl))
      parallel::makeCluster(parallel)
    } else parallel
    l <- parallel::parLapply(
      cl,
      nets,
      function(net) {
        frm <- nonsimp_update.formula(object, net ~ ., from.new="net")
        structure(
          summary_formula(frm, response = "weight"),
          season = get.vertex.attribute(net, "season")[1]
        )
      }
    )
  } else {
    l <- lapply(
      nets,
      function(net) {
        frm <- nonsimp_update.formula(object, net ~ ., from.new="net")
        # browser()
        structure(
          summary_formula(frm, response = "weight"),
          season = get.vertex.attribute(net, "season")[1]
        )
      }
    )    
  }
  
  l |>
    lapply(
      function(x) {
        tibble::enframe(x) |>
          dplyr::mutate(
            season = attr(x, "season")
          )
      }
    ) |>
    dplyr::bind_rows()
}