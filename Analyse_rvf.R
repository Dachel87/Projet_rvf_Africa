#!/usr/bin/env Rscript

# Charger les librairies

library(tidyverse)

# Définir les chemins
base_dir <- "~/Bureau/training_ghana/Projet_rvf_Africa"
data_dir <- file.path(base_dir, "data")
results_dir <- file.path(base_dir, "results")
output_file <- file.path(results_dir, "metadata_cleaned.tsv")
summary_report <- file.path(results_dir, "rapport_resume_R.txt")

# Lire les données
metadata <- read_tsv(file.path(data_dir, "metadata.tsv"), show_col_types = FALSE)

# Nettoyage : enlever les entrées sans date ou sans pays
cleaned_data <- metadata %>%
  filter(!is.na(CollectionDate), !is.na(IsolationCountry), CollectionDate != "", IsolationCountry != "")

# Sauvegarder les données filtrées
write_tsv(cleaned_data, output_file)

# Ajouter une colonne région (simple exemple basé sur les pays africains)
cleaned_data <- cleaned_data %>%
  mutate(region = case_when(
    IsolationCountry %in% c("Kenya", "Sudan", "Uganda", "Tanzania") ~ "East Africa",
    IsolationCountry %in% c("Nigeria", "Ghana", "Senegal") ~ "West Africa",
    IsolationCountry %in% c("South Africa", "Namibia") ~ "Southern Africa",
    TRUE ~ "Other"
  ))

# Renommer CollectionYear en year
cleaned_data <- cleaned_data %>%
  rename(year = CollectionYear)

# Résumer nombre de séquences par pays, année, segment
summary_country_year_segment <- cleaned_data %>%
  group_by(IsolationCountry, year, Segment) %>%
  summarise(n_sequences = n(), .groups = "drop")

# Compter le nombre de séquences par nom commun d’hôte
count_by_host <- cleaned_data %>%
  count(`Host Common Name`, sort = TRUE)

# Filtrer certains pays, années, segments (exemple : Kenya, 2007, segment L)
filtered_records <- cleaned_data %>%
  filter(IsolationCountry == "Kenya", year == 2007, Segment == "L")

# Pays avec le plus de séquences complètes (peu importe le segment)
top_countries <- cleaned_data %>%
  filter(GenomeStatus == "Complete") %>%
  count(IsolationCountry, sort = TRUE)

# Hôtes les plus fréquents
top_hosts <- count_by_host %>%
  top_n(5, n)

# Générer le résumé texte
sink(summary_report)
cat("=== RAPPORT R : Analyse des données RVF ===\n\n")
cat("Nombre total de séquences après nettoyage : ", nrow(cleaned_data), "\n\n")

cat("== Séquences par pays, année, segment ==\n")
print(summary_country_year_segment)

cat("\n== Nombre de séquences par nom commun d'hôte ==\n")
print(count_by_host)

cat("\n== Pays avec le plus de séquences complètes ==\n")
print(top_countries)

cat("\n== Top 5 des hôtes les plus fréquents ==\n")
print(top_hosts)

cat("\n== Extrait des enregistrements filtrés (Kenya, 2007, segment L) ==\n")
print(filtered_records)
sink()

cat("\nRésumé généré dans : ", summary_report, "\n")

