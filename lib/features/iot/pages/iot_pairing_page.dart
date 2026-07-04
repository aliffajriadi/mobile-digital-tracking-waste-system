import 'package:flutter/material.dart';
import 'iot_live_monitor_page.dart';

class IotPairingPage extends StatefulWidget {
  const IotPairingPage({super.key});

  @override
  State<IotPairingPage> createState() => _IotPairingPageState();
}

class _IotPairingPageState extends State<IotPairingPage> {
  final TextEditingController _codeController = TextEditingController();
  bool _isConnecting = false;

  void _handlePairing() async {
    // Validasi input sederhana
    if (_codeController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Masukkan kode alat terlebih dahulu!"), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isConnecting = true);
    
    // Simulasi proses pairing ke backend
    await Future.delayed(const Duration(seconds: 2));
    
    if (mounted) {
      setState(() => _isConnecting = false);
      
      // NAVIGASI KE HALAMAN MONITORING
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => IotLiveMonitorPage(deviceId: _codeController.text),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF14A38B);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F9),
      appBar: AppBar(
        title: const Text("Integrasi IoT", style: TextStyle(color: Colors.white)),
        backgroundColor: primaryColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.settings_input_antenna, size: 80, color: primaryColor),
            const SizedBox(height: 30),
            const Text(
              "Masukkan Kode Alat",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF264653)),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _codeController,
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                hintText: "Contoh: 829-102",
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isConnecting ? null : _handlePairing,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isConnecting 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("HUBUNGKAN ALAT", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 20),
            
          ],
        ),
      ),
    );
  }
}