import 'package:flutter/material.dart';
import '../../models/event_model.dart';
import '../../models/tag_model.dart';
import '../../services/review_service.dart';
import '../../utils/app_theme.dart';

class ReviewScreen extends StatefulWidget {
  final EventModel event;
  final String brandId;
  final VoidCallback? onReviewSubmitted;

  const ReviewScreen({
    super.key,
    required this.event,
    required this.brandId,
    this.onReviewSubmitted,
  });

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  int _rating = 0;
  final Set<String> _selectedTags = {};
  final _commentController = TextEditingController();
  bool _isSubmitting = false;
  List<TagModel> _availableTags = [];
  bool _isLoadingTags = true;

  @override
  void initState() {
    super.initState();
    _loadTags();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _loadTags() async {
    try {
      final tags = await ReviewService.getAllTags();
      setState(() {
        _availableTags = tags;
        _isLoadingTags = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingTags = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading tags: ${e.toString()}'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _submitReview() async {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a rating'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    if (_selectedTags.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one tag'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      await ReviewService.submitReview(
        eventId: widget.event.id,
        brandId: widget.brandId,
        rating: _rating,
        tagNames: _selectedTags.toList(),
        comment: _commentController.text.trim().isEmpty
            ? null
            : _commentController.text.trim(),
      );

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ReviewConfirmationScreen(pointsEarned: 10),
          ),
        );
        widget.onReviewSubmitted?.call();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Leave a Review')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Event Info
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.event.storeName,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.event.location,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Rating
            Text('Rating', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                return IconButton(
                  icon: Icon(
                    index < _rating ? Icons.star : Icons.star_border,
                    size: 48,
                    color: index < _rating
                        ? AppTheme.warningColor
                        : AppTheme.borderColor,
                  ),
                  onPressed: () {
                    setState(() {
                      _rating = index + 1;
                    });
                  },
                );
              }),
            ),

            const SizedBox(height: 32),

            // Tags
            Text(
              'Tags (select all that apply)',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            _isLoadingTags
                ? const Center(child: CircularProgressIndicator())
                : _availableTags.isEmpty
                ? Text(
                    'No tags available',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  )
                : Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _availableTags.map((tag) {
                      final isSelected = _selectedTags.contains(tag.name);
                      return FilterChip(
                        label: Text(tag.name),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedTags.add(tag.name);
                            } else {
                              _selectedTags.remove(tag.name);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),

            const SizedBox(height: 32),

            // Comment
            Text(
              'Additional Comments (Optional)',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _commentController,
              maxLines: 5,
              decoration: const InputDecoration(
                hintText: 'Share your experience...',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 32),

            // Submit Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitReview,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : const Text('Submit Review'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ReviewConfirmationScreen extends StatelessWidget {
  final int pointsEarned;

  const ReviewConfirmationScreen({super.key, required this.pointsEarned});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check_circle, size: 80, color: AppTheme.successColor),
              const SizedBox(height: 24),
              Text(
                'Review Submitted',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Text(
                        'You earned',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '$pointsEarned Points',
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('Done'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
