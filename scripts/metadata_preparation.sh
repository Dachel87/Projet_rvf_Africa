#!/bin/bash

# Définir les dossiers
BASE_DIR="$HOME/projet_phlebovirus"
DATA_DIR="$BASE_DIR/data"
SCRIPTS_DIR="$BASE_DIR/scripts"
RESULTS_DIR="$BASE_DIR/results"

# Créer les dossiers si nécessaire
mkdir -p "$DATA_DIR" "$SCRIPTS_DIR" "$RESULTS_DIR"

# Nom du fichier source et du fichier résultat
FICHIER_METADATA="$DATA_DIR/metadata.tsv"
FICHIER_RESULTAT="$RESULTS_DIR/analyse_resume.txt"

# Vérifier la présence du fichier metadata
if [[ ! -f "$FICHIER_METADATA" ]]; then
    echo "Erreur : fichier $FICHIER_METADATA introuvable."
    exit 1
fi

echo "Analyse des métadonnées commencée..."
echo "Les résultats seront enregistrés dans : $FICHIER_RESULTAT"
echo

# Initialiser le fichier résultat
echo "Résumé de l'analyse des métadonnées" > "$FICHIER_RESULTAT"
echo "===================================" >> "$FICHIER_RESULTAT"
echo "Date : $(date)" >> "$FICHIER_RESULTAT"
echo >> "$FICHIER_RESULTAT"

# Compter les numéros GenBank uniques (colonne 5)
NB_UNIQUE=$(tail -n +2 "$FICHIER_METADATA" | cut -f5 | sort | uniq | wc -l)
echo "Nombre de numéros d'accession GenBank uniques : $NB_UNIQUE" | tee -a "$FICHIER_RESULTAT"

# Compter les séquences complètes et partielles (colonne 2)
NB_COMPLETE=$(awk -F'\t' 'NR>1 && $2 ~ /Complete/i' "$FICHIER_METADATA" | wc -l)
NB_PARTIAL=$(awk -F'\t' 'NR>1 && $2 ~ /Partial/i' "$FICHIER_METADATA" | wc -l)
echo "Nombre de séquences complètes : $NB_COMPLETE" | tee -a "$FICHIER_RESULTAT"
echo "Nombre de séquences partielles : $NB_PARTIAL" | tee -a "$FICHIER_RESULTAT"

# Compter les segments S, L, M (colonne 4)
NB_S=$(awk -F'\t' 'NR>1 && $4 == "S"' "$FICHIER_METADATA" | wc -l)
NB_L=$(awk -F'\t' 'NR>1 && $4 == "L"' "$FICHIER_METADATA" | wc -l)
NB_M=$(awk -F'\t' 'NR>1 && $4 == "M"' "$FICHIER_METADATA" | wc -l)
echo "Nombre de segments S : $NB_S" | tee -a "$FICHIER_RESULTAT"
echo "Nombre de segments L : $NB_L" | tee -a "$FICHIER_RESULTAT"
echo "Nombre de segments M : $NB_M" | tee -a "$FICHIER_RESULTAT"

# Combiner segment + complétude
NB_S_COMPLETE=$(awk -F'\t' 'NR>1 && $4 == "S" && $2 ~ /Complete/i' "$FICHIER_METADATA" | wc -l)
NB_L_COMPLETE=$(awk -F'\t' 'NR>1 && $4 == "L" && $2 ~ /Complete/i' "$FICHIER_METADATA" | wc -l)
NB_M_COMPLETE=$(awk -F'\t' 'NR>1 && $4 == "M" && $2 ~ /Complete/i' "$FICHIER_METADATA" | wc -l)
echo "Nombre de segments S complets : $NB_S_COMPLETE" | tee -a "$FICHIER_RESULTAT"
echo "Nombre de segments L complets : $NB_L_COMPLETE" | tee -a "$FICHIER_RESULTAT"
echo "Nombre de segments M complets : $NB_M_COMPLETE" | tee -a "$FICHIER_RESULTAT"

echo
echo "Analyse terminée. Résultats enregistrés dans : $FICHIER_RESULTAT"

