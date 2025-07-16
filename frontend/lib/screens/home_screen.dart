import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:schematiq/config/app_config.dart';
import 'package:schematiq/models/plan_model.dart';
import 'package:schematiq/providers/plan_provider.dart';
import 'package:schematiq/screens/new_plan_screen.dart';
import 'package:schematiq/widgets/plan_card.dart';
import 'package:schematiq/widgets/research_modal.dart';

final tagFilterProvider = StateProvider<String?>((ref) => null);
final searchQueryProvider = StateProvider<String>((ref) => '');

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      ref.read(searchQueryProvider.notifier).state = _searchController.text;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final plansAsyncValue = ref.watch(plansProvider);
    final selectedTag = ref.watch(tagFilterProvider);
    final searchQuery = ref.watch(searchQueryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConfig.appName),
        leading: const Padding(
          padding: EdgeInsets.only(left: 16.0),
          child: Icon(Icons.schema_rounded, color: AppColors.primary, size: 28),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.travel_explore_rounded, color: AppColors.textSecondary, size: 28),
            tooltip: 'AI Research Assistant',
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                useSafeArea: true,
                builder: (context) => const ResearchModal(),
                backgroundColor: AppColors.cardBackground,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search strategies...',
                  prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
                  suffixIcon: searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: AppColors.textSecondary),
                          onPressed: () => _searchController.clear(),
                        )
                      : null,
                ),
              ),
            ),
            
            // --- THIS IS THE CORRECTED WIDGET STRUCTURE ---
            plansAsyncValue.when(
              data: (plans) {
                final allTags = List<Plan>.from(plans).expand((plan) => plan.tags).toSet().toList();
                if (allTags.isEmpty) return const SizedBox.shrink();
                
                // Use a Wrap widget for the tags. It will automatically handle wrapping.
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Wrap(
                    spacing: 8.0, // Horizontal space between chips
                    runSpacing: 8.0, // Vertical space between lines of chips
                    children: allTags.map((tag) {
                      return FilterChip(
                        label: Text(tag),
                        labelStyle: TextStyle(
                          color: selectedTag == tag ? AppColors.text : AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                        selected: selectedTag == tag,
                        onSelected: (isSelected) {
                          ref.read(tagFilterProvider.notifier).state = isSelected ? tag : null;
                        },
                        backgroundColor: AppColors.cardBackground,
                        selectedColor: AppColors.primary,
                        checkmarkColor: AppColors.background,
                        shape: StadiumBorder(side: BorderSide(color: Colors.grey.withOpacity(0.2))),
                      );
                    }).toList(),
                  ),
                );
              },
              loading: () => const SizedBox(height: 50),
              error: (e, s) => const SizedBox.shrink(),
            ),
            
            // --- PLAN LIST ---
            Expanded(
              child: plansAsyncValue.when(
                data: (plans) {
                  List<Plan> filteredPlans = List<Plan>.from(plans);
                  if (selectedTag != null) {
                    filteredPlans = filteredPlans.where((p) => p.tags.contains(selectedTag)).toList();
                  }
                  if (searchQuery.isNotEmpty) {
                    filteredPlans = filteredPlans.where((p) =>
                      p.title.toLowerCase().contains(searchQuery.toLowerCase())
                    ).toList();
                  }

                  if (filteredPlans.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Text(
                          "No plans match your criteria.",
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 16),
                        ),
                      ),
                    );
                  }
                  return RefreshIndicator(
                    onRefresh: () async => ref.invalidate(plansProvider),
                    color: AppColors.primary,
                    backgroundColor: AppColors.cardBackground,
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(0, 8, 0, 80),
                      itemCount: filteredPlans.length,
                      itemBuilder: (context, index) => PlanCard(plan: filteredPlans[index]),
                    ),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(AppColors.primary))),
                error: (err, stack) => Center(child: Text('Error: $err', style: const TextStyle(color: AppColors.accent))),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const NewPlanScreen()),
          );
        },
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: AppColors.background, size: 28),
        shape: const CircleBorder(),
      ),
    );
  }
}