import 'package:flutter/material.dart';
import 'package:frosty/api/twitch_api.dart';
import 'package:frosty/screens/video_chat.dart';
import 'package:frosty/stores/auth_store.dart';
import 'package:provider/provider.dart';

class Search extends StatefulWidget {
  const Search({Key? key}) : super(key: key);

  @override
  _SearchState createState() => _SearchState();
}

class _SearchState extends State<Search> {
  final _textController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _textController,
      autocorrect: false,
      decoration: const InputDecoration(
        isDense: true,
        contentPadding: EdgeInsets.all(8.0),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(5.0)),
        ),
        hintText: 'Search',
      ),
      onSubmitted: (string) async {
        if (await Twitch.getUser(userLogin: string, headers: context.read<AuthStore>().headersTwitch) != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) {
                return VideoChat(
                  userLogin: string,
                );
              },
            ),
          );
        } else {
          const snackBar = SnackBar(content: Text('User does not exist :('));
          ScaffoldMessenger.of(context).showSnackBar(snackBar);
        }
        _textController.clear();
      },
    );
  }
}