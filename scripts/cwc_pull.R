# Script to download and combine data for the FIFA Club World Cup
# This script installs/updates worldfootballR, reads the teams list,
# downloads match results and stats for each team and saves the combined
# data in RDS format under data/out/.

required_pkgs <- c("worldfootballR", "dplyr", "purrr", "readr", "stringr", "lubridate", "rvest")

# Install or update required packages
installed <- rownames(installed.packages())
if (!"remotes" %in% installed) {
  install.packages("remotes", repos = "https://cloud.r-project.org")
}
for (pkg in required_pkgs) {
  if (!pkg %in% installed) {
    if (pkg == "worldfootballR") {
      remotes::install_github("JaseZiv/worldfootballR")
    } else {
      install.packages(pkg, repos = "https://cloud.r-project.org")
    }
  }
}

library(worldfootballR)
library(dplyr)
library(purrr)
library(readr)
library(stringr)
library(lubridate)
library(rvest)

message("[", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), "] Starting data pull")

teams <- read_csv("data/teams.csv", show_col_types = FALSE)

#' Calculate FBref team URL based on team name and optional country
#' @param team team name as string
#' @param country optional country filter
get_team_url <- function(team, country = NA, league_code = NA) {
  urls <- NULL
  if (!is.na(league_code) && !is.na(country)) {
    # obtain league URLs for the specified season and country
    lg_urls <- tryCatch(
      worldfootballR::fb_league_urls(
        country = country,
        gender = "M",
        season_end_year = 2025
      ),
      error = function(e) NULL
    )
    if (!is.null(lg_urls) && length(lg_urls) > 0) {
      # filter by league name if multiple leagues returned
      lg_url <- lg_urls[stringr::str_detect(lg_urls, league_code)][1]
      if (is.na(lg_url)) lg_url <- lg_urls[1]
      urls <- worldfootballR::fb_teams_urls(lg_url)
    }
  }
  if (is.null(urls)) {
    urls <- worldfootballR::fb_teams_urls(season_end_year = 2025)
  }
  df <- urls %>% filter(str_detect(Squad, fixed(team, ignore_case = TRUE)))
  if (!is.na(country)) {
    df <- df %>% filter(str_detect(Country, fixed(country, ignore_case = TRUE)))
  }
  if (nrow(df) == 0) return(NA_character_)
  df$url[1]
}

#' Get Transfermarkt team URL from team name by scraping the search page
#' @param team team name as string
get_tm_team_url <- function(team) {
  search_url <- paste0(
    "https://www.transfermarkt.com/schnellsuche/ergebnis/schnellsuche?query=",
    utils::URLencode(team)
  )
  page <- tryCatch(rvest::read_html(search_url), error = function(e) NULL)
  if (is.null(page)) return(NA_character_)
  links <- rvest::html_attr(rvest::html_elements(page, "a"), "href")
  path <- links[grepl("/startseite/verein/", links)][1]
  if (is.na(path)) return(NA_character_)
  paste0("https://www.transfermarkt.com", path)
}

if ("league_code" %in% names(teams)) {
  teams <- teams %>% mutate(
    team_url = purrr::pmap_chr(list(team, country, league_code), get_team_url),
    tm_url = purrr::map_chr(team, get_tm_team_url)
  )
} else {
  teams <- teams %>% mutate(
    team_url = purrr::map2_chr(team, country, get_team_url),
    tm_url = purrr::map_chr(team, get_tm_team_url)
  )
}

results <- map(seq_len(nrow(teams)), function(i) {
  fb_url <- teams$team_url[i]
  tm_url <- teams$tm_url[i]
  if (is.na(fb_url)) {
    return(list(matches = NULL, team_stats = NULL,
                player_stats = NULL, injuries = NULL))
  }
  list(
    matches = tryCatch(fb_match_results(fb_url), error = function(e) NULL),
    team_stats = tryCatch(fb_team_stats(fb_url, stat_type = "standard"), error = function(e) NULL),
    player_stats = tryCatch(fb_player_season_stats(fb_url, stat_type = "standard"), error = function(e) NULL),
    injuries = if (is.na(tm_url)) NULL else tryCatch(tm_team_injuries(tm_url), error = function(e) NULL)
  )
})

names(results) <- teams$team

big_df <- map_df(seq_along(results), function(i) {
  r <- results[[i]]
  team <- teams$team[i]
  n_matches <- if (is.null(r$matches)) 0 else nrow(r$matches)
  message("Downloaded ", n_matches, " matches for ", team)
  tibble(team = team,
         matches = list(r$matches),
         team_stats = list(r$team_stats),
         player_stats = list(r$player_stats),
         injuries = list(r$injuries))
})

total_matches <- sum(map_int(big_df$matches, ~ if (is.null(.x)) 0 else nrow(.x)))
message("Total matches downloaded: ", total_matches)

stamp <- format(Sys.time(), "%Y%m%d_%H%M%S")
out_file <- file.path("data", "out", paste0(stamp, "_big_df.rds"))
dir.create(dirname(out_file), showWarnings = FALSE, recursive = TRUE)
saveRDS(big_df, out_file)

message("[", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), "] Finished data pull. Saved to ", out_file)
