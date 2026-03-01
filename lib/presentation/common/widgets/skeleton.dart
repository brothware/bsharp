import 'package:flutter/material.dart';

class ShimmerBox extends StatefulWidget {
  const ShimmerBox({
    this.width,
    this.height = 16,
    this.borderRadius = 4,
    super.key,
  });

  final double? width;
  final double height;
  final double borderRadius;

  @override
  State<ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<ShimmerBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final baseColor = theme.colorScheme.surfaceContainerHighest;
    final highlightColor = theme.colorScheme.surfaceContainerLow;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, _) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            color: Color.lerp(baseColor, highlightColor, _animation.value),
          ),
        );
      },
    );
  }
}

class SkeletonListTile extends StatelessWidget {
  const SkeletonListTile({this.hasLeading = true, super.key});

  final bool hasLeading;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          if (hasLeading) ...[
            const ShimmerBox(width: 40, height: 40, borderRadius: 20),
            const SizedBox(width: 16),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShimmerBox(
                  width: 160 + (hasLeading ? 0 : 40),
                  height: 14,
                ),
                const SizedBox(height: 8),
                const ShimmerBox(width: 100, height: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class SkeletonCard extends StatelessWidget {
  const SkeletonCard({this.height = 80, super.key});

  final double height;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ShimmerBox(
        height: height,
        borderRadius: 12,
      ),
    );
  }
}

class SkeletonList extends StatelessWidget {
  const SkeletonList({
    this.itemCount = 6,
    this.hasLeading = true,
    super.key,
  });

  final int itemCount;
  final bool hasLeading;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      itemCount: itemCount,
      itemBuilder: (context, index) => SkeletonListTile(
        hasLeading: hasLeading,
      ),
    );
  }
}
