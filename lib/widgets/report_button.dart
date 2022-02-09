import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ReportButton extends StatelessWidget {
  final String userLogin;
  final String? name;

  const ReportButton({
    Key? key,
    required this.userLogin,
    this.name,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: () => launch('https://www.twitch.tv/$userLogin/report'),
      child: Text(name == null ? 'Report' : 'Report $name'),
      style: OutlinedButton.styleFrom(primary: Colors.red),
    );
  }
}
