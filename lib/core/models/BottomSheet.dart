import 'package:flutter/material.dart';

// ─── Enums ───────────────────────────────────────────────────────────────────

enum SortOption { title, artist, album, date }

enum SortBy { ascending, descending }

// ─── Result model returned to the caller ─────────────────────────────────────

class SortFilterResult {
  final SortOption sortBy;
  final SortBy genre;

  const SortFilterResult({required this.sortBy, required this.genre});
}

// ─── Public helper to show the sheet ─────────────────────────────────────────

/// Shows the [SortFilterBottomSheet] and returns a [SortFilterResult]
/// (or `null` if the user dismisses without applying).
Future<SortFilterResult?> showSortFilterSheet(
  BuildContext context, {
  SortOption initialSort = SortOption.date,
  SortBy initialWay = SortBy.descending,
}) {
  return showModalBottomSheet<SortFilterResult>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) =>
        SortFilterBottomSheet(initialSort: initialSort, initialWay: initialWay),
  );
}

// ─── Widget ──────────────────────────────────────────────────────────────────

class SortFilterBottomSheet extends StatefulWidget {
  final SortOption initialSort;
  final SortBy initialWay;

  const SortFilterBottomSheet({
    super.key,
    this.initialSort = SortOption.date,
    this.initialWay = SortBy.descending,
  });

  @override
  State<SortFilterBottomSheet> createState() => _SortFilterBottomSheetState();
}

class _SortFilterBottomSheetState extends State<SortFilterBottomSheet> {
  late SortOption _sortBy;
  late SortBy _genre;

  @override
  void initState() {
    super.initState();
    _sortBy = widget.initialSort;
    _genre = widget.initialWay;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      // Keeps the sheet above the keyboard if it ever appears.
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top,
        bottom: MediaQuery.of(context).padding.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Drag handle ──────────────────────────────────────────────────
          Center(
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.onSurfaceVariant.withOpacity(0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'Sort & Filter',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          const SizedBox(height: 16),

          // ── Group 1 : Sort By ─────────────────────────────────────────────
          _RadioSection<SortOption>(
            title: 'Sort by',
            icon: Icons.sort_rounded,
            options: const [
              _RadioOption(value: SortOption.title, label: 'Title'),
              _RadioOption(value: SortOption.artist, label: 'Artist'),
              _RadioOption(value: SortOption.album, label: 'Album'),
              _RadioOption(value: SortOption.date, label: 'Date added'),
            ],
            groupValue: _sortBy,
            onChanged: (v) => setState(() => _sortBy = v!),
          ),

          const Divider(indent: 20, endIndent: 20),

          // ── Group 2 : Genre ───────────────────────────────────────────────
          _RadioSection<SortBy>(
            title: 'order',
            icon: Icons.swap_vert,
            options: const [
              _RadioOption(value: SortBy.ascending, label: 'Ascending'),
              _RadioOption(value: SortBy.descending, label: 'Descending'),
            ],
            groupValue: _genre,
            onChanged: (v) => setState(() => _genre = v!),
          ),

          const SizedBox(height: 12),

          // ── Apply button ──────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: FilledButton(
              onPressed: () => Navigator.of(
                context,
              ).pop(SortFilterResult(sortBy: _sortBy, genre: _genre)),
              child: const Text('Apply'),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Internal helper widgets ──────────────────────────────────────────────────

/// A labelled radio-button group rendered inside the sheet.
class _RadioSection<T> extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<_RadioOption<T>> options;
  final T groupValue;
  final ValueChanged<T?> onChanged;

  const _RadioSection({
    required this.title,
    required this.icon,
    required this.options,
    required this.groupValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          child: Row(
            children: [
              Icon(icon, size: 18, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                title,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        ...options.map(
          (opt) => RadioListTile<T>(
            title: Text(opt.label),
            value: opt.value,
            groupValue: groupValue,
            onChanged: onChanged,
            dense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12),
          ),
        ),
      ],
    );
  }
}

/// Tiny data class holding a radio option's value + display label.
class _RadioOption<T> {
  final T value;
  final String label;
  const _RadioOption({required this.value, required this.label});
}
