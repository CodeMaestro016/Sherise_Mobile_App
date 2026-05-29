import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

const apiBase = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: kIsWeb
      ? 'http://localhost:8000'
      : 'https://sherise-mobile-app.onrender.com',
);

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SheRiseApp());
}

class SheRiseApp extends StatelessWidget {
  const SheRiseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SheRise',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF8D8EC),
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFA327E6)),
        fontFamily: 'serif',
      ),
      home: const SplashPage(),
    );
  }
}

class AppColors {
  static const pinkBg = Color(0xFFF4D0E4);
  static const softPink = Color(0xFFFFF6FB);
  static const purple = Color(0xFFA327E6);
  static const purpleDark = Color(0xFF5D0C7A);
  static const deepPink = Color(0xFFC8145B);
  static const safetyGreen = Color(0xFF78E19A);
  static const redOrange = Color(0xFFD24D2D);
  static const homeCardPink = Color(0xFFF4C4C8);
  static const homeCardPurple = Color(0xFFD4B8E5);
  static const homeCardLilac = Color(0xFFD5A0C6);
  static const homeCardMint = Color(0xFFA6E4E3);
}

class Api {
  static String? token;

  static Map<String, String> get headers => {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

  static Future<void> loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    token = prefs.getString('token');
  }

  static Future<void> saveAuth(
      String authToken, Map<String, dynamic> user) async {
    token = authToken;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', authToken);
    await prefs.setString('user', jsonEncode(user));
  }

  static Future<Map<String, dynamic>?> loadSavedUser() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('user');
    if (raw == null) return null;
    return Map<String, dynamic>.from(jsonDecode(raw));
  }

  static Future<void> saveUser(Map<String, dynamic> user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user', jsonEncode(user));
  }

  static Future<void> logout() async {
    token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('user');
  }

  static dynamic _decode(http.Response response) {
    final body = response.body.isEmpty ? null : jsonDecode(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) return body;
    final msg = body is Map && body['detail'] != null
        ? body['detail'].toString()
        : 'Request failed';
    throw Exception(msg);
  }

  static Future<dynamic> get(String path) async => _decode(
        await http.get(Uri.parse('$apiBase$path'), headers: headers),
      );

  static Future<dynamic> post(String path, Map<String, dynamic> data) async =>
      _decode(
        await http.post(Uri.parse('$apiBase$path'),
            headers: headers, body: jsonEncode(data)),
      );

  static Future<dynamic> put(String path, Map<String, dynamic> data) async =>
      _decode(
        await http.put(Uri.parse('$apiBase$path'),
            headers: headers, body: jsonEncode(data)),
      );

  static Future<dynamic> delete(String path) async => _decode(
        await http.delete(Uri.parse('$apiBase$path'), headers: headers),
      );

  static Future<dynamic> uploadProfilePhoto(XFile image) async {
    final bytes = await image.readAsBytes();
    final req =
        http.MultipartRequest('POST', Uri.parse('$apiBase/profile/photo'));
    if (token != null) req.headers['Authorization'] = 'Bearer $token';
    req.files
        .add(http.MultipartFile.fromBytes('file', bytes, filename: image.name));
    final res = await req.send();
    return _decode(await http.Response.fromStream(res));
  }
}

void showMsg(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message)),
  );
}

String? requiredValidator(String? value, {int min = 2}) {
  if (value == null || value.trim().isEmpty) return 'Required';
  if (value.trim().length < min) return 'Minimum $min characters';
  return null;
}

String? emailValidator(String? value) {
  if (value == null || value.trim().isEmpty) return 'Email is required';
  final ok = RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(value.trim());
  return ok ? null : 'Enter a valid email';
}

String? phoneValidator(String? value) {
  if (value == null || value.trim().isEmpty) return 'Phone number is required';
  return RegExp(r'^[0-9+()\-\s]{7,20}$').hasMatch(value.trim())
      ? null
      : 'Enter a valid phone number';
}

