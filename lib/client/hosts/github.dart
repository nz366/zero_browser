import 'package:http/http.dart' as http;
import 'package:zero_browser/client/client.dart';
import 'package:zero_browser/model/data.dart';

final githubhosts = ["codeberg.org", "github.com"];

class GiteaRequest extends RequestTransformer {
  GiteaRequest({Uri? uri}) : super(host: githubhosts, uri: uri ?? Uri());

  @override
  RequestTransformer withUri(Uri uri) => GiteaRequest(uri: uri);

  @override
  Future<DataResponse> getData() async {
    if (uri.path == "") {
      return DataResponse(
        body: [
          CenteredSection(
            FormSection(
              fields: {"search": TextField(name: "search", label: "Search")},
            ),
          ),
        ],
        statusCode: 200,
        title: "Github",
      );
    }

    final html = await http.get(uri);
    if (html.isUnsuccesFull) {
      return unsuccesfulResponse(html);
    }

    String host = '';
    String name = '';
    RepoRootInfo Function(String s) getRepoRootInfo = RepoRootInfo.fromgithub;

    switch (uri.host) {
      case "github.com":
        host = "raw.githubusercontent.com";
        name = 'Github';
        break;
      case "codeberg.org":
        host = "codeberg.org";
        name = 'Codeberg';
        getRepoRootInfo = RepoRootInfo.fromGitea;
        break;
    }
    final repoRootInfo = getRepoRootInfo(html.body);

    Uri pageReadme = uri;

    if (!uri.path.contains('refs/')) {
      pageReadme = Uri.https(
        host,
        '${uri.path}/refs/heads/${repoRootInfo.branch}/README.md',
      );
    }

    final data = await http.get(pageReadme);

    return DataResponse(
      body: [
        MarkdownSection("# ${uri.path.split("/").last}"),
        TableSection(
          items: repoRootInfo.files.map((file) => {"file": file}).toList(),
        ),

        MarkdownSection(data.body),
      ],
      statusCode: data.statusCode,
      title: name,
    );
  }
}

extension on http.Response {
  bool get isUnsuccesFull => statusCode != 200;
}

class RepoRootInfo {
  final String branch;
  final List<String> files;

  RepoRootInfo({required this.branch, required this.files});

  factory RepoRootInfo.fromgithub(String html) {
    // Branch
    final branchMatch = RegExp(r'"defaultBranch":"([^"]+)"').firstMatch(html);

    final branch = branchMatch?.group(1) ?? 'main';

    // Root files
    final fileMatches = RegExp(
      r'"path":"([^"]+)","contentType":"(file|directory)"',
    ).allMatches(html);

    final files = <String>{};

    for (final m in fileMatches) {
      final path = m.group(1)!;

      // keep only root-level entries
      if (!path.contains('/')) {
        files.add(path);
      }
    }

    return RepoRootInfo(branch: branch, files: files.toList());
  }

  factory RepoRootInfo.fromGitea(String html) {
    return RepoRootInfo(branch: "unknown", files: []);
  }
}

DataResponse unsuccesfulResponse(http.Response html) {
  return DataResponse(
    body: [
      CenteredSection(
        MarkdownSection("# Error ${html.statusCode}\n\n${html.body}"),
      ),
    ],
    statusCode: html.statusCode,
    title: "Error ${html.statusCode}",
  );
}
