import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:frosty/apis/bttv_api.dart';
import 'package:frosty/apis/ffz_api.dart';
import 'package:frosty/apis/seventv_api.dart';
import 'package:frosty/apis/twitch_api.dart';
import 'package:frosty/screens/channel/chat/chat.dart';
import 'package:frosty/screens/channel/chat/details/chat_details_store.dart';
import 'package:frosty/screens/channel/chat/stores/chat_assets_store.dart';
import 'package:frosty/screens/channel/chat/stores/chat_store.dart';
import 'package:frosty/screens/channel/video/video.dart';
import 'package:frosty/screens/channel/video/video_bar.dart';
import 'package:frosty/screens/channel/video/video_overlay.dart';
import 'package:frosty/screens/channel/video/video_store.dart';
import 'package:frosty/screens/home/home_store.dart';
import 'package:frosty/screens/settings/stores/auth_store.dart';
import 'package:frosty/screens/settings/stores/settings_store.dart';
import 'package:frosty/theme.dart';
import 'package:frosty/utils.dart';
import 'package:frosty/widgets/app_bar.dart';
import 'package:frosty/widgets/notification.dart';
import 'package:provider/provider.dart';
import 'package:simple_pip_mode/actions/pip_actions_layout.dart';
import 'package:simple_pip_mode/pip_widget.dart';

/// Creates a widget that shows the video stream (if live) and chat of the given user.
class VideoChat extends StatefulWidget {
  final String userId;
  final String userName;
  final String userLogin;
  final VideoStore videoStore;

  const VideoChat({
    super.key,
    required this.userId,
    required this.userName,
    required this.userLogin,
    required this.videoStore,
  });

  @override
  State<VideoChat> createState() => _VideoChatState();
}

class _VideoChatState extends State<VideoChat> {
  final _videoKey = GlobalKey();
  final _chatKey = GlobalKey();

  late final ChatStore _chatStore = ChatStore(
    channelName: widget.userLogin,
    channelId: widget.userId,
    displayName: widget.userName,
    auth: context.read<AuthStore>(),
    settings: context.read<SettingsStore>(),
    chatDetailsStore: ChatDetailsStore(
      twitchApi: context.read<TwitchApi>(),
      channelName: widget.userLogin,
    ),
    assetsStore: ChatAssetsStore(
      twitchApi: context.read<TwitchApi>(),
      ffzApi: context.read<FFZApi>(),
      bttvApi: context.read<BTTVApi>(),
      sevenTVApi: context.read<SevenTVApi>(),
    ),
  );

  late final VideoStore _videoStore = widget.videoStore;

  late final _homeStore = context.read<HomeStore>();

