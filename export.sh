#!/bin/bash
# ============================================================
# export.sh — Exporta todas as tabelas do VacinaDB para CSV
# Uso: bash export.sh
# ============================================================

HOST="localhost"
PORT="5433"
USER="vacina_user"
DB="vacinadb"
OUTDIR="./exports"

mkdir -p "$OUTDIR"

TABLES=("fabricante" "vacina" "lote" "paciente" "vacinador" "vacinacao")

for TABLE in "${TABLES[@]}"; do
    echo "Exportando tabela: $TABLE ..."
    PGPASSWORD=vacina_pass psql -h "$HOST" -p "$PORT" -U "$USER" -d "$DB" \
        -c "\COPY $TABLE TO '$OUTDIR/export_${TABLE}.csv' WITH (FORMAT CSV, HEADER)"
    echo "  -> $OUTDIR/export_${TABLE}.csv"
done

echo ""
echo "✅ Exportação concluída! Arquivos em: $OUTDIR/"
ls -lh "$OUTDIR/"
