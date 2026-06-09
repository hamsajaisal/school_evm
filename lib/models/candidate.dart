class Candidate {
  final String id;
  final int serialNumber;
  final String name;
  final String symbolName;
  final String? photoBase64;
  int votes;

  Candidate({
    required this.id,
    required this.serialNumber,
    required this.name,
    required this.symbolName,
    this.photoBase64,
    this.votes = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'serialNumber': serialNumber,
      'name': name,
      'symbolName': symbolName,
      'photoBase64': photoBase64,
      'votes': votes,
    };
  }

  factory Candidate.fromMap(Map<dynamic, dynamic> map) {
    return Candidate(
      id: map['id'] as String,
      serialNumber: map['serialNumber'] as int,
      name: map['name'] as String,
      symbolName: map['symbolName'] as String,
      photoBase64: map['photoBase64'] as String?,
      votes: map['votes'] as int? ?? 0,
    );
  }
}
