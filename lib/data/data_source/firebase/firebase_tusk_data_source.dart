import 'dart:async';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:twitter_login/twitter_login.dart';
import 'package:twittusk/data/data_source/tusk_data_source.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:twittusk/data/dto/like_dto.dart';
import 'package:twittusk/data/dto/tusk_add_dto.dart';
import 'package:twittusk/data/dto/tusk_dto.dart';
import 'package:twittusk/data/dto/user_dto.dart';
import '../../dto/user_session_dto.dart';


class FirebaseTuskDataSource implements TuskDataSource {
  final _tuskStreamController = StreamController<List<TuskDto>>();
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  final _dynamicLinks = FirebaseDynamicLinks.instance;

  @override
  Future<UserSessionDto> signIn(String email, String password) async {
    final userCredential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return UserSessionDto.fromUserCredential(userCredential);
  }

  @override
  Future<UserSessionDto> signInWithGoogle() async {
    final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
    final GoogleSignInAuthentication? googleAuth = await googleUser?.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth?.accessToken,
      idToken: googleAuth?.idToken,
    );
    final credentials = await _auth.signInWithCredential(credential);
    return UserSessionDto.fromUserCredential(credentials);
  }

  @override
  Future<UserSessionDto> signInWithTwitter() async {
    final twitterLogin = TwitterLogin(
      apiKey: dotenv.env['TWITTER_API_KEY'] ?? "",
      apiSecretKey: dotenv.env['TWITTER_API_KEY_SECRET'] ?? "",
      redirectURI: "twittusk://",
    );
    final authResult = await twitterLogin.login();
    final AuthCredential twitterAuthCredential = TwitterAuthProvider.credential(
      accessToken: authResult.authToken!,
      secret: authResult.authTokenSecret!,
    );
    final userCredential = await _auth.signInWithCredential(twitterAuthCredential);
    return UserSessionDto.fromUserCredential(userCredential);
  }

  @override
  Future<void> addUser(UserDto user) async {
    final doc = _firestore.collection("users").doc(user.uid).set(user.toJson());
  }

  @override
  Future<UserSessionDto> signUp(String username, String email, String password) async {
    final userCredential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final user = UserDto(
        uid: userCredential.user!.uid,
        username: username,
        arobase: userCredential.user!.email!.split('@')[0],
        email: email);
    await _firestore.collection("users").doc(user.uid).set(user.toJson());
    return UserSessionDto.fromUserCredential(userCredential);
  }

  @override
  Future<UserDto?> getUserById(String uid) async {
    final user = await _firestore.collection("users").doc(uid).get();
    if (!user.exists) {
      return null;
    }
    return UserDto.fromJson(user.data()!, user.id);
  }

  @override
  Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  @override
  Stream<List<TuskDto>> getTusks() {
    FirebaseFirestore.instance
        .collection('tusks')
        .orderBy("publishedAt", descending: true)
        .snapshots()
        .listen((snapshot) async {
      final List<TuskDto> tuskList = [];
      for (var doc in snapshot.docs) {
        final tusk = TuskDto.fromJson(doc.data(), doc.id);
        tusk.user = await _getUserFromDocumentRef(doc.data()["user"]);
        // Get comments
        final commentsSnapshot = await doc.reference.collection("comments").get();
        final comments = commentsSnapshot.docs.map((comment) async {
          final commentDto = TuskDto.fromJson(comment.data(), comment.id);
          commentDto.user = await _getUserFromDocumentRef(comment.data()["user"]);
          return commentDto;
        }).toList();
        tusk.comments.addAll(await Future.wait(comments));

        // Get likes
        final likesSnapshot = await doc.reference.collection("likes").get();
        final likes = likesSnapshot.docs.map((like) async {
          final likeDto = LikeDto.fromJson(like.data(), like.id);
          likeDto.user = await _getUserFromDocumentRef(like.data()["user"]);
          return likeDto;
        }).toList();
        tusk.likes.addAll(await Future.wait(likes));

        tuskList.add(tusk);
      }
      _tuskStreamController.add(tuskList);
    });

    return _tuskStreamController.stream;
  }

  Future<UserDto> _getUserFromDocumentRef(DocumentReference doc) async {
    final user = await doc.get();
    return UserDto.fromJson(user.data() as Map<String, dynamic>, user.id);
  }

  @override
  Future<UserDto?> getCurrentUser() async {
    final user = _auth.currentUser;
    if (user == null) {
      return null;
    }
    final userDoc = await _firestore.collection("users").doc(user.uid).get();
    if (userDoc.exists == false) {
      return null;
    }
    return UserDto.fromJson(userDoc.data() as Map<String, dynamic>, userDoc.id);
  }

  @override
  Future<List<LikeDto>> getLikesByTusk(String tuskId) async {
    final tusk = FirebaseFirestore.instance.collection('tusks').doc(tuskId);
    final likes = await tusk.collection("likes").get();
    final List<LikeDto> likeList = [];
    for (var doc in likes.docs) {
      final like = LikeDto.fromJson(doc.data(), doc.id);
      like.user = await _getUserFromDocumentRef(doc.data()["user"]);
      likeList.add(like);
    }
    return likeList;
  }

  @override
  Future<void> addLikeTusk(LikeDto like, String tuskId) async {
    final tusk = FirebaseFirestore.instance.collection('tusks').doc(tuskId);
    final json = like.toJson();
    json["user"] = _firestore.collection("users").doc(like.user.uid);
    tusk.collection("likes").add(json);
  }

  @override
  Future<void> removeLikeTusk(String likeId, String tuskId) {
    final tusk = FirebaseFirestore.instance.collection('tusks').doc(tuskId);
    return tusk.collection("likes").doc(likeId).delete();
  }

  @override
  Future<Uri> generateTuskDynamicLink(String tuskId) async {
    final DynamicLinkParameters parameters = DynamicLinkParameters(
      uriPrefix: 'https://twittusk.page.link',
      link: Uri.parse('https://twittusk.com/tusk/$tuskId'),
      socialMetaTagParameters: SocialMetaTagParameters(
        title: 'Twittusk',
        description: 'Twittusk',
        imageUrl: Uri.parse(
            'https://cap.img.pmdstatic.net/fit/https.3A.2F.2Fi.2Epmdstatic.2Enet.2Fcap.2F2023.2F05.2F19.2F3716e4a3-1381-44ab-9d21-b350ebba33ea.2Ejpeg/1200x630/background-color/ffffff/quality/70/elon-musk-decouvrez-les-secrets-intrigants-de-lhomme-le-plus-puissant-de-la-planete-1468904.jpg'),
      ),
      androidParameters: AndroidParameters(
        packageName: 'com.yummy.twittusk',
        fallbackUrl: Uri.parse('https://twittusk.com'),
      ),
      iosParameters: IOSParameters(
        bundleId: 'com.yummy.twittusk ',
        fallbackUrl: Uri.parse('https://twittusk.com'),
      ),
    );

    final ShortDynamicLink shortLink = await _dynamicLinks.buildShortLink(parameters);
    return shortLink.shortUrl;
  }

  @override
  Stream<List<TuskDto>> getTusksByUser(UserDto user) {
    _firestore
        .collection('tusks')
        .where("user", isEqualTo: _firestore.collection("users").doc(user.uid))
        .orderBy("publishedAt", descending: true)
        .snapshots()
        .listen((snapshot) {
          print("Get tusk by user");
      List<TuskDto> tusks = snapshot.docs.map((doc) {
        final tusk = TuskDto.fromJson(doc.data(), user.uid);
        tusk.user = user;
        return tusk;
      }).toList();
      _tuskStreamController.add(tusks);
    });
    return _tuskStreamController.stream;
  }

  @override
  Future<void> addCommentToTusk(String tuskId, String comment, UserDto user) {
    final tuskRef = _firestore.collection('tusks').doc(tuskId);
    final json = TuskAddDto(
      description: comment,
      publishedAt: DateTime.now(),
      user: _firestore.collection("users").doc(user.uid),
    ).toJson();
    return tuskRef.collection("comments").add(json);
  }

  @override
  Stream<List<TuskDto>> getCommentsForTusk(String tuskId) {
    final tuskRef = _firestore.collection('tusks').doc(tuskId);
    tuskRef.collection("comments").snapshots().listen((snapshot) async {
      final List<TuskDto> tuskList = [];
      for (var doc in snapshot.docs) {
        final tusk = TuskDto.fromJson(doc.data(), doc.id);
        tusk.user = await _getUserFromDocumentRef(doc.data()["user"]);
        tuskList.add(tusk);
      }
      _tuskStreamController.add(tuskList);
    });

    return _tuskStreamController.stream;
  }

  @override
  Future<void> logout() {
    return _auth.signOut();
  }

  @override
  Future<String> uploadImage(String path) async {
    final user = await getCurrentUser();
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final filename = "upload_$timestamp${user!.uid}.jpg";
    final storageRef = FirebaseStorage.instance.ref().child("tusks/$filename");
    final uploadTask = storageRef.putFile(File(path));
    final snapshot = await uploadTask;
    return snapshot.ref.getDownloadURL();
  }

  @override
  Future<void> addTusk(String description, DateTime publishAt, String? image, UserDto user) async {
      final user = await getCurrentUser();
      final json = TuskAddDto(
        description: description,
        publishedAt: publishAt,
        image: image,
        user: _firestore.collection("users").doc(user!.uid),
      ).toJson();
      await _firestore.collection('tusks').add(json);
  }

  @override
  Future<TuskDto> getById(String tuskId) {
    final tuskRef = _firestore.collection('tusks').doc(tuskId);
    return tuskRef.get().then((doc) async {
      final tusk = TuskDto.fromJson(doc.data()!, doc.id);
      tusk.user = await _getUserFromDocumentRef(doc.data()!["user"]);
      return tusk;
    });
  }

  @override
  Future<void> updateUser(UserDto user) async {
    await _firestore.collection('users').doc(user.uid).update(user.toJson());
  }
}
