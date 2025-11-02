#!/bin/bash
# ============================================================
# Pipeline: Descarga del gen yggX (E. coli K-12 MG1655) y conversión a proteína
# Autor: [Tu nombre]
# Fecha: $(date +"%Y-%m-%d")
# Descripción:
#   - Crea carpeta de salida
#   - Descarga el gen yggX en formato nucleótido (.fna)
#   - Obtiene la secuencia proteica (.faa) usando Entrez Direct
#   - Verifica archivos y prepara para BLASTp
# ============================================================

# 1. Configuración
GENE_NAME="yggX"
OUTPUT_DIR="gene_${GENE_NAME}_ecoli_prot"
NUC_FASTA="${GENE_NAME}_ecoli.fna"
PROT_FASTA="${GENE_NAME}_ecoli.faa"

# Coordenadas del gen yggX en el genoma de E. coli K-12 (NC_000913.3)
FASTA_URL="https://www.ncbi.nlm.nih.gov/sviewer/viewer.cgi?id=NC_000913.3&db=nuccore&report=fasta&from=3104093&to=3104368&strand=true"

# 2. Crear carpeta de salida
mkdir -p "$OUTPUT_DIR"
cd "$OUTPUT_DIR" || exit 1

# 3. Descargar secuencia nucleotídica
echo "🔽 Descargando gen ${GENE_NAME} (ADN)..."
curl -L "$FASTA_URL" -o "$NUC_FASTA"

# 4. Verificar descarga
if [ ! -s "$NUC_FASTA" ]; then
    echo "⚠️ Error: No se descargó el archivo o está vacío."
    exit 1
fi

echo "✅ Descarga completada: $NUC_FASTA"
echo "📊 Información:"
wc -l "$NUC_FASTA"
wc -c "$NUC_FASTA"
head "$NUC_FASTA"

# 5. Obtener secuencia proteica usando Entrez Direct
# Nota: esto busca el registro proteico asociado al gen yggX en NCBI (E. coli K-12)
echo "🧬 Obteniendo secuencia proteica de ${GENE_NAME}..."
efetch -db protein -format fasta -id "NP_417437.1" > "$PROT_FASTA"

# 6. Verificar secuencia proteica
if [ ! -s "$PROT_FASTA" ]; then
    echo "⚠️ Error: No se descargó la secuencia proteica."
    exit 1
fi

echo "✅ Secuencia proteica obtenida: $PROT_FASTA"
echo "📊 Información:"
wc -l "$PROT_FASTA"
wc -c "$PROT_FASTA"
head "$PROT_FASTA"
