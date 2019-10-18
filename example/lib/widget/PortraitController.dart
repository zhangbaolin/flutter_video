import 'package:flutter/material.dart';
import 'package:flutter_video/flutter_video.dart';
import 'package:ijkplayer_example/widget/progress_bar.dart';
import 'package:ijkplayer_example/widget/time_helper.dart';

class PortraitController extends StatelessWidget {
  final IjkMediaController controller;
  final VideoInfo info;
  final TooltipDelegate tooltipDelegate;
  final bool playWillPauseOther;
  final Widget fullScreenWidget;

  const PortraitController({
    Key key,
    this.controller,
    this.info,
    this.tooltipDelegate,
    this.playWillPauseOther = true,
    this.fullScreenWidget,
  }) : super(key: key);

  bool get haveTime {
    return info.hasData && info.duration > 0;
  }

  @override
  Widget build(BuildContext context) {
    if (!info.hasData) {
      return Container();
    }
    Widget bottomBar = buildBottomBar(context);
    return Column(
      children: <Widget>[
        Expanded(
          child: Container(),
        ),
        bottomBar,
      ],
    );
  }

  Widget buildBottomBar(BuildContext context) {
    var currentTime = buildCurrentText();
    var maxTime = buildMaxTimeText();
    var progress = buildProgress(info);

    var playButton = buildPlayButton(context);

    var fullScreenButton = buildFullScreenButton();

    Widget widget = Container(
      width: MediaQuery.of(context).size.width,
      height: 35,
      child: Row(
        children: <Widget>[
          playButton,
          Padding(
            padding: const EdgeInsets.only(left: 8, right: 8),
            child: currentTime,
          ),
          Expanded(child: progress),
          Padding(
            padding: const EdgeInsets.only(left: 8, right: 8),
            child: maxTime,
          ),
          fullScreenButton,
        ],
      ),
    );
    widget = DefaultTextStyle(
      style: const TextStyle(
        color: Colors.white,
      ),
      child: widget,
    );
    widget = Container(
      color: Colors.black.withOpacity(0.12),
      child: widget,
    );
    return widget;
  }

  Widget buildProgress(VideoInfo info) {
    if (!info.hasData || info.duration == 0) {
      return Container();
    }
    return Container(
      height: 25,
      child: ProgressBar(
        current: info.currentPosition,
        max: info.duration,
        buffered: info.bufferPosition,
        bufferColor: Colors.green[200],
        changeProgressHandler: (progress) async {
          await controller.seekToProgress(progress);
          tooltipDelegate?.hideTooltip();
        },
        tapProgressHandler: (progress) async {
          if (controller.ijkStatus == IjkStatus.prepared ||
              controller.ijkStatus == IjkStatus.prepared) {
            controller.refreshVideoInfo();
          }
          await controller.seekToProgress(progress);
          // tooltipDelegate?.hideTooltip();
        },
      ),
    );
  }

  buildCurrentText() {
    return haveTime
        ? Text(
            TimeHelper.getTimeText(info.currentPosition),
          )
        : Container();
  }

  buildMaxTimeText() {
    return haveTime
        ? Text(
            TimeHelper.getTimeText(info.duration),
          )
        : Container();
  }

  buildPlayButton(BuildContext context) {
    return GestureDetector(
      onTap: () {
        controller.playOrPause(pauseOther: playWillPauseOther);
      },
      child: Container(
        width: 25,
        height: 25,
        alignment: Alignment.center,
        child: Icon(
          info.isPlaying ? Icons.pause : Icons.play_arrow,
          size: 25,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget buildFullScreenButton() {
    return fullScreenWidget ?? Container();
  }
}

abstract class TooltipDelegate {
  void showTooltip(Widget widget);

  Widget createTooltipWidgetWrapper(Widget widget);

  void hideTooltip();
}
