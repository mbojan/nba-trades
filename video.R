library(lubridate)
library(networkDynamic)

tl <- readRDS("data/trades.rds")
tl$Date <- as.character(tl$Date)
tl$P1 <- tl$franchise1
tl$P2 <- tl$franchise2
tl$franchise1 <- tl$franchise2 <- NULL

# Removing trades from the incomplete 2019-20 season
tl <- tl[which(as.Date(tl$Date) < as.Date("2019-06-01")),]

# MB: This is already fixed in `data/trades.rds`
# Correcting the misclassification of Hornets/Pelicans in ZR's recoding
# tl$P1[which(tl$P1=="Pelicans" & as.Date(tl$Date) < as.Date("2002-05-01"))] <- "Hornets"
# tl$P2[which(tl$P2=="Pelicans" & as.Date(tl$Date) < as.Date("2002-05-01"))] <- "Hornets"

# Grabbing the "Franchise ID"
fid <- unique(c(tl$P1, tl$P2))

# Setting up the basic network structure
  n <- network.initialize(length(fid), directed=F)
  set.vertex.attribute(n, "franchise_name", fid)

# Expansion Team 
  activate.vertices(n, onset=1980, terminus=2019, v=which(get.vertex.attribute(n, "franchise_name")=="Mavericks"))
  activate.vertices(n, onset=1988, terminus=2019, v=which(get.vertex.attribute(n, "franchise_name")=="Heat"))
  activate.vertices(n, onset=1988, terminus=2019, v=which(get.vertex.attribute(n, "franchise_name")=="Hornets"))
  activate.vertices(n, onset=1989, terminus=2019, v=which(get.vertex.attribute(n, "franchise_name")=="Timberwolves"))
  activate.vertices(n, onset=1989, terminus=2019, v=which(get.vertex.attribute(n, "franchise_name")=="Magic"))
  activate.vertices(n, onset=1995, terminus=2019, v=which(get.vertex.attribute(n, "franchise_name")=="Raptors"))
  activate.vertices(n, onset=1995, terminus=2019, v=which(get.vertex.attribute(n, "franchise_name")=="Grizzlies"))
  activate.vertices(n, onset=2002, terminus=2019, v=which(get.vertex.attribute(n, "franchise_name")=="Pelicans"))
  
# networkDynamic requires a numeric node ID, so quickly adding that
  p1 <- data.frame(p1.id=get.vertex.attribute(n, "vertex.names"), P1=get.vertex.attribute(n, "franchise_name"))
  p2 <- data.frame(p2.id=get.vertex.attribute(n, "vertex.names"), P2=get.vertex.attribute(n, "franchise_name"))
  tl <- merge(tl, p1, "P1", sort=F)
  tl <- merge(tl, p2, "P2", sort=F)
  
# For labeling purposes, adding the team name Concurrent to season.
  activate.vertex.attribute(n, "curr_name", get.vertex.attribute(n, "franchise_name"))
  activate.vertex.attribute(n, "curr_name", "Hornets", onset=2002, terminus=2013, v=which(get.vertex.attribute(n, "franchise_name")=="Pelicans"))
  activate.vertex.attribute(n, "curr_name", "Bobcats", onset=2004, terminus=2014, v=which(get.vertex.attribute(n, "franchise_name")=="Hornets"))
  activate.vertex.attribute(n, "curr_name", "SuperSonics", onset=1976, terminus=2008, v=which(get.vertex.attribute(n, "franchise_name")=="Thunder"))
  activate.vertex.attribute(n, "curr_name", "Bullets", onset=1976, terminus=1997, v=which(get.vertex.attribute(n, "franchise_name")=="Wizards"))
  activate.vertex.attribute(n, "curr_name", "Braves", onset=1976, terminus=1978, v=which(get.vertex.attribute(n, "franchise_name")=="Clippers"))

# Attaching Division information
  load("data/NBA_Meta.Rdata")
  activate.vertex.attribute(n, "division", NA)
  
  # Through 2004
  for(i in 1:(length(divisions)-1)){
    temp <- mapply(as.character, divisions[[i]])
    labs <- rownames(divisions[[i]])
    
    for (j in 1:nrow(temp)){
      activate.vertex.attribute(n, "division", labs[j], 
                                onset=as.numeric(names(divisions)[i]), 
                                terminus=as.numeric(names(divisions)[i+1]),
                                v=which(get.vertex.attribute(n,"franchise_name") %in% temp[j,]))
    }
  }
  
  # From 2004 on
  i<-9
  temp <- mapply(as.character, divisions[[i]])
  labs <- rownames(divisions[[i]])
  for (j in 1:nrow(temp)){
    activate.vertex.attribute(n, "division", labs[j], 
                              onset=as.numeric(names(divisions)[i]), 
                              terminus=2019,
                              v=which(get.vertex.attribute(n,"franchise_name") %in% temp[j,]))
  }

# As a strategy for clustering nodes in the viz by division, I'm going to add a division nodeset.
# Then I'll link teams to those, generate the layout, then remove the division nodes & edges.
  
n <- add.vertices.active(n, 3, onset=1976, terminus=2019)
activate.vertex.attribute(n, "curr_name", c("Atlantic", "Central", "Pacific"), 
                            onset=1976, terminus=2019, v=c(31:33))
n <- add.vertices.active(n, 1, onset=1976, terminus=2003)
activate.vertex.attribute(n, "curr_name", "Midwest", 
                          onset=1976, terminus=2004, v=34)
