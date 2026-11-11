#!/usr/bin/env bash
# Avvia un demone Hadoop in foreground.
# Uso: hadoop-entrypoint.sh namenode|datanode|resourcemanager|nodemanager
set -euo pipefail

role="${1:?specificare il ruolo}"

case "$role" in
  namenode)
    # Formatta il filesystem solo al primo avvio
    if [ ! -d /hadoop/dfs/name/current ]; then
      echo ">> Primo avvio: formattazione del NameNode"
      hdfs namenode -format -nonInteractive -force
    fi
    exec hdfs namenode
    ;;
  datanode)        exec hdfs datanode ;;
  resourcemanager) exec yarn resourcemanager ;;
  nodemanager)     exec yarn nodemanager ;;
  *)               exec "$@" ;;
esac
