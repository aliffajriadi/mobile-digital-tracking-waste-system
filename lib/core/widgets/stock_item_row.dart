import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';
import '../utils/formatters.dart';

/// Satu baris item (bahan baku / sampah keluar) dengan input jumlah yang dibatasi stok.
class StockItemRow extends StatelessWidget {
  final String name;
  final String unit;
  final double stock;
  final TextEditingController controller;
  final VoidCallback onRemove;
  final ValueChanged<String>? onChanged;
  final String? badge;
  final Color color;

  const StockItemRow({
    super.key,
    required this.name,
    required this.unit,
    required this.stock,
    required this.controller,
    required this.onRemove,
    this.onChanged,
    this.badge,
    this.color = AppColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 8, 4, 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
            child: Text.rich(
              TextSpan(children: [
                TextSpan(text: name, style: const TextStyle(fontWeight: FontWeight.w600)),
                if (badge != null)
                  WidgetSpan(
                    alignment: PlaceholderAlignment.middle,
                    child: Container(
                      margin: const EdgeInsets.only(left: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(6)),
                      child: Text(badge!, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w700)),
                    ),
                  ),
              ]),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            tooltip: 'Hapus',
            visualDensity: VisualDensity.compact,
            onPressed: onRemove,
            icon: const Icon(Icons.close_rounded, color: AppColors.muted),
          ),
        ]),
        Padding(
          padding: const EdgeInsets.only(right: 10),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Stok ${Fmt.qtyUnit(stock, unit)}', style: const TextStyle(fontSize: 12, color: AppColors.inkSoft)),
                InkWell(
                  borderRadius: BorderRadius.circular(6),
                  onTap: () {
                    controller.text = Fmt.qty(stock).replaceAll('.', '');
                    onChanged?.call(controller.text);
                  },
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 6),
                    child: Text('Pakai semua', style: TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600)),
                  ),
                ),
              ]),
            ),
            const SizedBox(width: 10),
            SizedBox(
              width: 132,
              child: TextFormField(
                controller: controller,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
                textAlign: TextAlign.right,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                autovalidateMode: AutovalidateMode.onUserInteraction,
                onChanged: onChanged,
                validator: (v) {
                  final q = Fmt.parseDecimal(v);
                  if (q == null || q <= 0) return 'Isi jumlah';
                  if (q > stock + 0.0001) return 'Maks ${Fmt.qty(stock)}';
                  return null;
                },
                decoration: InputDecoration(
                  isDense: true,
                  hintText: '0',
                  suffixText: unit,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  errorMaxLines: 2,
                ),
              ),
            ),
          ]),
        ),
      ]),
    );
  }
}
