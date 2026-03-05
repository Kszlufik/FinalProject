import 'package:flutter/material.dart';

class ReviewDialog extends StatefulWidget {
  final String gameName;
  final Map<String, dynamic>? existingReview;

  const ReviewDialog({
    super.key,
    required this.gameName,
    this.existingReview,
  });

  @override
  State<ReviewDialog> createState() => _ReviewDialogState();
}

class _ReviewDialogState extends State<ReviewDialog> {
  final TextEditingController _reviewController = TextEditingController();
  double _personalRating = 0;
  String _status = 'Playing';

  final List<String> _statusOptions = ['Playing', 'Completed', 'Dropped'];

  @override
  void initState() {
    super.initState();
    // If an existing review exists, pre-fill the fields
    if (widget.existingReview != null) {
      _reviewController.text = widget.existingReview!['reviewText'] ?? '';
      _personalRating = (widget.existingReview!['personalRating'] as num?)?.toDouble() ?? 0;
      _status = widget.existingReview!['status'] ?? 'Playing';
    }
  }

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.existingReview != null ? 'Edit Review' : 'Write a Review',
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.gameName,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 20),

            // Status selector
            const Text(
              'Status',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: _statusOptions.map((status) {
                final isSelected = _status == status;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(status),
                    selected: isSelected,
                    onSelected: (_) => setState(() => _status = status),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 20),

            // Star rating
            const Text(
              'Your Rating',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: List.generate(5, (index) {
                final starValue = index + 1.0;
                return IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: Icon(
                    _personalRating >= starValue
                        ? Icons.star
                        : Icons.star_border,
                    color: Colors.amber,
                    size: 32,
                  ),
                  onPressed: () => setState(() => _personalRating = starValue),
                );
              }),
            ),

            const SizedBox(height: 20),

            // Review text
            const Text(
              'Notes',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _reviewController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Write your thoughts about this game...',
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        // Delete button if editing existing review
        if (widget.existingReview != null)
          TextButton(
            onPressed: () => Navigator.pop(context, 'delete'),
            child: const Text(
              'Delete Review',
              style: TextStyle(color: Colors.red),
            ),
          ),
        TextButton(
          onPressed: () => Navigator.pop(context, null),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context, {
              'reviewText': _reviewController.text.trim(),
              'personalRating': _personalRating,
              'status': _status,
            });
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}