import pandas as pd
from mlxtend.frequent_patterns import apriori, association_rules
import psycopg2
import json
import requests
from datetime import datetime


df = pd.read_excel("dummy_transaksi.xlsx")
df.columns = df.columns.str.strip().str.lower().str.replace(" ", "_")
df['tanggal'] = pd.to_datetime(df['tanggal'])
df['bulan'] = df['tanggal'].dt.to_period('M')

basket = df.groupby(['id', 'bulan', 'kategori']).size().unstack().fillna(0)
basket = basket.applymap(lambda x: 1 if x > 0 else 0)

frequent_itemsets = apriori(basket, min_support=0.01, use_colnames=True)
rules = association_rules(frequent_itemsets, metric="confidence", min_threshold=0.1)

if rules.empty:
    print("Tidak ada rule ditemukan.")
    exit()

rules = rules[['antecedents', 'consequents', 'support', 'confidence', 'lift']]
rules['antecedents'] = rules['antecedents'].apply(lambda x: ', '.join(list(x)))
rules['consequents'] = rules['consequents'].apply(lambda x: ', '.join(list(x)))
rules.rename(columns={'antecedents': 'rule', 'consequents': 'rekomendasi'}, inplace=True)

kategori_dari_rules = set()
for index, row in rules.iterrows():
    kategori_dari_rules.update(map(str.strip, row['rule'].split(',')))
    kategori_dari_rules.update(map(str.strip, row['rekomendasi'].split(',')))
kategori_unik = list(kategori_dari_rules)


id_user = 1  

conn = psycopg2.connect(
    dbname='Manajemen',
    user='postgres',
    password='1234',
    host='localhost',
    port='5432'
)
cur = conn.cursor()

cur.execute("DELETE FROM hasil_apriori WHERE id_user = %s", (id_user,))

for _, row in rules.iterrows():
    try:
        cur.execute("""
            INSERT INTO hasil_apriori (id_user, rule, support, confidence, lift, rekomendasi)
            VALUES (%s, %s, %s, %s, %s, %s)
        """, (id_user, row['rule'], row['support'], row['confidence'], row['lift'], row['rekomendasi']))
        print("✅ Rule disimpan:", row['rule'], "→", row['rekomendasi'])
    except Exception as e:
        print("❌ Gagal menyimpan rule:", e)

for kategori in kategori_unik:
    try:
        cur.execute("""
            INSERT INTO kategori (nama_kategori)
            VALUES (%s)
            ON CONFLICT (nama_kategori) DO NOTHING
        """, (kategori,))
        print("✅ Kategori disimpan:", kategori)
    except Exception as e:
        print("❌ Gagal simpan kategori:", e)

conn.commit()
cur.close()
conn.close()
print("✅ Semua data disimpan ke PostgreSQL.")

data = {
    "id_user": id_user,
    "rules": [
        {
            "rule": row['rule'],
            "rekomendasi": row['rekomendasi'],
            "support": float(row['support']),
            "confidence": float(row['confidence']),
            "lift": float(row['lift']),
        } for _, row in rules.iterrows()
    ]
}

try:
    res = requests.post(
        "http://localhost:1212/api/simpan-hasil-apriori",
        headers={"Content-Type": "application/json"},
        data=json.dumps(data)
    )
    print("📤 Dikirim ke backend Express:", res.status_code, res.text)
except Exception as e:
    print("❌ Gagal kirim ke backend Express:", e)
