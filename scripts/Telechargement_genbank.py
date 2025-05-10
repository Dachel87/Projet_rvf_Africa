#!/usr/bin/env python3

import os
from Bio import Entrez, SeqIO

# Configuration de l'email pour Entrez
Entrez.email = "votre.email@exemple.com"  # Remplace par ton email !

# Dossiers
BASE_DIR = os.path.expanduser("~/Bureau/training_ghana/Projet_rvf_Africa")
DATA_DIR = os.path.join(BASE_DIR, "data")
RESULTS_DIR = os.path.join(BASE_DIR, "results")
GENBANK_DIR = os.path.join(RESULTS_DIR, "genbank_files")
FASTA_DIR = os.path.join(RESULTS_DIR, "fasta_L_segments")
METADATA_OUTPUT = os.path.join(RESULTS_DIR, "metadata_clean.tsv")

# Création des dossiers si nécessaire
os.makedirs(GENBANK_DIR, exist_ok=True)
os.makedirs(FASTA_DIR, exist_ok=True)

# Lire les numéros GenBank des séquences complètes en Afrique
metadata_file = os.path.join(DATA_DIR, "metadata.tsv")
accession_list = []
with open(metadata_file, "r") as f:
    header = f.readline().strip().split("\t")
    idx_status = header.index("GenomeStatus")
    idx_country = header.index("IsolationCountry")
    idx_segment = header.index("Segment")
    idx_accession = header.index("GenBank Accessions")

    for line in f:
        parts = line.strip().split("\t")
        status = parts[idx_status].strip().lower()
        country = parts[idx_country].strip().lower()
        segment = parts[idx_segment].strip().upper()
        accession = parts[idx_accession].strip()

        if status == "complete" and "africa" in country.lower():
            accession_list.append((accession, segment))

# Supprimer les doublons
unique_accessions = list(set(accession_list))

print(f"Nombre total d'accessions uniques complètes en Afrique : {len(unique_accessions)}")

# Préparer fichier metadata clean
with open(METADATA_OUTPUT, "w") as meta_out:
    meta_out.write("\t".join(["Accession", "Organism", "Strain", "Segment", "Host", "Country", "CollectionDate", "Product", "ProteinID"]) + "\n")

    l_lengths = []

    for accession, segment in unique_accessions:
        try:
            # Télécharger l'entrée GenBank
            handle = Entrez.efetch(db="nucleotide", id=accession, rettype="gb", retmode="text")
            record = SeqIO.read(handle, "genbank")
            handle.close()

            # Sauvegarder le fichier GenBank
            gb_file = os.path.join(GENBANK_DIR, f"{accession}.gb")
            SeqIO.write(record, gb_file, "genbank")

            # Extraire les champs demandés
            organism = record.annotations.get("organism", "NA")
            strain = record.annotations.get("strain", "NA")
            collection_date = record.annotations.get("collection_date", "NA")
            country = record.annotations.get("country", "NA")
            host = record.annotations.get("host", "NA")

            # Pour chaque feature, chercher produit et protein_id si disponible
            products = []
            protein_ids = []
            for feature in record.features:
                if feature.type == "CDS":
                    product = feature.qualifiers.get("product", ["NA"])[0]
                    protein_id = feature.qualifiers.get("protein_id", ["NA"])[0]
                    products.append(product)
                    protein_ids.append(protein_id)

            product_str = ";".join(products) if products else "NA"
            protein_id_str = ";".join(protein_ids) if protein_ids else "NA"

            # Écrire la ligne metadata
            meta_out.write(f"{accession}\t{organism}\t{strain}\t{segment}\t{host}\t{country}\t{collection_date}\t{product_str}\t{protein_id_str}\n")

            # Si segment L, sauvegarder en fasta et enregistrer la longueur
            if segment == "L":
                fasta_file = os.path.join(FASTA_DIR, f"{accession}.fasta")
                SeqIO.write(record, fasta_file, "fasta")
                l_lengths.append(len(record.seq))

            print(f"Téléchargé et traité : {accession}")

        except Exception as e:
            print(f"Erreur avec {accession} : {e}")

# Calcul de la longueur moyenne des segments L
if l_lengths:
    average_length = sum(l_lengths) / len(l_lengths)
    print(f"\nNombre total de segments L téléchargés : {len(l_lengths)}")
    print(f"Longueur moyenne des segments L : {average_length:.2f} nucléotides")
else:
    print("\nAucun segment L trouvé.")

