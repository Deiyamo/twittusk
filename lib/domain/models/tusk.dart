
import 'package:intl/intl.dart';
import 'package:twittusk/domain/models/profile.dart';

class Tusk {

  final String id;
  final String title;
  final String description;
  final String? imageUri;
  final Profile profile;
  final DateTime publishedAt;
  final int nbLikes;
  final int nbDislikes;
  final int nbComments;

  Tusk({
    required this.id,
    required this.title,
    required this.description,
    this.imageUri,
    required this.profile,
    required this.publishedAt,
    required this.nbLikes,
    required this.nbDislikes,
    required this.nbComments,
  });

  String getNbCommentStr() {
    if (nbComments < 1000) {
      return nbComments.toString();
    } else if (nbComments < 1000000) {
      return "${(nbComments / 1000).toStringAsFixed(1)}k";
    } else {
      return "${(nbComments / 1000000).toStringAsFixed(1)}M";
    }
  }

  String getNbLikesStr() {
    if (nbLikes < 1000) {
      return nbLikes.toString();
    } else if (nbLikes < 1000000) {
      return "${(nbLikes / 1000).toStringAsFixed(1)}k";
    } else {
      return "${(nbLikes / 1000000).toStringAsFixed(1)}M";
    }
  }

  String getNbDislikesStr() {
    if (nbDislikes < 1000) {
      return nbDislikes.toString();
    } else if (nbDislikes < 1000000) {
      return "${(nbDislikes / 1000).toStringAsFixed(1)}k";
    } else {
      return "${(nbDislikes / 1000000).toStringAsFixed(1)}M";
    }
  }

  String getPublishAtStr() {
    final diff = DateTime.now().difference(publishedAt);
    if(diff.inSeconds < 60) {
      return "${diff.inSeconds} seconds ago";
    } else if (diff.inMinutes < 60) {
      return "${diff.inMinutes} minutes ago";
    } else if (diff.inHours < 24) {
      return "${diff.inHours} day ago";
    } else if (diff.inDays < 4) {
      return "${diff.inDays} day ago";
    } else {
      return "Publish on ${DateFormat('MM/dd/YYYY').format(publishedAt)}";
    }
  }
}