// repository.dart
import 'package:http/http.dart' as http;
import 'dart:convert';

class Repository {
  final String name;
  final String description;
  final int stargazersCount;
  List<Commit>? commits;

  Repository.fromJson(Map<String, dynamic> json)
      : name = json['name'],
        description = json['description'] ?? '',
        stargazersCount = json['stargazers_count'],
        commits = null;

  Future<void> fetchCommits(String username, int page) async {
    const String token = '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';
    final response = await http.get(
      Uri.parse('https://api.github.com/repos/$username/$name/commits?page=$page&per_page=30'),  // Max limit is 100
      headers: {'Authorization': 'token $token'},
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as List;
      commits = data.map((item) => Commit.fromJson(item)).toList();
    }
  }
}

class Commit {
  final String sha;
  final CommitAuthor author;
  final String message;
  final DateTime? commitDate;

  Commit.fromJson(Map<String, dynamic> json)
      : sha = json['sha'],
        author = CommitAuthor.fromJson(json['commit']['author']),
        message = json['commit']['message'],
        commitDate = DateTime.tryParse(json['commit']['author']['date']);
}

class CommitAuthor {
  final String name;
  final String email;

  CommitAuthor.fromJson(Map<String, dynamic> json)
      : name = json['name'],
        email = json['email'];
}
