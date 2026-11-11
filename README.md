# Spark Docker Deployment — Laboratori

Laboratori dimostrativi sulle funzionalità fondamentali di **Apache Spark 4.3.0**, eseguiti con Docker Compose.

Ogni laboratorio avvia **solo i container di cui ha bisogno** (niente HDFS se non serve, niente database se non servono...), così da poter girare anche su un portatile. I notebook contengono **codice d'esempio commentato** da eseguire e mostrare, non esercizi.

| Lab | Argomento | Container avviati |
|---|---|---|
| [01 – Spark Core](labs/lab01-spark-core) | modalità di esecuzione (local, standalone, Spark Connect), RDD, lazy evaluation, **MapReduce** (word count, indice invertito), **calcolo parallelo** (Monte Carlo, speedup), broadcast, accumulatori, cache, tolleranza ai guasti, `spark-submit` | jupyter, spark-master, 2 × spark-worker |
| [02 – Spark SQL e Parquet](labs/lab02-spark-sql) | DataFrame, **Spark SQL**, join, window function, UDF / Pandas UDF, Catalyst; formati CSV/JSON/ORC/**Parquet**, pushdown, `partitionBy`, compressione, schema evolution; AQE, strategie di join, cache | jupyter, spark-master, 2 × spark-worker |
| [03 – HDFS e YARN](labs/lab03-hdfs-yarn) | **HDFS** (WebHDFS, blocchi e repliche, API FileSystem), Spark su HDFS, Parquet su HDFS; **Spark su YARN** | jupyter, namenode, 2 × datanode + Spark Standalone **oppure** YARN (resourcemanager, nodemanager) |
| [04 – Apache Ozone](labs/lab04-ozone) | **Ozone** come storage per Spark (`ofs://`), volumi/bucket/chiavi, Parquet su Ozone; accesso **S3** (boto3, PyArrow) agli stessi dati | jupyter, scm, om, datanode, s3g, spark-master, 2 × spark-worker |
| [05 – Database](labs/lab05-database) | **JDBC/MySQL** (pushdown, lettura parallela, scrittura) e **MongoDB** (documenti annidati, aggregation pipeline) | jupyter, mysql, mongo, spark-master, 2 × spark-worker |

## Requisiti

* Docker Desktop (macOS/Windows) o Docker Engine + Compose v2 (Linux).
* **Architettura**: funziona nativamente sia su **amd64** (Intel/AMD) sia su **arm64** (Apple Silicon). Tutte le immagini usate sono multi-architettura (vedi [Immagini](#immagini)).
* Memoria assegnata a Docker: almeno **4 GB** (consigliati 6 GB per i lab 03 e 04). In caso di poca memoria usare `--local` o `--workers 1`.
* Spazio disco: circa 9 GB per le immagini.

## Avvio rapido

```bash
./lab.sh build          # la prima volta (circa 5-10 minuti): costruisce le immagini
./lab.sh list           # elenco dei laboratori
./lab.sh up 01          # avvia il lab 01
```

Aprire **JupyterLab** su http://localhost:8888/lab?token=spark ed eseguire i notebook nell'ordine.

```bash
./lab.sh down 01        # ferma e rimuove i container del lab (prima di passare al successivo)
```

> Si consiglia di tenere attivo **un laboratorio alla volta**: usano le stesse porte.

## Modalità di esecuzione

Lo stesso codice Spark può girare con cluster manager diversi. `lab.sh` sceglie i container e imposta la variabile `SPARK_MASTER` letta dai notebook.

| Comando | Modalità | Master Spark | Lab |
|---|---|---|---|
| `./lab.sh up 01` | **Standalone** (default): master + worker | `spark://spark-master:7077` | tutti |
| `./lab.sh up 01 --local` | **Locale**: solo Jupyter, executor come thread del driver | `local[*]` | tutti |
| `./lab.sh up 01 --connect` | Standalone + **Spark Connect** server (client gRPC) | `sc://spark-connect:15002` | 01, 02 |
| `./lab.sh up 03 --yarn` | **Hadoop YARN** al posto dello Standalone | `yarn` | 03 |

Opzioni aggiuntive:

| Opzione | Effetto |
|---|---|
| `--workers N` | numero di worker Standalone (default 2, 3 con `--connect`) |
| `--history` | Spark History Server su http://localhost:18080 (job già conclusi) |
| `--recon` | Ozone Recon su http://localhost:9888 (solo lab 04) |

Altri comandi: `./lab.sh ps 03`, `./lab.sh logs 03 namenode`, `./lab.sh stop 03` (ferma mantenendo lo stato).

`lab.sh` è solo una comodità: in ogni cartella si può usare direttamente Docker Compose, ad esempio:

```bash
cd labs/lab03-hdfs-yarn
COMPOSE_PROFILES=yarn SPARK_MASTER=yarn docker compose up -d
```

## Interfacce web

| Servizio | URL | Disponibile |
|---|---|---|
| JupyterLab | http://localhost:8888 (token `spark`) | sempre |
| Spark UI dell'applicazione | http://localhost:4040 | con una SparkSession attiva |
| Spark Master | http://localhost:8080 | modalità Standalone |
| HDFS NameNode | http://localhost:9870 | lab 03 |
| YARN ResourceManager / NodeManager | http://localhost:8088 · http://localhost:8042 | lab 03 `--yarn` |
| Ozone Manager / SCM / S3 Gateway | http://localhost:9874 · http://localhost:9876 · http://localhost:9878 | lab 04 |
| MySQL / MongoDB | `localhost:3306` (spark/spark) · `localhost:27017` | lab 05 |

## Struttura del repository

```
lab.sh                     avvio/arresto dei laboratori
datasets/                  dati di input condivisi (montati in sola lettura su tutti i nodi)
docker/
  spark/                   immagine comune: driver Jupyter, master, worker, Spark Connect
  hadoop/                  immagine HDFS + YARN (lab 03)
labs/
  common/spark-services.yml   servizi Spark riutilizzati da ogni lab (extends)
  labNN-.../
    docker-compose.yml     container del laboratorio (con profili per le modalità)
    notebooks/             notebook dimostrativi (montati in /home/jovyan/work)
    data/                  output dei notebook, condiviso tra driver ed executor
```

Le cartelle `notebooks/`, `data/` e `datasets/` sono montate **con lo stesso percorso** nel driver e negli executor: in questo modo anche i percorsi locali (`file:///home/jovyan/...`) sono visibili a tutti i nodi, come un filesystem condiviso.

## Immagini

| Immagine | Base | Note |
|---|---|---|
| `spark-lab:4.3.0` | `quay.io/jupyter/pyspark-notebook:spark-4.3.0` (Spark 4.3.0, Python 3.13, Java 21) | + client Ozone `ofs://`, boto3. Usata per driver ed executor: stessa versione di Python ovunque |
| `spark-lab-hadoop:4.3.0` | come sopra + Hadoop 3.5.0 | i file di Hadoop sono copiati da `apache/hadoop:3.5.0` (pubblicata solo per amd64): copiando solo i `.jar` l'immagine resta nativa anche su Apple Silicon e i container YARN hanno lo stesso Python del driver |
| `apache/ozone:2.2.1` | ufficiale | multi-arch |
| `mysql:8.4`, `mongo:8.0` | ufficiali | multi-arch |

I connettori per MySQL e MongoDB sono scaricati da Maven Central al primo utilizzo (`spark.jars.packages`) e conservati nel volume `ivy-cache`.

## Risoluzione problemi

* **I container si chiudono / errori di memoria** → aumentare la RAM di Docker oppure usare `--local` / `--workers 1`.
* **Porta già in uso** → un altro laboratorio è ancora attivo: `./lab.sh down <lab>`.
* **Linux: permessi negati su `data/`** → i container girano con UID 1000; se il proprio utente ha un UID diverso: `chmod -R a+rwX labs/*/data`.
* **Il notebook YARN non trova `/dati/...`** → eseguire prima `01_hdfs_e_spark` nella stessa sessione (`down` cancella HDFS).
