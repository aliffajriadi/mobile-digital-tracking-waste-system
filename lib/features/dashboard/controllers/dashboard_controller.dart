import 'package:flutter/material.dart';

import '../models/dashboard_data.dart';
import '../services/dashboard_service.dart';

class DashboardController extends ChangeNotifier {
  final DashboardService _service = DashboardService();

  DashboardData? data;

  bool isLoading = true;

  Future<void> loadDashboard() async {
    try {
      isLoading = true;
      notifyListeners();

      data = await _service.getDashboardData();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}