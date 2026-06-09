import 'package:flutter/material.dart';
import 'package:mobile/core/theme/app_theme.dart';
import '../models/settings_menu_model.dart';

class SettingsMenuTile extends StatelessWidget {
  final SettingsMenuModel item;

  const SettingsMenuTile({
    super.key,
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: item.onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(
                    item.icon,
                    color: Colors.white,
                    size: 22,
                  ),
                  if (item.showBadge)
                    const Positioned(
                      top: 8,
                      right: 8,
                      child: CircleAvatar(
                        radius: 4,
                        backgroundColor: Colors.red,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                item.title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF334155),
                ),
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: AppTheme.primaryColor,
            ),
          ],
        ),
      ),
    );
  }
}