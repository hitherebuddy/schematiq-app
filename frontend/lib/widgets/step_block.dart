import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:schematiq/api/api_service.dart';
import 'package:schematiq/config/app_config.dart';
import 'package:schematiq/models/micro_step_model.dart';
import 'package:schematiq/models/plan_model.dart';
import 'package:schematiq/providers/auth_provider.dart';
import 'package:schematiq/providers/plan_provider.dart';
import 'package:schematiq/widgets/chat_modal.dart';
import 'package:schematiq/widgets/tool_card.dart';

class StepBlock extends ConsumerStatefulWidget {
  final PlanStep step;
  final int stepNumber;
  final bool isPowerMode;

  const StepBlock({
    super.key,
    required this.step,
    required this.stepNumber,
    required this.isPowerMode,
  });

  @override
  ConsumerState<StepBlock> createState() => _StepBlockState();
}

class _StepBlockState extends ConsumerState<StepBlock> {
  bool _isExpanded = false;
  bool _isDecomposing = false;
  List<MicroStep>? _microSteps;

  Future<void> _decomposeStep() async {
    if (_isDecomposing || _microSteps != null) return;
    setState(() => _isDecomposing = true);
    final apiService = ref.read(apiServiceProvider);
    final result = await apiService.decomposeStep(parentStepTitle: widget.step.title);
    if (mounted) {
      setState(() {
        _microSteps = result;
        _isDecomposing = false;
      });
    }
  }

