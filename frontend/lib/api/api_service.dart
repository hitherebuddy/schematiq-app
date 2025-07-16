import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:schematiq/api/api_client.dart';
import 'package:schematiq/config/app_config.dart';
import 'package:schematiq/models/plan_model.dart';
import 'package:schematiq/models/forecast_model.dart';
import 'package:schematiq/models/micro_step_model.dart';
import 'package:schematiq/providers/auth_provider.dart';

// This provider assembles the final, fully authenticated ApiService instance.
final apiServiceProvider = Provider<ApiService>((ref) {
  final dio = ref.watch(dioProvider);
  final authInterceptor = AuthInterceptor(ref);
  
  final newDio = Dio(dio.options);
  newDio.interceptors.add(authInterceptor);
  newDio.interceptors.add(LogInterceptor(requestBody: true, responseBody: true));

  return ApiService(newDio);
});

class ApiService {
  final Dio _dio;
  ApiService(this._dio);

  Future<List<Plan>> getPlans() async {
    try {
      final response = await _dio.get('/plans');
      List<dynamic> data = response.data;
      return data.map((json) => Plan.fromJson(json)).toList();
    } catch (e) {
      print("Error fetching plans: $e");
      return [];
    }
  }

  Future<Plan?> createPlan({
    required String userInput,
    required String mode,
    Map<String, dynamic>? extras,
  }) async {
    try {
      final response = await _dio.post(
        '/generate_plan',
        data: {
          'user_input': userInput,
          'mode': mode,
          'extras': extras,
        },
      );
      return Plan.fromJson(response.data);
    } catch (e) {
      print("Error creating plan: $e");
      return null;
    }
  }
  
  Future<void> toggleStepCompletion(String planId, String stepId) async {
    try {
      await _dio.patch('/plan/$planId/step/$stepId');
    } catch (e) {
      print("Error toggling step completion: $e");
      rethrow;
    }
  }

  Future<Plan?> replanFromOutcome({
    required String planId,
    required String stepId,
    required String outcome,
    String? reason,
  }) async {
    try {
      final response = await _dio.post(
        '/plan/$planId/step/$stepId/replan',
        data: {'outcome': outcome, 'reason': reason},
      );
      return Plan.fromJson(response.data);
    } catch (e) {
      print("Error replanning from outcome: $e");
      return null;
    }
  }

  Future<String> getNextBestMove(Plan plan) async {
    try {
      final response = await _dio.post(
        '/plan/next_move',
        data: plan.toJson(),
      );
      return response.data['suggestion'] ?? "Keep up the great work!";
    } catch (e) {
      print("Error fetching next best move: $e");
      return "Focus on the next available step to keep your momentum going.";
    }
  }

  Future<String?> askAiOnStep({
    required String stepDescription,
    required String userQuestion,
  }) async {
    try {
      final response = await _dio.post(
        '/ask_ai_on_step',
        data: {
          'step_description': stepDescription,
          'user_question': userQuestion,
        },
      );
      return response.data['answer'];
    } catch (e) {
      print("Error asking AI on step: $e");
      return "Sorry, I couldn't get a response. Please check your connection and try again.";
    }
  }

  // --- THIS METHOD IS NOW CORRECTED ---
  Future<List<MicroStep>?> decomposeStep({
    required String parentStepTitle,
  }) async {
    try {
      final response = await _dio.post(
        '/decompose_step',
        data: {'parent_step_title': parentStepTitle},
      );
      // 1. Get the response body, which is a Map.
      final responseData = response.data as Map<String, dynamic>;
      // 2. Access the 'micro_steps' key, which contains the List.
      final List<dynamic> data = responseData['micro_steps'];
      // 3. Map the list to your MicroStep model.
      return data.map((json) => MicroStep.fromJson(json)).toList();
    } catch (e) {
      print("Error decomposing step: $e");
      return null;
    }
  }

  Future<List<ForecastEvent>> getPlanForecast(String planId) async {
    try {
      final response = await _dio.get('/plan/$planId/forecast');
      List<dynamic> data = response.data;
      return data.map((json) => ForecastEvent.fromJson(json)).toList();
    } catch (e) {
      print("Error fetching plan forecast: $e");
      return [];
    }
  }

  Future<String?> performResearch({required String query}) async {
    try {
      final response = await _dio.post(
        '/research',
        data: {'query': query},
      );
      return response.data['research_summary'];
    } catch (e) {
      print("Error performing research: $e");
      return "Sorry, an error occurred while fetching intelligence.";
    }
  }

  Future<String?> discoverIdea({required String niche}) async {
    try {
      final response = await _dio.post(
        '/discover_idea',
        data: {'niche': niche},
      );
      return response.data['idea'];
    } catch (e) {
      print("Error discovering idea: $e");
      return "Sorry, an error occurred while generating an idea.";
    }
  }
}