class Activity {
  final String title;
  final String description;
  final String date;
  final String? imageUrl;
  final String location;
  final String time;

  Activity({
    required this.title,
    required this.description,
    required this.date,
    this.imageUrl,
    required this.location,
    required this.time,
  });

  factory Activity.fromMap(Map<String, dynamic> data) {
    return Activity(
      title: (data['title'] ?? '').toString(),
      description: (data['description'] ?? '').toString(),
      date: (data['date'] ?? '').toString(),
      imageUrl: data['imageUrl'] as String?,
      location: (data['location'] ?? '').toString(),
      time: (data['time'] ?? '').toString(),
    );
  }
}
