import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class RiwayatPage extends StatefulWidget {
  @override
  State<RiwayatPage> createState() => _RiwayatPageState();
}

class _RiwayatPageState extends State<RiwayatPage> {
  List<dynamic> _transaksiList = [];
  String? _selectedBulan;
  String? _selectedJenis;

  @override
  void initState() {
    super.initState();
    fetchTransaksi();
  }

  Future<void> fetchTransaksi() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) return;

    String url = 'http://10.0.3.2:1212/api/get-transaksi';
    Map<String, String> queryParams = {};

    if (_selectedBulan != null) queryParams['bulan'] = _selectedBulan!;
    if (_selectedJenis != null) queryParams['jenis'] = _selectedJenis!;

    if (queryParams.isNotEmpty) {
      url += '?${Uri(queryParameters: queryParams).query}';
    }

    final response = await http.get(
      Uri.parse(url),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      setState(() {
        _transaksiList = json.decode(response.body);
      });
    } else {
      print('Gagal memuat transaksi: ${response.statusCode}');
    }
  }

  void showDetailModal(Map<String, dynamic> transaksi) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Detail Transaksi'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Kategori: ${transaksi['kategori_relasi']['nama_kategori']}'),
            Text('Jumlah: Rp ${transaksi['jumlah']}'),
            Text('Tanggal: ${transaksi['tanggal_transaksi']}'),
            Text('Tipe: ${transaksi['kategori_relasi']['tipe']}'),
            Text('keterangan: ${transaksi['keterangan']}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bulanSekarang = DateFormat('yyyy-MM').format(DateTime.now());
    _selectedBulan ??= bulanSekarang;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Transaksi'),
        backgroundColor: Colors.teal,
      ),
      body: Column(
        children: [
          // Filter Dropdown
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                DropdownButton<String>(
                  value: _selectedBulan,
                  items: List.generate(12, (index) {
                    final bulan = DateFormat('yyyy-MM')
                        .format(DateTime(DateTime.now().year, index + 1));
                    return DropdownMenuItem(
                      value: bulan,
                      child: Text(bulan),
                    );
                  }),
                  onChanged: (value) {
                    setState(() {
                      _selectedBulan = value;
                    });
                    fetchTransaksi();
                  },
                ),
                const SizedBox(width: 10),
                // DropdownButton<String>(
                //   hint: const Text('Jenis'),
                //   value: _selectedJenis,
                //   items: ['pemasukan', 'pengeluaran'].map((jenis) {
                //     return DropdownMenuItem(
                //       value: jenis,
                //       child: Text(jenis),
                //     );
                //   }).toList(),
                //   onChanged: (value) {
                //     setState(() {
                //       _selectedJenis = value;
                //     });
                //     fetchTransaksi();
                //   },
                // ),
              ],
            ),
          ),
          Expanded(
            child: _transaksiList.isEmpty
                ? const Center(child: Text('Tidak ada transaksi.'))
                : ListView.builder(
                    itemCount: _transaksiList.length,
                    itemBuilder: (context, index) {
                      final item = _transaksiList[index];
                      final kategori = item['kategori_relasi']['nama_kategori'];
                      final tipe = item['kategori_relasi']['tipe'];
                      final jumlah = item['jumlah'];
                      final tanggal = item['tanggal_transaksi'];

                      return ListTile(
                        title: Text(kategori),
                        subtitle: Text('Rp $jumlah - $tanggal'),
                        trailing: Text(
                          tipe == 'pemasukan' ? '⬆' : '⬇',
                          style: TextStyle(
                            color:
                                tipe == 'pemasukan' ? Colors.green : Colors.red,
                          ),
                        ),
                        onTap: () => showDetailModal(item),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
