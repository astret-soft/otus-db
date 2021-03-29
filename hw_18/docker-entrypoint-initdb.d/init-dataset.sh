#!/bin/bash

cat /data.csv
mongoimport --type csv -d test -c dataset --headerline --drop /data.csv
