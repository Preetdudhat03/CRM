
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

class _AnimatedIndexedStackState extends State<AnimatedIndexedStack>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  late int _currentIndex;

  // Track which tabs have been visited — only build those
  late final Set<int> _visitedIndices;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.index;
    _visitedIndices = {widget.index}; // Only the initial tab is visited
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 150));
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeIn));
    _controller.forward();
  }

  @override
  void didUpdateWidget(covariant AnimatedIndexedStack oldWidget) {
    if (widget.index != _currentIndex) {
      _controller.reverse().then((_) {
        if (mounted) {
          setState(() {
            _currentIndex = widget.index;
            _visitedIndices.add(widget.index); // Mark as visited on first switch
          });
          _controller.forward();
        }
      });
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _animation,
      child: IndexedStack(
        index: _currentIndex,
        children: [
          for (int i = 0; i < widget.children.length; i++)
            // Only build child if the tab has been visited; otherwise use empty placeholder
            _visitedIndices.contains(i)
                ? widget.children[i]
                : const SizedBox.shrink(),
        ],
      ),
    );
  }
}
