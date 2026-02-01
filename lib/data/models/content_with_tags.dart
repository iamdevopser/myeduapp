import 'content_item.dart';
import 'tag_model.dart';

class ContentWithTags {
  ContentWithTags({
    required this.content,
    required this.tags,
  });

  final ContentItem content;
  final List<TagModel> tags;
}



