import 'package:stream_video_flutter/stream_video_flutter.dart';

class UserModel {
  UserModel({
    required this.name,
    required this.uid,
    required this.imageURL,
  });

  final String name;
  final String uid;
  final String imageURL;
}

final kUsers = [
  UserModel(
      name: 'Nash',
      uid: 'nash',
      imageURL:
          'https://ca.slack-edge.com/T02RM6X6B-U01DZ046DS8-0a302e68449c-512'),
  UserModel(
      name: 'Deven',
      uid: 'deven',
      imageURL:
          'https://ca.slack-edge.com/T02RM6X6B-U01AM7ELPTL-6e7e933ca1de-512'),
  UserModel(
      name: 'Thierry',
      uid: 'thierry',
      imageURL:
          'https://ca.slack-edge.com/T02RM6X6B-U02RM6X6D-g28a1278a98e-512'),
];

extension ToUserInfo on UserModel {
  UserInfo toUserInfo() => UserInfo(
        id: uid,
        role: 'user',
        name: name,
        image: imageURL,
      );
}
