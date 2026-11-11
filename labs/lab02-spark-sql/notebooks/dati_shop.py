"""
Generatore di un dataset sintetico "e-commerce" usato dai notebook del Lab 02.

I dati sono generati IN PARALLELO dagli executor (spark.range + funzioni SQL),
quindi la dimensione può crescere senza passare dalla memoria del driver.
Il seme fisso rende i risultati riproducibili.
"""
from pyspark.sql import DataFrame, SparkSession
from pyspark.sql import functions as F

CITTA = ["Roma", "Milano", "Napoli", "Torino", "Palermo", "Bologna", "Firenze", "Bari"]
CATEGORIE = ["Libri", "Elettronica", "Casa", "Sport", "Giochi", "Moda", "Alimentari", "Musica"]
CANALI = ["web", "app", "negozio"]


def _scegli(valori, indice_col):
    """Valore da una lista in base a un indice intero (0-based)."""
    return F.element_at(F.array(*[F.lit(v) for v in valori]), (indice_col % len(valori) + 1).cast("int"))


def clienti(spark: SparkSession, n: int = 10_000) -> DataFrame:
    return (spark.range(1, n + 1).withColumnRenamed("id", "cliente_id")
            .withColumn("nome", F.concat(F.lit("Cliente_"), F.lpad(F.col("cliente_id").cast("string"), 5, "0")))
            .withColumn("citta", _scegli(CITTA, F.col("cliente_id") * 7))
            .withColumn("eta", (18 + (F.col("cliente_id") * 13) % 60).cast("int"))
            .withColumn("iscrizione", F.date_add(F.lit("2020-01-01").cast("date"), (F.col("cliente_id") % 1500).cast("int"))))


def prodotti(spark: SparkSession, n: int = 200) -> DataFrame:
    return (spark.range(1, n + 1).withColumnRenamed("id", "prodotto_id")
            .withColumn("categoria", _scegli(CATEGORIE, F.col("prodotto_id")))
            .withColumn("prodotto", F.concat(F.col("categoria"), F.lit("_"), F.col("prodotto_id").cast("string")))
            .withColumn("prezzo", F.round(5 + F.rand(42) * 495, 2).cast("decimal(10,2)")))


def ordini(spark: SparkSession, n: int = 2_000_000, n_clienti: int = 10_000, n_prodotti: int = 200,
           partizioni: int = 8) -> DataFrame:
    # pow(rand, 3): pochi prodotti molto popolari (distribuzione sbilanciata, realistica)
    return (spark.range(0, n, numPartitions=partizioni).withColumnRenamed("id", "ordine_id")
            .withColumn("cliente_id", (F.rand(1) * n_clienti).cast("long") + 1)
            .withColumn("prodotto_id", (F.pow(F.rand(2), 3) * n_prodotti).cast("long") + 1)
            .withColumn("quantita", (F.rand(3) * 5).cast("int") + 1)
            .withColumn("data", F.date_add(F.lit("2024-01-01").cast("date"), (F.rand(4) * 730).cast("int")))
            .withColumn("canale", _scegli(CANALI, (F.rand(5) * 3).cast("int"))))


BASE = "/home/jovyan/data/shop"


def carica(spark: SparkSession, n_ordini: int = 2_000_000) -> dict:
    """
    Genera il dataset una sola volta, lo salva in Parquet in data/shop/ e lo rilegge.
    Leggere da file (invece che dal generatore) rende i piani di esecuzione più leggibili.
    """
    import os
    if not os.path.exists(f"{BASE}/_GENERATO"):
        print("Generazione del dataset in", BASE, "...")
        clienti(spark).write.mode("overwrite").parquet(f"{BASE}/clienti")
        prodotti(spark).write.mode("overwrite").parquet(f"{BASE}/prodotti")
        ordini(spark, n=n_ordini).write.mode("overwrite").parquet(f"{BASE}/ordini")
        open(f"{BASE}/_GENERATO", "w").write(str(n_ordini))
    return {t: spark.read.parquet(f"{BASE}/{t}") for t in ("clienti", "prodotti", "ordini")}
