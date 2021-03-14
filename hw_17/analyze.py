import csv
import json
import os


csv_name = 'some_customers.csv-67692-f6b765'
csv_gz_name = f'{csv_name}.gz'
csv_dst = './docker-entrypoint-initdb.d/data.csv'


def analyze(rows_: list):
    result = {}
    for row_ in rows_:
        for field, value in row_.items():
            result[field] = result.get(field, {})

            result[field]['max_length'] = max(result[field].get('max_length', 0), len(value))

            result[field]['values'] = result[field].get('values', {})
            result[field]['values'][value] = result[field]['values'].get(value, 0) + 1
    with open('analyze.json', 'w') as file:
        file.write(json.dumps(result, indent=2, ensure_ascii=False))


if __name__ == '__main__':
    try:
        rows = []
        os.system(f'gzip -dk {csv_gz_name}')
        os.rename(csv_name, csv_dst)
        with open(csv_dst) as f:
            reader = csv.reader(f)
            col = next(reader)
            for row in reader:
                rows.append(dict(zip(col, row)))
        analyze(rows)
    finally:
        # os.unlink(csv_temp)
        pass
