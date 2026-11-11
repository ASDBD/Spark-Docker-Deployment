"""
Word Count come job batch (MapReduce con RDD).

Uso:
    spark-submit --master spark://spark-master:7077 jobs/wordcount_job.py <input> <output>
"""
import re
import sys

from pyspark.sql import SparkSession


def main(input_path: str, output_path: str) -> None:
    spark = SparkSession.builder.appName("WordCountBatch").getOrCreate()
    sc = spark.sparkContext

    counts = (sc.textFile(input_path)
              .flatMap(lambda line: re.findall(r"[a-z]+", line.lower()))   # map
              .map(lambda word: (word, 1))
              .reduceByKey(lambda a, b: a + b)                               # shuffle + reduce
              .sortBy(lambda kv: -kv[1]))

    # Il risultato viene scritto in parallelo: un file part-XXXXX per partizione
    counts.map(lambda kv: f"{kv[0]}\t{kv[1]}").coalesce(1).saveAsTextFile(output_path)
    print(f"Parole distinte: {counts.count()} -> risultato in {output_path}")
    spark.stop()


if __name__ == "__main__":
    if len(sys.argv) != 3:
        sys.exit("uso: wordcount_job.py <input> <output>")
    main(sys.argv[1], sys.argv[2])
