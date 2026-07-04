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
