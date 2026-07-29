import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart' show Tooltip;
import 'package:markdown_widget/markdown_widget.dart';
import 'package:provider/provider.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' hide Tooltip;
import 'package:zero_browser/model/data.dart';
import 'package:zero_browser/providers/history_provider.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:zero_browser/utils/uri.dart';
import 'package:zero_browser/widgets/code.dart';
import 'package:zero_browser/widgets/comment_threads/comment_tree.dart';
import 'package:zero_browser/widgets/fields/file.dart';
import 'package:zero_browser/widgets/forms.dart';

class SourcePanel extends StatelessWidget {
  const SourcePanel({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TabProvider>();

    return SingleChildScrollView(
      child: Center(
        child: ConstrainedBox(
          constraints: provider.focusedTab.isWideMode
              ? const BoxConstraints()
              : const BoxConstraints(maxWidth: 1000),
          child: CodeSnippet(
            constraints: BoxConstraints(minWidth: double.infinity),
            code: CodeHighlighter(
              mode: "json",
              code: provider.focusedTab.page.content
                  .map((e) => e.toJson())
                  .join("\n"),
            ),
          ),
        ),
      ),
    );
  }
}

class ContentView extends StatefulWidget {
  final BrowserPage page;
  final ScrollController scrollController;
  const ContentView({
    super.key,
    required this.page,
    required this.scrollController,
  });

  @override
  State<ContentView> createState() => _ContentViewState();
}

class _ContentViewState extends State<ContentView> {
  bool? hovering = false;
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onHover: (_) => hovering = true,
      onExit: (_) => hovering = null,
      child: Padding(
        padding: const EdgeInsets.only(left: 16, right: 16, top: 8.0),

        child: CustomScrollView(
          controller: widget.scrollController,
          slivers: generateSlivers(context, widget.page),
        ),
      ),
    );
  }
}

List<Widget> generateSlivers(BuildContext context, BrowserPage page) {
  final content = page.content;
  List<Widget> slivers = [];
  for (var element in content) {
    slivers.add(sectionToWidget(context, page, element, true));
  }
  return slivers;
}

Widget wrapsliver(Widget box, bool useSliverAdapter) {
  return useSliverAdapter ? SliverToBoxAdapter(child: box) : box;
}

