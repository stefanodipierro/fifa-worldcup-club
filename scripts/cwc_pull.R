# Script to download and combine data for the FIFA Club World Cup
# This script installs/updates worldfootballR, reads the teams list,
# downloads match results and stats for each team and saves the combined
# data in RDS format under data/out/.

required_pkgs <- c("worldfootballR", "dplyr", "purrr", "readr", "stringr", "lubridate")

# Install or update required packages
installed <- rownames(installed.packages())
for (pkg in required_pkgs) {
  if (!pkg %in% installed) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  } else if (pkg == "worldfootballR") {
    tryCatch({
      install.packages(pkg, repos = "https://cloud.r-project.org")
    }, error = function(e) message("Unable to update worldfootballR: ", e$message))
  }
}

library(worldfootballR)
library(dplyr)
library(purrr)
library(readr)
library(stringr)
library(lubridate)

message("[", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), "] Starting data pull")

teams <- read_csv("data/teams.csv", show_col_types = FALSE)

#' Calculate FBref team URL based on team name and optional country
#' @param team team name as string
#' @param country optional country filter
get_team_url <- function(team, country = NA) {
  urls <- worldfootballR::fb_teams_urls()
  df <- urls %>% filter(str_detect(Squad, fixed(team, ignore_case = TRUE)))
  if (!is.na(country)) {
    df <- df %>% filter(str_detect(Country, fixed(country, ignore_case = TRUE)))
  }
  if (nrow(df) == 0) return(NA_character_)
  df$url[1]
}

teams <- teams %>% mutate(team_url = map2_chr(team, country, get_team_url))

results <- map(teams$team_url, function(url) {
  if (is.na(url)) return(list(matches = NULL, team_stats = NULL,
                              player_stats = NULL, injuries = NULL))
  list(
    matches = tryCatch(fb_match_results(url), error = function(e) NULL),
    team_stats = tryCatch(fb_team_stats(url, stat_type = "standard"), error = function(e) NULL),
    player_stats = tryCatch(fb_player_season_stats(url, stat_type = "standard"), error = function(e) NULL),
    injuries = tryCatch(tm_team_injuries(url), error = function(e) NULL)
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
