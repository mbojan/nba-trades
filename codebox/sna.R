#' Calculate Moody's alpha with confidence intervals
#'
#' @param net object of class network
#' @param att character; name of the vertex attribute
#' @param conf.level numeric; value in [0,1], the confidence level
#' 
#' @return Numeric vector with elements:
#' - `or` -- odds ratio for within-group ties
#' - `se` -- standard error (square root of the sum of reciprocals of the b-g and w-g counts)
#' - `ci.low`, `ci.high` -- confidence interval
#' - `conf.level` - confidence level
alpha <- function(net, att, conf.level = 0.95) {
  box::use(
    stats[
      qnorm
    ],
    network[
      set.vertex.attribute, 
      get.vertex.attribute,
      as.sociomatrix, 
      network,
      mixingmatrix,
      is.directed
    ]
  )
  stopifnot(inherits(net, "network"))
  net.noties <- network(1 - as.sociomatrix(net))
  set.vertex.attribute(
    net.noties, 
    att, 
    get.vertex.attribute(net, att)
  )
  # Mixing matrices:
  oT <- mixingmatrix(net, att)  # observed ties
  nT <- mixingmatrix(net.noties, att)  # null ties
  # Nos. of ties and noties between- and within-:
  wg.ties <- sum(diag(oT))
  bg.noties <- sum(nT) - sum(diag(nT))
  wg.noties <- sum(diag(nT))
  bg.ties <- sum(oT) - sum(diag(oT))
  if(!is.directed(net)) {
    # For undirected networks some of the counts need to be halved
    bg.noties <- bg.noties / 2
    bg.ties <- bg.ties / 2
    wg.noties <- wg.noties / 2
  }
  OR <- (wg.ties / wg.noties) / (bg.ties / bg.noties)
  SE <- sqrt(1 / wg.ties + 1 / bg.noties + 1 / wg.noties + 1 / bg.ties)
  CI <- exp(log(OR) + qnorm(c((1 - conf.level)/2, 1 - (1 - conf.level)/2)) * SE)
  names(CI) <- c("ci.low", "ci.high")
  return(c(
    or = OR, 
    se = SE,
    CI,
    conf.level = conf.level
  ))
}
