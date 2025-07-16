import pandas as pd
import random
from datetime import datetime, timedelta

kategori_list = ["Makanan", "Minuman", "Transportasi", "Hiburan", "Pendidikan", "Pemasukan"]
keterangan_map = {
    "Makanan": ["Nasi goreng", "Mie ayam", "Ayam geprek", "Nasi padang"],
    "Minuman": ["Teh manis", "Jus alpukat", "Air mineral", "Es teh"],
    "Transportasi": ["Naik ojek", "Naik angkot", "Grab motor"],
    "Hiburan": ["Nonton bioskop", "Main game", "Langganan Netflix"],
    "Pendidikan": ["Buku kuliah", "Alat tulis", "Kursus online"],
    "Pemasukan": ["Uang saku", "Gaji", "Beasiswa"]
}

data = []
start_date = datetime(2024, 6, 1)

for user_id in range(1, 11):  # 10 user
    for _ in range(20):  # masing-masing 20 transaksi
        date = start_date + timedelta(days=random.randint(0, 29))
        kategori = random.choice(kategori_list)
        jumlah = round(random.randint(5000, 100000), -3)  # Bulatkan ke ribuan
        tipe = "Masuk" if kategori == "Pemasukan" else "Keluar"
        keterangan = random.choice(keterangan_map[kategori])
        data.append([user_id, date.strftime('%Y-%m-%d'), kategori, jumlah, tipe, keterangan])

df = pd.DataFrame(data, columns=["id", "tanggal", "kategori", "jumlah", "tipe", "keterangan"])
df.to_excel("dummy_transaksi.xlsx", index=False)
print("✅ File dummy_transaksi.xlsx berhasil dibuat.")
