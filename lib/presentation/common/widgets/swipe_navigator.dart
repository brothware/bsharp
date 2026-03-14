import 'package:flutter/widgets.dart';

class SwipeNavigator extends StatefulWidget {
  const SwipeNavigator({
    required this.onSwipeForward,
    required this.onSwipeBackward,
    required this.contentBuilder,
    this.enabled = true,
    super.key,
  });

  final VoidCallback onSwipeForward;
  final VoidCallback onSwipeBackward;
  final Widget Function(int offset) contentBuilder;
  final bool enabled;

  @override
  State<SwipeNavigator> createState() => _SwipeNavigatorState();
}

class _SwipeNavigatorState extends State<SwipeNavigator> {
  late final PageController _controller;
  int? _pendingPage;

  @override
  void initState() {
    super.initState();
    _controller = PageController(initialPage: 1);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(SwipeNavigator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_controller.hasClients && _controller.page?.round() != 1) {
      _controller.jumpToPage(1);
    }
  }

  void _onPageChanged(int page) {
    if (page != 1) {
      _pendingPage = page;
    }
  }

  bool _onScrollNotification(ScrollNotification notification) {
    if (notification is ScrollEndNotification && _pendingPage != null) {
      final settledPage = _controller.page?.round() ?? 1;
      _pendingPage = null;

      if (settledPage == 1) return false;

      if (settledPage == 0) {
        widget.onSwipeBackward();
      } else {
        widget.onSwipeForward();
      }

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_controller.hasClients) {
          _controller.jumpToPage(1);
        }
      });
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: _onScrollNotification,
      child: PageView.builder(
        controller: _controller,
        onPageChanged: _onPageChanged,
        physics: widget.enabled
            ? const ClampingScrollPhysics()
            : const NeverScrollableScrollPhysics(),
        itemCount: 3,
        itemBuilder: (_, index) => widget.contentBuilder(index - 1),
      ),
    );
  }
}
