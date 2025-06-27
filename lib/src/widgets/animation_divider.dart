import 'package:flutter/material.dart';

class AnimationDivider extends StatefulWidget {
  late double width;
  AnimationDivider({Key? key, required this.width}) : super(key: key);

  @override
  State<AnimationDivider> createState() => _AnimationDividerState();
}

class _AnimationDividerState extends State<AnimationDivider>
    with SingleTickerProviderStateMixin {
  late Animation<double> _progressAnimation;
  late AnimationController _progressAnimcontroller;
  late double width;
  @override
  void initState() {
    super.initState();
    width = widget.width;

    _progressAnimcontroller = AnimationController(
      duration: Duration(milliseconds: 3000),
      vsync: this,
    );

    _progressAnimation = Tween<double>(begin: beginWidth, end: endWidth)
        .animate(_progressAnimcontroller);
  }

  late double growStepWidth = 0.0, beginWidth = 0.0, endWidth = 0.0;
  int totalPages = 4;

  _setProgressAnim(double maxWidth, int curPageIndex) {
    _progressAnimcontroller.reset();
    setState(() {
      beginWidth = 0;
      endWidth = width;

      _progressAnimation = Tween<double>(begin: beginWidth, end: endWidth)
          .animate(_progressAnimcontroller);
    });

    _progressAnimcontroller.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Row(
        children: <Widget>[
          AnimatedProgressBar(
            animation: _progressAnimation,
          ),
          Expanded(
            child: Container(
              height: 6.0,
              width: double.infinity,
              decoration: BoxDecoration(color: Colors.white),
            ),
          )
        ],
      ),
    );
  }
}

class AnimatedProgressBar extends AnimatedWidget {
  AnimatedProgressBar({Key? key, required Animation<double> animation})
      : super(key: key, listenable: animation);

  Widget build(BuildContext context) {
    final Animation<double> animation = listenable as Animation<double>;
    return Container(
      height: 6.0,
      width: animation.value,
      decoration: BoxDecoration(color: Colors.green),
    );
  }
}
