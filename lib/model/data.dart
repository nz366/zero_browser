import 'dart:typed_data';

import 'package:zero_browser/model/forms.dart';

export 'package:zero_browser/model/forms.dart';

class PostData extends CommentData {
  final String title;
  PostData({
    required super.id,
    required super.author,
    required super.content,
    required super.createdAt,
    required super.score,
    required super.replies,
    required this.title,
  });
  factory PostData.fromJson(Map<String, dynamic> json) {
    var list = json['replies'] as List;
    List<CommentData> commentList = list
        .map((i) => CommentData.fromJson(i))
        .toList();
    return PostData(
      title: json['title'],
      content: json['content'],
      author: json['author'],
      createdAt: json['created_at'],
      score: json['score'],
      id: json['id'],
      replies: commentList,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      "title": title,
      "content": content,
      "author": author,
      "created_at": createdAt,
      "score": score,
      "replies": replies.map((i) => i.toJson()).toList(growable: false),
      "id": id,
    };
  }
}

class Article {
  final String title;
  final String content;
  final String subgroup;
  final String author;
  final String time;
  final int upvotes;
  final String url;

  String? thumbnail;

  Article({
    required this.title,
    required this.content,
    required this.subgroup,
    required this.author,
    required this.time,
    required this.upvotes,
    required this.url,
    required this.thumbnail,
  });

  factory Article.fromJson(Map<String, dynamic> json) {
    return Article(
      title: json["title"],
      content: json["content"],
      subgroup: json["subgroup"],
      author: json["author"],
      time: json["time"],
      upvotes: json["upvotes"],
      url: json["url"],
      thumbnail: json["thumbnail"],
    );
  }

  toJson() {
    return {
      "title": title,
      "content": content,
      "subgroup": subgroup,
      "author": author,
      "time": time,
      "upvotes": upvotes,
      "url": url,
      "thumbnail": thumbnail,
    };
  }
}

class CommentData {
  final String id;
  final String author;
  final String content;
  final DateTime? createdAt;
  final int? score;
  List<CommentData> replies;

  bool collapsed;
  bool lineActive;
  CommentData({
    required this.id,
    required this.author,
    required this.content,
    required this.createdAt,
    required this.replies,
    this.score,
    this.collapsed = true,
    this.lineActive = false,
  });

  factory CommentData.fromJson(Map<String, dynamic> json) {
    var list = json['replies'] != null ? json['replies'] as List : [];
    List<CommentData> replyList = list
        .map((i) => CommentData.fromJson(i))
        .toList();
    return CommentData(
      id: json['id'],
      author: json['author'],
      content: json['content'],
      createdAt: DateTime.tryParse(json['created_at'] ?? ""),
      score: json['score'],
      replies: replyList,
    );
  }
  Map<String, dynamic> toJson() {
    return {
      "content": "\"$content\"",
      "author": author,
      "created_at": createdAt?.toIso8601String(),
      "score": score,
      "replies": replies.map((i) => i.toJson()).toList(growable: false),
      "id": id,
    };
  }

  void collapse() {
    collapsed = !collapsed;
  }
}

sealed class Section {
  const Section();

  factory Section.fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String;
    final data = json['data'];

    return switch (type) {
      'markdown' => MarkdownSection(data as String),
      'comment_thread' => CommentThreadSection(
        (data as List).map((e) => CommentData.fromJson(e)).toList(),
      ),
      'article_list' => ArticleListSection.fromJson(
        data as Map<String, dynamic>,
      ),
      'table' => TableSection.fromJson(data as Map<String, dynamic>),
      'image_grid' => ImageGridSection(data),
      'settings_sliver' => SettingsSliverSection(data as String),
      'form' => FormSection.fromJson(data as Map<String, dynamic>),
      'media' => MediaSection.fromJson(data as Map<String, dynamic>),
      _ => throw Exception('Unknown section type: $type'),
    };
  }

  Map<String, dynamic> toJson();
}

class MarkdownSection extends Section {
  final String data;
  const MarkdownSection(this.data);

  @override
  Map<String, dynamic> toJson() => {'type': 'markdown', 'data': "\"$data\""};
}

