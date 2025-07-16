import 'package:flutter/material.dart';
import 'package:schematiq/config/app_config.dart';
import 'package:schematiq/models/plan_model.dart';
import 'package:url_launcher/url_launcher.dart';

class ToolCard extends StatelessWidget {
  final ToolInfo tool;
  const ToolCard({super.key, required this.tool});

  @override
  Widget build(BuildContext context) {
    // A simple public API to get favicons, which often work as logos.
    final logoUrl = "https://logo.clearbit.com/${Uri.parse(tool.link).host}";

    return Card(
      margin: const EdgeInsets.only(top: 8, bottom: 4),
      color: AppColors.background.withOpacity(0.5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: Colors.grey.withOpacity(0.2)),
      ),
      elevation: 0,
      child: InkWell(
        onTap: () async {
          final url = Uri.parse(tool.link);
          // Check if the URL can be launched before attempting to launch it.
          if (await canLaunchUrl(url)) {
            await launchUrl(url, mode: LaunchMode.externalApplication);
          }
        },
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Image.network(
                    logoUrl,
                    width: 40,
                    height: 40,
                    errorBuilder: (context, error, stackTrace) =>
                        const Icon(Icons.build_circle_outlined, size: 40, color: AppColors.primary),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(tool.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 4),
                        Text(tool.description, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.4)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // --- THIS IS THE CORRECTED LAYOUT THAT PREVENTS OVERFLOW ---
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // This Expanded widget allows the cost text to wrap if it's too long.
                  Expanded(
                    child: Text(
                      tool.cost,
                      style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // This InkWell remains at a fixed size at the end.
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text("Visit ", style: TextStyle(color: AppColors.primary.withOpacity(0.8), fontSize: 14)),
                      Icon(Icons.open_in_new, color: AppColors.primary.withOpacity(0.8), size: 16),
                    ],
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}