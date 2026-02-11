import 'package:flutter/material.dart';

class PaginationBar extends StatelessWidget {
  final int currentPage;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  const PaginationBar({
    super.key,
    required this.currentPage,
    this.onPrevious,
    this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ElevatedButton(
          onPressed: onPrevious,
          child: const Text('Previous'),
        ),
        const SizedBox(width: 16),
        Text('Page $currentPage'),
        const SizedBox(width: 16),
        ElevatedButton(
          onPressed: onNext,
          child: const Text('Next'),
        ),
      ],
    );
  }
}
