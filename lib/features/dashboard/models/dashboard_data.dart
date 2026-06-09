import 'dashboard_summary.dart';

class DashboardData {
  final String fullName;
  final String? photo;
  final List<dynamic> categories;
  final List<dynamic> recentEntries;
  final DashboardSummary summary;

  DashboardData({
    required this.fullName,
    required this.photo,
    required this.categories,
    required this.recentEntries,
    required this.summary,
  });

  factory DashboardData.fromJson(Map<String, dynamic> json) {
    return DashboardData(
      fullName: json['full_name'] ?? '',
      photo: json['user_photo'],
      categories: json['categories'] ?? [],
      recentEntries: json['recent_entries'] ?? [],
      summary: DashboardSummary.fromJson(
        json['today_summary'] ?? {},
      ),
    );
  }
}