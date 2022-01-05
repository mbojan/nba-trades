requireNamespace("here")
requireNamespace("igraph")
library(ggplot2)
library(ergm)
library(ergm.count)
box::use(
  codebox/misc[get_r_cores]
)

set.seed(666)
r_cores <- get_r_cores()

graphlist <- readRDS(here::here("data", "igraph-list.rds"))
graphlist <- graphlist |>
  setNames(
    vapply(graphlist, igraph::graph_attr, character(1), name = "season")
  ) |>
  lapply(function(g) {
    igraph::V(g)$name <- paste0(g$season, "-", igraph::V(g)$name)
    igraph::V(g)$season <- g$season
    g$season <- NULL
    g
  }) |>
  head(-1) # Drop 2019-2020

season_from <- names(graphlist) |>
  substr(1, 4) |>
  as.numeric()

bigg <- do.call(igraph::disjoint_union, graphlist)
net <- intergraph::asNetwork(bigg)



# Fit model 1 -------------------------------------------------------------

# All seasons/periods

fit <- ergm(
  net ~ nodefactor("season", levels = TRUE) + nodematch("division"),
  constraints = ~ blockdiag("season"),
  reference = ~ Poisson,
  response = "weight",
  verbose = TRUE,
  control = control.ergm(
    parallel = r_cores
  )
)
saveRDS(fit, file="ergm-pooled1.rds")


# Fit model 2 -------------------------------------------------------------

# Seasons 1976 - 2004

bigg2 <- do.call(igraph::disjoint_union, graphlist[season_from <= 2003])
net2 <- intergraph::asNetwork(bigg2)

fit2 <- ergm(
  net2 ~ nodefactor("season", levels = TRUE) + nodematch("division"),
  constraints = ~ blockdiag("season"),
  reference = ~ Poisson,
  response = "weight",
  verbose = TRUE,
  control = control.ergm(
    parallel = r_cores
  )
)

summary(fit2)

saveRDS(fit2, file="ergm-pooled2.rds")


# Fit model 3 -------------------------------------------------------------

# Seasons 2005 - 2019

bigg3 <- do.call(igraph::disjoint_union, graphlist[season_from >= 2004])
net3 <- intergraph::asNetwork(bigg3)

fit3 <- ergm(
  net3 ~ nodefactor("season", levels = TRUE) + nodematch("division"),
  constraints = ~ blockdiag("season"),
  reference = ~ Poisson,
  response = "weight",
  verbose = TRUE,
  control = control.ergm(
    parallel = r_cores
  )
)

summary(fit3)

saveRDS(fit3, file="ergm-pooled3.rds")
