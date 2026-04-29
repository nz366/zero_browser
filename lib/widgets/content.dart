import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:markdown_widget/markdown_widget.dart';
import 'package:provider/provider.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' show LucideIcons;
import 'package:waterfall_flow/waterfall_flow.dart';
import 'package:zero_browser/model/data.dart';
import 'package:zero_browser/providers/history_provider.dart';

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
                            message: article.title,
                            child: Text(
                              article.title,
                              style: Theme.of(context).textTheme.bodyMedium,
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
                            style: Theme.of(context).textTheme.headlineSmall,
                            maxLines: 1,
                          ),
                          Text(
                            "${article.subgroup} • ${article.author} • ${article.upvotes} UP",

                            style: Theme.of(context).textTheme.headlineMedium
                                ?.copyWith(
                                  fontSize: Theme.of(
                                    context,
                                  ).textTheme.bodySmall?.fontSize,
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

          case LayoutConfig.masonry:
            slivers.add(
              WaterfallFlow.builder(
                gridDelegate: SliverWaterfallFlowDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 300,
                ),
                itemBuilder: (c, i) {
                  return ThumbnailWidget(
                    url:
                        articleList.articles[i].thumbnail ??
                        articleList.articles[i].url,
                  );
                },
              ),
            );

            break;
        }

      case TableSection tableSection:
        slivers.add(
          SliverToBoxAdapter(
            child: DataTable(
              columns: tableSection.items.first.keys
                  .map<DataColumn>((c) => DataColumn(label: Text(c)))
                  .toList(),
              rows: tableSection.items
                  .map(
                    (r) => DataRow(
                      cells: r.values
                          .map<DataCell>((c) => DataCell(Text(c.toString())))
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
                color: Colors.grey.withAlpha(100),
                activeColor: Colors.grey.withBlue(200),
                buildHeader: buildHeader,
                buildBody: buildBody,
                buildEnd: buildEnd,
              );
            },
          ),
        );
      case MarkdownSection markdown:
        slivers.add(buildMarkdown(markdown.data, context));

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
                itemExtent: MediaQuery.of(context).size.width * 0.8,

                children: mediaSection.items
                    .map((e) => Image.memory(e, fit: BoxFit.cover))
                    .toList(),
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
    if (widget.url == null) {
      return SizedBox.shrink();
    }
    return Image.network(
      widget.url!,
      errorBuilder: (c, e, s) {
        // ArgumentError (Invalid argument(s): No host specified in URI ''
        if (e is ArgumentError) {
          if (widget.url is String &&
              (widget.url!.length % 4 == 0) &&
              widget.url!.startsWith('data:image/') &&
              widget.url!.contains(';base64,')) {
            final imagemem = base64Decode(widget.url!.split(';base64,')[1]);
            return Image.memory(imagemem);
          }
        }

        return Icon(LucideIcons.imageOff);
      },
    );
  }
}

Widget buildMarkdown(element, BuildContext context) {
  final config = Theme.of(context).brightness == Brightness.dark
      ? MarkdownConfig.darkConfig
      : MarkdownConfig.defaultConfig;

  return MarkdownWidget(
    sliverMode: true,
    data: element,
    config: config.copy(
      configs: [
        ImgConfig(
          builder: (imageUrl, _) {
            return ThumbnailWidget(url: imageUrl);
          },
        ),
        LinkConfig(
          onTap: (url) {
            Provider.of<TabProvider>(
              context,
              listen: false,
            ).navigateWithHistory(url);
          },
        ),
      ],
    ),
  );
}

Widget buildBody(CommentData data) {
  return ConstrainedBox(
    constraints: BoxConstraints(maxHeight: 300),
    child: MarkdownBlock(data: data.content),
  );
}
