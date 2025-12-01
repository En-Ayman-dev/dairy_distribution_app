import 'package:flutter/material.dart';

class InfoDisplayRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isHighlight;
  final Color? valueColor;

  const InfoDisplayRow({
    super.key,
    required this.label,
    required this.value,
    this.isHighlight = false,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade600,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 3,
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: isHighlight
                  ? theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: valueColor ?? theme.primaryColor,
                    )
                  : theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: valueColor,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}