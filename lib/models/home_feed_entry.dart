import 'feed_post.dart';
import 'project_item.dart';

/// Entrada del feed tipo Instagram: publicación de favor o proyecto en curso.
class HomeFeedEntry {
  const HomeFeedEntry.post(this.post) : project = null;
  const HomeFeedEntry.project(this.project) : post = null;

  final FeedPost? post;
  final ProjectItem? project;

  bool get isProject => project != null;
}
