# =============================================================================
#  Immagine Hadoop (HDFS + YARN) per il laboratorio 03.
#
#  Perché non usare direttamente apache/hadoop?
#   1. L'immagine ufficiale esiste solo per amd64 (su Apple Silicon gira emulata).
#   2. In modalità Spark-on-YARN gli executor Python girano DENTRO i container
#      del NodeManager: serve lo stesso Python (e PySpark) del driver Jupyter.
#  Soluzione: partiamo dall'immagine Spark/Jupyter (nativa multi-arch) e
#  copiamo dentro la distribuzione Hadoop (sono solo file .jar e script).
# =============================================================================
ARG SPARK_VERSION=4.3.0
ARG HADOOP_VERSION=3.5.0

# Stage "donatore": apache/hadoop è pubblicata SOLO per amd64, ma qui copiamo
# soltanto file .jar e script (nessuna esecuzione): l'immagine finale resta
# nativa sia su amd64 sia su arm64 (Apple Silicon).
FROM --platform=linux/amd64 apache/hadoop:${HADOOP_VERSION} AS hadoop

FROM quay.io/jupyter/pyspark-notebook:spark-${SPARK_VERSION}

USER root
COPY --from=hadoop --chown=1000:100 /opt/hadoop /opt/hadoop
# Le librerie native (.so) sono compilate per amd64: le rimuoviamo così Hadoop
# usa ovunque le implementazioni Java pure (stesso comportamento su ogni CPU)
RUN rm -rf /opt/hadoop/lib/native

# JAVA_HOME indipendente dall'architettura (amd64 / arm64)
RUN ln -s "$(dirname "$(dirname "$(readlink -f "$(command -v java)")")")" /opt/java && \
    mkdir -p /hadoop/dfs /hadoop/yarn && chown -R ${NB_UID}:${NB_GID} /hadoop

COPY --chmod=755 hadoop-entrypoint.sh /usr/local/bin/hadoop-entrypoint.sh

USER ${NB_UID}
ENV JAVA_HOME=/opt/java \
    HADOOP_HOME=/opt/hadoop \
    HADOOP_CONF_DIR=/opt/hadoop/etc/hadoop \
    HADOOP_HEAPSIZE_MAX=384m \
    PATH=/opt/hadoop/bin:/opt/hadoop/sbin:${PATH}

ENTRYPOINT ["/usr/local/bin/hadoop-entrypoint.sh"]
