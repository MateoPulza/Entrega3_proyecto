#!/bin/bash
# ============================================================
# Paso 2: Búsqueda de ortólogos del gen yggX en otras bacterias
# ============================================================

GENE_NAME="yggX"
QUERY="gene_${GENE_NAME}_ecoli_sinecoli/${GENE_NAME}_ecoli.fna"
RESULTS_DIR="blast_${GENE_NAME}_results_sinecoli"
OUTFILE="${RESULTS_DIR}/${GENE_NAME}_blast.tsv"
FASTA_REGIONS="${RESULTS_DIR}/ortologos_${GENE_NAME}.fasta"
FASTA_NODUP="${RESULTS_DIR}/ortologos_${GENE_NAME}_nodup.fasta"

mkdir -p "$RESULTS_DIR"

# ------------------------------------------------------------
# 1. Ejecutar BLASTN remoto
# ------------------------------------------------------------
echo "🚀 Ejecutando BLASTN para ${GENE_NAME}..."
blastn -query "$QUERY" -db nt \
       -remote \
       -entrez_query "Bacteria[Organism] NOT (Escherichia[Organism] OR Shigella[Organism])" \
       -outfmt "6 qseqid sseqid pident length mismatch gapopen qstart qend sstart send evalue bitscore stitle" \
       -evalue 1e-3 \
       -max_target_seqs 40 \
       -out "$OUTFILE"


if [ ! -s "$OUTFILE" ]; then
    echo "⚠️ No se obtuvieron resultados. Revisa conexión o archivo de entrada."
    exit 1
fi

echo "✅ BLAST completado: $(pwd)/$OUTFILE"

# ------------------------------------------------------------
# 2. Descargar las regiones ortólogas (solo fragmentos alineados)
# ------------------------------------------------------------
echo "📥 Descargando regiones ortólogas alineadas..."
> "$FASTA_REGIONS"  # Limpia archivo anterior si existe

# Extrae solo las columnas necesarias: sseqid, sstart, send
awk '{print $2, $9, $10}' "$OUTFILE" | while read sseqid sstart send; do
  if [ -n "$sseqid" ] && [ -n "$sstart" ] && [ -n "$send" ]; then
    if [ "$sstart" -lt "$send" ]; then
      efetch -db nucleotide -id "$sseqid" -seq_start "$sstart" -seq_stop "$send" -format fasta >> "$FASTA_REGIONS"
    else
      efetch -db nucleotide -id "$sseqid" -seq_start "$send" -seq_stop "$sstart" -format fasta >> "$FASTA_REGIONS"
    fi
  fi
done

if [ ! -s "$FASTA_REGIONS" ]; then
    echo "⚠️ No se descargaron secuencias ortólogas. Revisa las IDs del BLAST."
    exit 1
fi

echo "✅ Descarga completada: $(pwd)/$FASTA_REGIONS"

# ------------------------------------------------------------
# 3. Eliminar secuencias duplicadas con seqtk
# ------------------------------------------------------------
echo "🧹 Eliminando secuencias duplicadas..."
seqtk seq "$FASTA_REGIONS" \
  | awk '/^>/ {if(seen[$0]++) next} {print}' > "$FASTA_NODUP"

if [ ! -s "$FASTA_NODUP" ]; then
    echo "⚠️ El archivo sin duplicados está vacío. Revisa el contenido del original."
    exit 1
fi

echo "✅ Limpieza completada. Archivo final:"
ls -lh "$FASTA_NODUP"
echo "🎯 Proceso finalizado correctamente."
