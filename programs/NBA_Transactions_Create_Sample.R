# ----------------------------------------------------------------------------------------
# Script Name: NBA Transactions Create Sample
#
# Purpose of Script: Create the sample from the Main NBA data scrape
#
# Author: Zachary Richardson, Ph.D.
#
# Date Created: 2020-01-14
#
# Copyright (c) Zachary Richardson, 2020
# Email: zachinthelab@gmail.com
# Blog: thelab.ghost.io
# --------------------------------------
#
# Notes: 
#  - The sample we used is from the ABA merger on. For consistency, team names are 
#    recoded to match the general franchises and not reflective of name changes (i.e the
#    original Charlotte Hornets who moved to New Orleans and are now known as the
#    Pelicans were recoded to always be the Pelicans and the new Charlotte franchise that
#    were the Bobcats and then renamed the Hornets are just referred to as the Hornets).
#    
#  - Updated on 1/18 to simplify the mutates editing team and partner names as well as
#    simplifying some of the code to remove redundencies and take care of some of the
#    known errors earlier in the code.
#
# ----------------------------------------------------------------------------------------
# Load Packages 
library(dplyr)
library(stringr)
library(stringi)
library(tidyr)
library(reshape2)
# ----------------------------------------------------------------------------------------
# ----------------------------------------------------------------------------------------
setwd("/Users/Admin/Dropbox/Post-Doc Files/The Lab (Blog Site)/Sports Transactions SNA Project")
load("NBA_Transactions.RData")
# ----------------------------------------------------------------------------------------
# Find trade partners for each listed trade
  trade.df <- main.df %>%
    select(Date, Team, Notes) %>%
    subset(., grepl("trade with ", Notes)) %>%
    subset(., !grepl("cancelled ", Notes)) %>%
    subset(., !grepl("rescinded ", Notes)) %>%
    subset(., !grepl("nullified ", Notes)) %>% 
    subset(., !grepl("voided ", Notes)) %>%
    mutate(Notes = gsub("\\s*\\([^\\)]+\\)","", .data$Notes)) %>%
    mutate(Partner = sapply(str_extract_all(.data$Notes,
                                            '\\b[A-Z][a-z]+\\b|\\b[0-9][0-9][a-z]+\\b'), 
                                            paste, collapse=', ')) %>%
    mutate(Num.Trade.Partners = as.numeric(gsub("([0-9]+).*$", "\\1", .data$Notes))) %>%
    mutate(Num.Trade.Partners = ifelse(is.na(.data$Num.Trade.Partners), 2, .data$Num.Trade.Partners)) %>%
    mutate(Partner = ifelse(Num.Trade.Partners == 2, 
                            gsub(',.*', '', .data$Partner),.data$Partner)) %>%
    mutate(season = as.numeric(format(Date, '%Y'))) %>%
  
    # Take care of some typos on the team names and rename teams that have moved to 
    # appropriate franchise names:
    mutate(Team = ifelse(Team == "Braves", "Clippers", Team)) %>%
    mutate(Team = ifelse(Team == "Bullets", "Wizards", Team)) %>%
    mutate(Team = ifelse(Team == "Cavalierse", "Cavaliers", Team)) %>%
    mutate(Team = ifelse(Team == "Clippets", "Clippers", Team)) %>%
    mutate(Team = ifelse(Team == "Grizzles", "Grizzlies", Team)) %>%
    mutate(Team = ifelse(Team == "Grizzlines", "Grizzlies", Team)) %>%
    mutate(Team = ifelse(Team == "Timberwoves", "Timberwolves", Team)) %>%
    mutate(Team = ifelse(Team == "Sonics", "Thunder", Team)) %>%
    mutate(Team = ifelse(Team == "Bull", "Bulls", Team)) %>%
    mutate(Team = ifelse(Team == "Hornets" & Date < lubridate::ymd("2014-05-20"), 
                         "Pelicans", Team)) %>%  
    mutate(Team = ifelse(Team == "Bobcats", "Hornets", Team)) %>%

    mutate(Partner = gsub('Braves', 'Clippers', .data$Partner)) %>%
    mutate(Partner = gsub('Bullets', 'Wizards', .data$Partner)) %>%
    mutate(Partner = gsub('Cavalierse', 'Cavaliers', .data$Partner)) %>%
    mutate(Partner = gsub('Clippets', 'Clippers', .data$Partner)) %>%
    mutate(Partner = gsub('Grizzles', 'Grizzlies', .data$Partner)) %>%
    mutate(Partner = gsub('Grizzlines', 'Grizzlies', .data$Partner)) %>%
    mutate(Partner = gsub('Timberwoves', 'Timberwolves', .data$Partner)) %>%
    mutate(Partner = gsub('Sonics', 'Thunder', .data$Partner)) %>%
    mutate(Partner = gsub('\\bBull\\b', 'Bulls', .data$Partner)) %>%
    mutate(Partner = ifelse(Date < lubridate::ymd("2014-05-20"), 
                            gsub('Hornets', 'Pelicans', .data$Partner), 
                            .data$Partner)) %>%
    mutate(Partner = gsub('Bobcats', 'Hornets', .data$Partner)) %>%

  # There is one weird error where the trade says Blazers to Blazers and Kings to Kings
  # and we just need to change it so the partner is replaced by the opposite team.
  mutate(Partner = ifelse(Date == lubridate::ymd("2019-02-07") & 
                            Team == "Blazers" & Partner == "Blazers", 
                            "Kings", .data$Partner)) %>%
  mutate(Partner = ifelse(Date == lubridate::ymd("2019-02-07") & 
                            Team == "Kings" & Partner == "Kings", 
                            "Blazers", .data$Partner)) %>%

  mutate(partner.len = nchar(.data$Partner))
