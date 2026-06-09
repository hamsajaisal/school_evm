class Voter {
  final String admissionNumber;
  final String serialNumber;
  final String fullName;
  final String classLevel;
  final String division;
  bool hasVoted;

  Voter({
    required this.admissionNumber,
    required this.serialNumber,
    required this.fullName,
    required this.classLevel,
    required this.division,
    this.hasVoted = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'admissionNumber': admissionNumber,
      'serialNumber': serialNumber,
      'fullName': fullName,
      'classLevel': classLevel,
      'division': division,
      'hasVoted': hasVoted,
    };
  }

  factory Voter.fromMap(Map<dynamic, dynamic> map) {
    return Voter(
      admissionNumber: map['admissionNumber'] as String,
      serialNumber: map['serialNumber'] as String,
      fullName: map['fullName'] as String,
      classLevel: map['classLevel'] as String,
      division: map['division'] as String,
      hasVoted: map['hasVoted'] as bool? ?? false,
    );
  }
}
