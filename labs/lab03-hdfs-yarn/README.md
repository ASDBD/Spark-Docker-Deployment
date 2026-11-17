# Lab 03 — HDFS e Spark su YARN

Laboratorio su **HDFS** (storage distribuito di Hadoop) e su **Spark come applicazione YARN**. Si vede come HDFS divide i file in blocchi replicati su più DataNode, come Spark li legge in parallelo (un blocco, una partizione) e come lo stesso codice Spark gira su **Standalone** (default) oppure su **YARN**.

## Struttura della cartella

```
lab03-hdfs-yarn/
├── docker-compose.yml     # HDFS + (Standalone | YARN) + JupyterLab
├── .env                   # modalità di default: Standalone
├── hadoop-conf/           # core-site, hdfs-site, yarn-site, capacity-scheduler
├── data/                  # cartella condivisa con i container (/home/jovyan/data)
└── notebooks/
    ├── sessione.py        # crea la SparkSession in base a SPARK_MASTER
    ├── 01_hdfs_e_spark.ipynb
    └── 02_spark_su_yarn.ipynb
```

## Requisiti

* Docker Desktop o Docker Engine con Compose v2, architettura amd64 o arm64.
* Memoria assegnata a Docker: almeno 4 GB, **consigliati 6 GB** (HDFS con due DataNode più Standalone o YARN).
* Circa 9 GB di spazio disco per le immagini (la prima build richiede 5-10 minuti).

## Come eseguire

1. Da questa cartella avvia il laboratorio (HDFS + Spark Standalone):

   ```bash
   docker compose up -d --build
   ```

   Per usare **YARN** al posto dello Standalone (necessario per il notebook 02), cambia **entrambe** le variabili:

   ```bash
   COMPOSE_PROFILES=yarn SPARK_MASTER=yarn docker compose up -d --build
   ```

2. Apri JupyterLab: http://127.0.0.1:8888/lab?token=spark
3. Esegui i notebook nell'ordine:

| # | Notebook | Modalità | Cosa mostra |
|---|---|---|---|
| 1 | `01_hdfs_e_spark.ipynb` | Standalone o YARN | scrittura via WebHDFS, API FileSystem, blocchi e repliche sui DataNode, blocco = partizione, Word Count e Parquet partizionato su HDFS, file locali vs HDFS |
| 2 | `02_spark_su_yarn.ipynb` | **solo YARN** | `master("yarn")`, configurazione usata, container degli executor, REST API del ResourceManager, job su dati HDFS, chiusura dell'applicazione |

Il notebook 02 usa i file creati dal notebook 01 (`/dati/alice.txt`, `/dati/vendite`): eseguilo dopo, nella stessa sessione di laboratorio avviata in modalità YARN.

## Servizi e porte

Tutte le porte sono pubblicate su `127.0.0.1`.

| Servizio | Porta | Modalità | Descrizione |
|---|---|---|---|
| JupyterLab (driver) | http://127.0.0.1:8888 | sempre | token `spark` |
| Spark UI applicazione | http://127.0.0.1:4040 | con SparkSession attiva | job, stage, task |
| HDFS NameNode | http://127.0.0.1:9870 | sempre | file (*Utilities → Browse the file system*), blocchi, DataNode |
| Spark Master | http://127.0.0.1:8080 | Standalone | worker e applicazioni |
| YARN ResourceManager | http://127.0.0.1:8088 | YARN | applicazioni, container, code |
| YARN NodeManager | http://127.0.0.1:8042 | YARN | container in esecuzione, log |
| Spark History Server | http://127.0.0.1:18080 | profilo `history` | applicazioni terminate |

Container: `jupyter`, `namenode`, `datanode1`, `datanode2`, più `spark-master` e `spark-worker` (Standalone, profilo `cluster`) oppure `resourcemanager` e `nodemanager` (YARN, profilo `yarn`).

## Note

* HDFS è configurato con **blocchi da 16 MB** e **replica 2** (valori di produzione: 128 MB e 3), così anche file piccoli mostrano più blocchi e più repliche.
* Il filesystem di default è `hdfs://namenode:8020`: un percorso senza schema punta a HDFS, per i file locali serve `file://`.
* Lo History Server si aggiunge con `COMPOSE_PROFILES=cluster,history docker compose up -d` (Standalone) oppure `COMPOSE_PROFILES=yarn,history SPARK_MASTER=yarn docker compose up -d` (YARN).
* Numero di worker Standalone: `SPARK_WORKERS=3 docker compose up -d`.
* Tieni attivo un solo laboratorio alla volta: usano le stesse porte.

## Fermare il laboratorio

```bash
docker compose --profile '*' down -v
```
