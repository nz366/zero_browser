import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:zero_browser/model/data.dart';

void main() {
  group('Section Serialization', () {
    test('MarkdownSection', () {
      const section = MarkdownSection('## Hello World');
      final json = section.toJson();
      final decoded = Section.fromJson(json) as MarkdownSection;
      expect(decoded.data, section.data);
    });

    test('CommentThreadSection', () {
      final comments = [
        CommentData(
          id: '1',
          author: 'user1',
          content: 'Hello',
          createdAt: DateTime(2024),
          replies: [],
          score: 10,
        ),
      ];
      final section = CommentThreadSection(comments);
      final json = section.toJson();
      final decoded = Section.fromJson(json) as CommentThreadSection;
      expect(decoded.data.length, 1);
      expect(decoded.data[0].author, 'user1');
      expect(decoded.data[0].content, 'Hello');
      expect(decoded.data[0].score, 10);
    });

    test('ArticleListSection', () {
      final articles = [
        Article(
          title: 'Title',
          content: 'Content',
          subgroup: 'Sub',
          author: 'Author',
          time: 'Time',
          upvotes: 100,
          url: 'https://example.com',
          thumbnail: null,
        ),
      ];
      final section = ArticleListSection(
        title: 'Articles',
        layout: LayoutConfig.list,
        articles: articles,
      );
      final json = section.toJson();
      final decoded = Section.fromJson(json) as ArticleListSection;
      expect(decoded.title, 'Articles');
      expect(decoded.layout, LayoutConfig.list);
      expect(decoded.articles.length, 1);
      expect(decoded.articles[0].title, 'Title');
    });

    test('TableSection', () {
      final section = TableSection(items: ['Item 1', 123, {'key': 'value'}]);
      final json = section.toJson();
      final decoded = Section.fromJson(json) as TableSection;
      expect(decoded.items, section.items);
    });

    test('ImageGridSection', () {
      final section = ImageGridSection(['url1', 'url2']);
      final json = section.toJson();
      final decoded = Section.fromJson(json) as ImageGridSection;
      expect(decoded.data, section.data);
    });

    test('SettingsSliverSection', () {
      final section = SettingsSliverSection('Settings Data');
      final json = section.toJson();
      final decoded = Section.fromJson(json) as SettingsSliverSection;
      expect(decoded.data, section.data);
    });

    test('FormSection', () {
      final Map<String, Field> fields = {
        'username': TextField(name: 'username', label: 'User', hint: 'Enter name'),
        'agree': CheckboxField(name: 'agree', label: 'Agree'),
      };
      (fields['username'] as TextField).value = 'testuser';
      final section = FormSection(title: 'My Form', fields: fields);
      
      final json = section.toJson();
      final decoded = Section.fromJson(json) as FormSection;
      
      expect(decoded.title, 'My Form');
      expect(decoded.fields.length, 2);
      expect(decoded.fields['username'] is TextField, true);
      expect(decoded.fields['username']?.value, 'testuser');
      expect((decoded.fields['username'] as TextField).hint, 'Enter name');
      expect(decoded.fields['agree'] is CheckboxField, true);
    });

    test('MediaSection', () {
      final data = Uint8List.fromList([1, 2, 3, 4]);
      final section = MediaSection(items: [data]);
      
      final json = section.toJson();
      final decoded = Section.fromJson(json) as MediaSection;
      
      expect(decoded.items.length, 1);
      expect(decoded.items[0], data);
    });
  });

  test('PageData Serialization', () {
    final page = PageData(
      url: 'https://test.com',
      title: 'Test Page',
      content: [
        const MarkdownSection('Start'),
        TableSection(items: [1, 2, 3]),
      ],
    );

    final json = page.toJson();
    final decoded = PageData.fromJson(json);

    expect(decoded.url, page.url);
    expect(decoded.title, page.title);
    expect(decoded.content.length, 2);
    expect(decoded.content[0] is MarkdownSection, true);
    expect(decoded.content[1] is TableSection, true);
  });
}
