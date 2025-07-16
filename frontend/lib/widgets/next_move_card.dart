import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:schematiq/api/api_service.dart';
import 'package:schematiq/config/app_config.dart';
import 'package:schematiq/models/plan_model.dart';
import 'package:shimmer/shimmer.dart';

// A provider that takes the plan and fetches the suggestion for it.
final nextMoveProvider = FutureProvider.family<String, Plan>((ref, plan) {
  final apiService = ref.watch(apiServiceProvider);
  return apiService.getNextBestMove(plan);
});

class NextMoveCard extends ConsumerWidget {
  final Plan plan;

  const NextMoveCard({super.key, required this.plan});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nextMoveAsync = ref.watch(nextMoveProvider(plan));

    return nextMoveAsync.when(
      data: (suggestion) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.primary.withOpacity(0.3)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.lightbulb_outline_rounded, color: AppColors.primary, size: 28),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                suggestion,
                style: const TextStyle(fontSize: 15, color: AppColors.textSecondary, height: 1.5),
              ),
            ),
          ],
        ),
      ),
      loading: () => Shimmer.fromColors(
        baseColor: AppColors.cardBackground,
        highlightColor: AppColors.cardBackground.withOpacity(0.5),
        child: Container(
          height: 80,
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      error: (err, stack) => const SizedBox.shrink(), // Don't show anything on error
    );
  }
}