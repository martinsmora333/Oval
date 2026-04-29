class TennisCenterDraft {
  // Basic info fields – expand as needed
  Map<String, dynamic> centerInfo;
  Map<String, dynamic> addressInfo;
  Map<String, dynamic> contactInfo;
  List<Map<String, dynamic>> courts;
  Map<String, Map<String, String>> operatingHours; // day -> {open, close}

  TennisCenterDraft({
    Map<String, dynamic>? centerInfo,
    Map<String, dynamic>? addressInfo,
    Map<String, dynamic>? contactInfo,
    List<Map<String, dynamic>>? courts,
    Map<String, Map<String, String>>? operatingHours,
  })  : centerInfo = centerInfo ?? <String, dynamic>{},
        addressInfo = addressInfo ?? <String, dynamic>{},
        contactInfo = contactInfo ?? <String, dynamic>{},
        courts = courts ?? <Map<String, dynamic>>[{
          'id': DateTime.now().millisecondsSinceEpoch.toString(),
          'name': 'Court 1',
          'surface': 'Hard',
          'indoor': false,
          'lighting': 'None',
          'pricePerHour': 25.0,
          'isActive': true,
        }],
        operatingHours = operatingHours ?? {};

  // Clone helper
  TennisCenterDraft copyWith({
    Map<String, dynamic>? centerInfo,
    Map<String, dynamic>? addressInfo,
    Map<String, dynamic>? contactInfo,
    List<Map<String, dynamic>>? courts,
    Map<String, Map<String, String>>? operatingHours,
  }) {
    return TennisCenterDraft(
      centerInfo: centerInfo ?? Map<String, dynamic>.from(this.centerInfo),
      addressInfo: addressInfo ?? Map<String, dynamic>.from(this.addressInfo),
      contactInfo: contactInfo ?? Map<String, dynamic>.from(this.contactInfo),
      courts: courts ?? List<Map<String, dynamic>>.from(this.courts),
      operatingHours: operatingHours ?? Map<String, Map<String, String>>.from(this.operatingHours),
    );
  }
}
