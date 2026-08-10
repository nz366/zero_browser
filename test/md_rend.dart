import 'dart:io';

import 'package:flutter/material.dart';
import 'package:markdown_widget/widget/all.dart';

void main() {
  runApp(
    MaterialApp(
      home: Scaffold(
        body: Row(
          children: [
            Expanded(
              child: MarkdownWidget(
                data: File("test/markdown.md").readAsStringSync(),
              ),
            ),

            Expanded(
              child: MarkdownBlock(
                data: File("test/markdown.md").readAsStringSync(),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
