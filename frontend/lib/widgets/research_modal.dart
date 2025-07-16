import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:schematiq/api/api_service.dart';
import 'package:schematiq/config/app_config.dart';
import 'package:schematiq/providers/auth_provider.dart'; // Import the new provider file
import 'package:url_launcher/url_launcher.dart';

class ResearchModal extends ConsumerStatefulWidget {
  const ResearchModal({super.key});

  @override
  ConsumerState<ResearchModal> createState() => _ResearchModalState();
}

class _ResearchModalState extends ConsumerState<ResearchModal> {
  final _controller = TextEditingController();
  String? _researchSummary;
  bool _isLoading = false;

  Future<void> _performResearch() async {
    if (_controller.text.trim().isEmpty) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _isLoading = true;
      _researchSummary = null;
    });

    // This line will now work correctly
    final apiService = ref.read(apiServiceProvider);
    final response = await apiService.performResearch(query: _controller.text.trim());
    
    if (mounted) {
      setState(() {
        _researchSummary = response;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16, right: 16, top: 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text("AI Research Assistant", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text("Ask about market trends, competitors, or idea saturation.", style: TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            autofocus: true,
            decoration: const InputDecoration(hintText: "e.g., Is the market for AI planners saturated?"),
            onSubmitted: (_) => _performResearch(),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _isLoading ? null : _performResearch,
            icon: const Icon(Icons.travel_explore_rounded, size: 18),
            label: const Text('Fetch Intelligence'),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent),
          ),
          const SizedBox(height: 20),
          if (_isLoading)
            const Center(child: CircularProgressIndicator(color: AppColors.accent))
          else if (_researchSummary != null)
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.cardBackground.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Markdown(
                  data: _researchSummary!,
                  selectable: true,
                  onTapLink: (text, href, title) {
                    if (href != null) {
                      launchUrl(Uri.parse(href));
                    }
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }
}