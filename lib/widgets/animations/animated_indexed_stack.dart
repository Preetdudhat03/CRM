
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
  late List<bool> _mountedTabs;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.index;
    _mountedTabs = List.generate(widget.children.length, (index) => index == _currentIndex);
    
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 150));
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeIn));
    _controller.forward();
  }

  @override
  void didUpdateWidget(covariant AnimatedIndexedStack oldWidget) {
    if (widget.index != _currentIndex) {
      _mountedTabs[widget.index] = true;
      _controller.reverse().then((_) {
        if (mounted) {
          setState(() => _currentIndex = widget.index);
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
    final lazyChildren = List<Widget>.generate(widget.children.length, (i) {
      if (_mountedTabs[i]) {
        return widget.children[i];
      } else {
        return const SizedBox.shrink(); // Prevent unvisited tabs from mounting and firing API queries
      }
    });

    return FadeTransition(
      opacity: _animation,
      child: IndexedStack(
        index: _currentIndex,
        children: lazyChildren,
      ),
    );
  }
}
