import 'package:zero_browser/client/client.dart';
import 'package:zero_browser/client/hosts/basichtml.dart';
import 'package:zero_browser/model/data.dart';
import 'package:zero_browser/model/sites.dart';

class GithubSite implements SiteProfile {
  @override
  List<String> get domains => ["github.com"];

  @override
  RequestProfile get request => RequestProfile(
    getContent: (Client client, String path) async {
      final response = await client.httpRequest(path, throwError: true);
      final uri = Uri.parse(path);
      if (uri.path.isEmpty) {}

      String host = "raw.githubusercontent.com";
      String name = 'Github';

      final repoRootInfo = RepoRootInfo.fromgithub(response.body);

      Uri pageReadme = uri;

      if (!uri.path.contains('refs/')) {
        pageReadme = Uri.https(
          host,
          '${uri.path}/refs/heads/${repoRootInfo.branch}/README.md',
        );
      }

      final data = await client.httpUriRequest(pageReadme);

      return Structure(
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
    },
  );
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

class GitlabSite implements SiteProfile {
  @override
  List<String> get domains => ["gitlab.*"];

  @override
  RequestProfile get request => RequestProfile(
    getContent: (Client client, String path) async {
      final response = await client.httpRequest(path);
      return defaultHtmlString(response.body, "Gitlab");
    },
  );
}

class GiteaSite implements SiteProfile {
  @override
  List<String> get domains => [
    "demo.gitea.com",
    "projects.blender.com",
    "codeberg.org",
  ];

  @override
  RequestProfile get request => RequestProfile(
    getContent: (Client client, String path) async {
      final response = await client.httpRequest(path);
      return defaultHtmlString(response.body, "Gitlab");
    },
  );
}
