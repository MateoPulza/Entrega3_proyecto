#!/bin/bash
# ============================================================
# Paso 3: Alineamiento múltiple de secuencias ortólogas (proteína YggX)
# Autor: Mate Pulgarín
# Fecha: $(date +"%Y-%m-%d")
# Descripción:
#   - Descarga las secuencias proteicas ortólogas identificadas por BLASTp
#   - Elimina duplicados
#   - Añade la secuencia original (E. coli)
#   - Realiza un alineamiento múltiple con MAFFT
# ============================================================

set -euo pipefail

# 1. Variables generales
GENE_NAME="yggX"
BLAST_RESULTS="blastp_${GENE_NAME}_results/${GENE_NAME}_blastp_filtered.tsv"
FASTA_IN="blastp_${GENE_NAME}_results/${GENE_NAME}_blastp_filtered_nodup_renamed.faa"
DEDUP_FASTA="${GENE_NAME}_orthologs_nodup.faa"
RESULTS_DIR="alineamiento_${GENE_NAME}_results"
ALN_OUT="${RESULTS_DIR}/alineamiento_${GENE_NAME}.fasta"
LOGFILE="${RESULTS_DIR}/mafft_${GENE_NAME}.log"
QUERY_FILE="gene_${GENE_NAME}_ecoli_prot/${GENE_NAME}_ecoli.faa"
MERGED_FASTA="${GENE_NAME}_orthologs_con_query.faa"

# 2. Verificar existencia del archivo de resultados filtrados
if [ ! -s "$BLAST_RESULTS" ]; then
    echo "⚠️ No se encontró el archivo filtrado: $BLAST_RESULTS"
    echo "Asegúrate de ejecutar primero el script de BLASTp."
    exit 1
fi

# 3. Crear carpeta de salida
mkdir -p "$RESULTS_DIR"

# 4. Descargar secuencias proteicas de los accesos del BLAST filtrado
echo "🔽 Descargando secuencias proteicas ortólogas desde NCBI..."
cut -f2 "$BLAST_RESULTS" | grep -o "WP_[0-9]\+\.[0-9]\+" | sort -u > blastp_${GENE_NAME}_results/accessions.txt

ACCESS_FILE="blastp_${GENE_NAME}_results/accessions.txt"
NUM=$(wc -l < "$ACCESS_FILE")
if [ "$NUM" -eq 0 ]; then
    echo "⚠️ No se encontraron accesos en $BLAST_RESULTS"
    exit 1
fi
echo "✅ Se encontraron $NUM accesos únicos."
head "$ACCESS_FILE"

# Descargar secuencias desde NCBI
echo "🧬 Descargando secuencias de aminoácidos..."
ID_LIST=$(tr '\n' ',' < "$ACCESS_FILE" | sed 's/,$//')
efetch -db protein -format fasta -id "$ID_LIST" > "$FASTA_IN"

# 5. Eliminar duplicados exactos (si existen)
echo "🧹 Eliminando secuencias idénticas (CD-HIT 100%)..."
cd-hit -i "$FASTA_IN" -o "$DEDUP_FASTA" -c 1.00 -n 5 -d 0 -T 0 -M 16000 > /dev/null

# === 🚀 NUEVO BLOQUE: Añadir la secuencia original (query) ===
if [ -s "$QUERY_FILE" ]; then
    echo "➕ Añadiendo la secuencia original (${GENE_NAME}) al conjunto..."
    cat "$QUERY_FILE" "$DEDUP_FASTA" > "$MERGED_FASTA"
    FINAL_FASTA="$MERGED_FASTA"
else
    echo "⚠️ No se encontró la secuencia original (${QUERY_FILE}), se usará solo el set de ortólogos."
    FINAL_FASTA="$DEDUP_FASTA"
fi
# =============================================================

# 6. Ejecutar MAFFT
echo "🚀 Ejecutando alineamiento múltiple con MAFFT..."
mafft --auto --thread -1 "$FINAL_FASTA" > "$ALN_OUT" 2> "$LOGFILE"

# 7. Validar salida
if [ -s "$ALN_OUT" ]; then
    echo "✅ Alineamiento completado exitosamente."
    echo "📁 Archivo de salida: $(pwd)/$ALN_OUT"
    echo "🧾 Log del proceso: $(pwd)/$LOGFILE"
else
    echo "⚠️ Error: No se generó el archivo alineado. Revisa el log."
    exit 1
fi

# 8. Resumen del alineamiento
echo "📊 Resumen del alineamiento:"
grep "^>" "$ALN_OUT" | wc -l | awk '{print "Número de secuencias alineadas:", $1}'
grep -v "^>" "$ALN_OUT" | awk '{chars+=length($0)} END {print "Longitud total alineada:", chars, "aa"}'

# 9. Verificar inclusión del query
grep "NP_417437.1" "$ALN_OUT" >/dev/null && \
    echo "✅ La secuencia query NP_417437.1 fue incluida correctamente." || \
    echo "⚠️ Advertencia: la query NP_417437.1 no se encuentra en el alineamiento."

echo "🎯 Proceso finalizado correctamente."
