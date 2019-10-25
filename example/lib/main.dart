import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_video/flutter_video.dart';
import 'package:flutter/services.dart';
import 'package:ijkplayer_example/EventBus.dart';
import 'package:ijkplayer_example/TestPage.dart';
import 'package:ijkplayer_example/VideoBean.dart';

import 'package:orientation/orientation.dart';

void main() {
  runApp(new MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MainPage(),
    );
  }
}

class MainPage extends StatefulWidget {
  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> with WidgetsBindingObserver {
  List<VideoBean> videolist = [];
  //itemHight  向上滑动的距离
  double itemHight = 0;
  //点击item的 角标
  int clickPosition = 0;
  //滚动控制器
  ScrollController _scrollController =
      new ScrollController(initialScrollOffset: 0);
  //列表滑动的距离的初始值
  double initPosition = 0;
  //向下滑动的距离
  double upHight = 0;
  //   initPosition  记录点击时候列表滑动的高度

  //zheng zai  bo  fang  de  id
  IjkMediaController controller;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this); //添加观察者
    controller = IjkMediaController();
    _scrollController.addListener(() {
      //_scrollController.position.pixels - initPosition   列表从当前位置向上滑动的距离
      //itemHight  视频应该向上滑动的距离  才能消失
      //initPosition - _scrollController.position.pixels   列表从当前位置向下滑动的距离
      //upHight    视频应该向下滑动的距离  才能消失
      print('haasasassssssssssssss${controller.getSystemVolume()}');
      if (itemHight > 0) {
        if (_scrollController.position.pixels - initPosition > itemHight ||
            initPosition - _scrollController.position.pixels > upHight) {
          print('控件该隐藏了');
          //获取点击的视频 然后隐藏   并且itemHight =0
          if (controller != null) {
            controller.dispose();
          }
          VideoBean bean = videolist[clickPosition];
          setState(() {
            bean.isSeeVideo = false;
            itemHight = 0;
          });
        }
      }
    });
    //获取列表数据
    getApiData();

    print('只是初始化了');

    bus.addListener('eventName', (arg) {
      //接受广播  停止播放视频
      if (controller != null) {
        controller.pause();
      }
    });
  }

//销毁
  @override
  void dispose() {
    super.dispose();
    if (controller != null) {
      controller.dispose();
    }
    WidgetsBinding.instance.removeObserver(this); //销毁观察者
    print('只是被销毁了了');
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    print(state);
    switch (state) {
      case AppLifecycleState.inactive: // 处于这种状态的应用程序应该假设它们可能在任何时候暂停。
        break;
      case AppLifecycleState.resumed: // 应用程序可见，前台
        print('OnResume()');
        if (controller != null) {
          controller.play();
        }
        break;
      case AppLifecycleState.paused: // 应用程序不可见，后台
        print('OnPaused()');
        if (controller != null) {
          bus.sendBroadcast('eventName');
        }
        break;
      case AppLifecycleState.suspending: // 申请将暂时暂停
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // SystemChrome.setPreferredOrientations(
        //     [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('Video Player'),
          actions: <Widget>[
            GestureDetector(
              onTap: () {
                bus.sendBroadcast('eventName');
        //          SystemChrome.setPreferredOrientations([
        //   DeviceOrientation.landscapeRight,
        //   DeviceOrientation.landscapeLeft,
        // ]);
        // if (Platform.isIOS) {
        //   OrientationPlugin.forceOrientation(DeviceOrientation.landscapeLeft);
        // }
        // SystemChrome.setEnabledSystemUIOverlays([]);
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => TestPage()));
              },
              child: Container(
                  height: 30,
                  width: 100,
                  alignment: Alignment.center,
                  color: Colors.lightBlue,
                  child: Text(
                    '点击跳转',
                    style: TextStyle(color: Colors.white, fontSize: 15),
                  )),
            )
          ],
        ),
        body: getListView(context),
      ),
    );
  }

