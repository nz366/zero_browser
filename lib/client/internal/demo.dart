import 'dart:typed_data';

import 'package:zero_browser/model/data.dart';

List<Section> demopage() => [
  MarkdownSection("""# This is a demo page

    Markdown Section


    """),

  MarkdownSection("## Forms"),
  FormSection(
    fields: {
      "name": TextField(name: "name"),
      "file": FileField(name: "Upload File"),
    },
  ),

  MarkdownSection("## Demo Files"),
  MediaSection(
    downloadMode: true,
    items: List.generate(20, (index) {
      return PreLoadedFile(Uint8List.fromList([]), name: "Empty File ($index)");
    }),
  ),

  MediaSection(
    downloadMode: true,
    items: List.generate(4, (index) {
      return PreLoadedFile(Uint8List.fromList([]), name: "Empty File ($index)");
    }),
  ),

  MarkdownSection("## Comments"),
  CommentThreadSection([
    CommentData(
      content: "This is a comment",
      author: "Demo",
      id: "0",
      createdAt: DateTime.now(),
      score: 0,
      replies: [
        CommentData(
          content: "This is a reply",
          author: "Demo",
          id: "0",
          createdAt: DateTime.now(),
          score: 0,
          replies: [],
        ),
        CommentData(
          content: "This is a reply",
          author: "Demo",
          id: "0",
          createdAt: DateTime.now(),
          score: 0,
          replies: [],
        ),
      ],
    ),
  ]),
];
