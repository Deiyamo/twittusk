part of 'feed_bloc.dart';

@immutable
abstract class FeedEvent {}

class FeedFetchEvent extends FeedEvent {}

class UserFeedFetchEvent extends FeedEvent {
  UserFeedFetchEvent(this.user);

  final User user;
}

class FeedLikeEvent extends FeedEvent {
  final String tuskId;
  final bool isLiked;

  FeedLikeEvent({
    required this.tuskId,
    required this.isLiked,
  });
}

class FeedShareEvent extends FeedEvent {
  final String tuskId;

  FeedShareEvent({
    required this.tuskId,
  });
}

class FeedCommentEvent extends FeedEvent {
  FeedCommentEvent({
    required this.tusk,
  });

  final Tusk tusk;
}