Widget sectionToWidget(
  BuildContext context,
  BrowserPage page,
  Section element,
  bool useSliverAdapter,
) {
  return switch (element) {
    CenteredSection centered => SliverToBoxAdapter(
      child: ConstrainedBox(
        constraints: BoxConstraints.expand(
          height: MediaQuery.of(context).size.height * 0.8,
        ),
        child: Center(
          child: sectionToWidget(context, page, centered.section, false),
        ),
      ),
    ),
    ArticleListSection articleList => switch (articleList.layout) {
      LayoutConfig.masonry => wrapsliver(SizedBox.shrink(), useSliverAdapter),
      LayoutConfig.grid => SliverGrid.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 5,
        ),
        itemCount: articleList.articles.length,
        itemBuilder: (context, i) {
          final article = articleList.articles[i];
          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: GestureDetector(
              onTap: () {
                Provider.of<TabProvider>(
                  context,
                  listen: false,
                ).branchTab(article.url);
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ThumbnailWidget(
                    url: article.thumbnail ?? article.url,
                    baseUri: page.sourceUri,
                  ),
                  Tooltip(
                    message: article.title,
                    child: Text(
                      article.title,
                      style: Theme.of(context).typography.medium,
                      maxLines: 1,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      LayoutConfig.list => SliverList.builder(
        itemCount: articleList.articles.length,
        itemBuilder: (context, i) {
          final article = articleList.articles[i];
          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: GestureDetector(
              onTap: () {
                Provider.of<TabProvider>(
                  context,
                  listen: false,
                ).branchTab(article.url);
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    article.title,
                    style: Theme.of(context).typography.h4,
                    maxLines: 1,
                  ),
                  Text(
                    "${article.subgroup} • ${article.author} • ${article.upvotes} UP",
                    style: Theme.of(context).typography.base.copyWith(
                      fontSize: Theme.of(context).typography.small.fontSize,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      LayoutConfig.table => const SliverToBoxAdapter(child: SizedBox.shrink()),
    },
    TableSection tableSection => wrapsliver(
      tableSection.items.isEmpty
          ? const SizedBox.shrink()
          : Table(
              rows: tableSection.items
                  .map(
                    (r) => TableRow(
                      cells: r.values
                          .map<TableCell>(
                            (c) => TableCell(
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: buildMiniMarkDown(
                                    c.toString(),
                                    context,
                                    page,
                                  ),
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  )
                  .toList(),
            ),
      useSliverAdapter,
    ),
    CommentThreadSection commentThread => SliverList.builder(
      itemCount: commentThread.data.length,
      itemBuilder: (c, i) {
        return CommentTree(
          comment: commentThread.data[i],
          color: Theme.of(context).colorScheme.border,
          activeColor: Colors.gray.withBlue(200),
          buildHeader: buildHeader,
          buildBody: (data) => buildBody(data, context, page),
          buildEnd: buildEnd,
        );
      },
    ),
    MarkdownSection markdown => buildMarkdown(markdown.data, context, page),
    SettingsSliverSection _ => wrapsliver(
      SizedBox(height: 1000, child: Column(children: [Text("Settings")])),
      useSliverAdapter,
    ),
    ImageGridSection imageGridSection => buildImageGrid(
      context,
      imageGridSection,
      page,
    ),
    FormSection formSection => wrapsliver(
      FormSectionWidget(formSection: formSection, page: page),
      useSliverAdapter,
    ),
    MediaSection mediaSection => wrapsliver(
      mediaSection.downloadMode
          ? FileDownloadWidget(
              section: mediaSection,
              onDownload: (item) async {
                Future.microtask(() async {
                  final bytes = await item.getBytes();
                  File file = await File(item.name).create();
                  await file.writeAsBytes(bytes);
                });
              },
            )
          : SizedBox(
              height: MediaQuery.of(context).size.height * 0.8,
              child: CarouselView(
                children: mediaSection.items.map((e) async {
                  final bytes = await e.getBytes();
                  final String start = String.fromCharCodes(
                    bytes.take(100),
                  ).toLowerCase();
                  if (start.contains('<svg') || start.contains('<?xml')) {
                    return SvgPicture.memory(bytes, fit: BoxFit.contain);
                  }
                  return Image.memory(bytes, fit: BoxFit.contain);
                }).toList(),
              ),
            ),
      useSliverAdapter,
    ),
    BrowserWidget section => wrapsliver(
      SizedBox(
        height: MediaQuery.of(context).size.height * 0.8,
        child: section.widget,
      ),
      useSliverAdapter,
    ),
  };
}

Widget buildImageGrid(
  BuildContext context,
  ImageGridSection imageGridSection,
  BrowserPage page,
) {
  return SliverGrid.builder(
    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 5),
    itemBuilder: (c, i) {
      return ThumbnailWidget(
        url: imageGridSection.data[i],
        baseUri: page.sourceUri,
      );
    },
  );
}

class ThumbnailWidget extends StatefulWidget {
  final String? url;
  final Uri? baseUri;
  const ThumbnailWidget({super.key, required this.url, this.baseUri});

  @override
  State<ThumbnailWidget> createState() => _ThumbnailWidgetState();
}

class _ThumbnailWidgetState extends State<ThumbnailWidget> {
  @override
  Widget build(BuildContext context) {
    if (widget.url == null || widget.url!.isEmpty) {
      return SizedBox.shrink();
    }
    final url = widget.url!;

    return Image.network(
      url,
      errorBuilder: (c, e, s) {
        if (e is ArgumentError) {
          print("Failed image ${widget.baseUri} $url");
          if (url.startsWith("//")) {
            return ThumbnailWidget(url: "https:$url", baseUri: widget.baseUri);
          }

          if (url.contains('data:')) {
            if (url.contains('image/svg+xml')) {
              final String base64Data = url.split(',').last;
              return SvgPicture.memory(base64Decode(base64Data));
            } else if (url.contains(';base64,')) {
              try {
                final imagemem = base64Decode(url.split(';base64,')[1]);
                return Image.memory(imagemem);
              } catch (e) {
                return Icon(LucideIcons.imageOff);
              }
            }
          }
        }

        if (url.toLowerCase().split('?').first.endsWith('.svg')) {
          return SvgPicture.network(
            url,
            placeholderBuilder: (context) =>
                Center(child: CircularProgressIndicator()),
            errorBuilder: (context, error, stackTrace) =>
                Icon(LucideIcons.imageOff),
          );
        }

        final parsed = Uri.parse(url);

        final withbase = parsed.resolveWithBase(base: widget.baseUri);

        if (url != withbase.toString()) {
          return ThumbnailWidget(
            url: withbase.toString(),
            baseUri: widget.baseUri,
          );
        }

        return Tooltip(
          message: "${widget.url}\n${e.toString()}\n",
          child: Icon(LucideIcons.imageOff),
        );
      },
    );
  }
}

Widget buildMarkdown(element, BuildContext context, BrowserPage page) {
  return MarkdownWidget(
    sliverMode: true,
    data: element,
    config: markdownBrowserConfig(context, page),
  );
}

MarkdownConfig markdownBrowserConfig(BuildContext context, BrowserPage page) {
  final config = Theme.of(context).brightness == Brightness.dark
      ? MarkdownConfig.darkConfig
      : MarkdownConfig.defaultConfig;

  return config.copy(
    configs: [
      ImgConfig(
        builder: (imageUrl, _) {
          return ThumbnailWidget(url: imageUrl, baseUri: page.sourceUri);
        },
      ),
      LinkConfig(
        onTap: (url) {
          Uri uri = Uri.parse(url);

          if (uri.host.isEmpty) {
            uri = uri.resolveWithBase(base: page.sourceUri);
          }

          Provider.of<TabProvider>(
            context,
            listen: false,
          ).loadTab(uri.toString());
        },
      ),
    ],
  );
}

Widget buildMiniMarkDown(String data, BuildContext context, BrowserPage page) {
  return MarkdownBlock(
    data: data,
    config: markdownBrowserConfig(context, page),
  );
}

Widget buildBody(CommentData data, BuildContext context, BrowserPage page) {
  return ConstrainedBox(
    constraints: BoxConstraints(maxHeight: 300),
    child: MarkdownBlock(
      data: data.content,
      config: markdownBrowserConfig(context, page),
    ),
  );
}

class CarouselView extends StatefulWidget {
  const CarouselView({super.key, required this.children});

  final List<Future<Widget>> children;
  @override
  State<CarouselView> createState() => _CarouselViewState();
}

class _CarouselViewState extends State<CarouselView> {
  final CarouselController controller = CarouselController();
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsetsGeometry.only(top: 30),
      child: Carousel(
        draggable: widget.children.length != 1,
        transition: const CarouselTransition.sliding(gap: 24),
        controller: controller,
        itemCount: widget.children.length,
        itemBuilder: (context, index) {
          return FutureBuilder(
            future: widget.children[index],
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }
              return snapshot.data ?? Center(child: Icon(LucideIcons.imageOff));
            },
          );
        },
      ),
    );
  }
}
