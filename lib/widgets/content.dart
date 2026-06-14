import 'dart:convert';
import 'package:markdown_widget/markdown_widget.dart';
import 'package:provider/provider.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:zero_browser/model/data.dart';
import 'package:zero_browser/providers/history_provider.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:zero_browser/widgets/comment_threads/comment_tree.dart';
import 'package:zero_browser/widgets/forms.dart';

class ContentView extends StatelessWidget {
  final PageData page;
  const ContentView({super.key, required this.page});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 8.0),
      child: CustomScrollView(slivers: generateSlivers(context, page)),
    );
  }
}

List<Widget> generateSlivers(BuildContext context, PageData page) {
  final content = page.content;
  List<Widget> slivers = [];

  for (var element in content) {
    switch (element) {
      case ArticleListSection articleList:
        switch (articleList.layout) {
          case LayoutConfig.masonry:
          //       gridDelegate: SliverWaterfallFlowDelegateWithMaxCrossAxisExtent(
          //         maxCrossAxisExtent: 300,
          //       ),
          case LayoutConfig.grid:
            slivers.add(
              SliverGrid.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
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
                        ).openTab(article.url);
                      },
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ThumbnailWidget(
                            url: article.thumbnail ?? article.url,
                          ),
                          Tooltip(
                            tooltip: TooltipContainer(
                              child: Text(article.title),
                            ),
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
            );
            break;

          case LayoutConfig.list:
            slivers.add(
              SliverList.builder(
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
                        ).openTab(article.url);
                      },
                      child: Column(
                        crossAxisAlignment: .start,
                        children: [
                          Text(
                            article.title,
                            style: Theme.of(context).typography.h4,
                            maxLines: 1,
                          ),
                          Text(
                            "${article.subgroup} • ${article.author} • ${article.upvotes} UP",

                            style: Theme.of(context).typography.base.copyWith(
                              fontSize: Theme.of(
                                context,
                              ).typography.small.fontSize,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            );
            break;

          case LayoutConfig.table:
            break;
        }

      case TableSection tableSection:
        slivers.add(
          SliverToBoxAdapter(
            child: tableSection.items.isEmpty
                ? SizedBox.shrink()
                : Table(
                    // columns: tableSection.columns
                    //     .map<DataColumn>(
                    //       (c) => DataColumn(
                    //         label: Text(c.toUpperCase()),
                    //         columnWidth: FixedColumnWidth(200),
                    //       ),
                    //     )
                    //     .toList(),
                    rows: tableSection.items
                        .map(
                          (r) => TableRow(
                            cells: r.values
                                .map<TableCell>(
                                  (c) => TableCell(
                                    child: SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      child: buildMiniMarkDown(
                                        c.toString(),
                                        context,
                                        page,
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                        )
                        .toList(),
                  ),
          ),
        );

      case CommentThreadSection commentThread:
        slivers.add(
          SliverList.builder(
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
        );
      case MarkdownSection markdown:
        slivers.add(buildMarkdown(markdown.data, context, page));

      case SettingsSliverSection _:
        slivers.add(
          SliverToBoxAdapter(
            child: SizedBox(
              height: 1000,
              child: Column(children: [Text("Settings")]),
            ),
          ),
        );
      case ImageGridSection imageGridSection:
        slivers.add(buildImageGrid(context, imageGridSection));

      case FormSection formSection:
        slivers.add(
          SliverToBoxAdapter(
            child: FormSectionWidget(formSection: formSection, page: page),
          ),
        );
      case MediaSection mediaSection:
        slivers.add(
          SliverToBoxAdapter(
            child: SizedBox(
              height: MediaQuery.of(context).size.height * 0.8,
              child: CarouselView(
                // itemExtent: MediaQuery.of(context).size.width * 0.8,
                children: mediaSection.items.map((e) {
                  final String start = String.fromCharCodes(
                    e.take(100),
                  ).toLowerCase();
                  if (start.contains('<svg') || start.contains('<?xml')) {
                    return SvgPicture.memory(e, fit: BoxFit.cover);
                  }
                  return Image.memory(e, fit: BoxFit.cover);
                }).toList(),
              ),
            ),
          ),
        );
    }
  }

  return slivers;
}

Widget buildImageGrid(BuildContext context, ImageGridSection imageGridSection) {
  return SliverGrid.builder(
    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 5),
    itemBuilder: (c, i) {
      return ThumbnailWidget(url: imageGridSection.data[i]);
    },
  );
}

class ThumbnailWidget extends StatefulWidget {
  final String? url;
  const ThumbnailWidget({super.key, required this.url});

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
          if (url.startsWith("//")) {
            return ThumbnailWidget(url: "https:$url");
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

        return Tooltip(
          tooltip: TooltipContainer(
            child: Text("${e.toString()}\n${s.toString()}"),
          ),
          child: Icon(LucideIcons.imageOff),
        );
      },
    );
  }
}

Widget buildMarkdown(element, BuildContext context, PageData page) {
  return MarkdownWidget(
    sliverMode: true,
    data: element,
    config: markdownBrowserConfig(context, page),
  );
}

MarkdownConfig markdownBrowserConfig(BuildContext context, PageData page) {
  final config = Theme.of(context).brightness == Brightness.dark
      ? MarkdownConfig.darkConfig
      : MarkdownConfig.defaultConfig;

  return config.copy(
    configs: [
      ImgConfig(
        builder: (imageUrl, _) {
          return ThumbnailWidget(url: imageUrl);
        },
      ),
      LinkConfig(
        onTap: (url) {
          Uri uri = Uri.parse(url);

          if (uri.host.isEmpty) {
            uri = Uri.parse(
              "https://${page.sourceUri?.host}${url.startsWith("/") ? "" : "/"}${uri.path}",
            );
          }

          Provider.of<TabProvider>(
            context,
            listen: false,
          ).navigateWithHistory(uri.toString());
        },
      ),
    ],
  );
}

Widget buildMiniMarkDown(String data, BuildContext context, PageData page) {
  return MarkdownBlock(
    data: data,
    config: markdownBrowserConfig(context, page),
  );
}

Widget buildBody(CommentData data, BuildContext context, PageData page) {
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

  final List<Widget> children;
  @override
  State<CarouselView> createState() => _CarouselViewState();
}

class _CarouselViewState extends State<CarouselView> {
  final CarouselController controller = CarouselController();
  @override
  Widget build(BuildContext context) {
    return Carousel(
      transition: const CarouselTransition.sliding(gap: 24),
      controller: controller,
      sizeConstraint: const CarouselFixedConstraint(200),
      autoplaySpeed: const Duration(seconds: 2),
      itemCount: 5,
      itemBuilder: (context, index) {
        return widget.children[index];
      },
      duration: const Duration(seconds: 1),
    );
  }
}
