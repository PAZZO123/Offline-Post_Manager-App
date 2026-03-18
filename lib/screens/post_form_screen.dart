// lib/screens/post_form_screen.dart

import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/post.dart';

class PostFormScreen extends StatefulWidget {
  /// If [post] is null, we are creating a new post.
  /// If [post] is provided, we are editing an existing one.
  final Post? post;

  const PostFormScreen({super.key, this.post});

  @override
  State<PostFormScreen> createState() => _PostFormScreenState();
}

class _PostFormScreenState extends State<PostFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  final _authorController = TextEditingController();

  final DatabaseHelper _dbHelper = DatabaseHelper();
  bool _isSaving = false;

  bool get _isEditing => widget.post != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _titleController.text = widget.post!.title;
      _bodyController.text = widget.post!.body;
      _authorController.text = widget.post!.author;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    _authorController.dispose();
    super.dispose();
  }

  // ── Save ──────────────────────────────────────────────────────────────────

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final now = DateTime.now();
      final dateStr =
          '${now.year}-${_pad(now.month)}-${_pad(now.day)}';

      if (_isEditing) {
        final updated = widget.post!.copyWith(
          title: _titleController.text.trim(),
          body: _bodyController.text.trim(),
          author: _authorController.text.trim(),
          createdAt: dateStr,
        );
        await _dbHelper.updatePost(updated);
        _showSnackBar('Post updated successfully');
      } else {
        final newPost = Post(
          title: _titleController.text.trim(),
          body: _bodyController.text.trim(),
          author: _authorController.text.trim(),
          createdAt: dateStr,
        );
        await _dbHelper.insertPost(newPost);
        _showSnackBar('Post created successfully');
      }

      if (mounted) Navigator.pop(context, true); // true = caller should refresh
    } catch (e) {
      setState(() => _isSaving = false);
      _showSnackBar('Error saving post: $e', isError: true);
    }
  }

  String _pad(int n) => n.toString().padLeft(2, '0');

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade700 : Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Post' : 'New Post'),
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.all(14),
              child: SizedBox(
                width: 20,
                height: 20,
                child:
                    CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
              ),
            )
          else
            TextButton(
              onPressed: _save,
              child: const Text('SAVE',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLabel('Title *'),
              _buildField(
                controller: _titleController,
                hint: 'Enter post title',
                maxLines: 2,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Title is required';
                  if (v.trim().length < 3) return 'Title is too short';
                  return null;
                },
              ),
              const SizedBox(height: 20),

              _buildLabel('Author *'),
              _buildField(
                controller: _authorController,
                hint: 'Enter author name',
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Author is required';
                  return null;
                },
              ),
              const SizedBox(height: 20),

              _buildLabel('Content *'),
              _buildField(
                controller: _bodyController,
                hint: 'Write your post content here...',
                maxLines: 10,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Content is required';
                  if (v.trim().length < 10) {
                    return 'Content must be at least 10 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),

              // Save Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A237E),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                      : Text(
                          _isEditing ? 'Save Changes' : 'Create Post',
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14,
          color: Color(0xFF2D3748),
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade400),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: Color(0xFF1A237E), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red.shade400),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}
