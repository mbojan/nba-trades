# ----------------------------------------------------------------------------------------
# Script Name: NBA Transaction Scrape
#
# Purpose of Script: Scrape all NBA trades from ABA merger
#
# Author: Zachary Richardson, Ph.D.
#
# Date Created: 2020-01-17
#
# Copyright (c) Zachary Richardson, 2020
# Email: zachinthelab@gmail.com
# Blog: thelab.ghost.io
# ----------------------------------------------------------------------------------------
# Load Packages 
library(rvest)
library(XML)
library(dplyr)
library(stringr)
library(stringi)
library(tidyr)
library(reshape2)
# ----------------------------------------------------------------------------------------
setwd("~./NBA_SNA_Project")
# ----------------------------------------------------------------------------------------
base.url <- "http://www.prosportstransactions.com/basketball/Search/SearchResults.php?Player=&Team=&BeginDate=1976-08-05&EndDate=2020-01-14&PlayerMovementChkBx=yes&Submit=Search&start="
seq.df <- data.frame(pg.no = 0:1653) %>%
  mutate(search.no = .data$pg.no*25) %>%
  mutate(search.url = paste0(base.url, .data$search.no))

bball.links <- as.list(seq.df$search.url)

main.df <- data.frame(Date = as.character(),
                      Team = as.character(),
                      Acquired = as.character(),
                      Relinquished = as.character(),
                      Notes = as.character())
# -------------------------------------------------
for(i in bball.links) {
  # Sys.sleep(3)
  page <- read_html(i)
  
  test.table <- page %>%
    html_nodes('.container table.datatable.center') %>%
    html_table(header = TRUE) %>% 
    .[[1]]
  
  main.df <- bind_rows(main.df, test.table)
}

main.df$Date <- as.Date(main.df$Date, format = "%Y-%m-%d")
save(main.df, file = "data/NBA_Transactions.RData")
# ----------------------------------------------------------------------------------------
