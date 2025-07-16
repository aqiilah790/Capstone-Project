import 'dart:convert';
import 'package:capstone_project/transaksi.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:fl_chart/fl_chart.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  late Future<List<Map<String, dynamic>>> _aprioriData;
  double _saldo = 0.0;
  String _status = '';
  double _totalAnggaran = 0.0;
  double _totalPengeluaran = 0.0;

  Map<String, double> _pengeluaranData = {
    'Makanan': 0,
    'Transportasi': 0,
    'Lainnya': 100, // Default awal 100% jika belum ada transaksi
  };

  @override
  void initState() {
    super.initState();
    _aprioriData = fetchAprioriResults();
    fetchSaldo();
    fetchPengeluaranBulanan();
  }

  Future<String?> ambilToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<void> fetchSaldo() async {
    final token = await ambilToken();
    if (token == null) return;

    final response = await http.get(
      Uri.parse('http://10.0.3.2:1212/api/saldo'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        _totalAnggaran = data['total_anggaran'].toDouble();
        _totalPengeluaran = data['total_pengeluaran'].toDouble();
        _saldo = data['saldo'].toDouble();
        _status = data['status'];
      });
    } else {
      print('Gagal mengambil saldo: ${response.statusCode}');
    }
  }

  Future<void> fetchPengeluaranBulanan() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) {
      print('Token tidak ditemukan');
      return;
    }

    final response = await http.get(
      Uri.parse('http://10.0.3.2:1212/api/pengeluaran-bulanan'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      _updatePieChart(data);
    } else {
      print('Gagal mengambil data pengeluaran bulanan: ${response.statusCode}');
    }
  }

  void _updatePieChart(List<dynamic> transaksiList) {
    double total = transaksiList.fold(0, (sum, item) => sum + item['jumlah']);
    if (total == 0) return;

    final data = {
      'Makanan': 0.0,
      'Transportasi': 0.0,
      'Lainnya': 0.0,
    };

    for (var item in transaksiList) {
      final kategori = item['kategori'];
      final jumlah = item['jumlah'];

      if (data.containsKey(kategori)) {
        data[kategori] = data[kategori]! + jumlah;
      } else {
        data['Lainnya'] = data['Lainnya']! + jumlah;
      }
    }

    setState(() {
      _pengeluaranData = {
        for (var entry in data.entries) entry.key: (entry.value / total * 100),
      };
    });
  }

  Future<List<Map<String, dynamic>>> fetchAprioriResults() async {
    final token = await ambilToken();
    if (token == null) throw Exception('Token tidak ditemukan');

    final response = await http.get(
      Uri.parse('http://10.0.3.2:1212/api/hasil-apriori'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    final body = json.decode(response.body);

    if (response.statusCode == 200) {
      final data = body['data'];
      if (data is List) {
        return List<Map<String, dynamic>>.from(data);
      } else {
        throw Exception(body['message'] ?? 'Data tidak valid');
      }
    } else {
      throw Exception(body['message'] ?? 'Gagal memuat hasil apriori');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Keuangan'),
        backgroundColor: Colors.teal,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              color: _saldo < 0 ? Colors.red[100] : Colors.green[100],
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Saldo Saat Ini',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Rp ${_saldo.toStringAsFixed(0)}',
                            style: const TextStyle(
                                fontSize: 24, fontWeight: FontWeight.bold)),
                        Icon(Icons.account_balance_wallet,
                            color: _saldo < 0 ? Colors.red : Colors.green),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text('Status: $_status',
                        style: TextStyle(
                            color: _saldo < 0 ? Colors.red : Colors.green)),
                    Text('Anggaran: Rp ${_totalAnggaran.toStringAsFixed(0)}'),
                    Text(
                        'Pengeluaran: Rp ${_totalPengeluaran.toStringAsFixed(0)}'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text('Pengeluaran Bulan Ini',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Expanded(
              child: Row(
                children: [
                  const Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        LegendItem(color: Colors.orange, text: 'Makanan'),
                        SizedBox(height: 10),
                        LegendItem(color: Colors.blue, text: 'Transportasi'),
                        SizedBox(height: 10),
                        LegendItem(color: Colors.grey, text: 'Lainnya'),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: PieChart(
                      PieChartData(
                        sections: [
                          PieChartSectionData(
                              value: _pengeluaranData['Makanan'] ?? 0,
                              title:
                                  '${_pengeluaranData['Makanan']?.toStringAsFixed(0) ?? 0}%',
                              color: Colors.orange,
                              radius: 60),
                          PieChartSectionData(
                              value: _pengeluaranData['Transportasi'] ?? 0,
                              title:
                                  '${_pengeluaranData['Transportasi']?.toStringAsFixed(0) ?? 0}%',
                              color: Colors.blue,
                              radius: 60),
                          PieChartSectionData(
                              value: _pengeluaranData['Lainnya'] ?? 0,
                              title:
                                  '${_pengeluaranData['Lainnya']?.toStringAsFixed(0) ?? 0}%',
                              color: Colors.grey,
                              radius: 60),
                        ],
                        sectionsSpace: 2,
                        centerSpaceRadius: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => Transaksi(
                        onSelesai: () {
                          fetchSaldo();
                          fetchPengeluaranBulanan();
                        },
                      ),
                    ));
              },
              icon: const Icon(Icons.add),
              label: const Text(
                'Tambah Transaksi',
                style: TextStyle(color: Colors.black),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
            const SizedBox(height: 20),
            const Text('Rekomendasi Keuangan (Hasil Apriori)',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _aprioriData,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Text('Error: ${snapshot.error}');
                  } else if (!snapshot.hasData) {
                    return const Text('Data tidak tersedia.');
                  } else {
                    final data = snapshot.data!;
                    if (data.isEmpty) {
                      return const Text(
                          'Belum cukup transaksi untuk analisis Apriori.');
                    }
                    return ListView.builder(
                      itemCount: data.length,
                      itemBuilder: (context, index) {
                        final item = data[index];
                        final rule = item['rule'];
                        final rekomendasi = item['rekomendasi'];

                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          child: ListTile(
                            leading:
                                const Icon(Icons.insights, color: Colors.teal),
                            title: Text('Kamu sering mengeluarkan untuk $rule'),
                            subtitle: Text(
                                'Biasanya setelah itu juga mengeluarkan untuk $rekomendasi.\nPertimbangkan buat anggaran untuk kategori ini.'),
                          ),
                        );
                      },
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class LegendItem extends StatelessWidget {
  final Color color;
  final String text;

  const LegendItem({super.key, required this.color, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 16, height: 16, color: color),
        const SizedBox(width: 8),
        Text(text, style: const TextStyle(fontSize: 16)),
      ],
    );
  }
}
