import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:schematiq/config/app_config.dart';
import 'package:schematiq/models/plan_model.dart';
import 'package:schematiq/providers/plan_provider.dart';
import 'package:schematiq/screens/plan_view_screen.dart';
import 'package:shimmer/shimmer.dart';

class PlanCard extends ConsumerStatefulWidget {
  final Plan plan;
  const PlanCard({super.key, required this.plan});

  @override
  ConsumerState<PlanCard> createState() => _PlanCardState();
}

class _PlanCardState extends ConsumerState<PlanCard> {
  bool _isSuggestionExpanded = false;

  Widget _buildInfoBadge(String text, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.background.withOpacity(0.4),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.textSecondary),
          const SizedBox(width: 6),
          Text(text, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isPro = widget.plan.isPowerMode;
    final Color gradientColor = isPro ? AppColors.accent : AppColors.primary;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      clipBehavior: Clip.antiAlias, // Ensures InkWell ripple respects the border radius
      child: InkWell( // --- INKWELL IS NOW THE PARENT ---
        onTap: () {
          ref.read(selectedPlanProvider.notifier).state = widget.plan;
          Navigator.push(context, MaterialPageRoute(builder: (context) => const PlanViewScreen()));
        },
        child: Stack( // --- STACK IS NOW THE CHILD OF INKWELL ---
          children: [
            // Layer 1: The Gradient Background
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1C1C1E),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      gradientColor.withOpacity(isPro ? 0.20 : 0.15),
                      const Color(0xFF1C1C1E).withOpacity(0.0),
                    ],
                    stops: const [0.0, 0.7],
                  ),
                ),
              ),
            ),
            
            // Layer 2: The Main Content
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.plan.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.text)),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      if (widget.plan.tags.isNotEmpty) _buildInfoBadge(widget.plan.tags.first, Icons.label_outline_rounded),
                      if (widget.plan.estimatedDuration != null) _buildInfoBadge(widget.plan.estimatedDuration!, Icons.timelapse_rounded),
                      if (widget.plan.budgetLevel != null) _buildInfoBadge("💰 ${widget.plan.budgetLevel!} Budget", Icons.monetization_on_outlined),
                    ],
                  ),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: () => setState(() => _isSuggestionExpanded = !_isSuggestionExpanded),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "Today's Suggestion",
                          style: TextStyle(color: AppColors.primary.withOpacity(0.9), fontWeight: FontWeight.w600, fontSize: 14),
                        ),
                        const SizedBox(width: 4),
                        Icon(_isSuggestionExpanded ? Icons.expand_less : Icons.expand_more, size: 20, color: AppColors.primary.withOpacity(0.9)),
                      ],
                    ),
                  ),
                  AnimatedSize(
                    duration: 300.ms,
                    curve: Curves.easeInOut,
                    child: ClipRect(
                      child: Animate(
                        target: _isSuggestionExpanded ? 1.0 : 0.0,
                        effects: [
                          FadeEffect(duration: 300.ms, curve: Curves.easeIn),
                          SlideEffect(begin: const Offset(0, -0.2), end: const Offset(0, 0), duration: 300.ms, curve: Curves.easeIn),
                        ],
                        child: _isSuggestionExpanded
                            ? Container(
                                width: double.infinity,
                                margin: const EdgeInsets.only(top: 10),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(color: AppColors.background.withOpacity(0.5), borderRadius: BorderRadius.circular(8)),
                                child: ref.watch(planSuggestionProvider(widget.plan)).when(
                                      data: (suggestion) => Text(suggestion, style: const TextStyle(color: AppColors.textSecondary, height: 1.5)),
                                      loading: () => Shimmer.fromColors(
                                        baseColor: Colors.grey[850]!,
                                        highlightColor: Colors.grey[800]!,
                                        child: Container(height: 16, width: double.infinity, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4))),
                                      ),
                                      error: (e, s) => const Text("Could not load suggestion.", style: TextStyle(color: AppColors.accent)),
                                    ),
                              )
                            : const SizedBox.shrink(),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Layer 3: The Pro Badge Overlay
            if (isPro)
              Positioned(
                top: 16,
                right: 16,
                child: Icon(Icons.star_rounded, color: AppColors.accent, size: 24),
              ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: (200).ms).slideY(begin: 0.1);
  }
}