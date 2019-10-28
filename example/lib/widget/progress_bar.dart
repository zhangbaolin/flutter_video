import 'package:flutter/material.dart';
import 'package:ijkplayer_example/widget/ui_helper.dart';

typedef ChangeProgressHandler(double progress);

typedef TapProgressHandler(double progress);

class ProgressBar extends StatefulWidget {
  final double max;
  final double current;
  final double buffered;
  final Color backgroundColor;
  final Color bufferColor;
  final Color playedColor;
  final ChangeProgressHandler changeProgressHandler;
  final TapProgressHandler tapProgressHandler;
  final double progressFlex;

  const ProgressBar({
    Key key,
    @required this.max,
    @required this.current,
    this.buffered,
    this.backgroundColor = const Color(0xFF616161),
    this.bufferColor = Colors.grey,
    this.playedColor = Colors.white,
    this.changeProgressHandler,
    this.tapProgressHandler,
    this.progressFlex = 0.4,
  }) : super(key: key);

  @override
  _ProgressBarState createState() => _ProgressBarState();
}
class _ProgressBarState extends State<ProgressBar> {
  GlobalKey _progressKey = GlobalKey();

  double tempLeft;
  double tempCenter;

  double firstlsft;

  double get left {
    var l = widget.current / widget.max;
    if (tempLeft != null) {
      return tempLeft;
    }
    return l;
  }

  var mid;
  @override
  void initState() {
    super.initState();
    tempCenter = null;
  }

  @override
  void dispose() {
    tempCenter = null;
    tempLeft = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.max == null || widget.current == null || widget.max == 0)
      return _buildEmpty();

    mid = (widget.buffered ?? 0) / widget.max;
    if (mid < 0) {
      mid = 0;
    }
    // if (tempCenter != null) {
    //   mid = tempCenter + mid;
    // }
    var right = 1 - left - mid;

    Widget progress = buildProgress(left, mid, right);

    if (widget.changeProgressHandler != null &&
        widget.tapProgressHandler != null) {
      progress = GestureDetector(
        child: progress,
        behavior: HitTestBehavior.translucent,
        onPanUpdate: _onPanUpdate,
        onHorizontalDragUpdate: _onHorizontalDragUpdate,
        onHorizontalDragEnd: _onHorizontalDragEnd,
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
      );
    }

    return progress;
  }

  _buildEmpty() {
    return Container();
  }

  int get flex => (widget.progressFlex * 100).toInt();

  Widget buildProgress(double left, double mid, double right) {
    return Column(
      children: <Widget>[
        Flexible(child: Container(), flex: 100 - flex ~/ 2),
        Flexible(
          flex: flex,
          child: Row(
            key: _progressKey,
            children: <Widget>[
              buildColorWidget(widget.playedColor, left),
              buildColorWidget(widget.bufferColor, mid),
              buildColorWidget(widget.backgroundColor, right),
            ],
          ),
        ),
        Flexible(child: Container(), flex: 100 - flex ~/ 2),
      ],
    );
  }

  Widget buildColorWidget(Color color, double flex) {
    if (flex == double.nan ||
        flex == double.infinity ||
        flex == double.negativeInfinity) {
      flex = 0;
    }
    if (flex == 0) {
      return Container();
    }
    return Expanded(
      flex: (flex * 1000).toInt(),
      child: Container(
        color: color,
      ),
    );
  }

  void _onTapDown(TapDownDetails details) {
    tempCenter = null;
    tempLeft = null;
    var progress = getProgress(details.globalPosition);
    firstlsft = progress;
    widget.tapProgressHandler(progress);
  }

  void _onPanUpdate(DragUpdateDetails details) {
    var progress = getProgress(details.globalPosition);
    widget.tapProgressHandler(progress);
  }

  void _onTapUp(TapUpDetails details) {
    var progress = getProgress(details.globalPosition);

    // print("正在播放的位置：$left");
    // print("正在缓存的位置：$mid");
    // print("点击后要播放的位置:  $progress");

    //重新计算
    //1. 判断点击的位置  是向前点击  还是向后点击
    //2. 判断是在缓冲区域点击还是在  非缓冲区域点击
    // setState(() {
    //   if (left < progress) {
    //     //向前  判断在缓冲区域前 还是在缓冲区域后
    //     if ((left + mid) < progress) {
    //       //缓冲区域外
    //       tempCenter = 0.0;
    //     } else {
    //       //缓冲区域内
    //       tempCenter = left + mid - progress;
    //     }
    //   } else {
    //     //向后
    //     tempCenter = mid + left - progress;
    //   }
    // });

    widget.changeProgressHandler(progress);
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    var progress = getProgress(details.globalPosition);
    // setState(() {
    //   tempLeft = progress;
    // });
    tempLeft = progress;

    //widget.tapProgressHandler(tempLeft);
   // widget.changeProgressHandler(progress);
  }

  double getProgress(Offset globalPosition) {
    var offset = _getLocalOffset(globalPosition);
    var globalRect = UIHelper.findGlobalRect(_progressKey);
    var progress = offset.dx / globalRect.width;
    if (progress > 1) {
      progress = 1;
    } else if (progress < 0) {
      progress = 0;
    }
    return progress;
  }

  Offset _getLocalOffset(Offset globalPosition) {
    return UIHelper.globalOffsetToLocal(
      _progressKey,
      globalPosition,
    );
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    if (tempLeft != null) {
      // print("拖动之后到达的播放位置 ：$tempLeft");
      // setState(() {
      //   if (firstlsft < tempLeft) {
      //     //向前  判断在缓冲区域前 还是在缓冲区域后
      //     if ((firstlsft + mid) < tempLeft) {
      //       //缓冲区域外
      //       print("缓冲区域外");
      //       tempCenter = 0.0;
      //     } else {
      //       //缓冲区域内
      //       print("缓冲区域内");
      //       tempCenter = tempLeft - firstlsft;
      //     }
      //   } else {
      //     //向后

      //     tempCenter = mid + firstlsft - tempLeft;
      //     print("向后拖动left:$firstlsft");
      //     print("向后拖动mid：$mid");
      //     print("向后拖动后的缓存tempCenter：$tempCenter");
      //   }
      // });
      widget.changeProgressHandler(tempLeft);
      tempLeft = null;
    }
  }
}
