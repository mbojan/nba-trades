requireNamespace("here")
requireNamespace("igraph")
library(networkDynamic)
library(lubridate)

glist <- readRDS(here::here("data", "igraph-list.rds"))
netlist <- lapply(glist, intergraph::asNetwork)

dn <- networkDynamic(network.list = netlist, vertex.pid = "vertex.names")
activate.vertex.attribute(dn, )

library(ndtv)
xy <- compute.animation(dn)

render.animation(xy)

render.d3movie(
  xy, 
  file="video0.html",
  tweenframes = 20,
  d3.options = list(
    enterExitAnimationFactor = 0.1
  ),
  displaylabels = TRUE
)
