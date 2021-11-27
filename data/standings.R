# Download standings

library(tidyverse)
library(glue)
library(xml2)
library(rvest)
library(stringi)
library(labelled)

base_url <- "https://www.basketball-reference.com/leagues"
years <- 1976:2019 # Season (year-1)-year
urls <- glue("{base_url}/NBA_{years}.html")
cat(urls, file=here::here("data", "fetchlist.txt"), sep="\n")

# NOW execute `data/fetch.sh` to wget all the pages and save them to
# `data/standings` folder. What follows assumes that they are there.

# List of downloaded files
fnames <- list.files(
  here::here("data", "standings"),
  "^NBA_[0-9]{4}\\.html",
  full.names = TRUE
)

# Extract division standings ----------------------------------------------

# Names of numerical columns
numcols <- c("W", "L", "W/L%", "GB", "PS/G", "PA/G", "SRS")

east <- fnames %>%
  lapply(read_html, options=c("RECOVER", "NOERROR", "NOBLANKS", "NONET") ) %>%
  lapply(html_node, css="table#divs_standings_E") %>%
  lapply(html_table, fill=TRUE) %>%
  bind_rows(.id="id_season") %>%
  rename(
    team = `Eastern Conference`
  ) %>%
  mutate(
    is_division_header = grepl("Division", team),
    division = mbtools::carryover(ifelse(is_division_header, team, as.character(NA)))
  ) %>%
  filter(!is_division_header) %>%
  mutate(
    file = basename(fnames)[as.numeric(id_season)],
    season_to = as.numeric(stri_extract_first_regex(file, "[0-9]{4}")),
    season_from = season_to - 1,
    in_playoffs = grepl("\\*", team),
    standing = as.integer(stri_extract_last_regex(team, "(?<=\\()[0-9]+(?=\\))")),
    full_team_name = stri_extract_first_regex(team, "\\b[A-Za-z0-9 ]+(?=\\*?)\\b"),
    conference = "Eastern"
  ) %>%
  select(
    season_from,
    season_to,
    division,
    standing,
    full_team_name,
    one_of(numcols)
  ) %>%
  mutate_at(
    numcols,
    ~ as.numeric(recode(., "—"=as.character(NA)))
  )

west <- fnames %>%
  lapply(read_html, options=c("RECOVER", "NOERROR", "NOBLANKS", "NONET") ) %>%
  lapply(html_node, css="table#divs_standings_W") %>%
  lapply(html_table, fill=TRUE) %>%
  bind_rows(.id="id_season") %>%
  rename(
    team = `Western Conference`
  ) %>%
  mutate(
    is_division_header = grepl("Division", team),
    division = mbtools::carryover(ifelse(is_division_header, team, as.character(NA)))
  ) %>%
  filter(!is_division_header) %>%
  mutate(
    file = basename(fnames)[as.numeric(id_season)],
    season_to = as.numeric(stri_extract_first_regex(file, "[0-9]{4}")),
    season_from = season_to - 1,
    in_playoffs = grepl("\\*", team),
    standing = as.integer(stri_extract_last_regex(team, "(?<=\\()[0-9]+(?=\\))")),
    full_team_name = stri_extract_first_regex(team, "\\b[A-Za-z0-9 ]+(?=\\*?)\\b"),
    conference = "Eastern"
  ) %>%
  select(
    season_from,
    season_to,
    division,
    standing,
    full_team_name,
    one_of(numcols)
  ) %>%
  mutate_at(
    numcols,
    ~ as.numeric(recode(., "—"=as.character(NA)))
  )




standings <- bind_rows(east, west) %>%
  as_tibble()

# Add variable labels based on tooltips (shits and giggles...)
ch <- read_html(fnames[1]) %>%
  html_node("#divs_standings_E > thead:nth-child(3) > tr:nth-child(1)") %>%
  html_children()
vl <- structure(
  as.list(html_attr(ch, "data-tip")),
  names = html_text(ch)
)[-1]
var_label(standings)  <- vl


saveRDS(standings, file=here::here("data", "standings.rds"))



# Extract team stats per game ---------------------------------------------

stats_per_game <- fnames %>%
  lapply(read_html, options=c("RECOVER", "NOERROR", "NOBLANKS", "NONET")) %>%
  lapply(html_nodes, xpath="//comment()") %>%
  lapply(html_text) %>%
  lapply(paste, collapse="") %>%
  lapply(read_html, options=c("RECOVER", "NOERROR", "NOBLANKS", "NONET")) %>%
  lapply(html_node, css="table#team-stats-per_game") %>%
  lapply(html_table) %>%
  bind_rows(.id=".id_season") %>%
  as_tibble() %>%
  filter(!is.na(Rk)) %>% # Season averages
  mutate(
    .file = basename(fnames)[as.numeric(.id_season)],
    season_to = as.numeric(stri_extract_first_regex(.file, "[0-9]{4}")),
    season_from = season_to - 1,
    season = paste0(season_from, "-", season_to),
    in_playoffs = grepl("\\*", Team),
    full_team_name = gsub("\\*", "", Team),
    team_acronym = stri_extract_last_regex(full_team_name, "\\b[[:alnum:]]+\\b")
  ) %>%
  select(
    season,
    team_acronym,
    full_team_name,
    everything(),
    - matches("^\\."),
    - Team,
  )


# Variable labels
ch <- read_html(fnames[1], options=c("RECOVER", "NOERROR", "NOBLANKS", "NONET")) %>%
  html_nodes(xpath="//comment()") %>%
  html_text() %>%
  paste(collapse="") %>%
  read_html(options=c("RECOVER", "NOERROR", "NOBLANKS", "NONET")) %>%
  html_node("#team-stats-per_game > thead:nth-child(3) > tr:nth-child(1)") %>%
  html_children()
vl <- structure(
  as.list(html_attr(ch, "data-tip")),
  names = html_text(ch)
)[-(1:2)]
var_label(stats_per_game)  <- vl


saveRDS(stats_per_game, file=here::here("data", "stats_per_game.rds"))