//获取列表
  getListView(BuildContext context) {
    return ListView.builder(
      controller: _scrollController,
      itemBuilder: (context, i) {
        GlobalKey firstKey = GlobalKey();
        GlobalKey secondKey = GlobalKey();
        return GestureDetector(
          onTap: () {
            itemClick(secondKey, i);
          },
          child: buildItems(videolist[i], firstKey, secondKey),
        );
      },
      itemCount: videolist.length,
    );
  }

  buildItems(
    VideoBean bean,
    GlobalKey firstKey,
    GlobalKey secondKey,
  ) {
    if (bean.isSeeVideo) {
      return Container(
        key: firstKey,
        height: 300,
        child: IjkPlayer(
          mediaController: controller,
        ),
      );
    } else {
      return Container(
        key: secondKey,
        height: 300,
        width: MediaQuery.of(context).size.width,
        margin: EdgeInsets.all(10),
        color: Color.fromRGBO(0, 0, 0, 0.5),
        child: Center(
          child: Icon(
            Icons.play_arrow,
            size: 40,
            color: Colors.white,
          ),
        ),
      );
    }
  }

  getApiData() {
    for (int i = 0; i < 6; i++) {
      VideoBean bean = new VideoBean();
      bean.id = i;
      bean.url = '';
      bean.name = '';
      videolist.add(bean);
    }
  }

  itemClick(GlobalKey secondKey, int position) async {
    //

    if (!controller.isInit) {
      //获取视频播放的进度
      var videoInfo = await controller.getVideoInfo();
      if (videoInfo.currentPosition != null) {
        var pos = videoInfo.currentPosition / videoInfo.duration;
        print('播放的时长：$pos');
      }

      controller.dispose();
    }
    initPlayer();

    RenderBox renderBox = secondKey.currentContext.findRenderObject();
    var offset = renderBox.localToGlobal(Offset(0.0, renderBox.size.height));
    setState(() {
      //获取当前列表滚动的距离
      itemHight = offset.dy;
      clickPosition = position;
    });
    print('$itemHight');
    for (int j = 0; j < videolist.length; j++) {
      VideoBean videoBean = videolist[j];
      setState(() {
        videoBean.isSeeVideo = false;
      });
    }

    VideoBean bean = videolist[position];
    setState(() {
      bean.isSeeVideo = true;
      initPosition = _scrollController.position.pixels;
      //屏幕的高度-视频所处的高度 +视频的高度
      upHight = MediaQuery.of(context).size.height - itemHight + 300;
    });
  }

//为了解决 初始化之后 直接播放某个进度的视频
  initPlayer() async {
    controller = IjkMediaController();
    await controller.setAssetDataSource('assets/video0.mp4', autoPlay: true);
    await controller.seekToProgress(0.5);
    //IjkManager.setSystemBrightness(0);

    //设置手势事件
    // DefaultIJKControllerWidget defaultIJKControllerWidget =
    //     new DefaultIJKControllerWidget(controller: controller);
    //    defaultIJKControllerWidget.
  }
}

// print('正在滑动:${_scrollController.position.pixels}');
// print('123455   ${_scrollController.offset}');
// print('itemHight$itemHight');
//两个问题  1. 滚动方向 2.滚动到什么程度
// if (itemHight > 0) {
//   if (_scrollController.position.pixels - initPosition > 0) {
//     //滑动的时候给initPosition赋值  手势向上滑动  列表是向下滑动
//     setState(() {
//       initPosition = _scrollController.position.pixels;
//       SCROLL_UP = true;
//       SCROLL_DOWN = false;
//     });
//     // print('向上滑动');
//   } else {
//     setState(() {
//       initPosition = _scrollController.position.pixels;
//       SCROLL_UP = false;
//       SCROLL_DOWN = true;
//     });
//     // print('向下滑动');
//   }

//   if (SCROLL_UP) {
//     //如果向上滚动
//     if (_scrollController.position.pixels - itemHight > 0) {
//       print('滑动到头了');
//       VideoBean bean = videolist[clickPosition];
//       setState(() {
//         bean.isSeeVideo = false;
//         itemHight = 0;
//       });
//     }
//   }
//根据可滚动的范围来判断  可滚动的范围就是最大的 长度减去
//  根据item的当前位置 判断向哪个方向才能消失
//可以判断item 距离底部  距离顶部的距离
//一种是向上 item不可见 消失  一种是向下  item 不可见

// if (SCROLL_DOWN) {
//   // //如果向下滚动
//   if (_scrollController.offset - itemHight < 0) {
//     print('滑动到底了');
//     VideoBean bean = videolist[clickPosition];
//     setState(() {
//       bean.isSeeVideo = false;
//       itemHight = 0;
//     });
//   }
// }`
//}

// if (itemHight != 0) {
//   //说明点击了  可以执行下面的滑动操作了
//   //判断滑动方向

//   //向上滑动
//   if (_scrollController.offset -itemHight> 0) {
//     print('向上滑动');
//     // VideoBean bean = videolist[clickPosition];
//     // setState(() {
//     //   bean.isSeeVideo = false;
//     //   itemHight = 0;
//     // });
//   } else {
//     //向下滑动
//     print('向向下滑动');
//     // VideoBean bean = videolist[clickPosition];
//     // setState(() {
//     //   bean.isSeeVideo = false;
//     //   itemHight = 0;
//     // });
//   }

//   //目前 两个问题 1. 列表向哪个方向滚动  2. 滚动到什么程度
// }