# ----------------------------------------------------------------------------------------
# Create a dataframe that's only the trade date and all parties involved: 
  len.tradepartners <- trade.df$Num.Trade.Partners
  
  trade.df_full <- data.frame(cbind(trade.df,
                                    str_split_fixed(trade.df$Partner, ",", 
                                                    max(len.tradepartners)),
                                    stringsAsFactors = FALSE)) %>%
    mutate_if(is.character, list(~na_if(., ""))) %>%
    select(-Partner, -Num.Trade.Partners, -Notes, -partner.len, -X5, -season) %>%
    rename(Partner1 = Team, Partner2 = X1, Partner3 = X2, 
           Partner4 = X3, Partner5 = X4)
  
  trade.df_full$trade.order.str <- apply(trade.df_full[, 2:6], 1, 
                                         function(x) paste0(sort(trimws(x)), 
                                                            collapse = ','))
# ----------------------------------------------------------------------------------------  
  trade.df_unique <- trade.df_full %>%
    select(Date, trade.order.str) %>%
    separate(trade.order.str, c("P1","P2","P3","P4","P5"), ",") %>%
    unique()
# -------------------------------------------------
  # Create the Combo of every P1 - P5 (10 in total) -
  #  -> To keep things clear, break up groups by starting partner number (i.e. P1, P2,...)
  #  -> Right now keeping it like this to make sure that all combos are done correctly,
  #     could possibly create a function for this and or do this all as creating a
  #     data.frame all in one.
    
# P1 Combos  
  trade.comb1 <- trade.df_unique %>% mutate(trade.id = row_number()) %>%
    select(Date, trade.id, P1, P2)
  trade.comb2 <- trade.df_unique %>% mutate(trade.id = row_number()) %>%
    select(Date, trade.id, P1, P3) %>% rename(P2 = P3) %>% subset(., !is.na(P2))
  trade.comb3 <- trade.df_unique %>% mutate(trade.id = row_number()) %>%
    select(Date, trade.id, P1, P4) %>% rename(P2 = P4) %>% subset(., !is.na(P2))  
  trade.comb4 <- trade.df_unique %>% mutate(trade.id = row_number()) %>%
    select(Date, trade.id, P1, P5) %>% rename(P2 = P5) %>% subset(., !is.na(P2)) 

