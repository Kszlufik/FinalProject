import 'package:flutter/material.dart';

class FiltersBar extends StatelessWidget {
  final String sortBy; // current sorting value
  final String genre; // current genre value
  final Function(String?) onSortChange;
  final Function(String?) onGenreChange;
  final VoidCallback onClearFilters;

  const FiltersBar({
    super.key,
    required this.sortBy,
    required this.genre,
    required this.onSortChange,
    required this.onGenreChange,
    required this.onClearFilters,
  });

  @override
  Widget build(BuildContext context) {
    // We implement sorting options
    final sortOptions = <String, String>{
      '-rating': 'Rating High → Low',
      'rating': 'Rating Low → High',
      '-released': 'Release New → Old',
      'released': 'Release Old → New',
    };

    // genere options 
    final genreOptions = <String, String>{
      '': 'All Genres',
      '4': 'Action',
      '51': 'Indie',
      '3': 'Adventure',
      '5': 'RPG',
      '10': 'Strategy',
      '2': 'Shooter',
      '7': 'Puzzle',
      '8': 'Arcade',
      '11': 'Horror',
      '14': 'Simulation',
      '83': 'Platformer',
      '6': 'Fighting',
      '40': 'Casual',
      '13': 'Educational',
    };

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
      child: Row(
        children: [
          // sort dropdown
          DropdownButton<String>(
            value: sortOptions.containsKey(sortBy) ? sortBy : null,
            hint: const Text('Sort by'),
            items: sortOptions.entries
                .map(
                  (e) => DropdownMenuItem(
                    value: e.key,
                    child: Text(e.value),
                  ),
                )
                .toList(),
            onChanged: onSortChange,
          ),

          const SizedBox(width: 16),

          // genre dropdown
          DropdownButton<String>(
            value: genreOptions.containsKey(genre) ? genre : '',
            hint: const Text('Genre'),
            items: genreOptions.entries
                .map(
                  (e) => DropdownMenuItem(
                    value: e.key,
                    child: Text(e.value),
                  ),
                )
                .toList(),
            onChanged: onGenreChange,
          ),

          const SizedBox(width: 16),

          // clear Filters Button
          ElevatedButton(
            onPressed: onClearFilters,
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }
}
