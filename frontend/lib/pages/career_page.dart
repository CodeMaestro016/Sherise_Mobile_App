import 'package:flutter/material.dart';
import '../services/api.dart';
import '../models/app_colors.dart';
import '../utils/validators.dart';

class CareerPage extends StatefulWidget {
  const CareerPage({super.key});

  @override
  State<CareerPage> createState() => _CareerPageState();
}

class _CareerPageState extends State<CareerPage> {
  List<Map<String, dynamic>> courses = [];
  Map<String, dynamic>? user;
  bool loading = true;
  bool showMine = true;
  final searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    setState(() => loading = true);
    try {
      user = await Api.loadSavedUser();
      courses = List<Map<String, dynamic>>.from(await Api.get('/courses'));
    } catch (e) {
      if (mounted)
        showMsg(context, e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> deleteCourse(int id) async {
    try {
      await Api.delete('/courses/$id');
      load();
    } catch (e) {
      if (mounted)
        showMsg(context, e.toString().replaceFirst('Exception: ', ''));
    }
  }

  @override
  Widget build(BuildContext context) {
    final keyword = searchController.text.trim().toLowerCase();
    final filtered = courses.where((course) {
      final mineOk = !showMine || course['owner_id'] == user?['id'];
      final searchOk = keyword.isEmpty ||
          (course['title'] ?? '').toString().toLowerCase().contains(keyword) ||
          (course['category'] ?? '').toString().toLowerCase().contains(keyword);
      return mineOk && searchOk;
    }).toList();

    return RefreshIndicator(
      onRefresh: load,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                  colors: [Color(0xFFD26CFF), Color(0xFFBF58E2)]),
              borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Career & Skills',
                    style: TextStyle(
                        fontSize: 28,
                        color: Colors.white,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                const Text('Unlock your potential',
                    style: TextStyle(color: Colors.white)),
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30)),
                  child: TextField(
                    controller: searchController,
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search),
                      hintText: 'search courses.......',
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                FilterChip(
                  selected: showMine,
                  label: const Text('My Courses'),
                  onSelected: (_) => setState(() => showMine = true),
                ),
                const SizedBox(width: 12),
                FilterChip(
                  selected: !showMine,
                  label: const Text('All Courses'),
                  onSelected: (_) => setState(() => showMine = false),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () async {
                    await Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const CourseFormPage()));
                    load();
                  },
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                        color: AppColors.purple,
                        borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.add, color: Colors.black),
                  ),
                ),
              ],
            ),
          ),
          if (loading)
            const Center(
                child: Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator())),
          ...filtered.map((course) => CourseCard(
                course: course,
                canEdit: course['owner_id'] == user?['id'],
                onEdit: () async {
                  await Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => CourseFormPage(initial: course)));
                  load();
                },
                onDelete: () => deleteCourse(course['id']),
              )),
          if (!loading && filtered.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Text('No courses found.', textAlign: TextAlign.center),
            ),
        ],
      ),
    );
  }
}

