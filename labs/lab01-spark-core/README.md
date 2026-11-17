# Lab 01 — Spark Core: modalità di esecuzione, RDD, MapReduce, calcolo parallelo

Primo laboratorio del corso: si studia il funzionamento di Spark come motore di calcolo distribuito.
Si confrontano le modalità di esecuzione (locale e cluster Standalone), si implementa il paradigma **MapReduce** con gli RDD (Word Count, indice invertito, job con `spark-submit`) e si esplorano gli strumenti del calcolo parallelo: partizioni e scalabilità, `mapPartitions`, broadcast, accumulatori, caching e tolleranza ai guasti.

Modalità Spark: **Standalone** (1 master + N worker), perché il lab riguarda il calcolo distribuito.

## Struttura della cartella

```
lab01-spark-core/
├── docker-compose.yml        # servizi del lab (riusa ../common/spark-services.yml)
├── .env                      # COMPOSE_PROFILES=cluster, SPARK_MASTER=spark://spark-master:7077
├── data/                     # output condiviso driver/executor (es. wordcount_out)
└── notebooks/
    ├── 01_modalita_esecuzione.ipynb
    ├── 02_mapreduce_wordcount.ipynb
    ├── 03_calcolo_parallelo.ipynb
    └── jobs/
        └── wordcount_job.py  # Word Count come job batch per spark-submit
```

Il dataset (`alice_in_wonderland.txt`) si trova in `../../datasets` ed è montato in sola lettura in `/home/jovyan/datasets`.

## Requisiti

* Docker con Docker Compose.
* Memoria assegnata a Docker: almeno **4 GB**. In caso di poca memoria usare un solo worker: `SPARK_WORKERS=1 docker compose up -d`.
* Spazio disco: circa 9 GB per le immagini (condivise con gli altri lab).

## Come eseguire

1. Dalla cartella del lab, avviare i container (la prima volta costruisce l'immagine):

   ```bash
   docker compose up -d --build
   ```

2. Aprire JupyterLab: http://127.0.0.1:8888/lab?token=spark
3. Eseguire i notebook nell'ordine, da `work/` in JupyterLab:

| Notebook | Cosa mostra |
|---|---|
| `01_modalita_esecuzione.ipynb` | driver, executor e cluster manager; stesso codice in `local[*]` e in Standalone; distribuzione dei task sugli host; lazy evaluation, DAG e lineage |
| `02_mapreduce_wordcount.ipynb` | MapReduce con gli RDD: Word Count fase per fase, shuffle e partizioni, `reduceByKey` vs `groupByKey`, indice invertito, versione DataFrame, job batch con `spark-submit` |
| `03_calcolo_parallelo.ipynb` | Monte Carlo per π e scalabilità, numeri primi, `mapPartitions`, broadcast e accumulatori, caching, tolleranza ai guasti |

Eseguire le celle in ordine: ogni notebook chiude la propria sessione con `spark.stop()` per liberare i core del cluster.

## Servizi e porte

Tutte le porte sono pubblicate solo su `127.0.0.1`.

| Servizio | Porta | Descrizione | Profilo |
|---|---|---|---|
| `jupyter` (driver) | http://127.0.0.1:8888 | JupyterLab (token `spark`) | sempre |
| `jupyter` | http://127.0.0.1:4040 | Spark UI dell'applicazione (solo con una SparkSession attiva) | sempre |
| `spark-master` | http://127.0.0.1:8080 | Web UI del master (worker e applicazioni); porta Spark 7077 interna alla rete Docker | `cluster` |
| `spark-worker` (x2 di default) | nessuna porta pubblicata | executor; 1 core e 1 GB di memoria ciascuno | `cluster` |
| `spark-history` | http://127.0.0.1:18080 | History Server dei job conclusi | `history` (opzionale) |

## Note

* Il profilo `cluster` è attivo di default (vedi `.env`); lo Spark History Server si aggiunge con `COMPOSE_PROFILES=cluster,history docker compose up -d`.
* Numero di worker: `SPARK_WORKERS=3 docker compose up -d` (default 2). Risorse per worker: `SPARK_WORKER_CORES` (default 1) e `SPARK_WORKER_MEMORY` (default 1g).
* Gli executor del notebook 01 chiedono 768 MB e 1 core ciascuno, compatibili con i worker di default.
* La cartella `notebooks/` è montata in `/home/jovyan/work` e `data/` in `/home/jovyan/data`: le modifiche e gli output restano sul disco locale.
* La Spark UI su porta 4040 risponde solo finché una sessione è aperta.

## Fermare il lab

```bash
docker compose --profile '*' down -v
```
