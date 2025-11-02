#!/bin/bash
# ============================================================
# Paso 4: Construcción del árbol filogenético con IQ-TREE
# Autor: [Tu nombre]
# Fecha: $(date +"%Y-%m-%d")
# Descripción:
#   - Toma el alineamiento múltiple generado por MAFFT
#   - Realiza un trimming automático con trimAl
#   - Construye el árbol filogenético con IQ-TREE2
# ============================================================

set -euo pipefail

# ========= Variables =========
GENE_NAME="yggX"
ALIGNMENT="alineamiento_${GENE_NAME}_results/alineamiento_${GENE_NAME}.fasta"
RESULTS_DIR="iqtree_${GENE_NAME}_results"
TRIMMED_ALIGNMENT="${RESULTS_DIR}/alineamiento_${GENE_NAME}_trimmed.fasta"
LOGFILE="${RESULTS_DIR}/iqtree_${GENE_NAME}.log"

# ========= Verificación del archivo de entrada =========
if [ ! -s "$ALIGNMENT" ]; then
    echo "⚠️ No se encontró el alineamiento: $ALIGNMENT"
    echo "Asegúrate de ejecutar primero el script de alineamiento."
    exit 1
fi

# ========= Preparar carpeta =========
mkdir -p "$RESULTS_DIR"

# ========= Trimming automático con trimAl =========
echo "✂️  Eliminando regiones mal alineadas con trimAl..."
trimal -automated1 -in "$ALIGNMENT" -out "$TRIMMED_ALIGNMENT"

if [ ! -s "$TRIMMED_ALIGNMENT" ]; then
    echo "⚠️ Error: trimAl no generó el archivo recortado."
    exit 1
fi

echo "✅ Archivo recortado generado: $TRIMMED_ALIGNMENT"

# ========= Ejecución de IQ-TREE =========
echo "🌳 Ejecutando IQ-TREE para el gen ${GENE_NAME}..."
iqtree2 -s "$TRIMMED_ALIGNMENT" \
        -m MFP \
        -bb 1000 \
        -B 1000 \
        -nt AUTO \
        -pre "${RESULTS_DIR}/arbol_${GENE_NAME}" \
        > "$LOGFILE" 2>&1

# ========= Verificar salida =========
TREE_FILE="${RESULTS_DIR}/arbol_${GENE_NAME}.treefile"

if [ -s "$TREE_FILE" ]; then
    echo "✅ Árbol generado correctamente:"
    echo "📄 Archivo: $(realpath "$TREE_FILE")"
else
    echo "⚠️ Error: no se generó el archivo del árbol. Revisa el log: $LOGFILE"
    exit 1
fi

# ========= Resumen =========
echo "📊 Archivos generados:"
ls -lh "$RESULTS_DIR"

echo "🧾 Log guardado en: $LOGFILE"
echo "✨ Siguiente paso: puedes visualizar el árbol en iTOL:"
echo "👉 https://itol.embl.de/"