class CourseCard extends StatelessWidget {
  final Map<String, dynamic> course;
  final bool canEdit;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  const CourseCard(
      {super.key,
      required this.course,
      required this.canEdit,
      required this.onEdit,
      required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final imageUrl = (course['image_url'] ?? '').toString();
    final progress = ((course['progress'] ?? 0) as num).toDouble();
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.88),
          borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20)),
                child: imageUrl.isEmpty
                    ? Container(
                        height: 130,
                        color: Colors.grey.shade300,
                        child: const Center(child: Icon(Icons.image, size: 40)))
                    : Image.network(
                        imageUrl,
                        height: 130,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                            height: 130,
                            color: Colors.grey.shade300,
                            child:
                                const Center(child: Icon(Icons.broken_image))),
                      ),
              ),
              Positioned(
                top: 10,
                left: 12,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                      color: AppColors.purple,
                      borderRadius: BorderRadius.circular(12)),
                  child: Text(progress > 0 ? 'Enrolled' : 'New',
                      style:
                          const TextStyle(color: Colors.white, fontSize: 12)),
                ),
              ),
              if (canEdit)
                Positioned(
                  top: 10,
                  right: 8,
                  child: Row(
                    children: [
                      IconButton(
                          onPressed: onEdit,
                          icon: const Icon(Icons.edit_outlined),
                          style: IconButton.styleFrom(
                              backgroundColor: Colors.white70)),
                      IconButton(
                          onPressed: onDelete,
                          icon: const Icon(Icons.delete_outline),
                          style: IconButton.styleFrom(
                              backgroundColor: Colors.white70)),
                    ],
                  ),
                ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(course['title'] ?? '',
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                          color: const Color(0xFFE9A5DD),
                          borderRadius: BorderRadius.circular(12)),
                      child: Text(course['category'] ?? '',
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.purpleDark)),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(course['description'] ?? '',
                    maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.person_outline,
                        size: 16, color: Colors.black54),
                    const SizedBox(width: 4),
                    Expanded(
                        child: Text((course['instructor'] ?? '').toString(),
                            style: const TextStyle(color: Colors.black54))),
                    const Icon(Icons.access_time,
                        size: 16, color: Colors.black54),
                    const SizedBox(width: 4),
                    Text((course['duration'] ?? '').toString(),
                        style: const TextStyle(color: Colors.black54)),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Expanded(
                        child: Text('Progress',
                            style: TextStyle(fontWeight: FontWeight.w500))),
                    Text('${progress.toInt()}%'),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: LinearProgressIndicator(
                      value: progress / 100,
                      minHeight: 10,
                      backgroundColor: Colors.grey.shade300,
                      color: AppColors.purple),
                ),
                if (progress == 0)
                  Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: FilledButton(
                        onPressed: () => showMsg(
                            context, 'Enrollment flow can be connected next.'),
                        child: const Text('Enroll Now'),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class CourseFormPage extends StatefulWidget {
  final Map<String, dynamic>? initial;
  const CourseFormPage({super.key, this.initial});

  @override
  State<CourseFormPage> createState() => _CourseFormPageState();
}

class _CourseFormPageState extends State<CourseFormPage> {
  final formKey = GlobalKey<FormState>();
  late final titleController =
      TextEditingController(text: widget.initial?['title'] ?? '');
  late final descriptionController =
      TextEditingController(text: widget.initial?['description'] ?? '');
  late final instructorController =
      TextEditingController(text: widget.initial?['instructor'] ?? '');
  late final durationController =
      TextEditingController(text: widget.initial?['duration'] ?? '');
  late final categoryController =
      TextEditingController(text: widget.initial?['category'] ?? '');
  late final imageUrlController =
      TextEditingController(text: widget.initial?['image_url'] ?? '');
  late final progressController =
      TextEditingController(text: '${widget.initial?['progress'] ?? 0}');
  bool saving = false;

  Future<void> save() async {
    if (!formKey.currentState!.validate()) return;
    setState(() => saving = true);
    final data = {
      'title': titleController.text.trim(),
      'description': descriptionController.text.trim(),
      'instructor': instructorController.text.trim(),
      'duration': durationController.text.trim(),
      'category': categoryController.text.trim(),
      'image_url': imageUrlController.text.trim(),
      'progress': int.tryParse(progressController.text.trim()) ?? 0,
      'provider': 'SheRise Academy',
      'level': 'Beginner',
      'is_premium': false,
    };

    try {
      if (widget.initial == null) {
        await Api.post('/courses', data);
      } else {
        await Api.put('/courses/${widget.initial!['id']}', data);
      }
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (mounted)
        showMsg(context, e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.softPink,
      appBar: AppBar(
          leading: const BackButton(), backgroundColor: Colors.transparent),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 18),
        child: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              const Text('Course Title',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                    hintText: 'Course title',
                    border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              const Text('Description',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
              TextField(
                controller: descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(
                    hintText: 'Description',
                    border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              const Text('Instructor',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
              TextField(
                controller: instructorController,
                decoration: const InputDecoration(
                    hintText: 'Instructor',
                    border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        const Text('Duration',
                            style: TextStyle(
                                fontSize: 26, fontWeight: FontWeight.bold)),
                        TextField(
                            controller: durationController,
                            decoration: const InputDecoration(
                                hintText: '6 weeks',
                                border: OutlineInputBorder()))
                      ])),
                  const SizedBox(width: 12),
                  Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        const Text('Category',
                            style: TextStyle(
                                fontSize: 26, fontWeight: FontWeight.bold)),
                        TextField(
                            controller: categoryController,
                            decoration: const InputDecoration(
                                hintText: 'Leadership',
                                border: OutlineInputBorder()))
                      ])),
                ],
              ),
              const SizedBox(height: 12),
              const Text('Image URL',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
              TextField(
                controller: imageUrlController,
                decoration: const InputDecoration(
                    hintText: 'https://....',
                    border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              const Text('Progress (%)',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
              TextField(
                controller: progressController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                    hintText: '0',
                    border: OutlineInputBorder()),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                      child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'))),
                  const SizedBox(width: 16),
                  Expanded(
                    child: FilledButton(
                      onPressed: saving ? null : save,
                      child: Text(widget.initial == null
                          ? 'Create Course'
                          : 'Update Course'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 26),
            ],
          ),
        ),
      ),
    );
  }
}
