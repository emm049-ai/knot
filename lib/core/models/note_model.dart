class Note {
  final String id;
  final String contactId;
  final String content;
  final String inputType; // 'voice', 'ocr', 'manual', 'email_bcc'
  final DateTime createdAt;

  Note({
    required this.id,
    required this.contactId,
    required this.content,
    required this.inputType,
    required this.createdAt,
  });

  factory Note.fromJson(Map<String, dynamic> json) {
    return Note(
      id: json['id'] as String,
      contactId: json['contact_id'] as String,
      content: json['content'] as String,
      inputType: json['input_type'] as String,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'contact_id': contactId,
      'content': content,
      'input_type': inputType,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
