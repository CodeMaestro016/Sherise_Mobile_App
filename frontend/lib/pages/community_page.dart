import 'package:flutter/material.dart';
import '../services/api.dart';
import '../models/app_colors.dart';
import '../utils/validators.dart';

class CommunityPage extends StatefulWidget {
  const CommunityPage({super.key});

  @override
  State<CommunityPage> createState() => _CommunityPageState();
}

class _CommunityPageState extends State<CommunityPage> {
  bool loading = true;
  List<Map<String, dynamic>> posts = [];
  List<Map<String, dynamic>> mentors = [];
  bool showPosts = true;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    setState(() => loading = true);
    try {
      posts = List<Map<String, dynamic>>.from(await Api.get('/posts'));
      mentors = List<Map<String, dynamic>>.from(await Api.get('/mentors'));
    } catch (e) {
      if (mounted)
        showMsg(context, e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final list = showPosts ? posts : mentors;
    return Scaffold(
      backgroundColor: AppColors.softPink,
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.purple,
        onPressed: () async {
          if (showPosts) {
            await Navigator.push(context,
                MaterialPageRoute(builder: (_) => const PostFormPage()));
          } else {
            await Navigator.push(context,
                MaterialPageRoute(builder: (_) => const MentorFormPage()));
          }
          load();
        },
        child: const Icon(Icons.add, color: Colors.black),
      ),
      body: RefreshIndicator(
        onRefresh: load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              children: [
                Expanded(
                  child: ChoiceChip(
                      label: const Text('Community Posts'),
                      selected: showPosts,
                      onSelected: (_) => setState(() => showPosts = true)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ChoiceChip(
                      label: const Text('Mentors'),
                      selected: !showPosts,
                      onSelected: (_) => setState(() => showPosts = false)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (loading)
              const Center(
                  child: Padding(
                      padding: EdgeInsets.all(20),
                      child: CircularProgressIndicator())),
            ...list.map((item) {
              if (showPosts) {
                return CommunityPostCard(post: item, onChanged: load);
              }
              return MentorCard(mentor: item, onChanged: load);
            }),
          ],
        ),
      ),
    );
  }
}

class CommunityPostCard extends StatelessWidget {
  final Map<String, dynamic> post;
  final Future<void> Function() onChanged;
  const CommunityPostCard(
      {super.key, required this.post, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(child: Icon(Icons.person)),
                const SizedBox(width: 10),
                Expanded(
                    child: Text(post['title'] ?? '',
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold))),
                IconButton(
                    onPressed: () async {
                      await Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => PostFormPage(initial: post)));
                      await onChanged();
                    },
                    icon: const Icon(Icons.edit_outlined)),
                IconButton(
                  onPressed: () async {
                    try {
                      await Api.delete('/posts/${post['id']}');
                      await onChanged();
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text(e
                                  .toString()
                                  .replaceFirst('Exception: ', ''))),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),
            Text(post['category'] ?? '',
                style: const TextStyle(color: AppColors.purple)),
            const SizedBox(height: 8),
            Text(post['content'] ?? ''),
          ],
        ),
      ),
    );
  }
}

class MentorCard extends StatelessWidget {
  final Map<String, dynamic> mentor;
  final Future<void> Function() onChanged;
  const MentorCard({super.key, required this.mentor, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: const CircleAvatar(child: Icon(Icons.school)),
        title: Text(mentor['name'] ?? ''),
        subtitle:
            Text('${mentor['expertise'] ?? ''}\n${mentor['email'] ?? ''}'),
        isThreeLine: true,
        trailing: SizedBox(
          width: 76,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: () async {
                  await Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) =>
                              MentorFormPage(initial: mentor)));
                  await onChanged();
                },
                icon: const Icon(Icons.edit_outlined),
                iconSize: 20,
                padding: EdgeInsets.zero,
                constraints:
                    const BoxConstraints(minWidth: 32, minHeight: 32),
                visualDensity: VisualDensity.compact,
              ),
              IconButton(
                onPressed: () async {
                  try {
                    await Api.delete('/mentors/${mentor['id']}');
                    await onChanged();
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text(e
                                .toString()
                                .replaceFirst('Exception: ', ''))),
                      );
                    }
                  }
                },
                icon: const Icon(Icons.delete_outline),
                iconSize: 20,
                padding: EdgeInsets.zero,
                constraints:
                    const BoxConstraints(minWidth: 32, minHeight: 32),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PostFormPage extends StatefulWidget {
  final Map<String, dynamic>? initial;
  const PostFormPage({super.key, this.initial});

  @override
  State<PostFormPage> createState() => _PostFormPageState();
}

