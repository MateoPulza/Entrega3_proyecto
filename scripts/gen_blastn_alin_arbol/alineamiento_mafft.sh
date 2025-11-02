#!/bin/bash
# ============================================================
# Paso 3: Alineamiento múltiple de secuencias con MAFFT
# Autor: [Tu nombre]
# Fecha: $(date +"%Y-%m-%d")
# Descripción: Alinea las secuencias ortólogas del gen con MAFFT
# ============================================================

set -euo pipefail

# 1. Variables generales
GENE_NAME="yggX"
INPUT_FILE="blast_${GENE_NAME}_results_sinecoli/ortologos_${GENE_NAME}_nodup.fasta"
RESULTS_DIR="alineamiento_${GENE_NAME}_results_sinecoli"
OUTFILE="${RESULTS_DIR}/alineamiento_${GENE_NAME}.fasta"
LOGFILE="${RESULTS_DIR}/mafft_${GENE_NAME}.log"

# 2. Verificar existencia del archivo de entrada
if [ ! -s "$INPUT_FILE" ]; then
    echo "⚠️ No se encontró el archivo de entrada: $INPUT_FILE"
    echo "Asegúrate de ejecutar primero el script del Paso 2."
    exit 1
fi

# 3. Crear carpeta de salida
mkdir -p "$RESULTS_DIR"

# 4. Ejecutar MAFFT
echo "🚀 Ejecutando alineamiento múltiple con MAFFT..."
mafft --auto --thread -1 "$INPUT_FILE" > "$OUTFILE" 2> "$LOGFILE"

# --auto  : MAFFT elige el mejor método según el tamaño del dataset
# --thread -1 : Usa todos los núcleos disponibles del procesador

# 5. Validar salida
if [ -s "$OUTFILE" ]; then
    echo "✅ Alineamiento completado exitosamente."
    echo "📁 Archivo de salida: $(pwd)/$OUTFILE"
    echo "🧾 Log del proceso: $(pwd)/$LOGFILE"
else
    echo "⚠️ Error: No se generó el archivo alineado. Revisa el log."
    exit 1
fi

# 6. Resumen
echo "📊 Resumen del alineamiento:"
grep "^>" "$OUTFILE" | wc -l | awk '{print "Número de secuencias alineadas:", $1}'
grep -v "^>" "$OUTFILE" | awk '{chars+=length($0)} END {print "Longitud total alineada:", chars, "pb"}'
