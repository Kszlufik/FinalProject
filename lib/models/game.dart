class Game {
  final int id;
  final String name;
  final String backgroundImage;
  final double rating;
  final String released;
  final String description;
  final List<String> platforms;

  Game({
    required this.id,
    required this.name,
    required this.backgroundImage,
    required this.rating,
    required this.released,
    this.description = 'No description available.',
    this.platforms = const [],
  });

  factory Game.fromJson(Map<String, dynamic> json) {
    // Parse platforms from RAWG response
    List<String> parsedPlatforms = [];
    if (json['platforms'] != null) {
      parsedPlatforms = (json['platforms'] as List)
          .map((p) => p['platform']['name'].toString())
          .toList();
    }

    return Game(
      id: json['id'],
      name: json['name'] ?? 'Unknown',
      backgroundImage: json['background_image'] ?? '',
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      released: json['released'] ?? 'Unknown',
      description: json['description_raw'] ?? 'No description available.',
      platforms: parsedPlatforms,
    );
  }
}