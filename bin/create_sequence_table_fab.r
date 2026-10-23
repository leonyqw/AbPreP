#!/usr/bin/env Rscript

# Process the heavy (and light chain) outputs from riot ,and summarises counts per VH-VL clone pair.

################################################
## LOAD LIBRARIES                             ##
################################################

library(readr)
library(tidyr)
library(dplyr)
library(stringr)
library(optparse)
library(fs)

################################################
## PARSE COMMAND-LINE PARAMETERS              ##
################################################

option_list <- list(
    make_option("--keep_cols", type = "character", metavar="path", help = "Path to files for columns to keep"),
    make_option("--input", type = "character", metavar="path", help = "Path to heavy and light chain files")
)

opt <- parse_args(OptionParser(option_list = option_list))
cols_keep_path  <- opt$keep_cols
files  <- opt$input

################################################
## READ IN FILES.                             ##
################################################

# Get list of column names to keep
columns_to_keep_df <- read_csv(cols_keep_path)
columns_to_keep <- columns_to_keep_df |>
  filter(flag_keep) |>
  select(variable)

################################################
## CREATE COUNTS MATRIX                       ##
################################################

# Combine all heavy chain sequence files together, and keep only required variables
H_chains <- read_csv(
  dir_ls(
    path = files,
    glob = "*_heavy.csv"),
  col_select = any_of(columns_to_keep[[1]]), 
  id = "sample") |>
  distinct(sequence_header, .keep_all = TRUE) |>
  # remove path from sample
  mutate(sample = str_replace_all(basename(sample), "(_\\d+)?_annot_heavy\\.csv", ""))

# Combine all light chain sequences files together, and keep only required variables
L_chains <- read_csv(
  dir_ls(
    path = files,
    glob = "*_light.csv"),
  col_select = any_of(columns_to_keep[[1]]),
  id = "sample") |>
  distinct(sequence_header, .keep_all = TRUE) |>
  # remove path from sample
  mutate(sample = str_replace_all(basename(sample), "(_\\d+)?_annot_light\\.csv", ""))

# combine the H and L chains
both_chains <- full_join(H_chains, L_chains, by = "sequence_header", 
                         suffix = c("_H", "_L"), 
                         relationship = "one-to-one") |>
  mutate(sample = sample_H) |>
  select(-c(sample_H, sample_L)) |>
  filter(!is.na(sample)) |> 
  relocate(sample)

# create the per sequence clone table of only productive sequences
both_chains |>
# collapse into clones
  filter(productive_H & productive_L) |>
  filter(cdr3_aa_H != cdr3_aa_L) |> # Remove sequences where HCDR3 & LCDR3 are the same
  select(-c(sequence_header, productive_H, productive_L, complete_vdj_H, complete_vdj_L)) |> 
  count(across(everything()), name = "count") |> 
  # summarise(
    # count = n(),
    # .by = any_of(colnames(both_chains))) |>
  # group_by(sample) |>
  # mutate(cpm = (count / sum(count)) * 1000000) |>
  # arrange(desc(cpm)) |>
  write_csv("counts_matrix.csv")
  
################################################
## R SESSION INFO                             ##
################################################

RLogFile <- "R_sessionInfo.log"

sink(RLogFile)
a <- sessionInfo()
print(a)
sink()

################################################
################################################