// lib/widgets/shimmer_loading.dart
//
// تأثير "شيمر" بسيط بدون أي مكتبة خارجية — بس Flutter عادي.
// بيغطي أي ويدجت وبيحط فوقها تدرّج لوني بيتحرك يمين-يسار باستمرار
// لإعطاء إحساس "عم يحمّل" بدل دائرة تحميل تقليدية.

import 'package:flutter/material.dart';

class ShimmerLoading extends StatefulWidget {
  final Widget child;

  const ShimmerLoading({super.key, required this.child});

  @override
  State<ShimmerLoading> createState() => _ShimmerLoadingState();
}

class _ShimmerLoadingState extends State<ShimmerLoading>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final double slide = _controller.value * 2 - 1; // من -1 إلى 1
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              colors: [
                Colors.grey.shade300,
                Colors.grey.shade100,
                Colors.grey.shade300,
              ],
              stops: const [0.35, 0.5, 0.65],
              begin: Alignment(-1 - slide, 0),
              end: Alignment(1 - slide, 0),
            ).createShader(bounds);
          },
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

// هيكل بديل (Skeleton) يحاكي شكل شاشة المخطط بالضبط ريثما توصل
// البيانات الحقيقية، بدل ما تكون الشاشة فاضية أو فيها بس دائرة تحميل صغيرة
class SkeletonDiagram extends StatelessWidget {
  const SkeletonDiagram({super.key});

  Widget _box({double? width, double height = 16, double radius = 8}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _box(width: 140, height: 20),
        const SizedBox(height: 16),
        Row(
          children: [
            _box(width: 90, height: 34, radius: 20),
            const SizedBox(width: 8),
            _box(width: 90, height: 34, radius: 20),
          ],
        ),
        const SizedBox(height: 20),
        _box(height: 260, radius: 12),
        const SizedBox(height: 24),
        _box(width: 120, height: 18),
        const SizedBox(height: 12),
        ...List.generate(
          4,
          (i) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _box(height: 56, radius: 12),
          ),
        ),
      ],
    );
  }
}

// قائمة هياكل بديلة (Skeleton) لشاشة قائمة الطالبات — كل عنصر شكله قريب
// من شكل كرت الطالبة الحقيقي (أفاتار دائرية + سطرين نص) حتى ما يصير
// "قفزة" بالتخطيط لما توصل البيانات الحقيقية وتحل مكان الهيكل
class SkeletonListView extends StatelessWidget {
  final int count;

  const SkeletonListView({super.key, this.count = 6});

  Widget _bar({double? width, double height = 14, double radius = 6}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      physics: const NeverScrollableScrollPhysics(),
      itemCount: count,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _bar(width: 130, height: 15),
                    const SizedBox(height: 8),
                    _bar(width: 90, height: 12),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