# P2 Combos  
  trade.comb5 <- trade.df_unique %>% mutate(trade.id = row_number()) %>%
    select(Date, trade.id, P2, P3) %>% rename(P1 = P2, P2 = P3) %>% subset(., !is.na(P2))
  trade.comb6 <- trade.df_unique %>% mutate(trade.id = row_number()) %>%
    select(Date, trade.id, P2, P4) %>% rename(P1 = P2, P2 = P4) %>% subset(., !is.na(P2))  
  trade.comb7 <- trade.df_unique %>% mutate(trade.id = row_number()) %>%
    select(Date, trade.id, P2, P5) %>% rename(P1 = P2, P2 = P5) %>% subset(., !is.na(P2))

# P3 Combos  
  trade.comb8 <- trade.df_unique %>% mutate(trade.id = row_number()) %>%
    select(Date, trade.id, P3, P4) %>% rename(P1 = P3, P2 = P4) %>% subset(., !is.na(P2))
  trade.comb9 <- trade.df_unique %>% mutate(trade.id = row_number()) %>%
    select(Date, trade.id, P3, P5) %>% rename(P1 = P3, P2 = P5) %>% subset(., !is.na(P2))

# P4 Combos
  trade.comb10 <- trade.df_unique %>% mutate(trade.id = row_number()) %>%
    select(Date, trade.id, P4, P5) %>% rename(P1 = P4, P2 = P5) %>% subset(., !is.na(P2))
# -------------------------------------------------
# Combine the other data frames together now to create a long data frame
  trade.df_long <- bind_rows(trade.comb1, trade.comb2, trade.comb3, 
                             trade.comb4, trade.comb5, trade.comb6, 
                             trade.comb7, trade.comb8, trade.comb9,
                             trade.comb10) %>%  arrange(trade.id, P1) %>%
    mutate(season = as.numeric(format(Date, '%Y'))) 
# NOTE: Before was doubling the rename here also, but now that it is changed with the
#       gsub versions then we should not need it from here on.
  
  rm(list = c(paste("trade.comb",c(1:10),sep="")))
    
# Check for the possible errors    
trade.df_long.sub <- subset(trade.df_long, P1 == P2)
  # Remove trade.df_long.sub if empty since it's just here to check for errors.
  rm(trade.df_long.sub)
  
# Remove the Spanish team for right now:
trade.df_long <- subset(trade.df_long, P2 != "Spanish")
# ----------------------------------------------------------------------------------------
save(list = ls(pattern = "trade."), file = "NBA_AnalysisData.RData")
# ----------------------------------------------------------------------------------------
# ----------------------------------------------------------------------------------------  
# ----------------------------------------------------------------------------------------
# ----------------------------------------------------------------------------------------
# ----------------------------------------------------------------------------------------
# COME BACK TO, WAS WORKING ON TRYING TO FIGURE OUT TO KEEP ALL PARTS OF THE TRADES:
#
# len.acq <- sapply(gregexpr("[^\001-\177]", main.df$Acquired), length)
#   main.df$len.acq <- len.acq
# 
# len.rel <- sapply(gregexpr("[^\001-\177]", main.df$Relinquished), length)
#   main.df$len.rel <- len.rel
#   
# # len.nts <- sapply(gregexpr("[^\001-\177]", main.df$Notes), length)
# #   main.df$len.nts <- len.nts  
#   
# main.df2 <- data.frame(cbind(main.df, 
#                              str_split_fixed(main.df$Acquired, 
#                                              "[^\001-\177]",
#                                              max(len.acq)),
#                              str_split_fixed(main.df$Relinquished,
#                                              "[^\001-\177]",
#                                              max(len.rel))),
#                        stringsAsFactors = FALSE)
# 
# cols <- colnames(main.df)
# names(main.df2) <- c(cols,
#                    paste0("Acq",1:max(len.acq)),
#                    paste0("Rel",1:max(len.rel)))
# ----------------------------------------------------------------------------------------  
# ----------------------------------------------------------------------------------------
# ----------------------------------------------------------------------------------------