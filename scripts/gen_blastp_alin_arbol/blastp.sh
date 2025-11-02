#!/bin/bash
# ============================================================
# Pipeline: Búsqueda de ortólogos del gen yggX por BLASTp
# Autor: [Tu nombre]
# Fecha: $(date +"%Y-%m-%d")
# Descripción:
#   - Toma la secuencia proteica de yggX (.faa)
#   - Ejecuta BLASTp remoto en la base de datos NR
#   - Excluye Escherichia y Shigella (para buscar ortólogos fuera del género)
#   - Aplica parámetros óptimos según Moreno-Hagelsieb & Latimer (2008)
#   - Filtra duplicados si existen (CD-HIT 100%)
# ============================================================

# 1. Configuración
GENE_NAME="yggX"
INPUT_PROT_FILE="../gene_${GENE_NAME}_ecoli_prot/${GENE_NAME}_ecoli.faa"
OUTPUT_DIR="blastp_${GENE_NAME}_results"
OUTPUT_TSV="${GENE_NAME}_blastp_results.tsv"
FILTERED_TSV="${GENE_NAME}_blastp_filtered.tsv"
DEDUP_FASTA="${GENE_NAME}_blastp_filtered_nodup.faa"

# 2. Crear carpeta de salida
mkdir -p "$OUTPUT_DIR"
cd "$OUTPUT_DIR" || exit 1

# 3. Verificar entrada
if [ ! -s "$INPUT_PROT_FILE" ]; then
    echo "⚠️ Error: No se encuentra el archivo proteico en $INPUT_PROT_FILE"
    echo "Por favor ejecuta primero el script que genera ${GENE_NAME}_ecoli.faa"
    exit 1
fi
echo "✅ Archivo de proteína encontrado: $INPUT_PROT_FILE"

# 4. BLASTp remoto para obtención de ortólogos
# =========================================

# ---- Configuración de variables ----
GENE_NAME="yggX"
INPUT_PROT_FILE="../gene_${GENE_NAME}_ecoli_prot/${GENE_NAME}_ecoli.faa"
OUTPUT_DIR="blastp_${GENE_NAME}_results_sinecoli"
OUTPUT_TSV="${OUTPUT_DIR}/${GENE_NAME}_blastp.tsv"

# Crear carpeta de resultados si no existe
mkdir -p "$OUTPUT_DIR"

# ---- Parámetros de control ----
MAX_TRIES=5
SLEEP_TIME=120  # segundos entre intentos
TRY=1

echo "🚀 Ejecutando BLASTp remoto (RefSeq Protein, excluyendo Escherichia y Shigella)..."

# ---- Bucle de ejecución con reintentos ----
while [ $TRY -le $MAX_TRIES ]; do
  echo "🧠 Intento $TRY de $MAX_TRIES..."

  blastp -query "$INPUT_PROT_FILE" \
    -db refseq_protein \
    -remote \
    -entrez_query "Bacteria[Organism] NOT (Escherichia[Organism] OR Shigella[Organism])" \
    -outfmt "6 qseqid sseqid pident length qcovs evalue bitscore stitle" \
    -evalue 1e-5 \
    -max_target_seqs 50 \
    -out "$OUTPUT_TSV"

  # ---- Verificación del resultado ----
  if [ -s "$OUTPUT_TSV" ]; then
    echo "✅ BLASTp completado correctamente en el intento $TRY."
    break
  else
    echo "⚠️ Error: Falló el intento $TRY. Reintentando en $SLEEP_TIME segundos..."
    ((TRY++))
    sleep $SLEEP_TIME
  fi
done

# ---- Control final ----
if [ ! -s "$OUTPUT_TSV" ]; then
  echo "❌ Error: No se logró completar BLASTp después de $MAX_TRIES intentos."
  exit 1
fi

echo "📁 Resultados guardados en: $OUTPUT_TSV"

# 5. Comprobar salida
if [ ! -s "$OUTPUT_TSV" ]; then
    echo "⚠️ Error: No se generó archivo de resultados BLASTp."
    exit 1
fi

echo "✅ BLASTp completado: $OUTPUT_TSV"
echo "📈 Primeras líneas:"
head "$OUTPUT_TSV"

# 6. Filtrado automático
echo "🧹 Filtrando resultados significativos..."
awk '$4 >= 70 && $3 >= 60 && $6 <= 1e-5 {print}' "$OUTPUT_TSV" > "$FILTERED_TSV"

if [ ! -s "$FILTERED_TSV" ]; then
    echo "⚠️ No se encontraron hits que cumplan los criterios de filtrado."
    exit 0
fi

echo "✅ Resultados filtrados: $FILTERED_TSV"
wc -l "$FILTERED_TSV"

# 7. Descargar secuencias FASTA de los accesos filtrados
echo "📥 Descargando secuencias proteicas de los accesos filtrados..."
awk '{if ($2 ~ /[A-Z]{2}_[0-9]+\.[0-9]+/) {match($2, /[A-Z]{2}_[0-9]+\.[0-9]+/, id); print id[0];}}' "$FILTERED_TSV" | sort -u > accessions.txt


NUM=$(wc -l < accessions.txt)
if [ "$NUM" -eq 0 ]; then
    echo "⚠️ No hay accesos válidos en los resultados filtrados."
    exit 1
fi
echo "✅ Se encontraron $NUM accesos únicos."

efetch -db protein -format fasta -id $(paste -sd, accessions.txt) > "${GENE_NAME}_blastp_filtered.faa"

# 8. Eliminar duplicados con CD-HIT
echo "🧬 Eliminando secuencias idénticas (CD-HIT 100%)..."
cd-hit -i "${GENE_NAME}_blastp_filtered.faa" -o "$DEDUP_FASTA" -c 1.00 -n 5 -d 0 -T 0 -M 16000 > /dev/null

if [ -s "$DEDUP_FASTA" ]; then
    echo "✅ Archivo sin duplicados generado: $DEDUP_FASTA"
    echo "📊 Total de secuencias únicas:"
    grep "^>" "$DEDUP_FASTA" | wc -l
else
    echo "⚠️ No se generó archivo deduplicado. Revisa los datos."
fi

echo "🎯 Proceso finalizado correctamente."

# 9. Renombrar secuencias con especie en el encabezado (opcional pero recomendado)
echo "🏷️  Renombrando encabezados con especie..."
sed -E 's/>([A-Z0-9_.]+).* \[([^\]]+)\]/>\1_\2/' "${GENE_NAME}_blastp_filtered_nodup.faa" \
| sed 's/ /_/g' > "${GENE_NAME}_blastp_filtered_nodup_renamed.faa"

if [ -s "${GENE_NAME}_blastp_filtered_nodup_renamed.faa" ]; then
    echo "✅ Secuencias renombradas correctamente: ${GENE_NAME}_blastp_filtered_nodup_renamed.faa"
else
    echo "⚠️ No se pudo generar el archivo renombrado. Revisa si los encabezados contienen los nombres de especie."
fi
