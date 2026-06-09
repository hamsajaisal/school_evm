class ElectionSettings {
  final String schoolName;
  final String year;
  final String targetClass;
  bool isElectionFinished;

  ElectionSettings({
    required this.schoolName,
    required this.year,
    required this.targetClass,
    this.isElectionFinished = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'schoolName': schoolName,
      'year': year,
      'targetClass': targetClass,
      'isElectionFinished': isElectionFinished,
    };
  }

  factory ElectionSettings.fromMap(Map<dynamic, dynamic> map) {
    return ElectionSettings(
      schoolName: map['schoolName'] as String? ?? '',
      year: map['year'] as String? ?? '',
      targetClass: map['targetClass'] as String? ?? '',
      isElectionFinished: map['isElectionFinished'] as bool? ?? false,
    );
  }
}
