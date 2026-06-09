import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile/core/constants/api_constants.dart';

class FormInputKeluarPage extends StatefulWidget {
  final Map<String, dynamic> selectedMethod;

  const FormInputKeluarPage({super.key, required this.selectedMethod});

  @override
  State<FormInputKeluarPage> createState() => _FormInputKeluarPageState();
}

class _FormInputKeluarPageState extends State<FormInputKeluarPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _catatanController = TextEditingController();
  final TextEditingController _qtyController = TextEditingController();

  // Variabel Fitur Waktu (Bisa Di-edit)
  DateTime _waktuKeluar = DateTime.now();

  // Variabel Fitur Upload Foto Bukti
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();

  // Variabel Fitur Dropdown Jenis Sampah Dinamis
  List<dynamic> _subcategoriesList = [];
  String? _selectedSubcategoryName;
  int? _selectedSubcategoryId;
  bool _isLoadingSubcategories = true;

  List<Map<String, dynamic>> _daftarItemSampah = [];
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _fetchSubcategories();
  }

  // --- AMBIL DATA SUBKATEGORI UNTUK DROPDOWN ---
  Future<void> _fetchSubcategories() async {
    try {
      final response = await http.get(Uri.parse('${ApiConstants.baseUrl}/waste-subcategories'));

      debugPrint('Status Code Dropdown: ${response.statusCode}');
      debugPrint('Response Body Dropdown: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          if (data is Map && data.containsKey('data')) {
            _subcategoriesList = data['data'] ?? [];
          } else if (data is List) {
            _subcategoriesList = data;
          } 
          _isLoadingSubcategories = false;
        });
      } else {
        setState(() => _isLoadingSubcategories = false);
      }
    } catch (e) {
      debugPrint('Error Ambil Dropdown: $e');
      setState(() => _isLoadingSubcategories = false);
    }
  }

  // --- FUNGSI PILIH EDIT TANGGAL & JAM ---
  Future<void> _pilihWaktu() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _waktuKeluar,
      firstDate: DateTime(2020),
      lastDate: DateTime(2101),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: Color(0xFFE76F51)),
        ),
        child: child!,
      ),
    );
    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_waktuKeluar),
      );
      if (pickedTime != null) {
        setState(() {
          _waktuKeluar = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
    }
  }

  // --- FUNGSI AMBIL FOTO (KAMERA / GALERI) ---
  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(source: source, imageQuality: 70);
      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
        });
      }
    } catch (e) {
      debugPrint("Error ambil foto: $e");
    }
  }

  void _tambahItemKeDaftar() {
    if (_selectedSubcategoryName == null || _qtyController.text.isEmpty || _selectedSubcategoryId == null) return;

    setState(() {
      _daftarItemSampah.add({
        'id_sub_category': _selectedSubcategoryId,
        'name': _selectedSubcategoryName,
        'quantity': double.tryParse(_qtyController.text) ?? 0.0,
        'unit': 'kg'
      });
    });

    _qtyController.clear();
    setState(() {
      _selectedSubcategoryName = null;
      _selectedSubcategoryId = null;
    });
    Navigator.pop(context);
  }

  // --- PUSH DATA MULTIPART KE LARAVEL ---
  Future<void> _pushDataSampahKeluar() async {
    if (!_formKey.currentState!.validate()) return;
    if (_daftarItemSampah.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(backgroundColor: Colors.orange, content: Text('Daftar item sampah tidak boleh kosong!')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      var uri = Uri.parse(ApiConstants.wasteOut);
      var request = http.MultipartRequest('POST', uri);

      request.headers['Authorization'] = 'Bearer $token';
      request.headers['Accept'] = 'application/json';

      // Mengirimkan ID sesuai blueprint database asli laravel kamu
      request.fields['id_waste_out_method'] = widget.selectedMethod['id'].toString();
      
      // Mengirimkan ID tujuan jika ada di widget.selectedMethod, jika tidak ada, kirim string kosong agar divalidasi sebagai null di Laravel
      String? destinationId = widget.selectedMethod['id_waste_destination']?.toString();
      if (destinationId != null) {
        request.fields['id_waste_destination'] = destinationId;
      }

      request.fields['notes'] = _catatanController.text;
      request.fields['created_at'] = DateFormat('yyyy-MM-dd HH:mm:ss').format(_waktuKeluar);
      request.fields['items'] = json.encode(_daftarItemSampah);

      if (_imageFile != null) {
        request.files.add(await http.MultipartFile.fromPath('photo', _imageFile!.path));
      }

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      final responseData = json.decode(response.body);

      if (response.statusCode == 201 || (responseData is Map && responseData['success'] == true)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(backgroundColor: Colors.green, content: Text('Laporan Sampah Keluar berhasil disimpan!')),
        );
        Navigator.pop(context);
        Navigator.pop(context);
      } else {
        _showErrorDialog(responseData['message'] ?? 'Gagal menyimpan transaksi.');
      }
    } catch (e) {
      _showErrorDialog('Terjadi error koneksi: $e');
    } finally {
      setState(() => _isSaving = false);
    }
  }

  void _showErrorDialog(String msg) {
    showDialog(
      context: context,
      builder: (context) => AppErrorDialog(msg: msg),
    );
  }

  // --- MODAL POPUP INPUT DENGAN DROPDOWN JENIS SAMPAH ---
  void _bukaModalTambahItem() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom, 
              left: 20, right: 20, top: 20
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Tambah Item Sampah', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 15),
                
                _isLoadingSubcategories
                    ? const Center(child: Padding(
                        padding: EdgeInsets.all(10.0),
                        child: CircularProgressIndicator(color: Color(0xFFE76F51)),
                      ))
                    : _subcategoriesList.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.all(10.0),
                            child: Text('Data jenis sampah kosong di database API', style: TextStyle(color: Colors.red, fontSize: 13)),
                          )
                        : Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(10)),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _selectedSubcategoryName,
                                hint: const Text('Pilih Jenis Sampah'),
                                isExpanded: true,
                                items: _subcategoriesList.map((item) {
                                  final nameStr = (item['name'] ?? item['nama'] ?? '-').toString();
                                  return DropdownMenuItem<String>(
                                    value: nameStr,
                                    child: Text(nameStr),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  final selectedItem = _subcategoriesList.firstWhere(
                                    (item) => (item['name'] ?? item['nama'] ?? '-').toString() == val,
                                    orElse: () => null,
                                  );

                                  if (selectedItem != null) {
                                    setModalState(() {
                                      _selectedSubcategoryName = val;
                                      _selectedSubcategoryId = selectedItem['id'];
                                    });
                                    setState(() {
                                      _selectedSubcategoryName = val;
                                      _selectedSubcategoryId = selectedItem['id'];
                                    });
                                  }
                                },
                              ),
                            ),
                          ),
                const SizedBox(height: 12),
                TextField(
                  controller: _qtyController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(hintText: 'Kuantitas (Kilo)', suffixText: 'kg', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE76F51)),
                    onPressed: _tambahItemKeDaftar,
                    child: const Text('Masukkan ke Daftar', style: TextStyle(color: Colors.white)),
                  ),
                ),
                const SizedBox(height: 25),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const primaryOutColor = Color(0xFFE76F51);
    String stringWaktu = DateFormat('dd MMM yyyy, HH:mm').format(_waktuKeluar);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F9),
      appBar: AppBar(
        backgroundColor: primaryOutColor,
        title: Text('Input Keluar: ${widget.selectedMethod['name']}'),
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.pop(context)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- SEKSI TANGGAL & WAKTU ---
              const Text('Waktu Pengeluaran', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF264653))),
              const SizedBox(height: 8),
              InkWell(
                onTap: _pilihWaktu,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(stringWaktu, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                      const Icon(Icons.calendar_month, color: primaryOutColor),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // --- FORM INFORMASI PENGELUARAN ---
              const Text('Informasi Pengeluaran', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF264653))),
              const SizedBox(height: 8),
              TextFormField(
                controller: _catatanController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Catatan tambahan pengeluaran...',
                  filled: true, fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 20),

              // --- SEKSI UPLOAD BUKTI FOTO ---
              const Text('Bukti Foto (Opsional)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF264653))),
              const SizedBox(height: 8),
              Center(
                child: GestureDetector(
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      builder: (context) => SafeArea(
                        child: Wrap(
                          children: [
                            ListTile(leading: const Icon(Icons.camera_alt), title: const Text('Kamera'), onTap: () { _pickImage(ImageSource.camera); Navigator.pop(context); }),
                            ListTile(leading: const Icon(Icons.photo_library), title: const Text('Galeri'), onTap: () { _pickImage(ImageSource.gallery); Navigator.pop(context); }),
                          ],
                        ),
                      ),
                    );
                  },
                  child: Container(
                    height: 150, width: double.infinity,
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade300)),
                    child: _imageFile != null
                        ? ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.file(_imageFile!, fit: BoxFit.cover))
                        : const Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.camera_alt_outlined, size: 40, color: Colors.grey), SizedBox(height: 8), Text('Ketuk untuk ambil/pilih foto', style: TextStyle(color: Colors.grey, fontSize: 12))]),
                  ),
                ),
              ),
              const SizedBox(height: 25),

              // --- SEKSI DAFTAR ITEM SAMPAH ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Daftar Item Sampah', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF264653))),
                  TextButton.icon(
                    icon: const Icon(Icons.add, color: primaryOutColor, size: 18),
                    label: const Text('Tambah Item', style: TextStyle(color: primaryOutColor, fontWeight: FontWeight.bold)),
                    onPressed: _bukaModalTambahItem,
                  )
                ],
              ),
              const SizedBox(height: 8),

              _daftarItemSampah.isEmpty
                  ? Container(
                      width: double.infinity, padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                      child: const Center(child: Text('Belum ada item sampah yang dimasukkan.', style: TextStyle(color: Colors.grey, fontSize: 13))),
                    )
                  : ListView.builder(
                      shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
                      itemCount: _daftarItemSampah.length,
                      itemBuilder: (context, idx) {
                        final item = _daftarItemSampah[idx];
                        return Card(
                          color: Colors.white, elevation: 0,
                          margin: const EdgeInsets.only(bottom: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          child: ListTile(
                            leading: IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red), onPressed: () => setState(() => _daftarItemSampah.removeAt(idx))),
                            title: Text(item['name'] ?? '-', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            trailing: Text('${item['quantity']} ${item['unit']}', style: const TextStyle(color: primaryOutColor, fontWeight: FontWeight.bold)),
                          ),
                        );
                      },
                    ),

              const SizedBox(height: 40),

              // --- TOMBOL SIMPAN KE DB ---
              SizedBox(
                width: double.infinity, height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: primaryOutColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  onPressed: _isSaving ? null : _pushDataSampahKeluar,
                  child: _isSaving 
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Simpan Data Keluar', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

class AppErrorDialog extends StatelessWidget {
  final String msg;
  const AppErrorDialog({super.key, required this.msg});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Error Push Data'),
      content: Text(msg),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
    );
  }
}