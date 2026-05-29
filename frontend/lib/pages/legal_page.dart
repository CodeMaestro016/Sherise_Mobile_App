import 'package:flutter/material.dart';
import '../services/api.dart';
import '../models/app_colors.dart';
import '../utils/validators.dart';

class LegalPage extends StatefulWidget {
  const LegalPage({super.key});

  @override
  State<LegalPage> createState() => _LegalPageState();
}

class _LegalPageState extends State<LegalPage> {
  List<Map<String, dynamic>> rights = [];
  List<Map<String, dynamic>> complaints = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    setState(() => loading = true);
    try {
      rights = List<Map<String, dynamic>>.from(
          await Api.get('/complaints/legal-rights'));
      complaints =
          List<Map<String, dynamic>>.from(await Api.get('/complaints'));
    } catch (e) {
      if (mounted)
        showMsg(context, e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.softPink,
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.purple,
        onPressed: () async {
          await Navigator.push(context,
              MaterialPageRoute(builder: (_) => const ComplaintFormPage()));
          load();
        },
        child: const Icon(Icons.add, color: Colors.black),
      ),
      body: RefreshIndicator(
        onRefresh: load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text('Legal Rights',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            ...rights.map((right) => Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    leading: const Icon(Icons.verified_user_outlined,
                        color: AppColors.purple),
                    title: Text(right['title'] ?? ''),
                    subtitle: Text(right['description'] ?? ''),
                  ),
                )),
            const SizedBox(height: 18),
            const Text('Complaints',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            if (loading) const Center(child: CircularProgressIndicator()),
            ...complaints.map((complaint) => Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    title: Text(complaint['subject'] ?? ''),
                    subtitle: Text(
                        '${complaint['complaint_type'] ?? ''} • ${complaint['status'] ?? ''}\n${complaint['description'] ?? ''}'),
                    isThreeLine: true,
                    trailing: Wrap(
                      children: [
                        IconButton(
                            onPressed: () async {
                              await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => ComplaintFormPage(
                                          initial: complaint)));
                              load();
                            },
                            icon: const Icon(Icons.edit_outlined)),
                        IconButton(
                            onPressed: () async {
                              try {
                                await Api.delete(
                                    '/complaints/${complaint['id']}');
                                load();
                              } catch (e) {
                                if (mounted)
                                  showMsg(
                                      context,
                                      e
                                          .toString()
                                          .replaceFirst('Exception: ', ''));
                              }
                            },
                            icon: const Icon(Icons.delete_outline)),
                      ],
                    ),
                  ),
                )),
            if (!loading && complaints.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Text(
                  'No complaints filed yet.',
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class ComplaintFormPage extends StatefulWidget {
  final Map<String, dynamic>? initial;
  const ComplaintFormPage({super.key, this.initial});

  @override
  State<ComplaintFormPage> createState() => _ComplaintFormPageState();
}

class _ComplaintFormPageState extends State<ComplaintFormPage> {
  final formKey = GlobalKey<FormState>();
  late final subjectController =
      TextEditingController(text: widget.initial?['subject'] ?? '');
  late final descriptionController =
      TextEditingController(text: widget.initial?['description'] ?? '');
  late final complaintTypeController = TextEditingController(
      text: widget.initial?['complaint_type'] ?? 'Harassment');
  bool saving = false;

  Future<void> save() async {
    if (!formKey.currentState!.validate()) return;
    setState(() => saving = true);
    final data = {
      'subject': subjectController.text.trim(),
      'description': descriptionController.text.trim(),
      'complaint_type': complaintTypeController.text.trim(),
      'status': widget.initial?['status'] ?? 'Pending',
    };
    try {
      if (widget.initial == null) {
        await Api.post('/complaints', data);
      } else {
        await Api.put('/complaints/${widget.initial!['id']}', data);
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
          backgroundColor: Colors.transparent,
          title: const Text('File a Complaint')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Complaint Type',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: complaintTypeController.text.isEmpty
                    ? 'Harassment'
                    : complaintTypeController.text,
                items: ['Harassment', 'Discrimination', 'Abuse', 'Other']
                    .map((type) => DropdownMenuItem(
                          value: type,
                          child: Text(type),
                        ))
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    complaintTypeController.text = value;
                  }
                },
                decoration: const InputDecoration(border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              const Text('Subject',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              TextField(
                controller: subjectController,
                decoration: const InputDecoration(
                    hintText: 'Brief subject of complaint',
                    border: OutlineInputBorder()),
                validator: (value) => requiredValidator(value),
              ),
              const SizedBox(height: 16),
              const Text('Description',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              TextField(
                controller: descriptionController,
                maxLines: 6,
                decoration: const InputDecoration(
                    hintText: 'Provide detailed description of the incident',
                    border: OutlineInputBorder()),
                validator: (value) => requiredValidator(value, min: 20),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                      child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'))),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: saving ? null : save,
                      child: Text(widget.initial == null
                          ? 'File Complaint'
                          : 'Update Complaint'),
                    ),
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