  void _showChatModal(BuildContext context, PlanStep step) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => ChatModal(step: step),
      backgroundColor: AppColors.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
    );
  }

  void _showFailureReasonDialog() {
    final reasonController = TextEditingController();
    final selectedPlan = ref.read(selectedPlanProvider);
    if (selectedPlan == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        title: const Text("Reason for Failure"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Briefly explain what went wrong. The AI will use this to create a better recovery plan."),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              autofocus: true,
              decoration: const InputDecoration(hintText: "e.g., The recommended tool was too expensive..."),
            ),
          ],
        ),
        actions: [
          TextButton(child: const Text("Cancel"), onPressed: () => Navigator.of(context).pop()),
          TextButton(
            child: const Text("Submit & Replan", style: TextStyle(color: AppColors.accent)),
            onPressed: () {
              Navigator.of(context).pop();
              ref.read(plansProvider.notifier).replanFromOutcome(
                planId: selectedPlan.id,
                stepId: widget.step.id,
                outcome: 'failure',
                reason: reasonController.text.trim(),
              );
            },
          ),
        ],
      ),
    );
  }

  void _handleToggle(bool? isCompleted) {
    final selectedPlan = ref.read(selectedPlanProvider);
    if (isCompleted == null || selectedPlan == null) return;
    
    final plansNotifier = ref.read(plansProvider.notifier);
    
    if (!isCompleted) {
      plansNotifier.toggleStepCompletion(selectedPlan.id, widget.step.id);
      return;
    }

    if (widget.isPowerMode) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: AppColors.cardBackground,
          title: const Text("Outcome Report"),
          content: const Text("How did this step go? The AI will adapt the rest of your plan based on your feedback."),
          actions: [
            TextButton(
              child: const Text("It Failed", style: TextStyle(color: AppColors.accent)),
              onPressed: () {
                Navigator.of(context).pop();
                _showFailureReasonDialog();
              },
            ),
            TextButton(
              child: const Text("It Succeeded", style: TextStyle(color: AppColors.primary)),
              onPressed: () {
                Navigator.of(context).pop();
                plansNotifier.replanFromOutcome(
                  planId: selectedPlan.id,
                  stepId: widget.step.id,
                  outcome: 'success',
                );
              },
            ),
          ],
        ),
      );
    } else {
      plansNotifier.toggleStepCompletion(selectedPlan.id, widget.step.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.withOpacity(0.1))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            child: Row(
              children: [
                Checkbox(
                  value: widget.step.isComplete,
                  onChanged: _handleToggle,
                  activeColor: AppColors.primary,
                  checkColor: AppColors.background,
                  shape: const CircleBorder(),
                ),
                Text('Step ${widget.stepNumber}:', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.step.title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      decoration: widget.step.isComplete ? TextDecoration.lineThrough : TextDecoration.none,
                      color: widget.step.isComplete ? AppColors.textSecondary : AppColors.text,
                    ),
                  ),
                ),
                Icon(_isExpanded ? Icons.expand_less : Icons.expand_more, color: AppColors.textSecondary),
              ],
            ),
          ),
          AnimatedSize(
            duration: 300.ms,
            curve: Curves.easeInOut,
            child: _isExpanded ? _buildExpandedContent() : const SizedBox.shrink(),
          ),
        ],
      ),
    ).animate().fadeIn(delay: (widget.stepNumber * 50).ms);
  }

  Widget _buildExpandedContent() {
    final authState = ref.watch(authTokenProvider);
    final bool canSeePowerFeatures = authState.value?.isPaidUser ?? false;

    return Padding(
      padding: const EdgeInsets.only(left: 16.0, top: 12, right: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(color: Colors.white12),
          const SizedBox(height: 16),
          if (_microSteps != null) _buildMicroStepsList() else ...widget.step.subtasks.map((task) => _buildSubtaskRow(task)),
          const SizedBox(height: 16),
          
          if (widget.isPowerMode)
            Column(
              children: [
                if (canSeePowerFeatures) ...[
                  if (widget.step.powerTools != null && widget.step.powerTools!.isNotEmpty)
                    _buildToolSection(),
                  if (widget.step.potentialPitfall != null)
                    _buildPowerFeature("Potential Pitfall", Icons.warning_amber_rounded, widget.step.potentialPitfall!),
                ] else ...[
                  if (widget.step.powerTools != null && widget.step.powerTools!.isNotEmpty)
                    _buildPowerFeatureTease("Tool Recommendations"),
                  if (widget.step.potentialPitfall != null)
                    _buildPowerFeatureTease("Risk Analysis"),
                ]
              ],
            ),
          
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            runSpacing: 8.0,
            children: [
              Chip(label: Text(widget.step.timeEstimate.displayString), backgroundColor: AppColors.primary.withOpacity(0.1), labelStyle: const TextStyle(color: AppColors.primary, fontSize: 12), side: BorderSide.none),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.isPowerMode)
                    TextButton.icon(
                      onPressed: canSeePowerFeatures ? _decomposeStep : null,
                      icon: _isDecomposing
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accent))
                          : Icon(Icons.splitscreen_rounded, size: 16, color: canSeePowerFeatures ? AppColors.accent : Colors.grey),
                      label: Text("Decompose", style: TextStyle(color: canSeePowerFeatures ? AppColors.accent : Colors.grey)),
                    ),
                  TextButton.icon(
                      onPressed: () => _showChatModal(context, widget.step),
                      icon: const Icon(Icons.chat_bubble_outline_rounded, size: 16, color: AppColors.primary),
                      label: const Text("Ask AI", style: TextStyle(color: AppColors.primary))),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPowerFeatureTease(String featureName) {
    return GestureDetector(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Upgrade to Strategist Mode to unlock this feature!"),
            backgroundColor: AppColors.accent,
          ),
        );
      },
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            height: 60,
            decoration: BoxDecoration(
              color: AppColors.cardBackground.withOpacity(0.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 3.0, sigmaY: 3.0),
                child: Container(color: Colors.transparent),
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock_outline_rounded, color: AppColors.accent, size: 16),
              const SizedBox(width: 8),
              Text("Unlock $featureName", style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold)),
            ],
          ).animate().fadeIn(),
        ],
      ),
    );
  }

  Widget _buildToolSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.build_circle_outlined, color: AppColors.accent, size: 16),
            SizedBox(width: 8),
            Text("Recommended Tools", style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold)),
          ],
        ),
        ...widget.step.powerTools!.map((tool) => ToolCard(tool: tool)),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildPowerFeature(String title, IconData icon, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0, top: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.accent, size: 16),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 24.0),
            child: Text(content, style: const TextStyle(color: AppColors.textSecondary)),
          ),
        ],
      ),
    );
  }

  Widget _buildSubtaskRow(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0, left: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.subdirectory_arrow_right_rounded, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(color: AppColors.textSecondary))),
        ],
      ),
    );
  }

  Widget _buildMicroStepItem(MicroStep step) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 2.0),
                child: Icon(Icons.subdirectory_arrow_right_rounded, size: 18, color: AppColors.textSecondary),
              ),
              const SizedBox(width: 8),
              Expanded(child: Text(step.title, style: const TextStyle(color: AppColors.text, fontSize: 15, fontWeight: FontWeight.w500))),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(left: 26.0, top: 4),
            child: Text(
              step.explanation,
              style: TextStyle(color: AppColors.textSecondary.withOpacity(0.8), fontSize: 13, height: 1.4),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 26.0, top: 4),
            child: Text(
              step.example,
              style: TextStyle(color: AppColors.textSecondary.withOpacity(0.6), fontSize: 13, fontStyle: FontStyle.italic),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMicroStepsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 12.0),
          child: Text(
            "MICRO-STEPS:",
            style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 0.8),
          ),
        ),
        ..._microSteps!.map((step) => _buildMicroStepItem(step)).toList().animate(interval: 50.ms).fadeIn(duration: 200.ms),
      ],
    );
  }
}