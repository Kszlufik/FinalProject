class Game {
  final int id;
  final String name;
  final String backgroundImage;
  final double rating;
  final String released;
  final String description; // optional for details

  Game({
    required this.id,
    required this.name,
    required this.backgroundImage,
    required this.rating,
    required this.released,
    this.description = 'No description available.',
  });

  factory Game.fromJson(Map<String, dynamic> json) {
    return Game(
      id: json['id'],
      name: json['name'] ?? 'Unknown',
      backgroundImage: json['background_image'] ?? '',
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      released: json['released'] ?? 'Unknown',
      description: json['description_raw'] ?? 'No description available.',
    );
  }
}
