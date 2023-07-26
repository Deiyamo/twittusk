import 'package:twittusk/domain/models/tusk.dart';
import 'package:twittusk/domain/models/user_session.dart';
import '../models/like.dart';
import '../models/user.dart';

abstract class TuskRepository {
  // USER
  Future<UserSession> signIn(String email, String password);

  Future<UserSession> signInWithGoogle();

  Future<UserSession> signInWithTwitter();

  Future<UserSession> signUp(String username, String email, String password);

  Future<User?> getUserById(String uid);

  Future<void> addUser(User user);

  Future<void> resetPassword(String email);

  // TUSKS
  Stream<List<Tusk>> getTusks();

  Stream<List<Tusk>> getTusksByUser(User user);

  Future<List<Like>> getMyLikesByTusk(String tuskId);

  Future<void> addLike(String tuskId, bool isLiked);

  Future<void> removeLike(String likeId, String tuskId);

  Future<Uri> generateTuskDynamicLink(String tuskId);
}