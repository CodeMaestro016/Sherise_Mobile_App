import 'package:flutter/material.dart';
import '../services/api.dart';
import '../models/app_colors.dart';
import '../utils/validators.dart';

class SafetyPage extends StatefulWidget {
  const SafetyPage({super.key});

  @override
  State<SafetyPage> createState() => _SafetyPageState();
}

class _SafetyPageState extends State<SafetyPage> {
  List<Map<String, dynamic>> emergencyContacts = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    setState(() => loading = true);
    try {
      emergencyContacts = List<Map<String, dynamic>>.from(
          await Api.get('/emergency-contacts'));
    } catch (e) {
      if (mounted)
        showMsg(context, e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> deleteContact(int id) async {
    try {
      await Api.delete('/emergency-contacts/$id');
      load();
    } catch (e) {
      if (mounted)
        showMsg(context, e.toString().replaceFirst('Exception: ', ''));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.safetyGreen,
        onPressed: () async {
          await Navigator.push(context,
              MaterialPageRoute(builder: (_) => const EmergencyContactFormPage()));
          load();
        },
        child: const Icon(Icons.add, color: Colors.black),
      ),
      body: RefreshIndicator(
        onRefresh: load,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            SafetyTopButton(onTap: () {
              showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                        title: const Text('Activate SOS?'),
                        content: const Text(
                            'This will immediately alert your emergency contacts.'),
                        actions: [
                          TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Cancel')),
                          TextButton(
                              onPressed: () async {
                                try {
                                  await Api.post('/sos', {});
                                  if (mounted) Navigator.pop(context);
                                  if (mounted)
                                    showMsg(context,
                                        'SOS alert sent to your emergency contacts!');
                                } catch (e) {
                                  if (mounted)
                                    showMsg(
                                        context,
                                        e
                                            .toString()
                                            .replaceFirst('Exception: ', ''));
                                }
                              },
                              child: const Text('Send SOS')),
                        ],
                      ));
            }),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Emergency Contacts',
                      style: TextStyle(
                          fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  if (loading)
                    const Center(
                        child: Padding(
                            padding: EdgeInsets.all(16),
                            child: CircularProgressIndicator())),
                  ...emergencyContacts.map((contact) =>
                      EmergencyContactCard(
                          contact: contact,
                          onDelete: () => deleteContact(contact['id']),
                          onEdit: () async {
                            await Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) =>
                                        EmergencyContactFormPage(
                                            initial: contact)));
                            load();
                          })),
                  if (!loading && emergencyContacts.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Text(
                        'No emergency contacts yet. Add one to stay safe.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                ],
              ),
            ),
            const Divider(height: 40),
            Container(
              padding: const EdgeInsets.all(16),
              child: GestureDetector(
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const SafetyTipsPage())),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                      color: AppColors.safetyGreen,
                      borderRadius: BorderRadius.circular(16)),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.white, size: 28),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'View Safety Tips & Resources',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                      Icon(Icons.arrow_forward,
                          color: Colors.white, size: 24),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class SafetyTopButton extends StatelessWidget {
  final VoidCallback onTap;
  const SafetyTopButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        padding: const EdgeInsets.symmetric(vertical: 32),
        decoration: BoxDecoration(
            color: Colors.red.shade400,
            borderRadius: BorderRadius.circular(16)),
        child: const Column(
          children: [
            Icon(Icons.emergency_share, size: 48, color: Colors.white),
            SizedBox(height: 16),
            Text('Emergency Signal',
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white)),
            SizedBox(height: 6),
            Text('Activate SOS',
                style: TextStyle(color: Colors.white70, fontSize: 14)),
          ],
        ),
      ),
    );
  }
}

