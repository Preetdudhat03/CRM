
import 'package:flutter/material.dart';

class AnimatedIndexedStack extends StatefulWidget {
  final int index;
  final List<Widget> children;

  const AnimatedIndexedStack({
    super.key,
    required this.index,
    required this.children,
  });

  @override
  State<AnimatedIndexedStack> createState() => _AnimatedIndexedStackState();
}

class _AnimatedIndexedStackState extends State<AnimatedIndexedStack> {
  late int _currentIndex;

  // Track which tabs have been visited — only build those
  late final Set<int> _visitedIndices;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.index;
    _visitedIndices = {widget.index};
  }

  @override
  void didUpdateWidget(covariant AnimatedIndexedStack oldWidget) {
    if (widget.index != _currentIndex) {
      setState(() {
        _currentIndex = widget.index;
        _visitedIndices.add(widget.index);
      });
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: IndexedStack(
        key: ValueKey(_currentIndex),
        index: _currentIndex,
        children: [
          for (int i = 0; i < widget.children.length; i++)
            _visitedIndices.contains(i)
                ? widget.children[i]
                : const SizedBox.shrink(),
        ],
      ),
    );
  }
}
