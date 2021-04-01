#!/bin/bash

awk 'NR>1' data.csv | tr ";" "\t" | \  # игнорируем первую строку с названием столбцов и переводим в tsv, чтобы mongo мог импортировать верно
mongoimport --db test --collection dataset \
  --type tsv \
  --columnsHaveTypes \
  --fields="fixed_acidity.decimal(),volatile_acidity.decimal(),citric_acid.decimal(),residual_sugar.decimal(),chlorides.decimal(),free_sulfur_dioxide.decimal(),total_sulfur_dioxide.decimal(),density.decimal(),pH.decimal(),sulphates.decimal(),alcohol.decimal(),quality.decimal()"
