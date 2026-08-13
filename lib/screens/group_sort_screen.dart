import 'dart:math';
import 'package:flutter/material.dart';
import '../models/group_sort.dart';
import '../utils/page_transitions.dart';
import 'result_screen.dart';

class GroupSortScreen extends StatefulWidget {
  final GroupSortData data;

  const GroupSortScreen({super.key, required this.data});

  @override
  State<GroupSortScreen> createState() => _GroupSortScreenState();
}

class _GroupSortScreenState extends State<GroupSortScreen> {
  late List<GroupSortItem> _pool;
  late Map<String, List<GroupSortItem>> _buckets;
  int _attempts = 0;

  @override
  void initState() {
    super.initState();
    _pool = List<GroupSortItem>.from(widget.data.items)..shuffle(Random());
    _buckets = {for (var category in widget.data.categories) category: []};
  }

  void _handleDrop(GroupSortItem item, String targetCategory) {
    setState(() {
      _attempts++;
      if (item.category == targetCategory) {
        _pool.remove(item);
        _buckets[targetCategory]!.add(item);
      }
    });

    if (_pool.isEmpty) {
      Future.delayed(const Duration(milliseconds: 400), () {
        if (!mounted) return;
        Navigator.push(
          context,
          buildFadeSlideRoute(
            ResultScreen(
              score: widget.data.items.length,
              total: _attempts,
              onPlayAgain: () => Navigator.popUntil(context, (route) => route.isFirst),
            ),
          ),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('Group Sort (${widget.data.items.length - _pool.length} von ${widget.data.items.length})'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Wörter einsortieren:', style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.7))),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [for (var item in _pool) _buildDraggable(context, item)],
            ),
            const SizedBox(height: 24),
            Expanded(
              child: Row(
                children: [
                  for (var category in widget.data.categories) ...[
                    Expanded(child: _buildBucket(context, category)),
                    if (category != widget.data.categories.last) const SizedBox(width: 12),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDraggable(BuildContext context, GroupSortItem item) {
    final colorScheme = Theme.of(context).colorScheme;
    final chip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(color: colorScheme.primaryContainer, borderRadius: BorderRadius.circular(10)),
      child: Text(item.word, style: const TextStyle(fontWeight: FontWeight.w600)),
    );

    return Draggable<GroupSortItem>(
      data: item,
      feedback: Material(color: Colors.transparent, child: chip),
      childWhenDragging: Opacity(opacity: 0.3, child: chip),
      child: chip,
    );
  }

  Widget _buildBucket(BuildContext context, String category) {
    final colorScheme = Theme.of(context).colorScheme;
    final placedItems = _buckets[category]!;

    return DragTarget<GroupSortItem>(
      onWillAcceptWithDetails: (_) => true,
      onAcceptWithDetails: (details) => _handleDrop(details.data, category),
      builder: (context, candidateData, rejectedData) {
        final highlighted = candidateData.isNotEmpty;
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: highlighted ? colorScheme.secondaryContainer : colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colorScheme.outline.withValues(alpha: 0.4)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                category,
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const Divider(),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      for (var item in placedItems)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(item.word, textAlign: TextAlign.center),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
