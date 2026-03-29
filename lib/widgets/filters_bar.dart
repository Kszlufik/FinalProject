import 'package:flutter/material.dart';

// Sort and genre filter bar — scrolls horizontally on narrow screens
class FiltersBar extends StatelessWidget {
  final String sortBy;
  final String genre;
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
    const _accent = Color(0xFF00E5FF);
    const _surface = Color(0xFF161B22);
    const _textSecondary = Color(0xFF8B949E);
    const _border = Color(0xFF30363D);
    const _bg = Color(0xFF0D1117);

    // Sort options passed to RAWG as the ordering parameter
    final sortOptions = <String, String>{
      '-rating': 'Top Rated',
      'rating': 'Lowest Rated',
      '-released': 'Newest First',
      'released': 'Oldest First',
    };

    // Genre options use RAWG genre IDs as keys
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

    // Wrapping in SingleChildScrollView prevents overflow on narrow screens
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      child: Row(
        children: [
          // Sort order dropdown
          _buildDropdown<String>(
            value: sortOptions.containsKey(sortBy) ? sortBy : '-rating',
            items: sortOptions,
            onChanged: onSortChange,
            icon: Icons.sort,
          ),
          const SizedBox(width: 10),

          // Genre filter dropdown
          _buildDropdown<String>(
            value: genreOptions.containsKey(genre) ? genre : '',
            items: genreOptions,
            onChanged: onGenreChange,
            icon: Icons.category_outlined,
          ),
          const SizedBox(width: 10),

          // Clear all filters button
          GestureDetector(
            onTap: onClearFilters,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: _surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _border),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.clear, color: _textSecondary, size: 14),
                  SizedBox(width: 4),
                  Text('Clear', style: TextStyle(color: _textSecondary, fontSize: 12)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Reusable styled dropdown used for both sort and genre
  Widget _buildDropdown<T>({
    required T value,
    required Map<T, String> items,
    required Function(T?) onChanged,
    required IconData icon,
  }) {
    const _surface = Color(0xFF161B22);
    const _textPrimary = Color(0xFFE6EDF3);
    const _textSecondary = Color(0xFF8B949E);
    const _border = Color(0xFF30363D);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          dropdownColor: _surface,
          style: const TextStyle(color: _textPrimary, fontSize: 12),
          icon: const Icon(Icons.keyboard_arrow_down, color: _textSecondary, size: 16),
          isDense: true,
          items: items.entries.map((e) => DropdownMenuItem<T>(
            value: e.key,
            child: Text(e.value, style: const TextStyle(color: _textPrimary, fontSize: 12)),
          )).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}