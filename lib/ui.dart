// ui.dart
import 'package:flutter/material.dart';
import 'repository.dart';
import 'api.dart';

String formatDateTime(String dateTimeString) {
  final DateTime dateTime = DateTime.parse(dateTimeString);
  final String formattedDate = dateTime.toIso8601String().split('T')[0];
  final String formattedTime = dateTime.toIso8601String().split('T')[1].split('.')[0];
  return 'Date: $formattedDate\nTime: $formattedTime';
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  int _currentPage = 1;
  late Future<List<Repository>> _repositories;
  final Map<String, Future<void>> _fetchCommits = {};
  final TextEditingController _usernameController = TextEditingController();

  bool _canLoadNextPage = true;

  @override
  void initState() {
    super.initState();
    _repositories = _usernameController.text.isEmpty
        ? Future.value([])
        : fetchRepositories(_usernameController.text, _currentPage);
  }

  Future<void> _changePage(int page) async {
    setState(() {
      _currentPage = page;
    });

    final repositories =
        await fetchRepositories(_usernameController.text, page);
    final hasNextPage = repositories.isNotEmpty;

    setState(() {
      _repositories = Future.value(repositories);
      _canLoadNextPage = hasNextPage;
      _fetchCommits.clear();
    });
  }

  Future<void> _fetchAllCommits(Repository repository) async {
    if (_fetchCommits[repository.name] == null && repository.commits == null) {
      setState(() {
        _fetchCommits[repository.name] =
            repository.fetchCommits(_usernameController.text);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        hintColor: Colors.orangeAccent,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('GitHub Repositories'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _usernameController,
                decoration: InputDecoration(
                  labelText: 'Enter GitHub Username',
                  prefixIcon: const Icon(Icons.person),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.search),
                    onPressed: () => _changePage(1),
                  ),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: FutureBuilder(
                  future: _repositories,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    } else if (snapshot.hasData) {
                      final List<Repository>? repositories = snapshot.data;
                      return ListView.builder(
                        itemCount: repositories?.length,
                        itemBuilder: (context, index) {
                          final repository = repositories![index];
                          return Card(
                            elevation: 3,
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            child: ListTile(
                              title: Text(repository.name),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(repository.description),
                                  Text(
                                    'Stars: ${repository.stargazersCount}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                ],
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.arrow_forward),
                                onPressed: () async {
                                  await _fetchAllCommits(repository);
                                  if (repository.commits != null) {
                                    Navigator.push(
                                      // ignore: use_build_context_synchronously
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => CommitsScreen(
                                          repository: repository,
                                        ),
                                      ),
                                    );
                                  }
                                },
                              ),
                            ),
                          );
                        },
                      );
                    }
                    return const SizedBox();
                  },
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_left),
                    onPressed: _currentPage > 1
                        ? () => _changePage(_currentPage - 1)
                        : null,
                  ),
                  Text('Page $_currentPage'),
                  IconButton(
                    icon: const Icon(Icons.arrow_right),
                    onPressed: _canLoadNextPage
                        ? () => _changePage(_currentPage + 1)
                        : null,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CommitsScreen extends StatelessWidget {
  final Repository repository;

  const CommitsScreen({super.key, required this.repository});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Commits for ${repository.name}'),
      ),
      body: ListView.builder(
        itemCount: repository.commits?.length ?? 0,
        itemBuilder: (context, index) {
          final commit = repository.commits![index];
          final formattedDateTime = commit.commitDate != null
              ? formatDateTime(commit.commitDate!.toIso8601String())
              : 'No date available';
          return ListTile(
            title: Text(commit.sha.substring(0, 7)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(commit.message),
                Text(formattedDateTime),
              ],
            ),
          );
        },
      ),
    );
  }
}
