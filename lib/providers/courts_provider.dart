import 'package:flutter/material.dart';

class CourtsProvider with ChangeNotifier {
  List<Map<String, dynamic>> _courts = [];

  List<Map<String, dynamic>> get courts => List.unmodifiable(_courts);

  void addCourt(Map<String, dynamic> court) {
    _courts.add(court);
    notifyListeners();
  }

  void updateCourt(int index, Map<String, dynamic> updates) {
    if (index < 0 || index >= _courts.length) return;
    _courts[index] = {..._courts[index], ...updates};
    notifyListeners();
  }

  void removeCourt(int index) {
    if (index < 0 || index >= _courts.length) return;
    _courts.removeAt(index);
    notifyListeners();
  }

  void initializeCourts(List<Map<String, dynamic>> initialCourts) {
    _courts = List.from(initialCourts);
    notifyListeners();
  }
}