class _PostFormPageState extends State<PostFormPage> {
  final formKey = GlobalKey<FormState>();
  late final titleController =
      TextEditingController(text: widget.initial?['title'] ?? '');
  late final categoryController =
      TextEditingController(text: widget.initial?['category'] ?? '');
  late final contentController =
      TextEditingController(text: widget.initial?['content'] ?? '');

  Future<void> save() async {
    if (!formKey.currentState!.validate()) return;
    final data = {
      'title': titleController.text.trim(),
      'category': categoryController.text.trim().isEmpty
          ? 'General'
          : categoryController.text.trim(),
      'content': contentController.text.trim(),
    };
    try {
      if (widget.initial == null) {
        await Api.post('/posts', data);
      } else {
        await Api.put('/posts/${widget.initial!['id']}', data);
      }
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (mounted)
        showMsg(context, e.toString().replaceFirst('Exception: ', ''));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text(widget.initial == null ? 'Create Post' : 'Update Post')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: formKey,
          child: Column(
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                    labelText: 'Title', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: categoryController,
                decoration: const InputDecoration(
                    labelText: 'Category', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: contentController,
                maxLines: 5,
                decoration: const InputDecoration(
                    labelText: 'Content', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                      onPressed: save,
                      child: Text(widget.initial == null
                          ? 'Create Post'
                          : 'Update Post'))),
            ],
          ),
        ),
      ),
    );
  }
}

class MentorFormPage extends StatefulWidget {
  final Map<String, dynamic>? initial;
  const MentorFormPage({super.key, this.initial});

  @override
  State<MentorFormPage> createState() => _MentorFormPageState();
}

class _MentorFormPageState extends State<MentorFormPage> {
  final formKey = GlobalKey<FormState>();
  late final nameController =
      TextEditingController(text: widget.initial?['name'] ?? '');
  late final expertiseController =
      TextEditingController(text: widget.initial?['expertise'] ?? '');
  late final emailController =
      TextEditingController(text: widget.initial?['email'] ?? '');
  late final phoneController =
      TextEditingController(text: widget.initial?['phone'] ?? '');
  late final availabilityController =
      TextEditingController(text: widget.initial?['availability'] ?? '');
  late final descriptionController =
      TextEditingController(text: widget.initial?['description'] ?? '');

  Future<void> save() async {
    if (!formKey.currentState!.validate()) return;
    final data = {
      'name': nameController.text.trim(),
      'expertise': expertiseController.text.trim(),
      'email': emailController.text.trim(),
      'phone': phoneController.text.trim(),
      'availability': availabilityController.text.trim().isEmpty
          ? 'Weekdays'
          : availabilityController.text.trim(),
      'description': descriptionController.text.trim(),
    };
    try {
      if (widget.initial == null) {
        await Api.post('/mentors', data);
      } else {
        await Api.put('/mentors/${widget.initial!['id']}', data);
      }
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (mounted)
        showMsg(context, e.toString().replaceFirst('Exception: ', ''));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text(widget.initial == null ? 'Add Mentor' : 'Update Mentor')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: formKey,
          child: Column(
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                    labelText: 'Mentor Name',
                    border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: expertiseController,
                decoration: const InputDecoration(
                    labelText: 'Expertise', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                    labelText: 'Email', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                    labelText: 'Phone', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: availabilityController,
                decoration: const InputDecoration(
                    labelText: 'Availability',
                    border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descriptionController,
                maxLines: 4,
                decoration: const InputDecoration(
                    labelText: 'Description', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                      onPressed: save,
                      child: Text(widget.initial == null
                          ? 'Create Mentor'
                          : 'Update Mentor'))),
            ],
          ),
        ),
      ),
    );
  }
}
