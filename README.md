# FIFA Club World Cup 2025 Data

This project gathers information related to the 2025 FIFA Club World Cup. The
primary goal is to pull squad data and other statistics from public resources so
that they can be used for further analysis or simple record keeping.

The project is based on R and mainly uses the `worldfootballR` package which
wraps the [FBref](https://fbref.com/en/) data sources.

## Dependencies

- R (version 4.0 or later)
- [worldfootballR](https://github.com/JaseZiv/worldfootballR)
- Other common packages used in the script include `dplyr`, `purrr` and
  `readr`

You can install the required packages from the R console with:

```r
install.packages(c("worldfootballR", "dplyr", "purrr", "readr"))
```

## Running the script

The repository includes a script called `cwc_pull.R` that downloads the data and
writes the results to the `data/` directory. To execute the script from the
shell use:

```bash
Rscript cwc_pull.R
```

By default the generated data will be saved under `data/cwc_squads.csv`. You can
adapt the script to change file names or add further transformations as needed.
