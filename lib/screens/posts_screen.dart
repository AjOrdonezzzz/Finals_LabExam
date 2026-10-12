import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class PostsScreen extends StatefulWidget {
  const PostsScreen({super.key});

  @override
  State<PostsScreen> createState() => _PostsScreenState();
}

class _PostsScreenState extends State<PostsScreen> {
  static const String _url = 'https://jsonplaceholder.typicode.com/posts';

  List<dynamic> _posts = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchPosts();
  }

  // Part 2: GET request called from initState().
  Future<void> _fetchPosts() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final response = await http.get(Uri.parse(_url));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List<dynamic>;
        setState(() {
          _posts = data;
          _loading = false;
        });
      } else {
        setState(() {
          _error = 'Failed to load posts (status ${response.statusCode})';
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Something went wrong: $e';
        _loading = false;
      });
    }
  }

  // Part 2: dialog + POST request.
  Future<void> _showCreateDialog() async {
    final titleController = TextEditingController();
    final bodyController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final submitted = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('New Post'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Title'),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Title is required'
                    : null,
              ),
              TextFormField(
                controller: bodyController,
                decoration: const InputDecoration(labelText: 'Body'),
                maxLines: 3,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Body is required' : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(dialogContext, true);
              }
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );

    if (submitted != true) return;

    String message;
    try {
      final response = await http.post(
        Uri.parse(_url),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode({
          'title': titleController.text.trim(),
          'body': bodyController.text.trim(),
          'userId': 1,
        }),
      );
      message = response.statusCode == 201
          ? 'Post created successfully!'
          : 'Failed to create post (status ${response.statusCode})';
    } catch (e) {
      message = 'Failed to create post: $e';
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 12),
              ElevatedButton(
                  onPressed: _fetchPosts, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }
    return ListView.builder(
      itemCount: _posts.length,
      itemBuilder: (context, index) {
        final post = _posts[index];
        return ListTile(
          title:
              Text(post['title'], maxLines: 1, overflow: TextOverflow.ellipsis),
          subtitle:
              Text(post['body'], maxLines: 2, overflow: TextOverflow.ellipsis),
          // Part 1: pass id, title, body as arguments.
          onTap: () => Navigator.pushNamed(
            context,
            '/details',
            arguments: {
              'id': post['id'],
              'title': post['title'],
              'body': post['body'],
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Posts'),
        actions: [
          IconButton(
            icon: const Icon(Icons.favorite),
            tooltip: 'Favorites',
            onPressed: () => Navigator.pushNamed(context, '/favorites'),
          ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}
