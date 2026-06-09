import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile/core/constants/api_constants.dart';
import 'package:mobile/core/widgets/ruler_picker_modal.dart';

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

  double _sliderValue = 0.0;

  // Variabel Fitur Waktu (Bisa Di-edit)
  DateTime _waktuKeluar = DateTime.now();

  // Variabel Fitur Upload Foto Bukti
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();

  // Variabel Fitur Dropdown Jenis Sampah Dinamis
  List<dynamic> _subcategoriesList = [];
  String? _selectedSubcategoryName;
  dynamic _selectedSubcategoryId;
  bool _isLoadingSubcategories = true;

  List<Map<String, dynamic>> _daftarItemSampah = [];
  bool _isSaving = false;

  // Variabel Ekstra Penjualan
  List<dynamic> _buyersList = [];
  String? _selectedBuyerName;
  int? _selectedBuyerId;
  final TextEditingController _revenueController = TextEditingController();

  // Variabel Ekstra TPA
  List<dynamic> _destinationsList = [];
  String? _selectedDestinationName;
  int? _selectedDestinationId;

  @override
  void initState() {
    super.initState();
    _fetchSubcategories();
    _fetchBuyersAndDestinations();
  }

  Future<void> _fetchBuyersAndDestinations() async {
    try {
      final methodStr = widget.selectedMethod['name'].toString().toLowerCase();
      if (methodStr.contains('penjualan')) {
        final res = await http.get(Uri.parse(ApiConstants.wasteBuyers));
        if (res.statusCode == 200) {
          final data = json.decode(res.body);
          setState(() => _buyersList = data['data'] ?? []);
        }
      }
      
      if (methodStr.contains('tpa') || methodStr.contains('buang')) {
        final res = await http.get(Uri.parse(ApiConstants.wasteDestinations));
        if (res.statusCode == 200) {
          final data = json.decode(res.body);
          setState(() => _destinationsList = data['data'] ?? []);
        }
      }
    } catch (e) {
      debugPrint("Error fetching extra fields: $e");
    }
  }

  // --- AMBIL DATA SUBKATEGORI UNTUK DROPDOWN ---
  Future<void> _fetchSubcategories() async {
    try {
      final response = await http.get(Uri.parse('${ApiConstants.baseUrl}/waste-subcategories'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        List<dynamic> raw = [];
        if (data is Map && data.containsKey('data')) {
          raw = data['data'] ?? [];
        } else if (data is List) {
          raw = data;
        } 
        
        final resProc = await http.get(Uri.parse(ApiConstants.processedWaste));
        List<dynamic> proc = [];
        if (resProc.statusCode == 200) {
           final procData = json.decode(resProc.body);
           proc = procData['data'] ?? [];
           proc = proc.map((e) => {
              'id': 'p_${e['id']}',
              'name': e['name'] + ' (Hasil Olahan)',
           }).toList();
        }

        setState(() {
          _subcategoriesList = [...raw, ...proc];
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
      _sliderValue = 0.0;
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
      
      if (_selectedDestinationId != null) {
        request.fields['id_waste_destination'] = _selectedDestinationId.toString();
      } else {
        String? destinationId = widget.selectedMethod['id_waste_destination']?.toString();
        if (destinationId != null) {
          request.fields['id_waste_destination'] = destinationId;
        }
      }

      if (_selectedBuyerId != null) {
        request.fields['id_buyer'] = _selectedBuyerId.toString();
        request.fields['total_revenue'] = _revenueController.text;
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
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white, 
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))]
                        ),
                        child: TextField(
                          controller: _qtyController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(
                            hintText: 'Kuantitas (Kilo)', 
                            suffixText: 'kg', 
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Material(
                      color: const Color(0xFFE76F51),
                      borderRadius: BorderRadius.circular(14),
                      elevation: 2,
                      shadowColor: const Color(0xFFE76F51).withOpacity(0.4),
                      child: InkWell(
                        onTap: () async {
                          double currentVal = double.tryParse(_qtyController.text.replaceAll(',', '.')) ?? 0.0;
                          final result = await showRulerPickerModal(
                            context,
                            initialValue: currentVal,
                            max: 500.0,
                            unit: 'kg',
                          );
                          if (result != null) {
                            setModalState(() {
                              _qtyController.text = result.toStringAsFixed(1);
                            });
                          }
                        },
                        borderRadius: BorderRadius.circular(10),
                        child: const Padding(
                          padding: EdgeInsets.all(15),
                          child: Icon(Icons.straighten_rounded, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
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
        elevation: 0,
        centerTitle: true,
        title: Text('Input Keluar: ${widget.selectedMethod['name']}', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20), onPressed: () => Navigator.pop(context)),
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
                  decoration: BoxDecoration(
                    color: Colors.white, 
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))]
                  ),
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

              // --- CONDITIONAL FIELDS BERDASARKAN METODE ---
              if (widget.selectedMethod['name'].toString().toLowerCase().contains('penjualan')) ...[
                const Text('Informasi Penjualan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF264653))),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))]),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedBuyerName,
                      hint: const Text('Pilih Pemborang / Pembeli'),
                      isExpanded: true,
                      items: _buyersList.map((item) {
                        return DropdownMenuItem<String>(value: item['name'], child: Text(item['name']));
                      }).toList(),
                      onChanged: (val) {
                        final selected = _buyersList.firstWhere((e) => e['name'] == val, orElse: () => null);
                        if (selected != null) {
                          setState(() {
                            _selectedBuyerName = val;
                            _selectedBuyerId = selected['id'];
                          });
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))]),
                  child: TextFormField(
                    controller: _revenueController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: 'Total Pendapatan (Rp)',
                      prefixText: 'Rp ',
                      filled: true, fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],

              if (widget.selectedMethod['name'].toString().toLowerCase().contains('tpa') || widget.selectedMethod['name'].toString().toLowerCase().contains('buang')) ...[
                const Text('Tujuan TPA', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF264653))),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))]),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedDestinationName,
                      hint: const Text('Pilih Tempat Tujuan TPA'),
                      isExpanded: true,
                      items: _destinationsList.map((item) {
                        return DropdownMenuItem<String>(value: item['name'], child: Text(item['name']));
                      }).toList(),
                      onChanged: (val) {
                        final selected = _destinationsList.firstWhere((e) => e['name'] == val, orElse: () => null);
                        if (selected != null) {
                          setState(() {
                            _selectedDestinationName = val;
                            _selectedDestinationId = selected['id'];
                          });
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // --- FORM INFORMASI PENGELUARAN ---
              const Text('Informasi Pengeluaran', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF264653))),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white, 
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))]
                ),
                child: TextFormField(
                  controller: _catatanController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Catatan tambahan pengeluaran...',
                    filled: true, fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                  ),
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
                    decoration: BoxDecoration(
                      color: Colors.white, 
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))]
                    ),
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
                          color: Colors.white,
                          elevation: 0,
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          shadowColor: Colors.black.withOpacity(0.1),
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