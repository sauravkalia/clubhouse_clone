import 'dart:developer';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:stream_video_flutter/stream_video_flutter.dart';
import 'package:uuid/uuid.dart';

import '../models/user_model.dart';
import '../widgets/create_room.dart';
import 'audio_room_screen.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.user});

  final UserModel user;

  static Route<dynamic> routeTo(UserModel user) {
    return MaterialPageRoute(
      builder: (context) {
        return HomeScreen(user: user);
      },
    );
  }

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  UserModel get user => widget.user;

  StreamVideo get video => StreamVideo.instance;

  Future<void> showCreationDialog() async {
    showAdaptiveDialog(
      context: context,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: CreateRoomDialog(
            onCreatePressed: _onDialogPressed,
          ),
        );
      },
    );
  }

  Future<void> showLogOutDialog() async {
    showAdaptiveDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog.adaptive(
        title: const Text('Logout'),
        content: const Text('Do you want to log out?'),
        actions: <Widget>[
          adaptiveAction(
            context: context,
            onPressed: () => Navigator.pop(context, 'Cancel'),
            child: const Text('Cancel'),
          ),
          adaptiveAction(
            context: context,
            onPressed: () async {
              await StreamVideo.instance.disconnect();
              await StreamVideo.reset();

              if (mounted) {
                Navigator.pop(context, 'Log Out');
                Navigator.of(context).pushReplacement(
                  LoginScreen.routeTo(),
                );
              }
            },
            child: const Text(
              'Log Out',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _onDialogPressed((String, String) roomInfo) async {
    final callWithMetadata = await createRoom(
      roomInfo.$1,
      roomInfo.$2,
    );

    await callWithMetadata.$1.join();
    log('Joining Call: ${callWithMetadata.$1.callCid}');

    if (mounted) {
      Navigator.of(context).push(
        AudioRoomScreen.routeTo(callWithMetadata.$1, callWithMetadata.$2, user),
      );
    }
  }

  Future<(Call, CallMetadata)> createRoom(
    final String title,
    final String description,
  ) async {
    final room = video.makeCall(
      type: "audio_room",
      id: const Uuid().v4(),
    );

    await room.getOrCreate();
    final metadataResult = await room.update(
      custom: {
        'name': title,
        'description': description,
        "flutterAudioRoomCall": true,
      },
    );

    return metadataResult.fold(
        success: (success) => (room, success.data),
        failure: (failure) => throw Exception(failure.error));
  }

  Future<void> joinRoom(QueriedCall room) async {
    final cid = room.call.cid;
    final call = video.makeCall(type: cid.type, id: cid.id);

    await call.join();

    log('Joining Call: $cid');

    if (mounted) {
      Navigator.of(context).push(
        AudioRoomScreen.routeTo(call, room.call, user),
      );
    }
  }

  Future<List<QueriedCall>> queryCalls() async {
    final result = await video.queryCalls(
      filterConditions: {
        "backstage": false,
        "custom.flutterAudioRoomCall": true,
      },
    );

    if (result.isSuccess) {
      return result.getDataOrNull()?.calls ?? [];
    } else {
      final error = result.getErrorOrNull();
      log('[queryCalls] failed with error $error');
      throw Exception('No rooms found');
    }
  }

  Widget adaptiveAction({
    required BuildContext context,
    required VoidCallback onPressed,
    required Widget child,
  }) {
    final ThemeData theme = Theme.of(context);
    switch (theme.platform) {
      case TargetPlatform.android:
      case TargetPlatform.fuchsia:
      case TargetPlatform.linux:
      case TargetPlatform.windows:
        return TextButton(onPressed: onPressed, child: child);
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        return CupertinoDialogAction(onPressed: onPressed, child: child);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Audio Rooms'),
        actions: [
          InkWell(
            onTap: showLogOutDialog,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: CircleAvatar(
                backgroundImage: NetworkImage(user.imageURL),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: showCreationDialog,
        child: const Center(
          child: Icon(Icons.add),
        ),
      ),
      body: SafeArea(
        child: FutureBuilder<List<QueriedCall>>(
          future: queryCalls(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const Center(
                child: Text('Could not fetch calls'),
              );
            }

            if (snapshot.hasData) {
              final data = snapshot.data ?? [];

              return ListView(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                children: [
                  for (final room in data)
                    InkWell(
                      onTap: () => joinRoom(room),
                      child: Card(
                        child: ListTile(
                          title: Text(
                            room.call.details.custom['name'] as String,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          subtitle: Text(
                            room.call.details.custom['description'] as String,
                          ),
                          trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: room.call.session.participants.values
                                  .map((p) => kUsers
                                      .where((user) => user.uid == p.userId)
                                      .firstOrNull
                                      ?.imageURL)
                                  .where((url) => url != null)
                                  .map((url) => CircleAvatar(
                                        backgroundImage: NetworkImage(url!),
                                      ))
                                  .toList()),
                        ),
                      ),
                    )
                ],
              );
            }
            return const Center(
              child: CircularProgressIndicator(),
            );
          },
        ),
      ),
    );
  }
}
