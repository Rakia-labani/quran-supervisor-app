class NotificationModel {
  final int id;
  final int userId;
  final String title;

  // حقول إضافية للتفاصيل (في حال كنا نستخدم هذا النموذج للتفاصيل أيضاً)
  final bool? isRead;
  final String? content;
  final DateTime? createdAt;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    this.isRead,
    this.content,
    this.createdAt,
  });

  // دالة تحويل من JSON إلى نموذج (للقائمة)
  factory NotificationModel.fromJsonList(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as int,
      userId: json['user_id'] as int,
      title: json['title'] as String,
    );
  }

  // دالة تحويل من JSON إلى نموذج (للتفاصيل)
  factory NotificationModel.fromJsonDetails(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as int,
      userId: json['user_id'] as int,
      title: json['title'] as String,
      isRead: json['is_read'] as bool,
      content: json['content'] as String,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? ''),
    );
  }
}
