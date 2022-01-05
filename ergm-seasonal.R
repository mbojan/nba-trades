# Fitting weighted ERGMs to seasonal networks


library(dplyr)
library(purrr)
library(rlang)
library(ergm.count)
library(parallel)
library(doParallel)
box::use(
  codebox/misc[...]
)

r_cores <- max(2, get_r_cores())


# Models ------------------------------------------------------------------

models <- list(
  A = net ~ sum + nodefactor("division"),
  B = net ~ sum + nodefactor("division") + nodematch("division"),
  C = net ~ sum + nodefactor("division") + nodematch("division", diff=TRUE),
  D = net ~ sum + nodematch("division", diff=FALSE)
) %>% 
  tibble::enframe("model_name", "model_formula")


# Data --------------------------------------------------------------------

graphlist <- readRDS(here::here("data", "igraph-list.rds"))

d <- tibble::tibble(
  season = vapply(graphlist, igraph::get.graph.attribute, character(1), "season"),
  graph = graphlist, # igraphs
  net = lapply(graphlist, intergraph::asNetwork) # networks
) %>%
  tidyr::crossing(models) %>%
  mutate(
    model_formula = map2(net, model_formula, ~ {
      environment(.y)$net <- .x
      .y
    }
    )
  )

d$model_formula[[1]]
ls(envir=environment(d$model_formula[[1]]))

# Fit in parallel ---------------------------------------------------------

cl <- makeCluster(r_cores)
registerDoParallel(cl)
do_fit <- function(i) {
  net <- d$net[[i]]
  frm <- d$model_formula[[i]]
  environment(frm)$net <- net
  fit <- try(ergm(frm, 
       reference = ~ Poisson,
       response = "weight"
  ))
  message("DONE ", i)
  fit
}
clusterEvalQ(cl, library("ergm.count"))
clusterExport(cl, list("do_fit", "d"))
results <- parLapply(cl, seq(1, nrow(d)), do_fit)
stopCluster(cl)
saveRDS(results, file = here::here("ergm-seasonal.rds"))
