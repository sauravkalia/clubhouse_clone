import 'package:flutter/material.dart';
import 'package:stream_video_flutter/stream_video_flutter.dart';

import '../models/user_model.dart';

class AudioRoomScreen extends StatefulWidget {
  const AudioRoomScreen({
    super.key,
    required this.activeCall,
    required this.room,
    required this.user,
  });

  static Route<dynamic> routeTo(Call call, CallMetadata room, UserModel user) {
    return MaterialPageRoute(
      builder: (context) {
        return AudioRoomScreen(
          activeCall: call,
          room: room,
          user: user,
        );
      },
    );
  }

  final CallMetadata room;
  final Call activeCall;
  final UserModel user;

  @override
  State<AudioRoomScreen> createState() => _AudioRoomScreenState();
}

class _AudioRoomScreenState extends State<AudioRoomScreen> {
  UserModel get currentUser => widget.user;

  Call get call => widget.activeCall;

  StreamVideo get video => StreamVideo.instance;

  late CallState callState;
  late ValueNotifier<bool> enabled;
  CallMetadata? roomMetadata;

  List<CallParticipantState> listeners = [];

  @override
  void initState() {
    super.initState();

    roomMetadata = widget.room;
    callState = call.state.value;
    enabled = ValueNotifier(false);
    listeners = _sortParticipants(callState.callParticipants);

    call.onPermissionRequest = (permissionRequest) {
      call.grantPermissions(
        userId: permissionRequest.user.id,
        permissions: permissionRequest.permissions.toList(),
      );
    };
  }

  List<CallParticipantState> _sortParticipants(
    List<CallParticipantState> participants,
  ) {
    if (participants.length > 1) {
      participants.sort(
        (a, b) {
          if (b.isAudioEnabled) {
            return 1;
          } else {
            return -1;
          }
        },
      );
    }

    return participants;
  }

  void _onMicrophonePressed() {
    if (enabled.value) {
      call.setMicrophoneEnabled(enabled: false);
      enabled.value = false;
    } else {
      if (!call.hasPermission(CallPermission.sendAudio)) {
        call.requestPermissions([CallPermission.sendAudio]);
      }
      call.setMicrophoneEnabled(enabled: true);
      enabled.value = true;
    }
  }

  Widget _buildBackstageBanner() {
    return StreamBuilder<CallState>(
      initialData: callState,
      stream: call.state.asStream(),
      builder: (context, snapshot) {
        if (snapshot.hasData && !snapshot.hasError) {
          callState = snapshot.data!;

          if (!callState.isBackstage) {
            return const SliverToBoxAdapter(
              child: SizedBox.shrink(),
            );
          }

          return SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Container(
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  color: Colors.amber,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'ROOM IN BACKSTAGE MODE',
                      style: TextStyle(color: Colors.white),
                    ),
                    TextButton(
                        onPressed: () {
                          call.goLive();
                        },
                        child: const Text(
                          'GO LIVE',
                          style: TextStyle(color: Colors.red),
                        ))
                  ],
                ),
              ),
            ),
          );
        }

        return const SliverToBoxAdapter(
          child: SizedBox.shrink(),
        );
      },
    );
  }

  Widget _buildParticipants() {
    return StreamBuilder<CallState>(
      initialData: callState,
      stream: call.state.asStream(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const SliverToBoxAdapter(
            child: Center(
              child: Text('We are not able to find rooms at this time'),
            ),
          );
        }
        if (snapshot.hasData && !snapshot.hasError) {
          callState = snapshot.data!;
          listeners = _sortParticipants(callState.callParticipants);
          return SliverGrid(
            delegate: SliverChildBuilderDelegate(
              (BuildContext context, int index) {
                return Align(
                  widthFactor: 0.8,
                  child: StreamCallParticipant(
                    call: call,
                    backgroundColor: Colors.transparent,
                    participant: listeners[index],
                    showParticipantLabel: false,
                    showConnectionQualityIndicator: false,
                    userAvatarTheme: const StreamUserAvatarThemeData(
                      constraints: BoxConstraints.expand(
                        height: 100,
                        width: 100,
                      ),
                    ),
                  ),
                );
              },
              childCount: listeners.length,
            ),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
            ),
          );
        }
        return const SliverToBoxAdapter(
          child: Center(
            child: CircularProgressIndicator(),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Text('Room ${roomMetadata?.details.custom['name']}'),
        ),
        floatingActionButton: _ActionMenu(
          call: call,
          isMicEnabled: enabled,
          onMicrophonePressed: _onMicrophonePressed,
        ),
        body: CustomScrollView(
          slivers: [
            _buildBackstageBanner(),
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(8.0),
                child: Text(
                  'Participants 🎙️',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24.0),
                ),
              ),
            ),
            _buildParticipants(),
          ],
        ),
      ),
    );
  }
}

class _ActionMenu extends StatelessWidget {
  const _ActionMenu({
    super.key,
    required this.call,
    required this.isMicEnabled,
    required this.onMicrophonePressed,
  });

  final Call call;
  final ValueNotifier<bool> isMicEnabled;
  final VoidCallback onMicrophonePressed;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ValueListenableBuilder(
          valueListenable: isMicEnabled,
          builder: (context, isEnabled, _) {
            if (isEnabled) {
              return ElevatedButton(
                onPressed: onMicrophonePressed,
                child: const Icon(Icons.mic),
              );
            } else {
              return ElevatedButton(
                onPressed: onMicrophonePressed,
                child: const Icon(Icons.mic_off),
              );
            }
          },
        ),
        const SizedBox(width: 12.0),
        ElevatedButton(
          onPressed: () async {
            await call.leave();
            Navigator.of(context).pop();
          },
          child: const Icon(Icons.exit_to_app),
        ),
      ],
    );
  }
}
