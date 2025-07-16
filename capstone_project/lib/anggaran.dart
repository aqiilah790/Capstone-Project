import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';


class Anggaran extends StatefulWidget {
  const Anggaran({super.key});

  @override
  State<Anggaran> createState() => _AnggaranState();
}

class _AnggaranState extends State<Anggaran> {
  final TextEditingController _totalAnggaranController =
      TextEditingController();
  DateTime? _periodeMulai;
  DateTime? _periodeSelesai;
  bool _isLoading = false;
  final DateFormat formatter = DateFormat('yyyy-MM-dd');

  Future<String?> ambilToken() async {
    
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<void> _submitAnggaran() async {
    if (_totalAnggaranController.text.isEmpty ||
        _periodeMulai == null ||
        _periodeSelesai == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Semua field wajib diisi')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final token = await ambilToken();
    print('Token yang dikirim: $token');
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Token tidak ditemukan')),
      );
      setState(() => _isLoading = false);
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('http://10.0.3.2:1212/api/anggaran'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'total_anggaran': _totalAnggaranController.text,
          'periode_mulai': _periodeMulai!.toIso8601String(),
          'periode_selesai': _periodeSelesai!.toIso8601String(),
        }),
      );

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Anggaran berhasil disimpan')),
        );
        _totalAnggaranController.clear();
        setState(() {
          _periodeMulai = null;
          _periodeSelesai = null;
        });
      } else {
        final data = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Gagal menyimpan: ${data['message'] ?? 'error'}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickDate({required bool isStart}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          _periodeMulai = picked;
        } else {
          _periodeSelesai = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Input Anggaran'),
        backgroundColor: Colors.teal,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _totalAnggaranController,
              decoration: const InputDecoration(
                labelText: 'Total Anggaran (Rp)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            ListTile(
              title: Text(_periodeMulai != null
                  ? 'Mulai: ${formatter.format(_periodeMulai!)}'
                  : 'Pilih Tanggal Mulai'),
              trailing: const Icon(Icons.calendar_today),
              onTap: () => _pickDate(isStart: true),
            ),
            ListTile(
              title: Text(_periodeSelesai != null
                  ? 'Selesai: ${formatter.format(_periodeSelesai!)}'
                  : 'Pilih Tanggal Selesai'),
              trailing: const Icon(Icons.calendar_today),
              onTap: () => _pickDate(isStart: false),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _submitAnggaran,
              icon: const Icon(Icons.save),
              label: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Simpan Anggaran', style: TextStyle(color: Colors.black),),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
