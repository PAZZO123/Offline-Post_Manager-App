// lib/screens/posts_list_screen.dart

import 'package:flutter/material.dart';

import '../database/database_helper.dart';
import '../models/post.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';
import 'post_detail_screen.dart';
import 'post_form_screen.dart';

class PostsListScreen extends StatefulWidget {
  const PostsListScreen({super.key});

  @override
  State<PostsListScreen> createState() => _PostsListScreenState();
}

class _PostsListScreenState extends State<PostsListScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final AuthService    _auth     = AuthService();

  List<Post> _posts        = [];
  bool       _isLoading    = true;
  String?    _errorMessage;
  String?    _username;    // logged-in user's name

  @override
  void initState() {
    super.initState();
    _loadUsername();
    _loadPosts();
  }

  // ── Load username for greeting ────────────────────────────────────────────

  Future<void> _loadUsername() async {
    final name = await _auth.getLoggedInUsername();
    if (mounted) setState(() => _username = name);
  }

  // ── Data ──────────────────────────────────────────────────────────────────

  Future<void> _loadPosts() async {
    setState(() { _isLoading = true; _errorMessage = null; });
    try {
      final posts = await _dbHelper.getAllPosts();
      setState(() { _posts = posts; _isLoading = false; });
    } catch (e) {
      setState(() { _errorMessage = e.toString(); _isLoading = false; });
    }
  }

  // ── Logout ────────────────────────────────────────────────────────────────

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    await _auth.logout();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  // ── Delete ────────────────────────────────────────────────────────────────

  Future<void> _deletePost(Post post) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Post'),
        content: Text('Delete "${post.title}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await _dbHelper.deletePost(post.id!);
      _showSnackBar('Post deleted');
      _loadPosts();
    } catch (e) {
      _showSnackBar('Error: $e', isError: true);
    }
  }

  void _showSnackBar(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor:
          isError ? Colors.red.shade700 : Colors.green.shade700,
      behavior: SnackBarBehavior.floating,
    ));
  }

  Future<void> _navigateToForm({Post? post}) async {
    final result = await Navigator.push<bool>(
        context, MaterialPageRoute(builder: (_) => PostFormScreen(post: post)));
    if (result == true) _loadPosts();
  }

  Future<void> _navigateToDetail(Post post) async {
    final result = await Navigator.push<bool>(
        context, MaterialPageRoute(builder: (_) => PostDetailScreen(post: post)));
    if (result == true) _loadPosts();
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome greeting
            if (_username != null)
              Text('Hello, $_username!',
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: Colors.white70)),
            const Text('Offline Posts Manager',
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Refresh',
              onPressed: _loadPosts),
          IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'Sign Out',
              onPressed: _logout),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToForm(),
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('New Post'),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.error_outline, color: Colors.red.shade400, size: 56),
            const SizedBox(height: 16),
            Text('Something went wrong',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(_errorMessage!, textAlign: TextAlign.center),
            const SizedBox(height: 24),
            ElevatedButton.icon(
                onPressed: _loadPosts,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry')),
          ]),
        ),
      );
    }
    if (_posts.isEmpty) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.article_outlined, size: 72, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text('No posts yet',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(color: Colors.grey.shade600)),
          const SizedBox(height: 8),
          Text('Tap + to create your first post',
              style: TextStyle(color: Colors.grey.shade500)),
        ]),
      );
    }
    return RefreshIndicator(
      onRefresh: _loadPosts,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        itemCount: _posts.length,
        itemBuilder: (context, index) => _PostCard(
          post: _posts[index],
          onTap: () => _navigateToDetail(_posts[index]),
          onEdit: () => _navigateToForm(post: _posts[index]),
          onDelete: () => _deletePost(_posts[index]),
        ),
      ),
    );
  }
}

// ── Post Card ─────────────────────────────────────────────────────────────────

class _PostCard extends StatelessWidget {
  final Post post;
  final VoidCallback onTap, onEdit, onDelete;

  const _PostCard({
    required this.post,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(
                child: Text(post.title,
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A237E)),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
              ),
              PopupMenuButton<String>(
                onSelected: (v) {
                  if (v == 'edit') onEdit();
                  if (v == 'delete') onDelete();
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'edit',
                      child: Row(children: [
                        Icon(Icons.edit, size: 18), SizedBox(width: 8),
                        Text('Edit')])),
                  const PopupMenuItem(value: 'delete',
                      child: Row(children: [
                        Icon(Icons.delete, size: 18, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Delete', style: TextStyle(color: Colors.red))])),
                ],
              ),
            ]),
            const SizedBox(height: 8),
            Text(post.body,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.grey.shade700, fontSize: 14)),
            const SizedBox(height: 12),
            Row(children: [
              const Icon(Icons.person_outline, size: 14, color: Colors.grey),
              const SizedBox(width: 4),
              Text(post.author,
                  style: const TextStyle(fontSize: 12, color: Colors.grey)),
              const Spacer(),
              const Icon(Icons.access_time, size: 14, color: Colors.grey),
              const SizedBox(width: 4),
              Text(post.createdAt,
                  style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ]),
          ]),
        ),
      ),
    );
  }
}