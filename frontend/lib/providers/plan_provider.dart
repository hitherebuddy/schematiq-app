import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:schematiq/api/api_service.dart';
import 'package:schematiq/models/plan_model.dart';
import 'package:schematiq/models/forecast_model.dart';
import 'package:schematiq/providers/auth_provider.dart';

// The main provider for our plans. It's a StateNotifierProvider that holds an AsyncValue.
// This gives us the power of a StateNotifier (for methods) and the safety of an AsyncValue.
final plansProvider = StateNotifierProvider<PlansNotifier, AsyncValue<List<Plan>>>((ref) {
  return PlansNotifier(ref);
});

class PlansNotifier extends StateNotifier<AsyncValue<List<Plan>>> {
  final Ref _ref;
  late final ApiService _apiService;

  PlansNotifier(this._ref) : super(const AsyncLoading()) {
    // Read the ApiService once
    _apiService = _ref.read(apiServiceProvider);
    // Initial fetch
    _init();
  }

  Future<void> _init() async {
    // Wait for the auth token before doing anything
    await _ref.read(authTokenProvider.future);
    await fetchPlans();
  }

  Future<void> fetchPlans() async {
    state = const AsyncLoading();
    try {
      final plans = await _apiService.getPlans();
      state = AsyncData(plans);
    } catch (e, stack) {
      state = AsyncError(e, stack);
    }
  }

  Future<Plan?> createPlan({
    required String userInput,
    required String mode,
    Map<String, dynamic>? extras,
  }) async {
    state = const AsyncLoading();
    final newPlan = await _apiService.createPlan(
      userInput: userInput, mode: mode, extras: extras
    );
    
    await fetchPlans();
    
    return newPlan;
  }

  Future<void> toggleStepCompletion(String planId, String stepId) async {
    if (state is! AsyncData<List<Plan>>) return;
    final currentPlans = state.value!;
    
    final updatedPlans = currentPlans.map((plan) {
      if (plan.id == planId) {
        return plan.copyWith(
          steps: plan.steps.map((step) {
            if (step.id == stepId) {
              return step.copyWith(isComplete: !step.isComplete);
            }
            return step;
          }).toList(),
        );
      }
      return plan;
    }).toList();
    
    state = AsyncData(updatedPlans);

    try {
      await _apiService.toggleStepCompletion(planId, stepId);
    } catch(e) {
      print("Failed to update step status on backend: $e");
      state = AsyncData(currentPlans);
    }
  }

  Future<void> replanFromOutcome({
    required String planId,
    required String stepId,
    required String outcome,
    String? reason,
  }) async {
    state = const AsyncLoading(); 
    try {
      await _apiService.replanFromOutcome(
        planId: planId, stepId: stepId, outcome: outcome, reason: reason
      );
      await fetchPlans();
    } catch (e) {
      print("Replanning failed: $e");
      await fetchPlans();
    }
  }
}

// Provider for the currently selected plan to view
final selectedPlanProvider = StateProvider<Plan?>((ref) => null);

// Provider for the Execution Forecast screen
final forecastProvider = FutureProvider.family<List<ForecastEvent>, String>((ref, planId) async {
  await ref.watch(authTokenProvider.future);
  final apiService = ref.watch(apiServiceProvider);
  return apiService.getPlanForecast(planId);
});

// --- NEW PROVIDER FOR ON-DEMAND PLAN SUGGESTIONS ---
final planSuggestionProvider = FutureProvider.family<String, Plan>((ref, plan) {
  // This provider also waits for authentication before running.
  ref.watch(authTokenProvider);
  
  final apiService = ref.watch(apiServiceProvider);
  // We reuse the getNextBestMove endpoint as it serves this purpose perfectly.
  return apiService.getNextBestMove(plan);
});