"""Crea la SparkSession adatta alla modalità con cui è stato avviato il laboratorio."""
import os
from pyspark.sql import SparkSession


def crea_sessione(nome: str) -> SparkSession:
    master = os.environ.get("SPARK_MASTER", "local[*]")
    builder = SparkSession.builder.appName(nome).master(master)
    if master == "yarn":
        builder = (builder
                   # i jar di Spark sono già presenti nell'immagine del NodeManager:
                   # evita di caricarli su HDFS a ogni avvio
                   .config("spark.yarn.jars", "local:/usr/local/spark/jars/*")
                   .config("spark.yarn.am.memory", "512m")      # ApplicationMaster
                   .config("spark.executor.instances", "2")
                   .config("spark.executor.memory", "512m"))
    return builder.getOrCreate()
