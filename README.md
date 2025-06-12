# FIFA Club World Cup 2025 Data

This project gathers information related to the 2025 FIFA Club World Cup. The
primary goal is to pull squad data and other statistics from public resources so
that they can be used for further analysis or simple record keeping.

The project is based on R and mainly uses the `worldfootballR` package which
wraps the [FBref](https://fbref.com/en/) data sources.

## Project Overview

The aim of this repository is to analyse teams in the FIFA Club World Cup 2025.
Major activities and expected completion dates are:

1. **Data collection** – June 2025
2. **Data cleaning** – July 2025
3. **Feature engineering** – August 2025
4. **Exploratory data analysis (EDA)** – September 2025
5. **Comparative analysis** – October 2025
6. **Final report** – November 2025


## Dependencies

- R (version 4.0 or later)
- [worldfootballR](https://github.com/JaseZiv/worldfootballR) (GitHub version)
  - The script installs this development version automatically using
    `remotes::install_github`.
- Other common packages used in the script include `dplyr`, `purrr` and
  `readr`

You can install the required packages from the R console with:

```r
install.packages("remotes")
# use the development version for the season_end_year argument
remotes::install_github("JaseZiv/worldfootballR")
install.packages(c("dplyr", "purrr", "readr"))
```

## Running the script

The repository includes a script called `cwc_pull.R` that downloads the data and
writes the results to the `data/out/` directory. To execute the script from the
shell use:

```bash
Rscript scripts/cwc_pull.R
```

By default the script saves an RDS file named `data/out/<timestamp>_big_df.rds`, where `<timestamp>` reflects the execution time. You can adapt the script to change file names or add further transformations as needed.

The script expects a `teams.csv` file inside the `data/` folder with at least
the following columns:

```csv
team,country,league_code
Palmeiras,Brazil,Serie A Brazil
Porto,Portugal,Primeira Liga
```

The `league_code` value is used to build the FBref URL for each team.

## Aggiornamento automatico

Per programmare l'esecuzione periodica di `cwc_pull.R` si può utilizzare
`cron` su sistemi Linux o l'Utilità di pianificazione (Task Scheduler) su
Windows.

### Esempio con cron (Linux)

Modifica il tuo file `crontab` con `crontab -e` e aggiungi una riga simile:

```cron
0 6 * * * Rscript /percorso/assoluto/cwc_pull.R
```

Questo comando avvia lo script ogni giorno alle 6:00 del mattino.

### Esempio con Task Scheduler (Windows)

1. Apri **Utilità di pianificazione** e crea una nuova operazione
   pianificata.
2. Nella sezione **Programma/script** indica il percorso di `Rscript.exe`.
3. Nella sezione **Aggiungi argomenti** inserisci il percorso completo allo
   script `cwc_pull.R`.

I file prodotti sono in formato RDS e vengono salvati nella cartella `data/out/` con un nome come `<timestamp>_big_df.rds`.
