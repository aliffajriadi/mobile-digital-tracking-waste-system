import 'package:flutter/material.dart';

class IotLiveMonitorPage extends StatefulWidget {
  final String deviceId;
  const IotLiveMonitorPage({super.key, required this.deviceId});

  @override
  State<IotLiveMonitorPage> createState() => _IotLiveMonitorPageState();
}

class _IotLiveMonitorPageState extends State<IotLiveMonitorPage> {
  // Simulasi data yang datang dari Alat IoT
  final TextEditingController _kategoriController = TextEditingController(text: "Organik");
  final TextEditingController _beratController = TextEditingController(text: "4.5");
  final TextEditingController _catatanController = TextEditingController();

  final String _picName = "Budi Santoso"; // Data diambil dari User Auth
  final String _waktu = "04 Juli 2026, 17:30 WIB";
  final String _lokasi = "TPST Utama - Zona A";

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF14A38B);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F9),
      appBar: AppBar(
        title: Text("Alat: ${widget.deviceId}", style: const TextStyle(color: Colors.white)),
        backgroundColor: primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Section Timbangan Digital
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
              ),
              child: Column(
                children: [
                  const Text("Berat Sampah (kg)", style: TextStyle(color: Colors.grey)),
                  TextField(
                    controller: _beratController,
                    style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Color(0xFF264653)),
                    textAlign: TextAlign.center,
                    decoration: const InputDecoration(border: InputBorder.none),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Section Detail Data (Read Only + Edit)
            _buildInfoTile(Icons.person, "PIC Bertugas", _picName),
            _buildInfoTile(Icons.access_time, "Waktu Input", _waktu),
            _buildInfoTile(Icons.location_on, "Lokasi", _lokasi),
            
            const SizedBox(height: 10),
            
            // Form Editan
            TextField(
              controller: _kategoriController,
              decoration: const InputDecoration(labelText: "Kategori Sampah", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _catatanController,
              decoration: const InputDecoration(labelText: "Catatan Tambahan", border: OutlineInputBorder()),
              maxLines: 2,
            ),
            
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Data berhasil disimpan ke sistem!")),
                  );
                },
                style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
                child: const Text("SIMPAN & KIRIM LAPORAN", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey, size: 20),
          const SizedBox(width: 10),
          Text("$label: ", style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF264653))),
        ],
      ),
    );
  }
}