class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF28CCB), Color(0xFFB878D6)],
          ),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: Opacity(
                opacity: 0.22,
                child: CustomPaint(painter: WavyPainter()),
              ),
            ),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'SheRise',
                    style: TextStyle(
                        fontSize: 54,
                        fontWeight: FontWeight.w700,
                        color: AppColors.purpleDark),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Empower Women, Inspire Change',
                    style: TextStyle(fontSize: 20, color: Colors.black87),
                  ),
                  const SizedBox(height: 170),
                  GestureDetector(
                    onTap: () async {
                      await Api.loadToken();
                      if (!context.mounted) return;
                      Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const AuthGatePage()));
                    },
                    child: Container(
                      width: 280,
                      height: 58,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        gradient: const LinearGradient(
                            colors: [Color(0xFFC113A0), Color(0xFF3115A9)]),
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        'continue',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w500),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class WavyPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..color = Colors.white70;

    for (double y = 60; y < size.height; y += 90) {
      final path = Path()..moveTo(0, y);
      for (double x = 0; x <= size.width; x += 40) {
        path.quadraticBezierTo(x + 20, y - 25, x + 40, y);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class AuthGatePage extends StatefulWidget {
  const AuthGatePage({super.key});

  @override
  State<AuthGatePage> createState() => _AuthGatePageState();
}

class _AuthGatePageState extends State<AuthGatePage> {
  bool loading = true;

  @override
  void initState() {
    super.initState();
    Future(() async {
      await Api.loadToken();
      if (mounted) setState(() => loading = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Api.token == null ? const LoginPage() : const MainShell();
  }
}

class AuthScaffold extends StatelessWidget {
  final Widget child;
  const AuthScaffold({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white,
                      const Color(0xFFFFF4FB),
                      Colors.white.withOpacity(0.96)
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              top: -30,
              right: -30,
              child: Container(
                width: 160,
                height: 160,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                      colors: [Color(0xFFFFB2DA), Colors.transparent]),
                ),
              ),
            ),
            SafeArea(child: child),
          ],
        ),
      ),
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool loading = false;
  bool obscure = true;

  Future<void> login() async {
    if (!formKey.currentState!.validate()) return;
    setState(() => loading = true);
    try {
      final res = await Api.post('/auth/login', {
        'email': emailController.text.trim(),
        'password': passwordController.text,
      });
      await Api.saveAuth(
          res['access_token'], Map<String, dynamic>.from(res['user']));
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(context,
          MaterialPageRoute(builder: (_) => const MainShell()), (_) => false);
    } catch (e) {
      if (mounted)
        showMsg(context, e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Form(
              key: formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 48),
                  const Text('Login',
                      style:
                          TextStyle(fontSize: 46, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Text(
                        'Don’t have an account? ',
                        style: TextStyle(
                            fontSize: 18, color: Colors.grey.shade700),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const RegisterPage())),
                        child: const Text('sign up',
                            style: TextStyle(
                                fontSize: 18,
                                color: AppColors.purple,
                                fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 34),
                  RoundedField(
                    controller: emailController,
                    hintText: 'Email',
                    validator: emailValidator,
                  ),
                  const SizedBox(height: 28),
                  RoundedField(
                    controller: passwordController,
                    hintText: 'password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    obscureText: obscure,
                    validator: (value) => requiredValidator(value, min: 6),
                    suffix: TextButton(
                        onPressed: () => showMsg(
                            context, 'Forgot password flow can be added next.'),
                        child: const Text('FORGOT')),
                  ),
                  const SizedBox(height: 34),
                  Align(
                    alignment: Alignment.centerRight,
                    child: GestureDetector(
                      onTap: loading ? null : login,
                      child: Container(
                        width: 190,
                        height: 74,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(36),
                          gradient: const LinearGradient(
                              colors: [Color(0xFFE78AF0), Color(0xFF6F236E)]),
                        ),
                        alignment: Alignment.center,
                        child: loading
                            ? const SizedBox(
                                width: 28,
                                height: 28,
                                child: CircularProgressIndicator(
                                    color: Colors.white))
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text('Sign In',
                                      style: TextStyle(
                                          fontSize: 22,
                                          color: Colors.black,
                                          fontWeight: FontWeight.w600)),
                                  SizedBox(width: 8),
                                  Icon(Icons.arrow_forward,
                                      color: Colors.black),
                                ],
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool loading = false;

  Future<void> register() async {
    if (!formKey.currentState!.validate()) return;
    setState(() => loading = true);
    try {
      await Api.post('/auth/register', {
        'name': nameController.text.trim(),
        'email': emailController.text.trim(),
        'password': passwordController.text.trim(),
      });
      if (!mounted) return;
      showMsg(context, 'Account created. Please sign in.');
      Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginPage()),
          (_) => false);
    } catch (e) {
      if (mounted)
        showMsg(context, e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Form(
              key: formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 30),
                  const Text('Create Account',
                      style:
                          TextStyle(fontSize: 46, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Text('Already have an account? ',
                          style: TextStyle(
                              fontSize: 18, color: Colors.grey.shade700)),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: const Text('Sign In',
                            style: TextStyle(
                                fontSize: 18,
                                color: AppColors.purple,
                                fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 34),
                  RoundedField(
                      controller: nameController,
                      hintText: 'Name',
                      validator: requiredValidator),
                  const SizedBox(height: 26),
                  RoundedField(
                      controller: emailController,
                      hintText: 'Email or phone',
                      validator: emailValidator),
                  const SizedBox(height: 26),
                  RoundedField(
                      controller: passwordController,
                      hintText: 'Password',
                      obscureText: true,
                      validator: (value) => requiredValidator(value, min: 6)),
                  const SizedBox(height: 46),
                  Align(
                    alignment: Alignment.centerRight,
                    child: GestureDetector(
                      onTap: loading ? null : register,
                      child: Container(
                        width: 190,
                        height: 74,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(36),
                          gradient: const LinearGradient(
                              colors: [Color(0xFFE78AF0), Color(0xFF6F236E)]),
                        ),
                        alignment: Alignment.center,
                        child: loading
                            ? const SizedBox(
                                width: 28,
                                height: 28,
                                child: CircularProgressIndicator(
                                    color: Colors.white))
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text('Sign Up',
                                      style: TextStyle(
                                          fontSize: 22,
                                          color: Colors.black,
                                          fontWeight: FontWeight.w600)),
                                  SizedBox(width: 6),
                                  Icon(Icons.arrow_forward,
                                      color: Colors.black),
                                ],
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class RoundedField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final String? Function(String?)? validator;
  final bool obscureText;
  final Widget? prefixIcon;
  final Widget? suffix;
  const RoundedField({
    super.key,
    required this.controller,
    required this.hintText,
    this.validator,
    this.obscureText = false,
    this.prefixIcon,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      validator: validator,
      obscureText: obscureText,
      decoration: InputDecoration(
        prefixIcon: prefixIcon,
        suffixIcon: suffix,
        hintText: hintText,
        hintStyle: TextStyle(color: Colors.grey.shade600, fontSize: 17),
        filled: true,
        fillColor: Colors.white.withOpacity(0.9),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 28, vertical: 26),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: const BorderSide(color: Colors.black54),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: const BorderSide(color: AppColors.purple, width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: const BorderSide(color: Colors.red),
        ),
      ),
    );
  }
}

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
              Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                  (_) => false);
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

class HomePage extends StatelessWidget {
  final void Function(int index) onNavigate;
  final Map<String, dynamic>? currentUser;
  const HomePage(
      {super.key, required this.onNavigate, required this.currentUser});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              gradient: const LinearGradient(
                  colors: [Color(0xFFA600D8), Color(0xFF8B5DDC)]),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hello ${currentUser?['name'] ?? 'SheRise User'}',
                  style: const TextStyle(
                      fontSize: 28,
                      color: Colors.white,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Get Start!',
                  style: TextStyle(fontSize: 22, color: Colors.white),
                ),
                const SizedBox(height: 16),
                Container(
                  height: 14,
                  decoration: BoxDecoration(
                      color: Colors.white54,
                      borderRadius: BorderRadius.circular(12)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 36),
          Wrap(
            spacing: 24,
            runSpacing: 24,
            children: [
              HomeQuickCard(
                  title: 'SOS Alert',
                  icon: Icons.sos,
                  color: AppColors.homeCardPink,
                  onTap: () => onNavigate(1)),
              HomeQuickCard(
                  title: 'Courses',
                  icon: Icons.cast_for_education_outlined,
                  color: AppColors.homeCardPurple,
                  onTap: () => onNavigate(2)),
              HomeQuickCard(
                  title: 'Community',
                  icon: Icons.groups_outlined,
                  color: AppColors.homeCardLilac,
                  onTap: () => onNavigate(3)),
              HomeQuickCard(
                  title: 'Legal Help',
                  icon: Icons.balance_outlined,
                  color: AppColors.homeCardMint,
                  onTap: () => onNavigate(4)),
            ],
          ),
        ],
      ),
    );
  }
}

class HomeQuickCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const HomeQuickCard(
      {super.key,
      required this.title,
      required this.icon,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: (MediaQuery.of(context).size.width - 60) / 2,
        child: Column(
          children: [
            Container(
              height: 150,
              decoration: BoxDecoration(
                  color: color, borderRadius: BorderRadius.circular(24)),
              child: Center(child: Icon(icon, size: 72, color: Colors.black54)),
            ),
            const SizedBox(height: 12),
            Text(title,
                textAlign: TextAlign.center,
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
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
              AppTextField(
                  controller: nameController,
                  label: 'Full Name',
                  validator: requiredValidator),
              AppTextField(
                  controller: phoneController,
                  label: 'Phone',
                  validator: phoneValidator),
              AppTextField(controller: addressController, label: 'Address'),
              AppTextField(
                  controller: occupationController, label: 'Occupation'),
              AppTextField(
                  controller: bioController, label: 'Bio', maxLines: 4),
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

class SafetyPage extends StatefulWidget {
  const SafetyPage({super.key});

  @override
  State<SafetyPage> createState() => _SafetyPageState();
}

class _SafetyPageState extends State<SafetyPage> {
  List<Map<String, dynamic>> contacts = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadContacts();
  }

  Future<void> loadContacts() async {
    setState(() => loading = true);
    try {
      contacts =
          List<Map<String, dynamic>>.from(await Api.get('/emergency-contacts'));
    } catch (e) {
      if (mounted)
        showMsg(context, e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> triggerSos() async {
    try {
      await Api.post('/sos', {'message': 'I need emergency help'});
      if (mounted) showMsg(context, 'SOS alert triggered successfully');
    } catch (e) {
      if (mounted)
        showMsg(context, e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> deleteContact(int id) async {
    try {
      await Api.delete('/emergency-contacts/$id');
      loadContacts();
    } catch (e) {
      if (mounted)
        showMsg(context, e.toString().replaceFirst('Exception: ', ''));
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: loadContacts,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
            decoration: const BoxDecoration(
              color: AppColors.redOrange,
              borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24)),
            ),
            child: const Text('Safety & Emergency',
                style: TextStyle(
                    fontSize: 30,
                    color: Colors.white,
                    fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              SafetyTopButton(
                  color: const Color(0xFFFA8C80),
                  icon: Icons.warning_amber_rounded,
                  label: 'SOS Alert',
                  onTap: triggerSos),
              SafetyTopButton(
                  color: const Color(0xFFA8E2F0),
                  icon: Icons.location_on_outlined,
                  label: 'Share\nLocation',
                  onTap: () => showMsg(context,
                      'Real-time location sharing can be connected next.')),
              SafetyTopButton(
                  color: const Color(0xFF8FD6B0),
                  icon: Icons.verified_user_outlined,
                  label: 'Safety Tips',
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const SafetyTipsPage()))),
            ],
          ),
          const SizedBox(height: 18),
          Align(
            alignment: Alignment.centerRight,
            child: FloatingActionButton.small(
              backgroundColor: AppColors.purple,
              onPressed: () async {
                await Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const EmergencyContactFormPage()));
                loadContacts();
              },
              child: const Icon(Icons.add, color: Colors.black),
            ),
          ),
          const SizedBox(height: 12),
          if (loading)
            const Center(
                child: Padding(
                    padding: EdgeInsets.all(22),
                    child: CircularProgressIndicator())),
          ...contacts.map((contact) => EmergencyContactCard(
                contact: contact,
                onEdit: () async {
                  await Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) =>
                              EmergencyContactFormPage(initial: contact)));
                  loadContacts();
                },
                onDelete: () => deleteContact(contact['id']),
              )),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
                color: const Color(0xFF6ED1A0),
                borderRadius: BorderRadius.circular(22)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text('Safety Score',
                        style: TextStyle(
                            fontSize: 18,
                            color: Colors.white,
                            fontWeight: FontWeight.w600)),
                    Icon(Icons.verified_user_outlined,
                        size: 42, color: Color(0xFF5FAF84)),
                  ],
                ),
                const SizedBox(height: 6),
                const Text('85%',
                    style: TextStyle(
                        fontSize: 22,
                        color: Colors.white,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                      value: 0.85,
                      minHeight: 8,
                      backgroundColor: Colors.white54,
                      color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class SafetyTopButton extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const SafetyTopButton(
      {super.key,
      required this.color,
      required this.icon,
      required this.label,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 86,
        height: 86,
        decoration: BoxDecoration(
            color: color, borderRadius: BorderRadius.circular(18)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 34),
            const SizedBox(height: 6),
            Text(label,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12.5, height: 1.0)),
          ],
        ),
      ),
    );
  }
}

class EmergencyContactCard extends StatelessWidget {
  final Map<String, dynamic> contact;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  const EmergencyContactCard(
      {super.key,
      required this.contact,
      required this.onEdit,
      required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.82),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.black26)),
      child: Row(
        children: [
          const Icon(Icons.add_ic_call_outlined, size: 38),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(contact['name'] ?? '',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
                Text(contact['phone'] ?? '',
                    style: const TextStyle(color: Colors.black54)),
                Text(contact['relationship'] ?? '',
                    style: const TextStyle(color: Colors.black45)),
              ],
            ),
          ),
          Column(
            children: [
              IconButton(
                  onPressed: onEdit, icon: const Icon(Icons.edit_outlined)),
              IconButton(
                  onPressed: onDelete, icon: const Icon(Icons.delete_outline)),
            ],
          ),
        ],
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
  bool isPrimary = false;
  bool saving = false;

  @override
  void initState() {
    super.initState();
    isPrimary = widget.initial?['is_primary'] == true;
  }

  Future<void> save() async {
    if (!formKey.currentState!.validate()) return;
    setState(() => saving = true);
    final data = {
      'name': nameController.text.trim(),
      'relationship': relationshipController.text.trim(),
      'phone': phoneController.text.trim(),
      'is_primary': isPrimary,
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
              : 'Update Emergency Contact')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: formKey,
          child: Column(
            children: [
              AppTextField(
                  controller: nameController,
                  label: 'Name',
                  validator: requiredValidator),
              AppTextField(
                  controller: relationshipController,
                  label: 'Relationship',
                  validator: requiredValidator),
              AppTextField(
                  controller: phoneController,
                  label: 'Phone',
                  validator: phoneValidator),
              SwitchListTile(
                value: isPrimary,
                title: const Text('Primary Contact'),
                onChanged: (value) => setState(() => isPrimary = value),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                    onPressed: saving ? null : save,
                    child: Text(widget.initial == null
                        ? 'Create Contact'
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
              borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24)),
            ),
            child: const Center(
              child: Text(
                'Stay safe with these important\nguidelines',
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
              const Text('course Title',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
              AppTextField(
                  controller: titleController,
                  label: '',
                  hint: 'Course title',
                  validator: requiredValidator),
              const SizedBox(height: 12),
              const Text('Description',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
              AppTextField(
                  controller: descriptionController,
                  label: '',
                  hint: 'Description',
                  maxLines: 3,
                  validator: (value) => requiredValidator(value, min: 10)),
              const SizedBox(height: 12),
              const Text('Instructor',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
              AppTextField(
                  controller: instructorController,
                  label: '',
                  hint: 'Instructor',
                  validator: requiredValidator),
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
                        AppTextField(
                            controller: durationController,
                            label: '',
                            hint: '6 week',
                            validator: requiredValidator)
                      ])),
                  const SizedBox(width: 12),
                  Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        const Text('Category',
                            style: TextStyle(
                                fontSize: 26, fontWeight: FontWeight.bold)),
                        AppTextField(
                            controller: categoryController,
                            label: '',
                            hint: 'Leadership',
                            validator: requiredValidator)
                      ])),
                ],
              ),
              const SizedBox(height: 12),
              const Text('Image URL',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
              AppTextField(
                  controller: imageUrlController,
                  label: '',
                  hint: 'https://....'),
              const SizedBox(height: 12),
              const Text('Progress (%)',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
              AppTextField(
                  controller: progressController,
                  label: '',
                  hint: '0',
                  validator: (value) {
                    if (value == null || value.trim().isEmpty)
                      return 'Required';
                    final p = int.tryParse(value.trim());
                    if (p == null || p < 0 || p > 100)
                      return 'Enter a number between 0 and 100';
                    return null;
                  }),
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
                          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
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
                          builder: (_) => MentorFormPage(initial: mentor)));
                  await onChanged();
                },
                icon: const Icon(Icons.edit_outlined),
                iconSize: 20,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
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
                        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
                      );
                    }
                  }
                },
                icon: const Icon(Icons.delete_outline),
                iconSize: 20,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
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
              AppTextField(
                  controller: titleController,
                  label: 'Title',
                  validator: requiredValidator),
              AppTextField(controller: categoryController, label: 'Category'),
              AppTextField(
                  controller: contentController,
                  label: 'Content',
                  maxLines: 5,
                  validator: (value) => requiredValidator(value, min: 5)),
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
              AppTextField(
                  controller: nameController,
                  label: 'Mentor Name',
                  validator: requiredValidator),
              AppTextField(
                  controller: expertiseController,
                  label: 'Expertise',
                  validator: requiredValidator),
              AppTextField(
                  controller: emailController,
                  label: 'Email',
                  validator: emailValidator),
              AppTextField(
                  controller: phoneController,
                  label: 'Phone',
                  validator: phoneValidator),
              AppTextField(
                  controller: availabilityController, label: 'Availability'),
              AppTextField(
                  controller: descriptionController,
                  label: 'Description',
                  maxLines: 4),
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
                              await Api.delete(
                                  '/complaints/${complaint['id']}');
                              load();
                            },
                            icon: const Icon(Icons.delete_outline)),
                      ],
                    ),
                  ),
                )),
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
  late final typeController =
      TextEditingController(text: widget.initial?['complaint_type'] ?? '');
  late final statusController =
      TextEditingController(text: widget.initial?['status'] ?? 'Submitted');
  late final descriptionController =
      TextEditingController(text: widget.initial?['description'] ?? '');

  Future<void> save() async {
    if (!formKey.currentState!.validate()) return;
    final data = {
      'subject': subjectController.text.trim(),
      'complaint_type': typeController.text.trim(),
      'status': statusController.text.trim().isEmpty
          ? 'Submitted'
          : statusController.text.trim(),
      'description': descriptionController.text.trim(),
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
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text(widget.initial == null
              ? 'File a Complaint'
              : 'Update Complaint')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: formKey,
          child: Column(
            children: [
              AppTextField(
                  controller: subjectController,
                  label: 'Subject',
                  validator: requiredValidator),
              AppTextField(
                  controller: typeController,
                  label: 'Complaint Type',
                  validator: requiredValidator),
              AppTextField(controller: statusController, label: 'Status'),
              AppTextField(
                  controller: descriptionController,
                  label: 'Description',
                  maxLines: 5,
                  validator: (value) => requiredValidator(value, min: 10)),
              SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                      onPressed: save,
                      child: Text(widget.initial == null
                          ? 'Submit Complaint'
                          : 'Update Complaint'))),
            ],
          ),
        ),
      ),
    );
  }
}

class AppTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? Function(String?)? validator;
  final int maxLines;
  final String? hint;
  const AppTextField(
      {super.key,
      required this.controller,
      required this.label,
      this.validator,
      this.maxLines = 1,
      this.hint});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        validator: validator,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label.isEmpty ? null : label,
          hintText: hint,
          filled: true,
          fillColor: Colors.white.withOpacity(0.88),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(18)),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: const BorderSide(color: Colors.black45)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide:
                  const BorderSide(color: AppColors.purple, width: 1.6)),
        ),
      ),
    );
  }
}
