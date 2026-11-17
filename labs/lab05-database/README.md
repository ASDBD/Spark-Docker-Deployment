# Lab 05 – Spark e sorgenti esterne: MySQL (JDBC) e MongoDB

Il laboratorio mostra come Spark 4.3.0 legge e scrive dati da un database **relazionale** (MySQL, tramite JDBC) e da uno **documentale** (MongoDB, tramite il MongoDB Spark Connector). Spark gira in modalità `local[*]` dentro il container Jupyter (il driver); i connettori vengono scaricati da Maven al primo avvio della `SparkSession` e conservati nel volume `ivy-cache`.

## Struttura della cartella

```
lab05-database/
├── docker-compose.yml        # servizi jupyter, mysql, mongo (+ spark-history opzionale)
├── .env                      # SPARK_MASTER=local[*], nessun profilo attivo
├── initdb/01-shop.sql        # database "shop": customers (500 righe), orders (20 000 righe)
├── data/                     # cartella montata in /home/jovyan/data
└── notebooks/
    ├── 01_mysql_jdbc.ipynb   # Spark e MySQL
    └── 02_mongodb.ipynb      # Spark e MongoDB
```

## Requisiti

* Docker Desktop (macOS/Windows) o Docker Engine + Compose v2 (Linux), su amd64 o arm64.
* Memoria assegnata a Docker: almeno **4 GB** (il lab usa `local[*]`, MySQL con buffer pool da 64 MB e MongoDB con cache WiredTiger da 0,25 GB).
* Spazio disco: circa 9 GB per le immagini (condivise con gli altri lab).
* Connessione a Internet al primo avvio dei notebook, per scaricare da Maven i connettori JDBC e MongoDB.

## Come eseguire

1. Dalla cartella del lab, avviare i servizi (la prima volta l'immagine `spark-lab:4.3.0` viene costruita, circa 5-10 minuti):
   ```bash
   docker compose up -d --build
   ```
2. Aprire JupyterLab: <http://127.0.0.1:8888/lab?token=spark>
3. Eseguire i notebook in `work/`, nell'ordine:

| # | Notebook | Cosa mostra |
|---|---|---|
| 1 | `01_mysql_jdbc.ipynb` | lettura di tabelle via JDBC, pushdown di filtri e query, lettura parallela con `numPartitions`, join con altri dati, scrittura su tabelle MySQL |
| 2 | `02_mongodb.ipynb` | scrittura e lettura di documenti annidati (struct, array), schema dedotto, pushdown e `aggregation.pipeline`, da DataFrame piatto a documenti |

Per fermare tutto e rimuovere container e volumi:

```bash
docker compose --profile '*' down -v
```

## Servizi e porte

Le porte sono pubblicate solo su `127.0.0.1`.

| Servizio | Porta | Descrizione |
|---|---|---|
| `jupyter` | 8888 | JupyterLab (token `spark`) |
| `jupyter` | 4040 | Spark UI dell'applicazione (attiva solo con una `SparkSession` aperta) |
| `mysql` | 3306 | MySQL 8.4, database `shop`, utente `spark` / password `spark` (root: `root`) |
| `mongo` | 27017 | MongoDB 8.0, senza autenticazione |
| `spark-history` | 18080 | Spark History Server, **solo con il profilo `history`** (non avviato di default) |

## Note

* Il database `shop` è creato da `initdb/01-shop.sql` solo al **primo avvio** di MySQL; `down -v` rimuove i volumi, quindi al successivo `up` i dati di partenza sono ricreati. Le tabelle scritte dal notebook 1 (`risultati_citta`, `statistiche_mensili`) e le collezioni create dal notebook 2 (`recensioni`, `profili`) vivono nei container e spariscono con `down -v`.
* Il `jupyter` parte solo quando MySQL è `healthy`; MongoDB è atteso solo come avviato.
* Ogni notebook termina con `spark.stop()`; i due notebook creano ciascuno la propria sessione, quindi si possono rieseguire in modo indipendente.
* Per usare lo Spark History Server: `docker compose --profile history up -d` (oppure impostare `COMPOSE_PROFILES=history`).
