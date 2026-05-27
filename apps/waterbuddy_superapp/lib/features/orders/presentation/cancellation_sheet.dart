import 'package:flutter/material.dart';

Future<String?> showCancellationReasonSheet(
  BuildContext context, {
  String status = 'SEARCHING',
}) {
  const reasons = [
    'Booked by mistake',
    'Found another tanker',
    'Waiting too long',
    'Price too high',
    'Address issue',
    'Other',
  ];

  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: Colors.white,
    builder: (context) {
      String? selectedReason;
      return StatefulBuilder(
        builder: (context, setSheetState) {
          final showWarning = status == 'DRIVER_ASSIGNED' ||
              status == 'ON_THE_WAY' ||
              status == 'ARRIVED';
          return SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 6, 20, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Cancel water tanker request?',
                    style: TextStyle(
                      color: Color(0xFF0F172A),
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    showWarning
                        ? 'A partner may already be moving toward you. Please select a reason before cancelling.'
                        : 'Tell us why you are cancelling so we can improve dispatch.',
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  for (final reason in reasons)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () =>
                            setSheetState(() => selectedReason = reason),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 14),
                          decoration: BoxDecoration(
                            color: selectedReason == reason
                                ? const Color(0xFFE0F2FE)
                                : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: selectedReason == reason
                                  ? const Color(0xFF0EA5E9)
                                  : const Color(0xFFE2E8F0),
                              width: selectedReason == reason ? 1.6 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                selectedReason == reason
                                    ? Icons.radio_button_checked_rounded
                                    : Icons.radio_button_off_rounded,
                                color: selectedReason == reason
                                    ? const Color(0xFF0EA5E9)
                                    : const Color(0xFF94A3B8),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  reason,
                                  style: const TextStyle(
                                    color: Color(0xFF0F172A),
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: FilledButton(
                      onPressed: selectedReason == null
                          ? null
                          : () => Navigator.pop(context, selectedReason),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFEF4444),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'Confirm Cancel',
                        style: TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}
