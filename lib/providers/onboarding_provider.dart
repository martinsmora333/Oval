import 'package:flutter/material.dart';
import '../models/tennis_center_draft.dart';

class OnboardingProvider extends ChangeNotifier {
  TennisCenterDraft _draft = TennisCenterDraft();
  int _currentStep = 0; // 0-based index of onboarding flow

  TennisCenterDraft get draft => _draft;
  int get currentStep => _currentStep;

  // Centre-wide setters
  void updateCenterInfo(Map<String, dynamic> info) {
    _draft.centerInfo = info;
    notifyListeners();
  }

  void updateAddress(Map<String, dynamic> info) {
    _draft.addressInfo = info;
    notifyListeners();
  }

  void updateContact(Map<String, dynamic> info) {
    _draft.contactInfo = info;
    notifyListeners();
  }

  // Courts list helpers
  void addCourt([Map<String, dynamic>? court]) {
    final newCourt = court ?? {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'name': 'Court ${_draft.courts.length + 1}',
      'surface': 'Hard',
      'indoor': false,
      'lighting': 'None',
      'pricePerHour': 25.0,
      'isActive': true,
    };
    _draft.courts.add(newCourt);
    notifyListeners();
  }

  void initializeCourts(List<Map<String, dynamic>> courts) {
    _draft.courts = List<Map<String, dynamic>>.from(courts);
    notifyListeners();
  }

  void updateCourt(String id, Map<String, dynamic> updates) {
    final idx = _draft.courts.indexWhere((c) => c['id'] == id);
    if (idx == -1) return;
    _draft.courts[idx] = {..._draft.courts[idx], ...updates};
    notifyListeners();
  }

  void removeCourt(String id) {
    if (_draft.courts.length == 1) return; // keep at least one
    _draft.courts.removeWhere((c) => c['id'] == id);
    // rename sequentially
    for (int i = 0; i < _draft.courts.length; i++) {
      _draft.courts[i]['name'] = 'Court ${i + 1}';
    }
    notifyListeners();
  }

  // Operating hours (simplified)
  void setDayHours(String day, String open, String close) {
    _draft.operatingHours[day] = {'open': open, 'close': close};
    notifyListeners();
  }

  // Navigation helpers
  void nextStep() {
    _currentStep++;
    notifyListeners();
  }

  void previousStep() {
    if (_currentStep > 0) _currentStep--;
    notifyListeners();
  }

  void jumpToStep(int step) {
    _currentStep = step;
    notifyListeners();
  }

  void reset() {
    _draft = TennisCenterDraft();
    _currentStep = 0;
    notifyListeners();
  }
}
