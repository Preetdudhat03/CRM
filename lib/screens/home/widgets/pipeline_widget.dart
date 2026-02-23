import 'package:flutter/material.dart';
import '../../../models/deal_model.dart';
import '../../../widgets/animations/fade_in_slide.dart';

class PipelineWidget extends StatelessWidget {
  final Map<DealStage, int> pipelineData;

  const PipelineWidget({super.key, required this.pipelineData});

  @override
  Widget build(BuildContext context) {
    // Define the exact horizontal order for the snapshot based on requirements and enum
    final stages = [
      DealStage.qualification, // 'New' / Qualification
      DealStage.needsAnalysis, // 'Contacted' / Needs Analysis
      DealStage.proposal,
      DealStage.negotiation,
      DealStage.closedWon, // Won
      DealStage.closedLost, // Lost
    ];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sales Pipeline',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 24),
          LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: List.generate(stages.length, (index) {
                    final stage = stages[index];
                    final count = pipelineData[stage] ?? 0;
                    final isLast = index == stages.length - 1;

                    return Row(
                      children: [
                        _buildStageNode(context, stage, count),
                        if (!isLast) _buildConnector(context, stage),
                      ],
                    );
                  }),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStageNode(BuildContext context, DealStage stage, int count) {
    // Override label purely for UI snapshot as requested
    String label = stage.label;
    if (stage == DealStage.qualification) label = 'New';
    if (stage == DealStage.needsAnalysis) label = 'Contacted';
    if (stage == DealStage.closedWon) label = 'Won';
    if (stage == DealStage.closedLost) label = 'Lost';

    return SizedBox(
      width: 80,
      child: Column(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: stage.color.withOpacity(0.15),
              shape: BoxShape.circle,
              border: Border.all(color: stage.color, width: 2),
            ),
            child: Center(
              child: Text(
                count.toString(),
                style: TextStyle(
                  color: stage.color,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildConnector(BuildContext context, DealStage stage) {
    return Container(
      width: 40,
      height: 2,
      margin: const EdgeInsets.only(bottom: 24), // Align with circle center
      color: stage.color.withOpacity(0.3),
    );
  }
}
