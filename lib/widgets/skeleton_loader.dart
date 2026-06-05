import 'package:flutter/material.dart';
import '../../core/app_theme.dart';

class PostCardSkeleton extends StatefulWidget {
  const PostCardSkeleton({super.key});
  @override
  State<PostCardSkeleton> createState() => _PostCardSkeletonState();
}

class _PostCardSkeletonState extends State<PostCardSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.3, end: 0.7).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.surfaceDark,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            _Bone(width: 40, height: 40, radius: 20, opacity: _anim.value),
            const SizedBox(width: 10),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _Bone(width: 120, height: 12, opacity: _anim.value),
              const SizedBox(height: 6),
              _Bone(width: 80, height: 10, opacity: _anim.value),
            ]),
          ]),
          const SizedBox(height: 14),
          _Bone(width: double.infinity, height: 12, opacity: _anim.value),
          const SizedBox(height: 8),
          _Bone(width: double.infinity * 0.7, height: 12, opacity: _anim.value),
          const SizedBox(height: 14),
          _Bone(width: double.infinity, height: 200, radius: 12, opacity: _anim.value),
        ]),
      ),
    );
  }
}

class _Bone extends StatelessWidget {
  final double width;
  final double height;
  final double radius;
  final double opacity;

  const _Bone({
    required this.width,
    required this.height,
    this.radius = 6,
    required this.opacity,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppTheme.cardDark.withValues(alpha: opacity),
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}
