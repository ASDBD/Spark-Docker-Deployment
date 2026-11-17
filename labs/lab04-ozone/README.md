# Lab 04 — Apache Ozone

In questo laboratorio **Apache Ozone**, object store distribuito del mondo Hadoop, fa da storage per Spark.
I notebook mostrano come leggere e scrivere dati su Ozone con il filesystem `ofs://` (volumi, bucket, chiavi, Parquet partizionato, rinomina atomica) e come accedere agli stessi dati con l'API **S3** (boto3, PyArrow) tramite l'S3 Gateway.
Spark gira in modalità `local[*]` dentro Jupyter: il lab riguarda lo storage, non il calcolo distribuito.

## Struttura della cartella

```
lab04-ozone/
├── docker-compose.yml      # jupyter + scm, om, datanode, s3g (recon e spark-history opzionali)
├── ozone.env               # configurazione dei demoni Ozone (replica 1, container/blocchi piccoli)
├── .env                    # modalità Spark di default (SPARK_MASTER=local[*])
├── data/                   # cartella locale montata in /home/jovyan/data
└── notebooks/              # montata in /home/jovyan/work
    ├── 01_ozone_e_spark.ipynb
    └── 02_ozone_s3.ipynb
```

## Requisiti

* Docker Desktop (macOS/Windows) o Docker Engine + Compose v2 (Linux).
* Memoria assegnata a Docker: almeno **4 GB**, consigliati **6 GB** (il cluster Ozone ha quattro demoni, ciascuno con heap di 384 MB).
* Architettura amd64 o arm64: tutte le immagini sono multi-architettura.

## Come eseguire

1. Da questa cartella avvia i servizi (la prima volta costruisce l'immagine):
   ```bash
   docker compose up -d --build
   ```
   Attendi qualche decina di secondi: SCM, OM e DataNode devono avviarsi e il DataNode registrarsi prima che si possano scrivere dati.
2. Apri JupyterLab: http://127.0.0.1:8888/lab?token=spark
3. Esegui i notebook, dalla cartella `work`, nell'ordine:

| Notebook | Cosa mostra |
|---|---|
| `01_ozone_e_spark.ipynb` | `SparkSession` con `ofs://`, volumi e bucket, Word Count su un file in Ozone, Parquet partizionato e query SQL, CSV/JSON, rinomina atomica |
| `02_ozone_s3.ipynb` | bucket e oggetti con boto3, lettura Spark degli stessi dati da `ofs://om/s3v/...`, Parquet scritto da Spark e letto con PyArrow via S3, download di un oggetto |

## Servizi e porte

Tutte le porte sono pubblicate solo su `127.0.0.1`.

| Servizio | Ruolo | URL / porta |
|---|---|---|
| `jupyter` | driver Spark + JupyterLab | http://127.0.0.1:8888/lab?token=spark |
| `jupyter` | Spark UI (con una SparkSession attiva) | http://127.0.0.1:4040 |
| `om` | Ozone Manager (namespace) | http://127.0.0.1:9874 |
| `scm` | Storage Container Manager | http://127.0.0.1:9876 |
| `datanode` | memorizza i dati (container da 256 MB) | nessuna porta pubblicata |
| `s3g` | S3 Gateway (API S3) | http://127.0.0.1:9878 |
| `recon` (profilo `recon`) | UI di monitoraggio di Ozone | http://127.0.0.1:9888 |
| `spark-history` (profilo `history`) | Spark History Server | http://127.0.0.1:18080 |

## Note

* Ozone Recon e lo Spark History Server sono opzionali: `COMPOSE_PROFILES=recon docker compose up -d`, oppure `COMPOSE_PROFILES=recon,history docker compose up -d`.
* Con un solo DataNode la replica è 1 (in produzione: `RATIS/THREE`).
* La sicurezza è disattivata: il client S3 accetta qualunque access key.
* I bucket creati via S3 usano il layout `FILE_SYSTEM_OPTIMIZED` (`ozone.s3g.default.bucket.layout` in `ozone.env`), perciò sono leggibili anche con `ofs://`.
* Il notebook 02 usa il volume `/s3v` di Ozone, creato dall'S3 Gateway.
* I dati di Ozone stanno in volumi Docker: si perdono con `down -v`.

## Fermare e pulire

```bash
docker compose --profile '*' down -v
```
