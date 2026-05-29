import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api.dart';
import '../models/app_colors.dart';
import '../utils/validators.dart';
import 'home_page.dart';
import 'safety_page.dart';
import 'career_page.dart';
import 'community_page.dart';
import 'legal_page.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int index = 0;
  Map<String, dynamic>? currentUser;

  final titles = const [
    'Home',
    'Safety & Emergency',
    'Career & Skills',
    'Community',
    'Legal Help'
  ];

  @override
  void initState() {
    super.initState();
    loadUser();
  }

  Future<void> loadUser() async {
    final savedUser = await Api.loadSavedUser() ?? {};
    Map<String, dynamic> mergedUser = Map<String, dynamic>.from(savedUser);
    try {
      final profile = Map<String, dynamic>.from(await Api.get('/profile'));
      mergedUser = {
        ...savedUser,
        'name': profile['full_name'] ?? savedUser['name'],
        'full_name': profile['full_name'],
        'phone': profile['phone'],
        'address': profile['address'],
        'occupation': profile['occupation'],
        'bio': profile['bio'],
        'profile_photo': profile['profile_photo'],
      };
      await Api.saveUser(mergedUser);
    } catch (_) {
      if (savedUser.isNotEmpty) {
        mergedUser = Map<String, dynamic>.from(savedUser);
      }
    }
    currentUser = mergedUser.isEmpty ? null : mergedUser;
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomePage(
          onNavigate: (i) => setState(() => index = i),
          currentUser: currentUser),
      const SafetyPage(),
      const CareerPage(),
      const CommunityPage(),
      const LegalPage(),
    ];
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black.withOpacity(0.06),
        title: Text(titles[index]),
        centerTitle: true,
        actions: [
          IconButton(
            icon: CircleAvatar(
              radius: 14,
              backgroundColor: Colors.white,
              backgroundImage: currentUser?['profile_photo'] != null
                  ? NetworkImage(currentUser!['profile_photo'])
                  : null,
              child: currentUser?['profile_photo'] == null
                  ? const Icon(Icons.person, size: 16)
                  : null,
            ),
            onPressed: () async {
              await Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const ProfilePage()));
              loadUser();
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await Api.logout();
              if (!mounted) return;
              // Note: Import LoginPage from auth pages
              // Navigator.pushAndRemoveUntil(
              //     context,
              //     MaterialPageRoute(builder: (_) => const LoginPage()),
              //     (_) => false);
            },
          ),
        ],
      ),
      body: IndexedStack(index: index, children: pages),
      bottomNavigationBar: Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        padding: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
                color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))
          ],
        ),
        child: NavigationBar(
          backgroundColor: Colors.transparent,
          indicatorColor: const Color(0xFFE6CAE8),
          selectedIndex: index,
          onDestinationSelected: (value) => setState(() => index = value),
          destinations: const [
            NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home),
                label: 'Home'),
            NavigationDestination(
                icon: Icon(Icons.verified_user_outlined),
                selectedIcon: Icon(Icons.verified_user),
                label: 'Safety'),
            NavigationDestination(
                icon: Icon(Icons.cast_for_education_outlined),
                selectedIcon: Icon(Icons.cast_for_education),
                label: 'Career'),
            NavigationDestination(
                icon: Icon(Icons.groups_outlined),
                selectedIcon: Icon(Icons.groups),
                label: 'Community'),
            NavigationDestination(
                icon: Icon(Icons.balance_outlined),
                selectedIcon: Icon(Icons.balance),
                label: 'Legal'),
          ],
        ),
      ),
    );
  }
}

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Map<String, dynamic>? profile;
  bool loading = true;
  final picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    setState(() => loading = true);
    try {
      profile = Map<String, dynamic>.from(await Api.get('/profile'));
    } catch (e) {
      if (mounted)
        showMsg(context, e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> pickUpload() async {
    final img = await picker.pickImage(
        source: ImageSource.gallery, imageQuality: 80, maxWidth: 900);
    if (img == null) return;
    try {
      await Api.uploadProfilePhoto(img);
      await load();
      if (mounted) showMsg(context, 'Profile picture updated');
    } catch (e) {
      if (mounted)
        showMsg(context, e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> deletePhoto() async {
    try {
      await Api.delete('/profile/photo');
      await load();
      if (mounted) showMsg(context, 'Profile picture removed');
    } catch (e) {
      if (mounted)
        showMsg(context, e.toString().replaceFirst('Exception: ', ''));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading)
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final p = profile ?? {};
    return Scaffold(
      backgroundColor: AppColors.softPink,
      appBar: AppBar(title: const Text('Profile')),
      body: RefreshIndicator(
        onRefresh: load,
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            Center(
              child: CircleAvatar(
                radius: 58,
                backgroundColor: Colors.white,
                backgroundImage: p['profile_photo'] != null
                    ? NetworkImage(p['profile_photo'])
                    : null,
                child: p['profile_photo'] == null
                    ? const Icon(Icons.person,
                        size: 62, color: AppColors.purple)
                    : null,
              ),
            ),
            const SizedBox(height: 14),
            Center(
                child: Text(p['full_name'] ?? '',
                    style: const TextStyle(
                        fontSize: 28, fontWeight: FontWeight.bold))),
            Center(
                child: Text(p['occupation'] ?? '',
                    style:
                        const TextStyle(color: Colors.black54, fontSize: 16))),
            const SizedBox(height: 18),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                    onPressed: pickUpload,
                    icon: const Icon(Icons.add_a_photo),
                    label: const Text('Add / Update Photo')),
                OutlinedButton.icon(
                    onPressed: p['profile_photo'] == null ? null : deletePhoto,
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Delete Photo')),
                FilledButton.tonalIcon(
                  onPressed: () async {
                    await Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => EditProfilePage(initial: p)));
                    load();
                  },
                  icon: const Icon(Icons.edit),
                  label: const Text('Edit Profile'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            InfoCard(
                icon: Icons.phone, title: 'Phone', value: p['phone'] ?? ''),
            InfoCard(
                icon: Icons.location_on_outlined,
                title: 'Address',
                value: p['address'] ?? ''),
            InfoCard(
                icon: Icons.badge_outlined,
                title: 'Occupation',
                value: p['occupation'] ?? ''),
            InfoCard(
                icon: Icons.info_outline, title: 'Bio', value: p['bio'] ?? ''),
          ],
        ),
      ),
    );
  }
}

class EditProfilePage extends StatefulWidget {
  final Map<String, dynamic> initial;
  const EditProfilePage({super.key, required this.initial});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final formKey = GlobalKey<FormState>();
  late final nameController =
      TextEditingController(text: widget.initial['full_name'] ?? '');
  late final phoneController =
      TextEditingController(text: widget.initial['phone'] ?? '');
  late final addressController =
      TextEditingController(text: widget.initial['address'] ?? '');
  late final occupationController =
      TextEditingController(text: widget.initial['occupation'] ?? '');
  late final bioController =
      TextEditingController(text: widget.initial['bio'] ?? '');
  bool saving = false;

  Future<void> save() async {
    if (!formKey.currentState!.validate()) return;
    setState(() => saving = true);
    try {
      await Api.put('/profile', {
        'full_name': nameController.text.trim(),
        'phone': phoneController.text.trim(),
        'address': addressController.text.trim(),
        'occupation': occupationController.text.trim(),
        'bio': bioController.text.trim(),
      });
      if (!mounted) return;
      showMsg(context, 'Profile updated');
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
      appBar: AppBar(title: const Text('Edit Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Form(
          key: formKey,
          child: Column(
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                    labelText: 'Full Name',
                    border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                    labelText: 'Phone',
                    border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: addressController,
                decoration: const InputDecoration(
                    labelText: 'Address',
                    border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: occupationController,
                decoration: const InputDecoration(
                    labelText: 'Occupation',
                    border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: bioController,
                maxLines: 4,
                decoration: const InputDecoration(
                    labelText: 'Bio',
                    border: OutlineInputBorder()),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: saving ? null : save,
                  child: saving
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Update Profile'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  const InfoCard(
      {super.key,
      required this.icon,
      required this.title,
      required this.value});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon, color: AppColors.purple),
        title: Text(title),
        subtitle: Text(value.isEmpty ? '-' : value),
      ),
    );
  }
}
