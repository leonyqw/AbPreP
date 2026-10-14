# process the data and collapse by clones

library(readr)
library(tidyr)
library(dplyr)
library(stringr)
library(optparse)

option_list <- list(
    make_option("--keep-cols",    type = "character", help = "Path to BAM file"),
    make_option("--input",    type = "character", help = "Path to GTF file"),
)

opt <- parse_args(OptionParser(option_list = option_list))

cols_keep_path  <- opt$keep_cols
inputs  <- opt$input

# Input and output file path locations
# cols_keep_path <- "/home/users/allstaff/wang.leo/antibody_projects/leon_phd/preprocessing/data/columns_to_keep.csv"
# sequences_path <- "/vast/projects/antibody_sequencing/leon_phd/preprocessing/results/riot/best/"

# Get list of column names to keep
columns_to_keep_df <- read_csv(cols_keep_path)

columns_to_keep <- columns_to_keep_df |>
  filter(flag_keep) |>
  select(variable)

# Combine all heavy chain sequence files together, and keep only required variables
H_chains <- read_csv(
  fs::dir_ls(
    path = inputs,
    glob = "*_heavy.csv"),
  col_select = any_of(columns_to_keep[[1]]), 
  id = "sample") |>
  distinct(sequence_header, .keep_all = TRUE) |>
  # remove path from sample
  mutate(sample = str_replace_all(basename(sample), "_annot_heavy.csv", ""))

# Combine all light chain sequences files together, and keep only required variables
L_chains <- read_csv(
  fs::dir_ls(
    path = inputs,
    glob = "*_light.csv"),
  col_select = any_of(columns_to_keep[[1]]),
  id = "sample") |>
  distinct(sequence_header, .keep_all = TRUE) |>
  # remove path from sample
  mutate(sample = str_replace_all(basename(sample), "_annot_light.csv", ""))

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
  summarise(
    count = n(),
    .by = any_of(colnames(both_chains))) |>
  group_by(sample) |>
  # mutate(cpm = (count / sum(count)) * 1000000) |>
  # arrange(desc(cpm)) |>
  write_csv("sequence_table.csv")

## Add to new analysis script for aim 2?
# # table of most common amino acid sequence for each clone 
# both_chains |>
# # collapse into clones
#   filter(productive_H & productive_L) |>
#   filter(cdr3_aa_H != cdr3_aa_L) |>
#   mutate(v_call_L = str_remove(v_call_L, "\\*.*$"),
#            v_call_H = str_remove(v_call_H, "\\*.*$")) |>
#   #filter(nchar(sequence_aa_L) > 75, nchar(sequence_aa_H) > 90) |>
#   summarise(count = n(), 
#             .by = c(cdr3_aa_H, cdr3_aa_L, v_call_H, v_call_L, sequence_aa_L, sequence_aa_H)) |>
#   summarise(
#     sequence_aa_L = sequence_aa_L[which.max(count)],
#     sequence_aa_H = sequence_aa_H[which.max(count)], 
#     .by = c(cdr3_aa_H, cdr3_aa_L, v_call_H, v_call_L)) |>
#   write_csv()