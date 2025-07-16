import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:schematiq/config/app_config.dart';
import 'package:schematiq/providers/plan_provider.dart';
import 'package:schematiq/screens/plan_view_screen.dart';

// Model for our constraints
class PlanConstraints {
  double? timePerDay;
  double? budgetMonthly;
  List<String> negative = [];
  
  Map<String, dynamic> toJson() {
    // Only include non-null/non-empty values in the JSON
    final map = <String, dynamic>{};
    if (timePerDay != null && timePerDay! > 0) map['time_per_day'] = timePerDay;
    if (budgetMonthly != null && budgetMonthly! > 0) map['budget_monthly'] = budgetMonthly;
    if (negative.isNotEmpty) map['negative'] = negative;
    return map;
  }
}

class NewPlanScreen extends ConsumerStatefulWidget {
  const NewPlanScreen({super.key});

  @override
  ConsumerState<NewPlanScreen> createState() => _NewPlanScreenState();
}

class _NewPlanScreenState extends ConsumerState<NewPlanScreen> {
  final _ideaController = TextEditingController();
  final _outcomeController = TextEditingController();
  String _selectedMode = 'free';
  String _selectedExperience = 'Beginner';
  bool _isGenerating = false;

  // State for the re-integrated constraints feature
  bool _showConstraints = false;
  final _constraints = PlanConstraints();
  final _negativeConstraintController = TextEditingController();

  @override
  void dispose() {
    _ideaController.dispose();
    _outcomeController.dispose();
    _negativeConstraintController.dispose();
    super.dispose();
  }

  Future<void> _generatePlan() async {
    if (_ideaController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please describe your idea first.")),
      );
      return;
    }

    setState(() => _isGenerating = true);

    final extras = {
      'experience': _selectedExperience,
      'expected_outcome': _outcomeController.text.trim(),
      // Correctly include the constraints only for paid mode
      'constraints': _selectedMode == 'paid' ? _constraints.toJson() : null,
    };

    final newPlan = await ref.read(plansProvider.notifier).createPlan(
      userInput: _ideaController.text.trim(),
      mode: _selectedMode,
      extras: extras,
    );
    
    if(mounted) setState(() => _isGenerating = false);