  @override
  Widget build(BuildContext context) {
    final orientation = MediaQuery.of(context).orientation;

    final settingsStore = _chatStore.settings;

    final appBar = FrostyAppBar(
      title: Text(
        getReadableName(_chatStore.displayName, _chatStore.channelName),
      ),
    );

    final player = GestureDetector(
      onLongPress: _videoStore.handleToggleOverlay,
      child: Video(
        key: _videoKey,
        videoStore: _videoStore,
      ),
    );

    final overlay = GestureDetector(
      onLongPress: _videoStore.handleToggleOverlay,
      onDoubleTap: orientation == Orientation.landscape
          ? () => settingsStore.fullScreen = !settingsStore.fullScreen
          : null,
      onTap: () {
        if (_videoStore.miniVedioMode) {
          _videoStore.setMiniVedioMode(false);
          return;
        }
        if (_chatStore.assetsStore.showEmoteMenu) {
          _chatStore.assetsStore.showEmoteMenu = false;
        } else {
          if (_chatStore.textFieldFocusNode.hasFocus) {
            _chatStore.textFieldFocusNode.unfocus();
          } else {
            _videoStore.handleVideoTap();
          }
        }
      },
      child: Observer(
        builder: (_) {
          final videoOverlay = VideoOverlay(
            videoStore: _videoStore,
            chatStore: _chatStore,
            settingsStore: settingsStore,
          );

          if (_videoStore.paused || _videoStore.streamInfo == null) {
            return videoOverlay;
          }

          return AnimatedOpacity(
            opacity: _videoStore.overlayVisible ? 1.0 : 0.0,
            curve: Curves.ease,
            duration: const Duration(milliseconds: 200),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(settingsStore.overlayOpacity),
              ),
              child: IgnorePointer(
                ignoring: !_videoStore.overlayVisible,
                child: videoOverlay,
              ),
            ),
          );
        },
      ),
    );

    final video = Observer(
      builder: (context) {
        if (!_videoStore.settingsStore.showOverlay) return player;

        return Stack(
          children: [
            player,
            overlay,
          ],
        );
      },
    );

    final chat = Observer(
      builder: (context) {
        final videoBarVisible = _videoStore.streamInfo != null &&
            _chatStore.settings.showVideo &&
            (_videoStore.paused || _videoStore.overlayVisible);

        return Stack(
          children: [
            Chat(
              key: _chatKey,
              chatStore: _chatStore,
            ),
            if (orientation == Orientation.portrait)
              AnimatedOpacity(
                opacity: videoBarVisible ? 1 : 0,
                curve: Curves.ease,
                duration: const Duration(milliseconds: 200),
                child: IgnorePointer(
                  ignoring: !videoBarVisible,
                  child: ColoredBox(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_videoStore.streamInfo != null)
                          VideoBar(
                            streamInfo: _videoStore.streamInfo!,
                            tappableCategory: false,
                          ),
                        const Divider(),
                      ],
                    ),
                  ),
                ),
              ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              child: _chatStore.notification != null
                  ? Align(
                      alignment: _chatStore.settings.chatNotificationsOnBottom
                          ? Alignment.bottomCenter
                          : Alignment.topCenter,
                      child: FrostyNotification(
                        message: _chatStore.notification!,
                        showPasteButton:
                            _chatStore.notification!.contains('copied'),
                        onButtonPressed: () async {
                          // Paste clipboard text into the text controller.
                          final data =
                              await Clipboard.getData(Clipboard.kTextPlain);

                          if (data != null) {
                            _chatStore.textController.text = data.text!;
                          }

                          _chatStore.updateNotification('');
                        },
                      ),
                    )
                  : null,
            ),
          ],
        );
      },
    );

    final videoChat = Observer(
      builder: (context) {
        return Stack(
          children: <Widget>[
            if (!_videoStore.miniVedioMode) Container(color: Colors.black54),
            AnimatedPositioned(
              right: _videoStore.miniVedioMode ? 10 : 0,
              top: _videoStore.miniVedioMode
                  ? MediaQuery.of(context).size.height - 180
                  : _videoStore.topPosition,
              width: _videoStore.miniVedioMode
                  ? 180
                  : MediaQuery.of(context).size.width,
              height: _videoStore.miniVedioMode
                  ? 100
                  : MediaQuery.of(context).size.height,
              duration: _videoStore.isDragging
                  ? const Duration(milliseconds: 30)
                  : const Duration(milliseconds: 300),
              child: _videoStore.miniVedioMode
                  ? Dismissible(
                      key: ValueKey('${widget.key}_mini'),
                      onDismissed: (direction) {
                        _homeStore.closeVideoChat();
                      },
                      child: Scaffold(
                        body: Observer(
                          builder: (context) {
                            SystemChrome.setEnabledSystemUIMode(
                              SystemUiMode.manual,
                              overlays: SystemUiOverlay.values,
                            );
                            return AspectRatio(
                              aspectRatio: 16 / 9,
                              child: video,
                            );
                          },
                        ),
                      ),
                    )
                  : PopScope(
                      canPop: _videoStore.miniVedioMode,
                      onPopInvoked: (didPop) {
                        if (didPop || _chatStore.assetsStore.showEmoteMenu) {
                          return;
                        }
                        _videoStore.setMiniVedioMode(true);
                      },
                      child: GestureDetector(
                        onVerticalDragStart: (_) {
                          _videoStore.updateIsDragging(true);
                        },
                        onVerticalDragUpdate: orientation ==
                                Orientation.portrait
                            ? (details) {
                                final newPosition =
                                    _videoStore.topPosition + details.delta.dy;
                                if (newPosition < 0) return;
                                final lowerBound =
                                    MediaQuery.of(context).size.height -
                                        MediaQuery.of(context).size.width /
                                            (16 / 9) -
                                        MediaQuery.of(context).padding.top;
                                if (newPosition > lowerBound) return;

                                _videoStore.updateTopPosition(newPosition);
                              }
                            : null,
                        onVerticalDragEnd: (details) {
                          _videoStore.updateIsDragging(false);
                          if (_videoStore.topPosition >
                              MediaQuery.of(context).size.height * 0.4) {
                            _videoStore.setMiniVedioMode(true);
                          } else {
                            _videoStore.updateTopPosition(0);
                          }
                        },
                        child: Scaffold(
                          backgroundColor: Colors.transparent,
                          body: Observer(
                            builder: (context) {
                              if (orientation == Orientation.landscape &&
                                  !settingsStore.landscapeForceVerticalChat) {
                                SystemChrome.setEnabledSystemUIMode(
                                  SystemUiMode.immersiveSticky,
                                );

                                final landscapeChat = AnimatedContainer(
                                  curve: Curves.ease,
                                  duration: const Duration(milliseconds: 200),
                                  width: _chatStore.expandChat
                                      ? MediaQuery.of(context).size.width / 2
                                      : MediaQuery.of(context).size.width *
                                          _chatStore.settings.chatWidth,
                                  color: _chatStore.settings.fullScreen
                                      ? Colors.black.withOpacity(
                                          _chatStore.settings
                                              .fullScreenChatOverlayOpacity,
                                        )
                                      : Theme.of(context)
                                          .scaffoldBackgroundColor,
                                  child: chat,
                                );

                                final overlayChat = Visibility(
                                  visible: settingsStore.fullScreenChatOverlay,
                                  maintainState: true,
                                  child: Theme(
                                    data: FrostyThemes().dark,
                                    child: DefaultTextStyle(
                                      style: DefaultTextStyle.of(context)
                                          .style
                                          .copyWith(color: Colors.white),
                                      child: landscapeChat,
                                    ),
                                  ),
                                );

                                return ColoredBox(
                                  color: settingsStore.showVideo
                                      ? Colors.black
                                      : Theme.of(context)
                                          .scaffoldBackgroundColor,
                                  child: SafeArea(
                                    bottom: false,
                                    left: (settingsStore.landscapeCutout ==
                                                LandscapeCutoutType.both ||
                                            settingsStore.landscapeCutout ==
                                                LandscapeCutoutType.left)
                                        ? false
                                        : true,
                                    right: (settingsStore.landscapeCutout ==
                                                LandscapeCutoutType.both ||
                                            settingsStore.landscapeCutout ==
                                                LandscapeCutoutType.right)
                                        ? false
                                        : true,
                                    child: settingsStore.showVideo
                                        ? settingsStore.fullScreen
                                            ? Stack(
                                                children: [
                                                  player,
                                                  if (settingsStore.showOverlay)
                                                    Row(
                                                      children: settingsStore
                                                              .landscapeChatLeftSide
                                                          ? [
                                                              overlayChat,
                                                              Expanded(
                                                                child: overlay,
                                                              ),
                                                            ]
                                                          : [
                                                              Expanded(
                                                                child: overlay,
                                                              ),
                                                              overlayChat,
                                                            ],
                                                    ),
                                                ],
                                              )
                                            : Row(
                                                children: settingsStore
                                                        .landscapeChatLeftSide
                                                    ? [
                                                        landscapeChat,
                                                        Expanded(child: video),
                                                      ]
                                                    : [
                                                        Expanded(child: video),
                                                        landscapeChat,
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
                              SystemChrome.setEnabledSystemUIMode(
                                SystemUiMode.manual,
                                overlays: SystemUiOverlay.values,
                              );
                              return SafeArea(
                                child: Container(
                                  color:
                                      Theme.of(context).scaffoldBackgroundColor,
                                  child: Column(
                                    children: [
                                      if (!settingsStore.showVideo)
                                        appBar
                                      else
                                        AspectRatio(
                                          aspectRatio: 16 / 9,
                                          child: video,
                                        ),
                                      Expanded(child: chat),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
            ),
          ],
        );
      },
    );
    // If on Android, use PiPSwitcher to enable PiP functionality.
    if (Platform.isAndroid) {
      return PipWidget(
        pipLayout: PipActionsLayout.media_only_pause,
        onPipAction: (_) => _videoStore.handlePausePlay(),
        pipChild: player,
        child: videoChat,
      );
    }

    return videoChat;
  }

  @override
  void dispose() {
    _chatStore.dispose();

    _videoStore.dispose();

    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
    );

    SystemChrome.setPreferredOrientations([]);

    super.dispose();
  }
}
