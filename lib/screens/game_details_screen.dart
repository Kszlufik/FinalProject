import 'package:flutter/material.dart';
import '../models/game.dart';
import '../services/user_service.dart';
import '../widgets/review_dialog.dart';

class GameDetailsScreen extends StatefulWidget {
  final Game game;
  const GameDetailsScreen({super.key, required this.game});

  @override
  State<GameDetailsScreen> createState() => _GameDetailsScreenState();
}

class _GameDetailsScreenState extends State<GameDetailsScreen> {
  static const _bg = Color(0xFF0D1117);
  static const _surface = Color(0xFF161B22);
  static const _surface2 = Color(0xFF1C2333);
  static const _accent = Color(0xFF00E5FF);
  static const _textPrimary = Color(0xFFE6EDF3);
  static const _textSecondary = Color(0xFF8B949E);
  static const _border = Color(0xFF30363D);
  static const _gold = Color(0xFFFFD700);

  final UserService _userService = UserService();
  Map<String, dynamic>? existingReview;
  bool isLoadingReview = true;

  @override
  void initState() {
    super.initState();
    _loadReview();
  }

  Future<void> _loadReview() async {
    final review = await _userService.loadReview(widget.game.id);
    if (mounted) setState(() { existingReview = review; isLoadingReview = false; });
  }

  Future<void> _openReviewDialog() async {
    final result = await showDialog<dynamic>(
      context: context,
      builder: (_) => ReviewDialog(gameName: widget.game.name, existingReview: existingReview),
    );
    if (result == null) return;
    if (result == 'delete') {
      await _userService.deleteReview(widget.game.id);
      if (mounted) setState(() => existingReview = null);
      return;
    }
    await _userService.saveReview(
      gameId: widget.game.id,
      gameName: widget.game.name,
      imageUrl: widget.game.backgroundImage,
      reviewText: result['reviewText'],
      personalRating: result['personalRating'],
      status: result['status'],
    );
    if (mounted) setState(() => existingReview = result);
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Completed': return const Color(0xFF4ADE80);
      case 'Playing': return _accent;
      case 'Dropped': return Colors.redAccent;
      default: return _textSecondary;
    }
  }

  String _statusEmoji(String status) {
    switch (status) {
      case 'Completed': return '✅';
      case 'Playing': return '🎮';
      case 'Dropped': return '❌';
      default: return '🎮';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: _bg,
        colorScheme: const ColorScheme.dark(primary: _accent, surface: _surface),
      ),
      child: Scaffold(
        backgroundColor: _bg,
        body: CustomScrollView(
          slivers: [
            _buildHeroAppBar(),
            SliverToBoxAdapter(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 800),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildGameMeta(),
                        const SizedBox(height: 16),
                        if (widget.game.platforms.isNotEmpty) _buildPlatformChips(),
                        const SizedBox(height: 24),
                        _buildDescription(),
                        const SizedBox(height: 32),
                        _buildReviewSection(),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroAppBar() {
    return SliverAppBar(
      expandedHeight: 280,
      pinned: true,
      backgroundColor: _surface,
      leading: Padding(
        padding: const EdgeInsets.all(8),
        child: CircleAvatar(
          backgroundColor: _bg.withOpacity(0.7),
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: _textPrimary, size: 16),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: CircleAvatar(
            backgroundColor: _bg.withOpacity(0.7),
            child: IconButton(
              icon: Icon(
                existingReview != null ? Icons.rate_review : Icons.rate_review_outlined,
                color: existingReview != null ? _accent : _textPrimary,
                size: 18,
              ),
              onPressed: _openReviewDialog,
              tooltip: existingReview != null ? 'Edit Review' : 'Write Review',
            ),
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            if (widget.game.backgroundImage.isNotEmpty)
              Image.network(
                widget.game.backgroundImage,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(color: _surface2),
              ),
            // Gradient overlay bottom
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Color(0xFF0D1117)],
                  stops: [0.4, 1.0],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGameMeta() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.game.name,
          style: const TextStyle(color: _textPrimary, fontSize: 26, fontWeight: FontWeight.bold, height: 1.2),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: _gold.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _gold.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.star_rounded, color: _gold, size: 16),
                  const SizedBox(width: 4),
                  Text(widget.game.rating.toStringAsFixed(2), style: const TextStyle(color: _gold, fontWeight: FontWeight.bold, fontSize: 13)),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: _surface2,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _border),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today_outlined, color: _textSecondary, size: 13),
                  const SizedBox(width: 4),
                  Text(widget.game.released, style: const TextStyle(color: _textSecondary, fontSize: 13)),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPlatformChips() {
    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: widget.game.platforms.map((p) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: _surface2,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _border),
        ),
        child: Text(p, style: const TextStyle(color: _textSecondary, fontSize: 11)),
      )).toList(),
    );
  }

  Widget _buildDescription() {
    if (widget.game.description.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('ABOUT', style: TextStyle(color: _textSecondary, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
        const SizedBox(height: 10),
        Text(
          widget.game.description,
          style: const TextStyle(color: _textSecondary, fontSize: 14, height: 1.6),
        ),
      ],
    );
  }

  Widget _buildReviewSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(height: 1, color: _border),
        const SizedBox(height: 24),
        const Text('YOUR REVIEW', style: TextStyle(color: _textSecondary, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
        const SizedBox(height: 14),
        if (isLoadingReview)
          Center(child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: _accent, strokeWidth: 2)))
        else if (existingReview != null)
          _buildExistingReview()
        else
          _buildNoReview(),
      ],
    );
  }

  Widget _buildExistingReview() {
    final status = existingReview!['status'] ?? 'Playing';
    final personalRating = (existingReview!['personalRating'] as num?)?.toDouble() ?? 0;
    final reviewText = existingReview!['reviewText']?.toString() ?? '';
    final statusColor = _statusColor(status);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: statusColor.withOpacity(0.3)),
                ),
                child: Text(
                  '${_statusEmoji(status)} $status',
                  style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
              const Spacer(),
              Row(
                children: List.generate(5, (i) => Icon(
                  personalRating > i ? Icons.star_rounded : Icons.star_outline_rounded,
                  color: personalRating > i ? _gold : _textSecondary.withOpacity(0.3),
                  size: 20,
                )),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: _openReviewDialog,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: _accent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _accent.withOpacity(0.3)),
                  ),
                  child: const Text('Edit', style: TextStyle(color: _accent, fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
          if (reviewText.isNotEmpty) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _surface2,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _border),
              ),
              child: Text(reviewText, style: const TextStyle(color: _textSecondary, fontSize: 14, height: 1.5)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNoReview() {
    return GestureDetector(
      onTap: _openReviewDialog,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _border, style: BorderStyle.solid),
        ),
        child: Column(
          children: [
            Icon(Icons.rate_review_outlined, size: 40, color: _textSecondary.withOpacity(0.4)),
            const SizedBox(height: 10),
            const Text('No review yet', style: TextStyle(color: _textSecondary, fontSize: 14)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: _accent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _accent.withOpacity(0.3)),
              ),
              child: const Text('Write a Review', style: TextStyle(color: _accent, fontWeight: FontWeight.bold, fontSize: 13)),
            ),
          ],
        ),
      ),
    );
  }
}