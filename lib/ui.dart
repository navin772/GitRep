// ui.dart
import 'package:flutter/material.dart';
import 'repository.dart';
import 'api.dart';
import 'package:shared_preferences/shared_preferences.dart';

String formatDateTime(String dateTimeString) {
  final DateTime dateTime = DateTime.parse(dateTimeString);
  final String formattedDate = dateTime.toIso8601String().split('T')[0];
  final String formattedTime =
      dateTime.toIso8601String().split('T')[1].split('.')[0];
  return 'Date: $formattedDate\nTime: $formattedTime';
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  int _currentPage = 1;
  late Future<List<Repository>> _repositories;
  final Map<String, Future<void>> _fetchCommits = {};
  final TextEditingController _usernameController = TextEditingController();

  bool _canLoadNextPage = true;

  ThemeMode _themeMode = ThemeMode.light;

  void _toggleTheme() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _themeMode =
          _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
      prefs.setInt('themeMode', _themeMode.index);
    });
  }

  @override
  void initState() {
    super.initState();
    _retrieveThemeMode();
    _repositories = _usernameController.text.isEmpty
        ? Future.value([])
        : fetchRepositories(_usernameController.text, _currentPage);
  }

// Use shared preferences package to retrieve the previously selected theme mode
  void _retrieveThemeMode() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int themeIndex = prefs.getInt('themeMode') ?? ThemeMode.light.index;
    setState(() {
      _themeMode = ThemeMode.values[themeIndex];
    });
  }

  Future<void> _changePage(int page) async {
  setState(() {
    _currentPage = page;
  });

  if (_usernameController.text.isEmpty) {
    // If username is empty, set repositories to an empty list
    setState(() {
      _repositories = Future.value([]);
      _canLoadNextPage = false; // Disable next page loading
      _fetchCommits.clear();
    });
    return;
  }

  try {
    final repositories = await fetchRepositories(_usernameController.text, page);
    final hasNextPage = repositories.isNotEmpty;

    setState(() {
      _repositories = Future.value(repositories);
      _canLoadNextPage = hasNextPage;
      _fetchCommits.clear();
    });
  } catch (error) {
    setState(() {
      _repositories = Future.error('The user does not exists on GitHub');
      _canLoadNextPage = false; // Disable next page loading
      _fetchCommits.clear();
    });
  }
}

  Future<void> _fetchAllCommitsAndNavigate(
      BuildContext context, Repository repository) async {
    await _fetchAllCommits(repository);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CommitsScreen(
          repository: repository,
          usernameController: _usernameController,
        ),
      ),
    );
  }

  Future<void> _fetchAllCommits(Repository repository) async {
    if (_fetchCommits[repository.name] == null && repository.commits == null) {
      setState(() {
        _fetchCommits[repository.name] =
            repository.fetchCommits(_usernameController.text, 1);
      });
      await _fetchCommits[repository.name]!;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      themeMode: _themeMode,
      home: Scaffold(
        appBar: AppBar(
          title: const Text('GitHub Repositories'),
          actions: [
            IconButton(
              icon: Icon(Icons.lightbulb),
              onPressed: _toggleTheme,
            ),
          ],
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
                                onPressed: () => _fetchAllCommitsAndNavigate(
                                    context, repository),
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
                  if (_usernameController
                      .text.isNotEmpty) // Only show if username is not empty
                    IconButton(
                      icon: const Icon(Icons.arrow_left),
                      onPressed: _currentPage > 1
                          ? () => _changePage(_currentPage - 1)
                          : null,
                    ),
                  if (_usernameController
                      .text.isNotEmpty) // Only show if username is not empty
                    Text('Page $_currentPage'),
                  if (_usernameController
                      .text.isNotEmpty) // Only show if username is not empty
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

class CommitsScreen extends StatefulWidget {
  final Repository repository;
  final TextEditingController usernameController;

  const CommitsScreen({
    required this.repository,
    required this.usernameController,
  });

  @override
  _CommitsScreenState createState() => _CommitsScreenState();
}

class _CommitsScreenState extends State<CommitsScreen> {
  late ScrollController _scrollController;
  bool _loading = false;
  bool _noMoreCommits =
      false; // Flag to indicate if there are no more commits left
  int _currentPage = 1;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_scrollListener);
    _fetchCommits();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.offset >=
            _scrollController.position.maxScrollExtent &&
        !_scrollController.position.outOfRange &&
        !_loading &&
        !_noMoreCommits) {
      // Check if there are more commits to fetch
      _fetchCommits();
    }
  }

  Future<void> _fetchCommits() async {
    if (_noMoreCommits) return; // Stop fetching if there are no more commits

    setState(() {
      _loading = true;
    });

    await widget.repository.fetchCommits(
      widget.usernameController.text,
      _currentPage,
    );

    setState(() {
      _currentPage++;
      _loading = false;
      if (widget.repository.commits?.isEmpty ?? true) {
        _noMoreCommits = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Commits for ${widget.repository.name}'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: widget.repository.commits?.length ?? 0,
              itemBuilder: (context, index) {
                final commit = widget.repository.commits![index];
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
              controller: _scrollController,
            ),
          ),
          if (_loading)
            const CircularProgressIndicator(), // Display loading indicator
          if (_noMoreCommits)
            const Text(
                'No more commits'), // Display message if there are no more commits left
        ],
      ),
    );
  }
}
