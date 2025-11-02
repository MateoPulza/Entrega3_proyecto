 #!/bin/bash
# ============================================================
# Paso 3: Construcción del árbol filogenético con IQ-TREE
# Autor: [Tu nombre]
# Fecha: $(date +"%Y-%m-%d")
# Descripción: Genera un árbol filogenético a partir del
# alineamiento múltiple (MAFFT) del gen de interés.
# ============================================================

set -euo pipefail

# ========= Variables =========
GENE_NAME="yggX"
ALIGNMENT="alineamiento_${GENE_NAME}_results_sinecoli/alineamiento_${GENE_NAME}.fasta"
RESULTS_DIR="iqtree_${GENE_NAME}_results_sinecoli"

# ========= Preparar carpeta =========
mkdir -p "$RESULTS_DIR"
cd "$RESULTS_DIR"

# ========= Ejecución de IQ-TREE =========
echo "🌳 Ejecutando IQ-TREE para el gen ${GENE_NAME}..."
iqtree2 -s "../${ALIGNMENT}" \
        -m MFP \
        -bb 1000 \
        -B 1000 \
        -nt AUTO \
        -pre "arbol_${GENE_NAME}"

# ========= Verificar salida =========
if [ -s "arbol_${GENE_NAME}.treefile" ]; then
    echo "✅ Árbol generado correctamente:"
    echo "$(pwd)/arbol_${GENE_NAME}.treefile"
else
    echo "⚠️ Error: no se generó el archivo del árbol."
    exit 1
fi

# ========= Resumen =========
echo "📊 Archivos generados:"
ls -lh

echo "✨ Siguiente paso: puedes subir el archivo .treefile a iTOL:"
echo "👉 https://itol.embl.de/"
