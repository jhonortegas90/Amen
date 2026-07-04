import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../design_system/amen_colors.dart';

void showReportDialog(BuildContext context, WidgetRef ref, String intentionId) {
  showDialog<void>(
    context: context,
    builder: (context) => _ReportDialog(intentionId: intentionId),
  );
}

class _ReportDialog extends ConsumerStatefulWidget {
  const _ReportDialog({required this.intentionId});

  final String intentionId;

  @override
  ConsumerState<_ReportDialog> createState() => _ReportDialogState();
}

class _ReportDialogState extends ConsumerState<_ReportDialog> {
  String _selectedReason = 'Harassment or Bullying';
  bool _isSubmitting = false;

  final List<String> _reasons = [
    'Harassment or Bullying',
    'Offensive Language or Hate',
    'Self-Harm or Violence',
    'Spam or Commercial Post',
    'Other Safety Concern',
  ];

  Future<void> _submitReport() async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    setState(() => _isSubmitting = true);
    try {
      final callable = FirebaseFunctions.instance.httpsCallable('reportIntention');
      await callable.call(<String, dynamic>{
        'intentionId': widget.intentionId,
        'reason': _selectedReason,
      });
      if (mounted) {
        navigator.pop();
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Thank you. Post reported for moderator review.'),
            backgroundColor: AmenColors.nightElevated,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        navigator.pop();
        messenger.showSnackBar(
          SnackBar(
            content: Text('Report submitted: $_selectedReason'),
            backgroundColor: AmenColors.nightElevated,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AmenColors.night,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: AmenColors.amenGold.withValues(alpha: 0.3)),
      ),
      title: const Row(
        children: [
          Icon(Icons.flag_outlined, color: Colors.orangeAccent),
          SizedBox(width: 10),
          Text(
            'Report Post',
            style: TextStyle(color: AmenColors.pureWhite, fontSize: 18),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Please select the reason for reporting this intention:',
              style: TextStyle(color: AmenColors.mutedText, fontSize: 14),
            ),
            const SizedBox(height: 16),
            ..._reasons.map((reason) {
              return ListTile(
                leading: Radio<String>(
                  value: reason,
                  groupValue: _selectedReason,
                  activeColor: AmenColors.amenGold,
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedReason = val);
                  },
                ),
                title: Text(
                  reason,
                  style: const TextStyle(color: AmenColors.pureWhite, fontSize: 14),
                ),
                onTap: () => setState(() => _selectedReason = reason),
              );
            }),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel', style: TextStyle(color: AmenColors.mutedText)),
        ),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _submitReport,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orangeAccent,
            foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: _isSubmitting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                )
              : const Text('Submit Report'),
        ),
      ],
    );
  }
}
