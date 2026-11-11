# =============================================================================
#  Immagine comune a TUTTI i laboratori:
#  driver (Jupyter), Spark master, Spark worker, Spark Connect server.
#
#  Usare la stessa immagine per driver ed executor garantisce la stessa
#  versione di Python/Java/Spark su tutti i nodi (requisito di PySpark).
# =============================================================================
ARG SPARK_VERSION=4.3.0
ARG OZONE_VERSION=2.2.1

# Multi-architettura: tutte le immagini usate (Jupyter, Ozone) sono pubblicate
# per linux/amd64 e linux/arm64 -> build nativa sia su PC Intel/AMD sia su Apple Silicon.

# Stage "donatore": serve solo per copiare il client filesystem di Ozone (ofs://)
FROM apache/ozone:${OZONE_VERSION} AS ozone

FROM quay.io/jupyter/pyspark-notebook:spark-${SPARK_VERSION}
ARG OZONE_VERSION

USER root

# Client Ozone (shaded, per Hadoop 3) -> abilita gli schemi ofs:// e o3fs://
COPY --from=ozone /opt/hadoop/share/ozone/lib/ozone-filesystem-hadoop3-${OZONE_VERSION}.jar /usr/local/spark/jars/

# Configurazione di default di Spark (memoria contenuta per laptop/aule)
COPY spark-defaults.conf /usr/local/spark/conf/spark-defaults.conf
COPY log4j2.properties  /usr/local/spark/conf/log4j2.properties

# Directory di lavoro del worker standalone e degli eventi (History Server)
RUN mkdir -p /opt/spark-work /opt/spark-events && \
    chown -R ${NB_UID}:${NB_GID} /opt/spark-work /opt/spark-events

USER ${NB_UID}

# boto3: client S3 (usato con il S3 Gateway di Ozone)
# zstandard: compressione usata dal client Spark Connect
RUN pip install --no-cache-dir boto3 zstandard && \
    mkdir -p /home/jovyan/.ivy2   # cache di spark.jars.packages (montata come volume)

ENV SPARK_WORKER_DIR=/opt/spark-work \
    SPARK_NO_DAEMONIZE=true
