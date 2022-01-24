import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:frosty/api/twitch_api.dart';
import 'package:frosty/constants/constants.dart';
import 'package:frosty/screens/channel/chat/chat.dart';
import 'package:frosty/screens/channel/stores/chat_store.dart';
import 'package:frosty/screens/channel/stores/video_store.dart';
import 'package:frosty/screens/channel/video/video.dart';
import 'package:frosty/screens/channel/video/video_overlay.dart';
import 'package:frosty/screens/settings/settings.dart';
import 'package:provider/provider.dart';

class VideoChat extends StatefulWidget {
  final ChatStore chatStore;

  const VideoChat({
    Key? key,
    required this.chatStore,
  }) : super(key: key);

  @override
  _VideoChatState createState() => _VideoChatState();
}

class _VideoChatState extends State<VideoChat> {
  final _videoKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final chatStore = widget.chatStore;
    final settingsStore = chatStore.settings;

    final videoStore = VideoStore(
      twitchApi: context.read<TwitchApi>(),
      userLogin: chatStore.channelName,
      authStore: chatStore.auth,
      settingsStore: chatStore.settings,
    );

    final player = Video(
      key: _videoKey,
      videoStore: videoStore,
    );

    final video = GestureDetector(
      onLongPress: videoStore.handleToggleOverlay,
      onTap: () {
        if (chatStore.assetsStore.showEmoteMenu) {
          chatStore.assetsStore.showEmoteMenu = false;
        } else {
          if (chatStore.textFieldFocusNode.hasFocus) {
            chatStore.textFieldFocusNode.unfocus();
          } else {
            videoStore.handleVideoTap();
          }
        }
      },
      child: Observer(
        builder: (context) {
          if (videoStore.settingsStore.showOverlay) {
            return Stack(
              children: [
                player,
                Observer(
                  builder: (_) {
                    if (videoStore.paused) return VideoOverlay(videoStore: videoStore);
                    return Observer(
                      builder: (_) => AnimatedOpacity(
                        opacity: videoStore.overlayVisible ? 1.0 : 0.0,
                        duration: const Duration(milliseconds: 200),
                        child: ColoredBox(
                          color: const Color.fromRGBO(0, 0, 0, 0.5),
                          child: IgnorePointer(
                            ignoring: !videoStore.overlayVisible,
                            child: VideoOverlay(videoStore: videoStore),
                          ),
                        ),
                      ),
                    );
                  },
                )
              ],
            );
          }
          return player;
        },
      ),
    );

    final chat = Chat(chatStore: chatStore);

    final appBar = AppBar(
      title: Text(
        regexEnglish.hasMatch(chatStore.displayName) ? chatStore.displayName : chatStore.displayName + ' (${chatStore.channelName})',
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
        builder: (context, orientation) {
          if (orientation == Orientation.landscape) {
            SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
            return Observer(
              builder: (context) => ColoredBox(
                color: settingsStore.showVideo ? Colors.black : Theme.of(context).scaffoldBackgroundColor,
                child: SafeArea(
                  bottom: false,
                  child: settingsStore.showVideo
                      ? settingsStore.fullScreen
                          ? video
                          : Row(
                              children: [
                                Flexible(
                                  flex: 2,
                                  child: video,
                                ),
                                Flexible(
                                  flex: 1,
                                  child: ColoredBox(
                                    color: Theme.of(context).scaffoldBackgroundColor,
                                    child: chat,
                                  ),
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
              ),
            );
          }

          SystemChrome.setEnabledSystemUIMode(
            SystemUiMode.manual,
            overlays: [SystemUiOverlay.bottom, SystemUiOverlay.top],
          );
          return SafeArea(
            child: Column(
              children: [
                Observer(
                  builder: (_) {
                    if (settingsStore.showVideo) {
                      return AspectRatio(
                        aspectRatio: 16 / 9,
                        child: video,
                      );
                    }
                    return appBar;
                  },
                ),
                Expanded(child: chat),
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

    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: [SystemUiOverlay.bottom, SystemUiOverlay.top],
    );

    super.dispose();
  }
}