    if (newPlan != null && mounted) {
      ref.read(selectedPlanProvider.notifier).state = newPlan;
      Navigator.of(context).pop();
      Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => const PlanViewScreen()),
      );
    } else if (mounted) {
       ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Sorry, couldn't create a plan."), backgroundColor: AppColors.accent),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Plan'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("What do you want to plan?", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                const Text("Describe your goal, project, or messy idea.", style: TextStyle(color: AppColors.textSecondary, fontSize: 16)),
                const SizedBox(height: 24),
                TextField(controller: _ideaController, maxLines: 4, autofocus: true, decoration: const InputDecoration(hintText: "e.g., Launch a new SaaS product...")),
                const SizedBox(height: 24),
                const Text("What is your desired outcome?", style: TextStyle(color: AppColors.textSecondary, fontSize: 16)),
                const SizedBox(height: 12),
                TextField(controller: _outcomeController, maxLines: 2, decoration: const InputDecoration(hintText: "e.g., Achieve 100 paying customers in 6 months.")),
                const SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(child: _ModeCard(icon: Icons.check_circle_outline_rounded, title: 'Everyday Mode', subtitle: 'For simple tasks & goals. (Free)', isSelected: _selectedMode == 'free', onTap: () => setState(() => _selectedMode = 'free'))),
                    const SizedBox(width: 12),
                    Expanded(child: _ModeCard(icon: Icons.star_rounded, title: 'Strategist Mode', subtitle: 'Deeper insights & risks. (Paid)', isSelected: _selectedMode == 'paid', onTap: () => setState(() => _selectedMode = 'paid'), isPremium: true)),
                  ],
                ),
                const SizedBox(height: 24),
                
                // --- RE-INTEGRATED ADVANCED CONSTRAINTS ---
                // This section now correctly appears only when Strategist Mode is selected.
                if (_selectedMode == 'paid')
                  _buildConstraintSection().animate().fadeIn(delay: 200.ms),

                const SizedBox(height: 32),
                const Text("Your Experience Level?", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                _buildExperienceSelector(),
                const SizedBox(height: 40),
                ElevatedButton(
                  onPressed: _isGenerating ? null : _generatePlan,
                  style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 56), backgroundColor: AppColors.primary, foregroundColor: AppColors.background),
                  child: const Text('Generate Plan'),
                ),
                const SizedBox(height: 40),
              ],
            ).animate().fadeIn(duration: 300.ms),
          ),
          if (_isGenerating)
            Container(
              color: Colors.black.withOpacity(0.7),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(AppColors.primary)),
                    SizedBox(height: 20),
                    Text('SchematIQ is thinking...', style: TextStyle(color: AppColors.text, fontSize: 16)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // --- WIDGET FOR THE COLLAPSIBLE CONSTRAINTS PANEL ---
  Widget _buildConstraintSection() {
    return Column(
      children: [
        GestureDetector(
          onTap: () => setState(() => _showConstraints = !_showConstraints),
          child: Container(
            color: Colors.transparent,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.tune_rounded, color: AppColors.accent, size: 18),
                const SizedBox(width: 8),
                const Text("Advanced Constraints", style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold)),
                Icon(_showConstraints ? Icons.expand_less : Icons.expand_more, color: AppColors.accent),
              ],
            ),
          ),
        ),
        AnimatedSize(
          duration: 300.ms,
          curve: Curves.easeInOut,
          child: _showConstraints ? _buildConstraintInputs() : const SizedBox(width: double.infinity),
        ),
      ],
    );
  }

  // --- WIDGET FOR THE ACTUAL CONSTRAINT INPUTS ---
  Widget _buildConstraintInputs() {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground.withOpacity(0.5),
        border: Border.all(color: AppColors.accent.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Time per day (hours): ${_constraints.timePerDay?.toStringAsFixed(0) ?? 'Any'}"),
          Slider(
            value: _constraints.timePerDay ?? 0,
            onChanged: (val) => setState(() => _constraints.timePerDay = val == 0 ? null : val),
            min: 0, max: 12, divisions: 12,
            label: _constraints.timePerDay?.toStringAsFixed(0) ?? "Any",
            activeColor: AppColors.accent,
          ),
          Text("Max tool budget (\$/month): ${_constraints.budgetMonthly?.toStringAsFixed(0) ?? 'Any'}"),
          Slider(
            value: _constraints.budgetMonthly ?? 0,
            onChanged: (val) => setState(() => _constraints.budgetMonthly = val == 0 ? null : val),
            min: 0, max: 1000, divisions: 20,
            label: _constraints.budgetMonthly?.toStringAsFixed(0) ?? "Any",
            activeColor: AppColors.accent,
          ),
          const SizedBox(height: 8),
          const Text("Strategies/tools to AVOID:"),
          const SizedBox(height: 8),
          TextField(
            controller: _negativeConstraintController,
            decoration: InputDecoration(
              hintText: "e.g., TikTok, Facebook Ads...",
              suffixIcon: IconButton(
                icon: const Icon(Icons.add_circle, color: AppColors.accent),
                onPressed: () {
                  if (_negativeConstraintController.text.trim().isNotEmpty) {
                    setState(() {
                      _constraints.negative.add(_negativeConstraintController.text.trim());
                      _negativeConstraintController.clear();
                    });
                  }
                },
              ),
            ),
          ),
          const SizedBox(height: 8),
          if (_constraints.negative.isNotEmpty)
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: _constraints.negative.map((item) => Chip(
                label: Text(item),
                onDeleted: () => setState(() => _constraints.negative.remove(item)),
                backgroundColor: AppColors.accent.withOpacity(0.2),
                deleteIconColor: AppColors.accent.withOpacity(0.7),
                labelStyle: TextStyle(color: AppColors.text.withOpacity(0.8)),
              )).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildExperienceSelector() {
    final options = ['Beginner', 'Intermediate', 'Expert'];
    return Row(
      children: options.map((level) {
        final isSelected = _selectedExperience == level;
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _selectedExperience = level),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : AppColors.cardBackground,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                level,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isSelected ? AppColors.background : AppColors.text,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// Private helper widget for the mode selection cards, styled to match the design.
class _ModeCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isSelected;
  final bool isPremium;
  final VoidCallback onTap;

  const _ModeCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
    this.isPremium = false,
  });

  @override
  Widget build(BuildContext context) {
    final selectedColor = isPremium ? AppColors.accent : AppColors.primary;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? selectedColor : AppColors.cardBackground,
            width: 2,
          ),
          boxShadow: isSelected ? [
            BoxShadow(color: selectedColor.withOpacity(0.2), blurRadius: 8, spreadRadius: -2)
          ] : [],
        ),
        child: Column(
          children: [
            Icon(icon, color: selectedColor, size: 28),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(subtitle, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}