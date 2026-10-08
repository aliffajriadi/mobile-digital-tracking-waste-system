import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/app_events.dart';
import '../../core/network/api_exception.dart';
import '../../core/session/session_store.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_feedback.dart';
import '../../core/widgets/state_views.dart';
import '../../data/repository.dart';

class IotPage extends StatefulWidget {
  const IotPage({super.key});

  @override
  State<IotPage> createState() => _IotPageState();
}

class _IotPageState extends State<IotPage> {
  final _code = TextEditingController();
  bool _loading = true;
  bool _busy = false;
  String? _pairedCode;
  String? _error;

  @override
  void initState() {
    super.initState();
    _restore();
  }

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  /// Status diambil dari server, bukan hanya dari HP, agar sesuai dengan kondisi timbangan.
  Future<void> _restore() async {
    setState(() => _loading = true);
    try {
      final code = await Repo.iotSession();
      await SessionStore.setIotCode(code);
      if (mounted) setState(() => _pairedCode = code);
    } on ApiException {
      final local = await SessionStore.iotCode();
      if (mounted) setState(() => _pairedCode = local);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pair() async {
    final code = _code.text.trim().toUpperCase();
    if (code.length < 4) {
      setState(() => _error = 'Masukkan 4 karakter kode yang tampil di layar timbangan.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final message = await Repo.iotPair(code);
      await SessionStore.setIotCode(code);
      if (!mounted) return;
      setState(() => _pairedCode = code);
      _code.clear();
      AppFeedback.success(context, message);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _unpair() async {
    final ok = await AppFeedback.confirm(
      context,
      title: 'Putuskan timbangan?',
      message: 'Timbangan tidak akan lagi mencatat atas nama Anda dan akan menampilkan kode baru.',
      confirmLabel: 'Putuskan',
      destructive: true,
    );
    if (!ok || _pairedCode == null) return;
    setState(() => _busy = true);
    try {
      final message = await Repo.iotUnpair(_pairedCode!);
      if (mounted) AppFeedback.success(context, message);
    } on ApiException catch (e) {
      // Kode sudah kedaluwarsa di server: tetap bersihkan status lokal
      if (e.statusCode != 404 && mounted) {
        AppFeedback.snack(context, e.message, type: FeedbackType.error);
        setState(() => _busy = false);
        return;
      }
    }
    await SessionStore.setIotCode(null);
    AppEvents.notifyDataChanged();
    if (mounted) {
      setState(() {
        _pairedCode = null;
        _busy = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Timbangan IoT')),
      body: _loading
          ? const LoadingView(message: 'Memeriksa status timbangan…')
          : RefreshIndicator(
              onRefresh: _restore,
              child: ListView(physics: const AlwaysScrollableScrollPhysics(), padding: const EdgeInsets.all(20), children: [
                if (_pairedCode != null) _connected() else _pairForm(),
                const SizedBox(height: 24),
                const Text('Cara pakai', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                const SizedBox(height: 10),
                const _Step(n: 1, text: 'Nyalakan timbangan. Layar akan menampilkan 4 karakter kode.'),
                const _Step(n: 2, text: 'Masukkan kode tersebut di halaman ini lalu ketuk Hubungkan.'),
                const _Step(n: 3, text: 'Letakkan sampah, pilih jenisnya di timbangan, lalu kirim. Data masuk otomatis atas nama Anda.'),
                const _Step(n: 4, text: 'Selesai bertugas? Ketuk Putuskan agar petugas lain bisa memakai timbangan.'),
              ]),
            ),
    );
  }

  Widget _connected() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [AppColors.primaryDark, AppColors.primary]),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.18), shape: BoxShape.circle),
          child: const Icon(Icons.link_rounded, color: Colors.white, size: 36),
        ),
        const SizedBox(height: 14),
        const Text('Timbangan terhubung', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text('Kode perangkat $_pairedCode', style: const TextStyle(color: Colors.white70)),
        const SizedBox(height: 6),
        const Text('Setiap timbangan yang dikirim tercatat sebagai Sampah Masuk Anda.',
            textAlign: TextAlign.center, style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.4)),
        const SizedBox(height: 18),
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: const BorderSide(color: Colors.white54)),
          onPressed: _busy ? null : _unpair,
          icon: _busy
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.link_off_rounded),
          label: const Text('Putuskan timbangan'),
        ),
      ]),
    );
  }

  Widget _pairForm() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(children: [
          Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(color: AppColors.primarySoft, shape: BoxShape.circle),
            child: const Icon(Icons.scale_rounded, color: AppColors.primary, size: 34),
          ),
          const SizedBox(height: 14),
          const Text('Hubungkan timbangan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          const Text('Masukkan kode yang tampil di layar timbangan.', style: TextStyle(color: AppColors.inkSoft)),
          const SizedBox(height: 18),
          TextField(
            controller: _code,
            textAlign: TextAlign.center,
            maxLength: 4,
            textCapitalization: TextCapitalization.characters,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp('[a-zA-Z0-9]')),
              TextInputFormatter.withFunction((_, v) => v.copyWith(text: v.text.toUpperCase())),
            ],
            onSubmitted: (_) => _pair(),
            style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800, letterSpacing: 12),
            decoration: InputDecoration(counterText: '', hintText: 'A1B2', errorText: _error, errorMaxLines: 3),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _busy ? null : _pair,
            icon: _busy
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.link_rounded),
            label: const Text('Hubungkan'),
          ),
        ]),
      ),
    );
  }
}

class _Step extends StatelessWidget {
  final int n;
  final String text;
  const _Step({required this.n, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 24,
          height: 24,
          alignment: Alignment.center,
          decoration: const BoxDecoration(color: AppColors.primarySoft, shape: BoxShape.circle),
          child: Text('$n', style: const TextStyle(color: AppColors.primaryDark, fontWeight: FontWeight.w700, fontSize: 12)),
        ),
        const SizedBox(width: 12),
        Expanded(child: Text(text, style: const TextStyle(height: 1.5, fontSize: 13))),
      ]),
    );
  }
}
