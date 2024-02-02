import 'package:flutter/material.dart';
import 'package:stream_video_flutter/stream_video_flutter.dart';

import '../core/token_service.dart';
import '../models/user_model.dart';
import 'home_screen.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  static Route<dynamic> routeTo() {
    return MaterialPageRoute(
      builder: (context) {
        return const LoginScreen();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Select a User')),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final user in kUsers)
              ListTile(
                title: Text(user.name),
                leading: CircleAvatar(
                  backgroundImage: NetworkImage(user.imageURL),
                ),
                onTap: () async {
                  final tokenResponse = await const TokenService().loadToken(
                    environment: Environment.demo,
                    userId: user.uid,
                  );
                  StreamVideo(
                    tokenResponse.apiKey,
                    user: User(info: user.toUserInfo()),
                    userToken: tokenResponse.token,
                  );

                  Navigator.of(context).pushReplacement(
                    HomeScreen.routeTo(user),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
