class Course {
  final String id;
  final String title;
  final String description;
  final double price;
  final String videoUrl;

  Course({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.videoUrl,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'price': price,
    'videoUrl': videoUrl,
  };

  static Course fromJson(Map<String, dynamic> j) => Course(
    id: j['id'],
    title: j['title'],
    description: j['description'],
    price: (j['price'] ?? 0.0) * 1.0,
    videoUrl: j['videoUrl'],
  );
}