class CommentThreadSection extends Section {
  final List<CommentData> data;
  const CommentThreadSection(this.data);

  @override
  Map<String, dynamic> toJson() => {
    'type': 'comment_thread',
    'data': data.map((e) => e.toJson()).toList(growable: false),
  };
}

class ImageGridSection extends Section {
  final dynamic data;
  const ImageGridSection(this.data);

  @override
  Map<String, dynamic> toJson() => {'type': 'image_grid', 'data': data};
}

class SettingsSliverSection extends Section {
  final String data;
  const SettingsSliverSection(this.data);

  @override
  Map<String, dynamic> toJson() => {'type': 'settings_sliver', 'data': data};
}

class ArticleListSection extends Section {
  final String title;

  final LayoutConfig layout;

  final List<Article> articles;

  ArticleListSection({
    required this.title,
    required this.layout,
    required this.articles,
  });

  factory ArticleListSection.fromJson(Map<String, dynamic> json) {
    return ArticleListSection(
      title: json["title"],
      layout: LayoutConfig.values.firstWhere((e) => e.name == json["layout"]),
      articles: (json["articles"] as List<dynamic>)
          .map((e) => Article.fromJson(e))
          .toList(),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      "type": "article_list",
      "data": {
        "title": title,
        "layout": layout.name,
        "articles": articles.map((e) => e.toJson()).toList(),
      },
    };
  }
}

enum LayoutConfig { table, list, grid, masonry }

class PageData {
  String url;
  String title;
  bool loading;
  List<Section> content;

  PageData({
    required this.url,
    required this.title,
    this.loading = false,
    required this.content,
  });

  factory PageData.fromJson(Map<String, dynamic> json) {
    return PageData(
      url: json['url'] ?? '',
      title: json['title'] ?? '',
      loading: json['loading'] ?? false,
      content: (json['content'] as List? ?? [])
          .map((e) => Section.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'url': url,
      'title': title,
      'loading': loading,
      'content': content.map((e) => e.toJson()).toList(),
    };
  }

  @override
  String toString() {
    return content
        .map((e) {
          return switch (e) {
            MarkdownSection s => s.data,
            CommentThreadSection s => s.data.map((e) => e.toJson()).join("\n"),
            ArticleListSection s => s.title,
            TableSection s => s.items.toString(),
            ImageGridSection s => s.data.toString(),
            SettingsSliverSection s => s.data,
            FormSection s => s.toJson().toString(),
            MediaSection s => s.items.toString(),
          };
        })
        .join("\n");
  }
}

class TableSection extends Section {
  final List<dynamic> items;

  TableSection({required this.items});

  @override
  Map<String, dynamic> toJson() {
    return {
      "type": "table",
      "data": {"items": items},
    };
  }

  factory TableSection.fromJson(Map<String, dynamic> json) {
    return TableSection(items: json['items'] as List<dynamic>);
  }
}

class FormSection extends Section {
  final String? title;
  final Map<String, Field> fields;

  FormSection({this.title, this.fields = const {}});

  bool checkConstraints() {
    return fields.values.every((field) => field.checkConstraints());
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': 'form',
      'data': {
        'title': title,
        'fields': {
          for (final MapEntry(key: key, value: value) in fields.entries)
            key: value.toJson(),
        },
      },
    };
  }

  factory FormSection.fromJson(Map<String, dynamic> json) {
    return FormSection(
      title: json['title'] as String?,
      fields: (json['fields'] as Map<String, dynamic>).map(
        (key, value) =>
            MapEntry(key, Field.fromJson(value as Map<String, dynamic>)),
      ),
    );
  }
}

class MediaSection extends Section {
  final List<Uint8List> items;

  MediaSection({required this.items});

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': 'media',
      "data": {"items": items.map((e) => e.toList()).toList()},
    };
  }

  factory MediaSection.fromJson(Map<String, dynamic> json) {
    return MediaSection(
      items: (json['items'] as List)
          .map((e) => Uint8List.fromList((e as List).cast<int>()))
          .toList(),
    );
  }
}
