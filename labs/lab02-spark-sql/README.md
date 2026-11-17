# Lab 02 — Spark SQL, DataFrame e Parquet

Questo laboratorio mostra come interrogare dati strutturati con **DataFrame** e **Spark SQL**, come funziona l'ottimizzatore **Catalyst**, come si comportano i formati di file (CSV, JSON, ORC, **Parquet**) e quali tecniche rendono le query più veloci (AQE, strategie di join, partizionamento, cache).
Spark gira in modalità **local** (`local[*]`) dentro il container Jupyter: SQL e Parquet non richiedono un cluster, quindi il consumo di RAM è minimo.

## Struttura della cartella

```
lab02-spark-sql/
├── docker-compose.yml      # servizi: jupyter (+ spark-history opzionale)
├── .env                    # modalità Spark: SPARK_MASTER=local[*]
├── notebooks/              # montata in JupyterLab come /home/jovyan/work
│   ├── 01_dataframe_sql.ipynb
│   ├── 02_parquet_formati.ipynb
│   ├── 03_ottimizzazione.ipynb
│   └── dati_shop.py        # generatore del dataset e-commerce sintetico
└── data/                   # output dei notebook (dataset shop, formati, warehouse)
```

Il dataset (clienti, prodotti, 2 milioni di ordini) viene generato dai task Spark al primo avvio e salvato in `data/shop/`.

## Requisiti

* Docker Desktop (macOS/Windows) o Docker Engine + Compose v2 (Linux); funziona su amd64 e arm64.
* Memoria assegnata a Docker: almeno **4 GB** (questo lab usa un solo container).
* Spazio disco: circa 9 GB per le immagini, più qualche centinaio di MB in `data/` per i file generati.
* Altri laboratori usano le stesse porte: tenerne attivo uno alla volta.

## Come eseguire

1. Avvia il laboratorio da questa cartella (al primo avvio l'immagine viene costruita, circa 5-10 minuti):
   ```bash
   docker compose up -d --build
   ```
2. Apri JupyterLab: http://127.0.0.1:8888/lab?token=spark
3. Esegui i notebook nell'ordine (cartella `work`):

| # | Notebook | Cosa mostra |
|---|---|---|
| 1 | `01_dataframe_sql.ipynb` | API DataFrame e SQL equivalenti, join, `ROLLUP`, `pivot`, funzioni finestra, UDF e Pandas UDF, piano di Catalyst |
| 2 | `02_parquet_formati.ipynb` | confronto CSV/JSON/ORC/Parquet, schema, column pruning, metadati Parquet, predicate pushdown, `partitionBy`, codec, `mergeSchema`, SQL sui file e tabelle del catalogo |
| 3 | `03_ottimizzazione.ipynb` | shuffle e AQE, broadcast vs sort-merge join, `repartition` vs `coalesce`, caching |

## Servizi e porte

Le porte sono pubblicate solo su `127.0.0.1`.

| Servizio | Porta | Note |
|---|---|---|
| `jupyter` (driver) | 8888 | JupyterLab, token `spark` |
| `jupyter` — Spark UI | 4040 | attiva solo con una SparkSession aperta |
| `spark-history` | 18080 | opzionale: avviare con `COMPOSE_PROFILES=history docker compose up -d` |

## Note

* Ogni notebook termina con `spark.stop()`: eseguili uno alla volta (o riavvia il kernel) per liberare la Spark UI sulla porta 4040.
* I tempi misurati nei notebook dipendono dalla macchina: contano i confronti relativi.
* Il catalogo di Spark è in memoria (nessun metastore): le tabelle create con `saveAsTable` sopravvivono come file in `data/warehouse/`, ma la loro definizione si perde a fine sessione.
* Le cartelle in `data/` sono sovrascritte a ogni esecuzione dei notebook.

## Fermare il laboratorio

```bash
docker compose --profile '*' down -v
```
