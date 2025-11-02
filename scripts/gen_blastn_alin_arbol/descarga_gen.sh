#!/bin/bash
# ============================================================
# Pipeline: Descarga del gen yggX (E. coli K-12 MG1655)
# Autor: [Tu nombre]
# Fecha: $(date +"%Y-%m-%d")
# Descripción: Crea una carpeta, descarga el gen yggX desde NCBI
#              y verifica la descarga.
# ============================================================

# 1. Configuración
GENE_NAME="yggX"
OUTPUT_DIR="gene_${GENE_NAME}_ecoli_sinecoli"
FASTA_FILE="${GENE_NAME}_ecoli.fna"

# Enlace directo del gen (NC_000913.3 rango 3104093..3104368)
# Puedes verificar este rango en la página de NCBI
FASTA_URL="https://www.ncbi.nlm.nih.gov/sviewer/viewer.cgi?id=NC_000913.3&db=nuccore&report=fasta&from=3104093&to=3104368&strand=true"

# 2. Crear carpeta de salida
mkdir -p "$OUTPUT_DIR"
cd "$OUTPUT_DIR"

# 3. Descargar secuencia FASTA
echo "🔽 Descargando gen ${GENE_NAME} de Escherichia coli (K-12 MG1655)..."
curl -L "$FASTA_URL" -o "$FASTA_FILE"

# 4. Verificar contenido
if [ -s "$FASTA_FILE" ]; then
    echo "✅ Descarga completada correctamente."
    echo "📂 Archivo guardado en: $(pwd)/$FASTA_FILE"
else
    echo "⚠️ Error: No se descargó el archivo o está vacío."
    exit 1
fi

# 5. Mostrar información básica
echo "📊 Información del archivo:"
wc -l "$FASTA_FILE"
wc -c "$FASTA_FILE"
echo "🔍 Primeras líneas del archivo:"
head "$FASTA_FILE"

echo "✅ Proceso finalizado."
