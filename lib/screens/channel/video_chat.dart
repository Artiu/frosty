import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:frosty/screens/channel/chat/chat.dart';
import 'package:frosty/screens/channel/stores/chat_store.dart';
import 'package:frosty/screens/channel/stores/video_store.dart';
import 'package:frosty/screens/channel/video/video.dart';
import 'package:frosty/screens/settings/settings.dart';

class VideoChat extends StatefulWidget {
  final String displayName;
  final VideoStore videoStore;
  final ChatStore chatStore;

  const VideoChat({
    Key? key,
    required this.displayName,
    required this.videoStore,
    required this.chatStore,
  }) : super(key: key);

  @override
  _VideoChatState createState() => _VideoChatState();
}

class _VideoChatState extends State<VideoChat> {
  final videoKey = GlobalKey();
  final chatKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final videoStore = widget.videoStore;
    final chatStore = widget.chatStore;
    final settingsStore = chatStore.settings;

    final video = Video(
      key: videoKey,
      userLogin: videoStore.userLogin,
      videoStore: videoStore,
    );

    final chat = Chat(
      key: chatKey,
      chatStore: chatStore,
    );

    final appBar = AppBar(
      title: Text(
        widget.displayName,
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      ),
      actions: [
        IconButton(
          tooltip: 'Settings',
          icon: const Icon(Icons.settings),
          onPressed: () => showModalBottomSheet(
            isScrollControlled: true,
            context: context,
            builder: (context) => SizedBox(
              height: MediaQuery.of(context).size.height * 0.8,
              child: Settings(settingsStore: settingsStore),
            ),
          ),
        ),
      ],
    );

    return Scaffold(
      body: OrientationBuilder(
        builder: (_, orientation) {
          if (orientation == Orientation.landscape) {
            if (settingsStore.fullScreen) SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
            return Observer(
              builder: (_) => SafeArea(
                bottom: settingsStore.fullScreen ? false : true,
                child: settingsStore.showVideo
                    ? settingsStore.fullScreen
                        ? WillPopScope(
                            onWillPop: () async => false,
                            child: Stack(
                              children: [
                                Visibility(
                                  visible: false,
                                  maintainState: true,
                                  child: chat,
                                ),
                                Center(child: video),
                              ],
                            ),
                          )
                        : Row(
                            children: [
                              Flexible(
                                flex: 2,
                                child: video,
                              ),
                              Flexible(
                                flex: 1,
                                child: chat,
                              ),
                            ],
                          )
                    : Column(
                        children: [
                          appBar,
                          Expanded(child: chat),
                        ],
                      ),
              ),
            );
          }

          settingsStore.fullScreen = false;
          SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: [SystemUiOverlay.bottom, SystemUiOverlay.top]);
          return SafeArea(
            child: Column(
              children: [
                Observer(
                  builder: (_) {
                    if (settingsStore.showVideo) {
                      return video;
                    }
                    return appBar;
                  },
                ),
                Expanded(
                  child: chat,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    widget.chatStore.dispose();
    super.dispose();
  }
}
