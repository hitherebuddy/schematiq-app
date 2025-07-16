import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:schematiq/config/app_config.dart';
import 'package:schematiq/models/plan_model.dart';
import 'package:schematiq/providers/plan_provider.dart';
import 'package:schematiq/screens/power_mode_screen.dart';
import 'package:schematiq/widgets/next_move_card.dart';
import 'package:schematiq/widgets/step_block.dart';

class PlanViewScreen extends ConsumerWidget {
  const PlanViewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Get the plan that was selected on the previous screen.
    final initialPlan = ref.watch(selectedPlanProvider);
    if (initialPlan == null) {
      return Scaffold(appBar: AppBar(), body: const Center(child: Text('Error: No plan was selected.')));
    }

    // Watch the main provider to get live updates for all plans.
    final plansAsyncValue = ref.watch(plansProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(initialPlan.title, overflow: TextOverflow.ellipsis),
        actions: [
          // --- LIVE PROGRESS RING ---
          // This watches the async value and builds the progress ring only when data is available.
          plansAsyncValue.when(
            data: (plans) {
              final plan = plans.firstWhere((p) => p.id == initialPlan.id, orElse: () => initialPlan);
              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: CircularPercentIndicator(
                  radius: 18.0,
                  lineWidth: 3.5,
                  percent: plan.progress,
                  center: Text("${(plan.progress * 100).toInt()}%", style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                  progressColor: AppColors.primary,
                  backgroundColor: AppColors.cardBackground.withOpacity(0.5),
                  circularStrokeCap: CircularStrokeCap.round,
                ).animate().fadeIn(),
              );
            },
            loading: () => const SizedBox.shrink(), // Don't show anything while loading
            error: (e, s) => const SizedBox.shrink(), // Or on error
          ),
          
          if (initialPlan.isPowerMode)
            IconButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => PowerModeScreen(planId: initialPlan.id))),
              icon: const Icon(Icons.insights_rounded, color: AppColors.accent),
              tooltip: 'Execution Forecast',
            ),
        ],
      ),
      body: plansAsyncValue.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (err, stack) => Center(child: Text('Error: $err', style: const TextStyle(color: AppColors.accent))),
        data: (plans) {
          final Plan livePlan;
          try {
            livePlan = plans.firstWhere((p) => p.id == initialPlan.id);
          } catch (e) {
            return const Center(child: Text("This plan may have been deleted."));
          }
          
          // Use a Column to stack the ListView and the NextMoveCard
          return Column(
            children: [
              // The ListView of steps now needs to be wrapped in an Expanded widget
              // to make it fill the available space without overflowing.
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: livePlan.steps.length,
                  itemBuilder: (context, index) {
                    final step = livePlan.steps[index];
                    return StepBlock(
                      key: ValueKey(step.id),
                      step: step,
                      stepNumber: index + 1,
                      isPowerMode: livePlan.isPowerMode,
                    );
                  },
                ),
              ),
              
              // --- NEXT BEST MOVE INSIGHT BLOCK ---
              // This card only appears if the plan is not yet 100% complete.
              if (livePlan.progress < 1.0)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  child: NextMoveCard(plan: livePlan),
                ).animate().slideY(begin: 0.5, end: 0, duration: 400.ms).fadeIn(),
            ],
          );
        },
      ),
    );
  }
}