n <- add.vertices.active(n, 3, onset=2004, terminus=2019)
activate.vertex.attribute(n, "curr_name", c("Southeast", "Northwest", "Southwest"), 
                          onset=2004, terminus=2019, v=c(35:37))

  for (i in 1976:2003){
    n <- add.edges.active(n, tail=which(get.vertex.attribute.active(n, "division", at=i)=="Midwest"),
                          head=which(get.vertex.attribute.active(n, "curr_name", at=i)=="Midwest"), onset=i,terminus=i+1)
    n <- add.edges.active(n, tail=which(get.vertex.attribute.active(n, "division", at=i)=="Central"),
                          head=which(get.vertex.attribute.active(n, "curr_name", at=i)=="Central"), onset=i,terminus=i+1)
    n <- add.edges.active(n, tail=which(get.vertex.attribute.active(n, "division", at=i)=="Atlantic"),
                          head=which(get.vertex.attribute.active(n, "curr_name", at=i)=="Atlantic"), onset=i,terminus=i+1)
    n <- add.edges.active(n, tail=which(get.vertex.attribute.active(n, "division", at=i)=="Pacific"),
                          head=which(get.vertex.attribute.active(n, "curr_name", at=i)=="Pacific"), onset=i,terminus=i+1)
  }

  for (i in 2004:2018){
    n <- add.edges.active(n, tail=which(get.vertex.attribute.active(n, "division", at=i)=="Southeast"),
                          head=which(get.vertex.attribute.active(n, "curr_name", at=i)=="Southeast"), onset=i,terminus=i+1)
    n <- add.edges.active(n, tail=which(get.vertex.attribute.active(n, "division", at=i)=="Central"),
                          head=which(get.vertex.attribute.active(n, "curr_name", at=i)=="Central"), onset=i,terminus=i+1)
    n <- add.edges.active(n, tail=which(get.vertex.attribute.active(n, "division", at=i)=="Atlantic"),
                          head=which(get.vertex.attribute.active(n, "curr_name", at=i)=="Atlantic"), onset=i,terminus=i+1)
    n <- add.edges.active(n, tail=which(get.vertex.attribute.active(n, "division", at=i)=="Pacific"),
                          head=which(get.vertex.attribute.active(n, "curr_name", at=i)=="Pacific"), onset=i,terminus=i+1)
    n <- add.edges.active(n, tail=which(get.vertex.attribute.active(n, "division", at=i)=="Northwest"),
                          head=which(get.vertex.attribute.active(n, "curr_name", at=i)=="Northwest"), onset=i,terminus=i+1)
    n <- add.edges.active(n, tail=which(get.vertex.attribute.active(n, "division", at=i)=="Southwest"),
                          head=which(get.vertex.attribute.active(n, "curr_name", at=i)=="Southwest"), onset=i,terminus=i+1)
  }

###########################################################################
# Everything above creates the networkDyanmic object
# Now we can set up the actual video
library(ndtv)
# Just tweaking the color preferences
palette(c("green", "red", "yellow", "blue", "cyan", "magenta"))

# Rendering the layouts
compute.animation(n, 
                  slice.par=list(start=1976,end=2018, interval=1, aggregate.dur=1, rule="all"), 
                  displayisolates=T, weight.dist=T)
deactivate.edges(n, e=c(1:1170), onset=1976, terminus=2019)
deactivate.vertices(n, v=c(31:37), onset=1976, terminus=2019)

# Adding all of the edge toggles (for the moment, annual)
add.edges.active(n,onset=tl$season_from, terminus=tl$season_to,tail=tl$p1.id,head=tl$p2.id)

# Creating an edge attribute of division homophily
activate.edge.attribute(n, "sd", "gray66")
for(i in 1976:2018){
  ds <- get.vertex.attribute.active(n, "division", onset=i, terminus=i+1)
  el <- as.edgelist(network.extract(n, onset=i, terminus=i+1, retain.all.vertices=T))
  for(j in 1:nrow(el)){
    if(ds[el[j,1]]==ds[el[j,2]]){
      activate.edge.attribute(n, "sd", "red", onset=i, terminus=i+1, e=get.edgeIDs.active(n, el[j,1], alter=el[j,2], onset=i, terminus=i+1))
    }
  }
}

# Let's make that object something we save out.
nd <- n # just making a *slightly* more meaningful object name
save(nd, file="data/trades_dynamic.Rdata")

# Some options for plotting the movie for output as .mp4 or .html
# This version can be saved as an .mp4 if you have ffmpeg installed.
# render.animation(nd, main="NBA Trades", xlab=function(s){paste(s+1975,"-",s+1976,sep="")},
#                  label="curr_name", vertex.col="division", edge.col="sd",
#                  displaylabels=T, label.col="gray75", vertex.border="black",
#                  label.cex=.5, displayisolates=T, ani.options=list(interval=.2),
#                  render.par=list(tween.frames=5, show.time=F))

#The HTML embeddable version isn't working right, but I'm not sure why.
render.d3movie(nd, filename="NBA_Trades.html", tween.frames=20,
               main="NBA Trades", xlab=function(s){paste(s+1975,"-",s+1976,sep="")},
               label="curr_name", vertex.col="division", output.mode="HTML",
               edge.col="sd", d3.options = list(enterExitAnimationFactor=0.01), 
               displaylabels=T, label.col="gray25", vertex.border="black",
               label.cex=.8, ani.options=list(interval=.1), legend=T)

## For adding a legend:
# render.par=list(extraPlotCmds=expression(
#   text(0,0,'hello\nworld',col='blue')
# ))