class EmergencyContactCard extends StatelessWidget {
  final Map<String, dynamic> contact;
  final VoidCallback onDelete;
  final VoidCallback onEdit;
  const EmergencyContactCard(
      {super.key,
      required this.contact,
      required this.onDelete,
      required this.onEdit});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.safetyGreen.withOpacity(0.2),
          child: const Icon(Icons.contact_phone,
              color: AppColors.safetyGreen),
        ),
        title: Text(contact['name'] ?? ''),
        subtitle: Text(contact['relationship'] ?? ''),
        trailing: SizedBox(
          width: 100,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined),
                  iconSize: 20),
              IconButton(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline),
                  iconSize: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class EmergencyContactFormPage extends StatefulWidget {
  final Map<String, dynamic>? initial;
  const EmergencyContactFormPage({super.key, this.initial});

  @override
  State<EmergencyContactFormPage> createState() =>
      _EmergencyContactFormPageState();
}

class _EmergencyContactFormPageState extends State<EmergencyContactFormPage> {
  final formKey = GlobalKey<FormState>();
  late final nameController =
      TextEditingController(text: widget.initial?['name'] ?? '');
  late final relationshipController =
      TextEditingController(text: widget.initial?['relationship'] ?? '');
  late final phoneController =
      TextEditingController(text: widget.initial?['phone'] ?? '');
  bool saving = false;

  Future<void> save() async {
    if (!formKey.currentState!.validate()) return;
    setState(() => saving = true);
    final data = {
      'name': nameController.text.trim(),
      'relationship': relationshipController.text.trim(),
      'phone': phoneController.text.trim(),
    };
    try {
      if (widget.initial == null) {
        await Api.post('/emergency-contacts', data);
      } else {
        await Api.put('/emergency-contacts/${widget.initial!['id']}', data);
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
      appBar: AppBar(
          title: Text(widget.initial == null
              ? 'Add Emergency Contact'
              : 'Update Contact')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: formKey,
          child: Column(
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                    labelText: 'Full Name', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: relationshipController,
                decoration: const InputDecoration(
                    labelText: 'Relationship',
                    border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                    labelText: 'Phone Number',
                    border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                    onPressed: saving ? null : save,
                    child: Text(widget.initial == null
                        ? 'Add Contact'
                        : 'Update Contact')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SafetyTipsPage extends StatelessWidget {
  const SafetyTipsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
          backgroundColor: AppColors.safetyGreen,
          foregroundColor: Colors.white),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 22),
            decoration: const BoxDecoration(
              color: AppColors.safetyGreen,
              borderRadius: BorderRadius.all(Radius.circular(24)),
            ),
            child: const Center(
              child: Text(
                'Stay safe with these important guidelines',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
            ),
          ),
          const SizedBox(height: 14),
          const SafetyTipCard(
              icon: Icons.verified_user_outlined,
              title: 'Stay Connected',
              description:
                  'Always keep your phone charged and share your location with trusted contacts when going out.'),
          const SafetyTipCard(
              icon: Icons.groups_outlined,
              title: 'Trust Your Instincts',
              description:
                  'If a situation feels wrong, remove yourself immediately. Your intuition is a powerful safety tool.'),
          const SafetyTipCard(
              icon: Icons.location_on_outlined,
              title: 'Safe Transportation',
              description:
                  'Use verified transportation services, share trip details with friends, and sit in the back seat.'),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: AppColors.deepPink,
                borderRadius: BorderRadius.circular(24)),
            child: Column(
              children: const [
                Text('Important Numbers',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                SizedBox(height: 12),
                SafetyNumberRow(label: 'Emergency Services', number: '912'),
                SafetyNumberRow(label: 'Women\'s Helpline', number: '199'),
                SafetyNumberRow(label: 'Domestic Violence', number: '1912'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class SafetyTipCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  const SafetyTipCard(
      {super.key,
      required this.icon,
      required this.title,
      required this.description});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.black54)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
                color: const Color(0xFFBDECC7),
                borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, size: 28),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Text(description,
                    style: const TextStyle(fontSize: 16, height: 1.35)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class SafetyNumberRow extends StatelessWidget {
  final String label;
  final String number;
  const SafetyNumberRow({super.key, required this.label, required this.number});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                  color: const Color(0xFFF79AC1),
                  borderRadius: BorderRadius.circular(16)),
              child: Text(label, style: const TextStyle(fontSize: 16)),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 90,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(16)),
            alignment: Alignment.center,
            child: Text(number,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
