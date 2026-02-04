class Game {
  final int id;
  final String name;
  final String backgroundImage;
  final double rating;
  final String released;

  Game({
    required this.id,
    required this.name,
    required this.backgroundImage,
    required this.rating,
    required this.released,
  });

  factory Game.fromJson(Map<String, dynamic> json) {
    return Game(
      id: json['id'],
      name: json['name'],
      backgroundImage: json['background_image'] ?? '',
      rating: (json['rating'] as num).toDouble(),
      released: json['released'] ?? 'Unknown',
    );
  }
}
