class Task {
  final int id;
  final String title;
  final String? description;
  final bool isCompleted;
  final String priority;
  final String? category;
  final DateTime createdAt;

  Task({
    required this.id,
    required this.title,
    this.description,
    this.isCompleted = false,
    this.priority = 'medium',
    this.category,
    required this.createdAt,
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      isCompleted: json['isCompleted'],
      priority: json['priority'] ?? 'medium',
      category: json['category'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'isCompleted': isCompleted,
      'priority': priority,
      'category': category,
    };
  }
}
