// api.dart
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'repository.dart';

int currentPage = 1;

Future<List<Repository>> fetchRepositories(String username, int page) async {
  const String token = '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';
  final response = await http.get(
    Uri.parse(
        'https://api.github.com/users/$username/repos?page=$page&per_page=30'),
    headers: {'Authorization': 'token $token'},
  );
  if (response.statusCode == 200) {
    final data = jsonDecode(response.body) as List;
    return parseRepositories(data);
  } else {
    throw Exception('Failed to load repositories');
  }
}

List<Repository> parseRepositories(List<dynamic> data) {
  final List<Repository> repositories = [];
  for (var item in data) {
    repositories.add(Repository.fromJson(item as Map<String, dynamic>));
  }
  return repositories;
}
