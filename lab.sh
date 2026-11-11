#!/usr/bin/env bash
# =============================================================================
#  lab.sh - avvia/ferma i laboratori Spark avviando SOLO i container necessari
#
#  Uso:
#    ./lab.sh list                         elenco dei laboratori
#    ./lab.sh up   <lab> [modalità...]     avvia un laboratorio
#    ./lab.sh down <lab>                   ferma e rimuove i container (e i dati dei volumi)
#    ./lab.sh stop <lab>                   ferma i container mantenendo lo stato
#    ./lab.sh ps   <lab>                   stato dei container
#    ./lab.sh logs <lab> [servizio]        log
#    ./lab.sh build                        costruisce le immagini Docker
#
#  <lab> può essere il numero (01, 1) o il nome della cartella (lab01-spark-core).
#
#  Modalità (combinabili):
#    (nessuna)    Spark Standalone: master + worker              [default]
#    --local      solo driver Jupyter con Spark in local[*]      [minimo consumo RAM]
#    --connect    aggiunge il server Spark Connect (3 worker)    [lab 01, 02]
#    --yarn       Spark su Hadoop YARN invece che Standalone      [lab 03]
#    --history    aggiunge lo Spark History Server (porta 18080)
#    --recon      aggiunge Ozone Recon (porta 9888)              [lab 04]
#    --workers N  numero di worker Standalone (default 2)
# =============================================================================
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LABS_DIR="$ROOT/labs"

die()  { echo "Errore: $*" >&2; exit 1; }

list_labs() {
  echo "Laboratori disponibili:"
  for d in "$LABS_DIR"/lab*/; do
    d="${d%/}"; name="$(basename "$d")"
    desc="$(sed -n 's/^#  LAB [0-9]* - //p' "$d/docker-compose.yml" | head -1)"
    printf "  %-20s %s\n" "$name" "$desc"
  done
}

resolve_lab() {
  local arg="$1" match
  if [ -d "$LABS_DIR/$arg" ]; then echo "$LABS_DIR/$arg"; return; fi
  arg="$(printf '%02d' "$((10#${arg#lab}))" 2>/dev/null)" || die "laboratorio '$1' non valido"
  match="$(ls -d "$LABS_DIR"/lab"$arg"-*/ 2>/dev/null | head -1)"
  [ -n "$match" ] || die "laboratorio '$1' non trovato (usa ./lab.sh list)"
  echo "${match%/}"
}

compose() { (cd "$LAB" && docker compose "$@"); }

cmd="${1:-help}"; shift || true

case "$cmd" in
  list) list_labs; exit 0 ;;
  build)
    docker build -t spark-lab:4.3.0        "$ROOT/docker/spark"
    docker build -t spark-lab-hadoop:4.3.0 "$ROOT/docker/hadoop"
    exit 0 ;;
  up|down|stop|ps|logs) ;;
  *) sed -n '2,27p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
esac

[ $# -ge 1 ] || die "specificare il laboratorio (./lab.sh list)"
LAB="$(resolve_lab "$1")"; shift

case "$cmd" in
  down) compose --profile '*' down -v --remove-orphans; exit 0 ;;
  stop) compose --profile '*' stop; exit 0 ;;
  ps)   compose --profile '*' ps; exit 0 ;;
  logs) compose --profile '*' logs -f "$@"; exit 0 ;;
esac

# ------------------------------------------------------------------ up
mode="cluster"; extra=(); workers_set="${SPARK_WORKERS:+yes}"
export SPARK_WORKERS="${SPARK_WORKERS:-2}"
while [ $# -gt 0 ]; do
  case "$1" in
    --local)   mode="local" ;;
    --yarn)    mode="yarn" ;;
    --connect) extra+=("connect") ;;
    --history) extra+=("history") ;;
    --recon)   extra+=("recon") ;;
    --workers) shift; SPARK_WORKERS="${1:?numero di worker mancante}"; workers_set=yes ;;
    *) die "opzione sconosciuta: $1" ;;
  esac
  shift
done

case "$mode" in
  local)   profiles=();          export SPARK_MASTER="local[*]" ;;
  yarn)    profiles=("yarn");    export SPARK_MASTER="yarn" ;;
  cluster) profiles=("cluster"); export SPARK_MASTER="spark://spark-master:7077" ;;
esac
# Verifica che il laboratorio supporti la modalità richiesta
has_service() { grep -q "^  $1:" "$LAB/docker-compose.yml"; }
[ "$mode" = "yarn" ] && ! has_service resourcemanager && die "--yarn è disponibile solo nel lab 03"
for p in ${extra[@]+"${extra[@]}"}; do
  case "$p" in
    connect)
      has_service spark-connect || die "--connect è disponibile solo nei lab 01 e 02"
      [ "$mode" = "cluster" ]   || die "--connect richiede la modalità Standalone"
      # il server Connect occupa stabilmente 1 core: un worker in più per i notebook
      [ -n "$workers_set" ] || SPARK_WORKERS=3 ;;
    recon)
      has_service recon || die "--recon è disponibile solo nel lab 04" ;;
  esac
  profiles+=("$p")
done

COMPOSE_PROFILES="$(IFS=,; echo "${profiles[*]-}")"
export COMPOSE_PROFILES

echo ">> $(basename "$LAB")  |  master: $SPARK_MASTER  |  profili: ${COMPOSE_PROFILES:-nessuno}$([ "$mode" = cluster ] && echo "  |  worker: $SPARK_WORKERS")"
compose up -d --build --remove-orphans

cat <<INFO

  JupyterLab        http://localhost:8888/lab?token=${JUPYTER_TOKEN:-spark}
  Spark UI (app)    http://localhost:4040   (con una SparkSession attiva)
INFO
[ "$mode" = "cluster" ] && echo "  Spark Master      http://localhost:8080"
[[ " ${profiles[*]-} " == *" history "* ]] && echo "  History Server    http://localhost:18080"
[[ " ${profiles[*]-} " == *" connect "* ]] && echo "  Spark Connect     sc://localhost:15002"
grep -q 'namenode:' "$LAB/docker-compose.yml" && echo "  HDFS NameNode     http://localhost:9870"
[ "$mode" = "yarn" ] && echo "  YARN RM           http://localhost:8088"
grep -q '^  om:' "$LAB/docker-compose.yml" && echo "  Ozone OM / SCM    http://localhost:9874  http://localhost:9876" && echo "  Ozone S3 Gateway  http://localhost:9878"
[[ " ${profiles[*]-} " == *" recon "* ]] && echo "  Ozone Recon       http://localhost:9888"
echo
