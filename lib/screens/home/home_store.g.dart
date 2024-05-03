// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'home_store.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic, no_leading_underscores_for_local_identifiers

mixin _$HomeStore on HomeStoreBase, Store {
  late final _$_selectedIndexAtom =
      Atom(name: 'HomeStoreBase._selectedIndex', context: context);

  int get selectedIndex {
    _$_selectedIndexAtom.reportRead();
    return super._selectedIndex;
  }

  @override
  int get _selectedIndex => selectedIndex;

  @override
  set _selectedIndex(int value) {
    _$_selectedIndexAtom.reportWrite(value, super._selectedIndex, () {
      super._selectedIndex = value;
    });
  }

  late final _$_videoChatAtom =
      Atom(name: 'HomeStoreBase._videoChat', context: context);

  VideoChat? get videoChat {
    _$_videoChatAtom.reportRead();
    return super._videoChat;
  }

  @override
  VideoChat? get _videoChat => videoChat;

  @override
  set _videoChat(VideoChat? value) {
    _$_videoChatAtom.reportWrite(value, super._videoChat, () {
      super._videoChat = value;
    });
  }

  late final _$HomeStoreBaseActionController =
      ActionController(name: 'HomeStoreBase', context: context);

  @override
  void handleTap(int index) {
    final _$actionInfo = _$HomeStoreBaseActionController.startAction(
        name: 'HomeStoreBase.handleTap');
    try {
      return super.handleTap(index);
    } finally {
      _$HomeStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void openVideoChat(
      {required BuildContext context,
      required String userId,
      required String userName,
      required String userLogin}) {
    final _$actionInfo = _$HomeStoreBaseActionController.startAction(
        name: 'HomeStoreBase.openVideoChat');
    try {
      return super.openVideoChat(
          context: context,
          userId: userId,
          userName: userName,
          userLogin: userLogin);
    } finally {
      _$HomeStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void closeVideoChat() {
    final _$actionInfo = _$HomeStoreBaseActionController.startAction(
        name: 'HomeStoreBase.closeVideoChat');
    try {
      return super.closeVideoChat();
    } finally {
      _$HomeStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  String toString() {
    return '''

    ''';
  }
}
