# Flutter Firebase Chat App (GetX + Theming + Localization)

This single-file code bundle contains the main project scaffolding and essential files for a Flutter chat app using Firebase, GetX for state management, GetStorage for simple local persistence (theme), Firestore for messages, and GetX translations for localization.

---

## pubspec.yaml (essential dependencies - add these to your project's pubspec.yaml)

```yaml
name: chat_app_getx
description: A Flutter chat app with Firebase, GetX, theming, and localization.

environment:
sdk: '>=2.18.0 <3.0.0'

dependencies:
flutter:
sdk: flutter
firebase_core: ^2.10.0
firebase_auth: ^4.4.0
cloud_firestore: ^4.7.0
get: ^4.6.5
get_storage: ^3.0.1
flutter_localizations:
sdk: flutter

dev_dependencies:
flutter_test:
sdk: flutter
```

---

## File: lib/main.dart

```dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import 'controllers/auth_controller.dart';
import 'controllers/chat_controller.dart';
import 'services/theme_service.dart';
import 'translations/app_translations.dart';
import 'screens/login_screen.dart';
import 'screens/chat_list_screen.dart';

// Make sure to add your generated firebase_options.dart or initialize Firebase with default options.
import 'firebase_options.dart';

void main() async {
WidgetsFlutterBinding.ensureInitialized();
await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
await GetStorage.init();

// Initialize controllers (optional eager init)
Get.put(AuthController());
Get.put(ChatController());

runApp(MyApp());
}

class MyApp extends StatelessWidget {
@override
Widget build(BuildContext context) {
return GetMaterialApp(
debugShowCheckedModeBanner: false,
title: 'Chat App',
translations: AppTranslations(),
locale: Locale('en', 'US'),
fallbackLocale: Locale('en', 'US'),
theme: ThemeData.light(),
darkTheme: ThemeData.dark(),
themeMode: ThemeService().theme,
home: Root(),
);
}
}

class Root extends GetWidget<AuthController> {
@override
Widget build(BuildContext context) {
return Obx(() {
final user = controller.user;
if (user != null) {
return ChatListScreen();
} else {
return LoginScreen();
}
});
}
}
```

---

## File: lib/controllers/auth_controller.dart

```dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

class AuthController extends GetxController {
final FirebaseAuth _auth = FirebaseAuth.instance;
Rxn<User> _firebaseUser = Rxn<User>();

User? get user => _firebaseUser.value;

@override
void onInit() {
_firebaseUser.bindStream(_auth.authStateChanges());
super.onInit();
}

Future<void> signInAnonymously() async {
await _auth.signInAnonymously();
}

Future<void> signOut() async {
await _auth.signOut();
}

Future<void> signInWithEmail(String email, String password) async {
await _auth.signInWithEmailAndPassword(email: email, password: password);
}

Future<void> registerWithEmail(String email, String password) async {
await _auth.createUserWithEmailAndPassword(email: email, password: password);
}
}
```

---

## File: lib/controllers/chat_controller.dart

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import '../models/message_model.dart';

class ChatController extends GetxController {
final FirebaseFirestore _firestore = FirebaseFirestore.instance;

Stream<List<Message>> messagesStream(String chatId) {
return _firestore
    .collection('chats')
    .doc(chatId)
    .collection('messages')
    .orderBy('timestamp', descending: false)
    .snapshots()
    .map((snap) => snap.docs.map((d) => Message.fromMap(d.data())).toList());
}

Future<String> createChatIfNotExists(List<String> participants) async {
// Simple strategy: create a doc with combined participant IDs sorted.
final id = participants..sort();
final chatId = id.join('_');
final doc = _firestore.collection('chats').doc(chatId);
final snapshot = await doc.get();
if (!snapshot.exists) {
await doc.set({'participants': participants, 'createdAt': FieldValue.serverTimestamp()});
}
return chatId;
}

Future<void> sendMessage(String chatId, Message message) async {
final ref = _firestore.collection('chats').doc(chatId).collection('messages');
await ref.add(message.toMap());
await _firestore.collection('chats').doc(chatId).update({'lastMessage': message.text, 'lastTimestamp': FieldValue.serverTimestamp()});
}
}
```

---

## File: lib/models/message_model.dart

```dart
class Message {
final String senderId;
final String text;
final DateTime timestamp;

Message({required this.senderId, required this.text, required this.timestamp});

Map<String, dynamic> toMap() => {
'senderId': senderId,
'text': text,
'timestamp': timestamp.toUtc(),
};

factory Message.fromMap(Map<String, dynamic> map) {
return Message(
senderId: map['senderId'] ?? '',
text: map['text'] ?? '',
timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
);
}
}
```

---

## File: lib/services/theme_service.dart

```dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class ThemeService {
final _box = GetStorage();
final _key = 'isDarkMode';

ThemeMode get theme {
return _loadThemeFromBox() ? ThemeMode.dark : ThemeMode.light;
}

bool _loadThemeFromBox() => _box.read(_key) ?? false;

void _saveThemeToBox(bool isDarkMode) => _box.write(_key, isDarkMode);

void switchTheme() {
Get.changeThemeMode(_loadThemeFromBox() ? ThemeMode.light : ThemeMode.dark);
_saveThemeToBox(!_loadThemeFromBox());
}
}
```

---

## File: lib/translations/app_translations.dart

```dart
import 'package:get/get.dart';

class AppTranslations extends Translations {
@override
Map<String, Map<String, String>> get keys => {
'en_US': {
'login': 'Login',
'email': 'Email',
'password': 'Password',
'send': 'Send',
'logout': 'Logout',
'chats': 'Chats',
'type_message': 'Type a message...',
'theme': 'Theme',
},
'gu_IN': {
'login': 'લૉગિન',
'email': 'ઇમેઇલ',
'password': 'પાસવર્ડ',
'send': 'મોકલો',
'logout': 'લૉગઆઉટ',
'chats': 'ચેટ્સ',
'type_message': 'એક સંદેશ લખો...',
'theme': ' થીમ',
}
};
}
```

---

## File: lib/screens/login_screen.dart

```dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';

class LoginScreen extends StatelessWidget {
final emailController = TextEditingController();
final passwordController = TextEditingController();
final auth = Get.find<AuthController>();

@override
Widget build(BuildContext context) {
return Scaffold(
appBar: AppBar(title: Text('login'.tr)),
body: Padding(
padding: const EdgeInsets.all(16.0),
child: Column(
children: [
TextField(controller: emailController, decoration: InputDecoration(labelText: 'email'.tr)),
TextField(controller: passwordController, decoration: InputDecoration(labelText: 'password'.tr), obscureText: true),
SizedBox(height: 12),
ElevatedButton(
onPressed: () async {
try {
await auth.signInWithEmail(emailController.text.trim(), passwordController.text.trim());
} catch (e) {
Get.snackbar('Error', e.toString());
}
},
child: Text('login'.tr),
),
TextButton(
onPressed: () async {
await auth.signInAnonymously();
},
child: Text('Continue as Guest'),
)
],
),
),
);
}
}
```

---

## File: lib/screens/chat_list_screen.dart

```dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import '../controllers/chat_controller.dart';
import 'chat_screen.dart';
import '../services/theme_service.dart';

class ChatListScreen extends StatelessWidget {
final auth = Get.find<AuthController>();
final chatController = Get.find<ChatController>();

@override
Widget build(BuildContext context) {
return Scaffold(
appBar: AppBar(
title: Text('chats'.tr),
actions: [
IconButton(
icon: Icon(Icons.brightness_6),
onPressed: () => ThemeService().switchTheme(),
),
IconButton(
icon: Icon(Icons.language),
onPressed: () {
final next = Get.locale?.languageCode == 'en' ? Locale('gu', 'IN') : Locale('en', 'US');
Get.updateLocale(next);
},
),
IconButton(icon: Icon(Icons.logout), onPressed: () => auth.signOut()),
],
),
body: StreamBuilder<QuerySnapshot>(
stream: FirebaseFirestore.instance.collection('chats').orderBy('lastTimestamp', descending: true).snapshots(),
builder: (context, snapshot) {
if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
final docs = snapshot.data!.docs;
return ListView.builder(
itemCount: docs.length,
itemBuilder: (context, index) {
final data = docs[index].data() as Map<String, dynamic>;
final chatId = docs[index].id;
final last = data['lastMessage'] ?? '';
return ListTile(
title: Text('Chat: $chatId'),
subtitle: Text(last),
onTap: () async {
Get.to(() => ChatScreen(chatId: chatId));
},
);
},
);
},
),
);
}
}
```

---

## File: lib/screens/chat_screen.dart

```dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/chat_controller.dart';
import '../controllers/auth_controller.dart';
import '../models/message_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ChatScreen extends StatefulWidget {
final String chatId;
ChatScreen({required this.chatId});

@override
_ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
final chatController = Get.find<ChatController>();
final auth = Get.find<AuthController>();
final TextEditingController _controller = TextEditingController();

@override
Widget build(BuildContext context) {
return Scaffold(
appBar: AppBar(title: Text('Chat')),
body: Column(
children: [
Expanded(
child: StreamBuilder<List<Message>>(
stream: chatController.messagesStream(widget.chatId),
builder: (context, snapshot) {
if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
final messages = snapshot.data!;
return ListView.builder(
itemCount: messages.length,
itemBuilder: (context, index) {
final m = messages[index];
final isMe = m.senderId == auth.user?.uid;
return Align(
alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
child: Container(
margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
padding: EdgeInsets.all(12),
decoration: BoxDecoration(color: isMe ? Colors.blueAccent : Colors.grey[300], borderRadius: BorderRadius.circular(8)),
child: Text(m.text, style: TextStyle(color: isMe ? Colors.white : Colors.black)),
),
);
},
);
},
),
),
SafeArea(
child: Row(
children: [
Expanded(
child: TextField(controller: _controller, decoration: InputDecoration(hintText: 'type_message'.tr)),
),
IconButton(
icon: Icon(Icons.send),
onPressed: () async {
final text = _controller.text.trim();
if (text.isEmpty) return;
final message = Message(senderId: auth.user!.uid, text: text, timestamp: DateTime.now());
await chatController.sendMessage(widget.chatId, message);
_controller.clear();
},
)
],
),
)
],
),
);
}
}
```

---

## Additional notes & setup steps

1. Create a Firebase project and add Android & iOS apps. Download `google-services.json` (Android) and `GoogleService-Info.plist` (iOS). Place them in the proper platform folders.
2. Run `flutterfire configure` or use the Firebase Console and generate `firebase_options.dart` (used in main.dart). Alternatively initialize Firebase manually.
3. Enable Authentication (Email/Password and Anonymous if you want) and Firestore database in Firebase Console. Configure Firestore rules for your needs.
4. Update Android `minSdkVersion` to at least 21 in `android/app/build.gradle` if necessary.
5. Run `flutter pub get` and then `flutter run`.

---

This bundle is a starting point — it focuses on core architecture: GetX controllers, theme switching, translations, authentication, Firestore messages. You can extend features: profile pics (Firebase Storage), push notifications (Firebase Cloud Messaging), typing indicators, message statuses (delivered/read), pagination, media messages, and UI polish.
Important: add these packages to your pubspec.yaml and run flutter pub get:

get_storage

image_picker

firebase_storage

(If you want to store credentials securely instead of GetStorage, use flutter_secure_storage — I also include a note below.)

lib/screens/login_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../controllers/auth_controller.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
@override
_LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
final emailController = TextEditingController();
final passwordController = TextEditingController();
final auth = Get.find<AuthController>();
final box = GetStorage();

final _formKey = GlobalKey<FormState>();
bool _obscure = true;
bool _remember = false;

@override
void initState() {
super.initState();
// Load saved credentials if user chose remember
_remember = box.read('remember') ?? false;
if (_remember) {
emailController.text = box.read('email') ?? '';
passwordController.text = box.read('password') ?? '';
}
}

void _saveRemember() {
if (_remember) {
box.write('remember', true);
box.write('email', emailController.text);
box.write('password', passwordController.text);
} else {
box.remove('remember');
box.remove('email');
box.remove('password');
}
}

@override
Widget build(BuildContext context) {
return Scaffold(
appBar: AppBar(title: Text('login'.tr)),
body: Padding(
padding: const EdgeInsets.all(16.0),
child: Form(
key: _formKey,
child: Column(
children: [
TextFormField(
controller: emailController,
decoration: InputDecoration(labelText: 'email'.tr),
keyboardType: TextInputType.emailAddress,
validator: (v) {
if (v == null || v.trim().isEmpty) return 'Please enter email';
final emailRegex = RegExp(r"^[^@\s]+@[^@\s]+\.[^@\s]+$");
if (!emailRegex.hasMatch(v.trim())) return 'Enter valid email';
return null;
},
),
SizedBox(height: 12),
TextFormField(
controller: passwordController,
obscureText: _obscure,
decoration: InputDecoration(
labelText: 'password'.tr,
suffixIcon: IconButton(
icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
onPressed: () => setState(() => _obscure = !_obscure),
),
),
validator: (v) {
if (v == null || v.isEmpty) return 'Please enter password';
if (v.length < 6) return 'Password must be at least 6 characters';
return null;
},
),
Row(
children: [
Checkbox(
value: _remember,
onChanged: (v) => setState(() => _remember = v ?? false),
),
Text('Remember me')
],
),
SizedBox(height: 12),
ElevatedButton(
onPressed: () async {
if (!_formKey.currentState!.validate()) return;
try {
await auth.signInWithEmail(emailController.text.trim(), passwordController.text.trim());
_saveRemember();
} catch (e) {
Get.snackbar('Error', e.toString());
}
},
child: Text('login'.tr),
),
TextButton(
onPressed: () {
Get.to(() => RegisterScreen());
},
child: Text('Create account'),
),
TextButton(
onPressed: () async {
await auth.signInAnonymously();
},
child: Text('Continue as Guest'),
)
],
),
),
),
);
}
}

lib/screens/register_screen.dart
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../controllers/auth_controller.dart';

class RegisterScreen extends StatefulWidget {
@override
_RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
final _formKey = GlobalKey<FormState>();
final nameController = TextEditingController();
final emailController = TextEditingController();
final phoneController = TextEditingController();
final passwordController = TextEditingController();
final confirmController = TextEditingController();

bool _obscure = true;
File? _pickedImage;
final picker = ImagePicker();
final auth = Get.find<AuthController>();

Future<void> _pickImage() async {
final picked = await picker.pickImage(source: ImageSource.gallery, maxWidth: 800, maxHeight: 800, imageQuality: 80);
if (picked != null) setState(() => _pickedImage = File(picked.path));
}

Future<String?> _uploadProfile(File file, String uid) async {
final ref = FirebaseStorage.instance.ref().child('profiles').child('$uid.jpg');
final uploadTask = await ref.putFile(file);
return await uploadTask.ref.getDownloadURL();
}

@override
Widget build(BuildContext context) {
return Scaffold(
appBar: AppBar(title: Text('Register')),
body: SingleChildScrollView(
padding: EdgeInsets.all(16),
child: Form(
key: _formKey,
child: Column(
crossAxisAlignment: CrossAxisAlignment.stretch,
children: [
GestureDetector(
onTap: _pickImage,
child: CircleAvatar(
radius: 48,
backgroundImage: _pickedImage != null ? FileImage(_pickedImage!) : null,
child: _pickedImage == null ? Icon(Icons.camera_alt, size: 36) : null,
),
),
SizedBox(height: 12),
TextFormField(
controller: nameController,
decoration: InputDecoration(labelText: 'Full Name'),
validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter name' : null,
),
SizedBox(height: 8),
TextFormField(
controller: emailController,
decoration: InputDecoration(labelText: 'Email'),
keyboardType: TextInputType.emailAddress,
validator: (v) {
if (v == null || v.trim().isEmpty) return 'Enter email';
final emailRegex = RegExp(r"^[^@\s]+@[^@\s]+\.[^@\s]+$");
if (!emailRegex.hasMatch(v.trim())) return 'Enter valid email';
return null;
},
),
SizedBox(height: 8),
TextFormField(
controller: phoneController,
decoration: InputDecoration(labelText: 'Phone'),
keyboardType: TextInputType.phone,
validator: (v) {
if (v == null || v.trim().isEmpty) return 'Enter phone';
final phoneRegex = RegExp(r"^[0-9]{7,15}");
if (!phoneRegex.hasMatch(v.trim())) return 'Enter valid phone';
return null;
},
),
SizedBox(height: 8),
TextFormField(
controller: passwordController,
obscureText: _obscure,
decoration: InputDecoration(
labelText: 'Password',
suffixIcon: IconButton(icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility), onPressed: () => setState(() => _obscure = !_obscure)),
),
validator: (v) {
if (v == null || v.isEmpty) return 'Enter password';
if (v.length < 6) return 'Password must be at least 6 characters';
return null;
},
),
SizedBox(height: 8),
TextFormField(
controller: confirmController,
obscureText: _obscure,
decoration: InputDecoration(labelText: 'Confirm Password'),
validator: (v) {
if (v == null || v.isEmpty) return 'Confirm password';
if (v != passwordController.text) return 'Passwords do not match';
return null;
},
),
SizedBox(height: 16),
ElevatedButton(
onPressed: () async {
if (!_formKey.currentState!.validate()) return;
try {
final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
email: emailController.text.trim(),
password: passwordController.text.trim(),
);
final uid = cred.user!.uid;
String? photoUrl;
if (_pickedImage != null) {
photoUrl = await _uploadProfile(_pickedImage!, uid);
}
await cred.user!.updateDisplayName(nameController.text.trim());
if (photoUrl != null) await cred.user!.updatePhotoURL(photoUrl);
// Optionally create user doc in Firestore here with phone etc.
Get.snackbar('Success', 'Account created');
Get.back();
} catch (e) {
Get.snackbar('Error', e.toString());
}
},
child: Text('Register'),
),
],
),
),
),
);
}
}

Quick notes & next steps

Dependencies: Add to pubspec.yaml:

get_storage: ^3.0.1
image_picker: ^0.8.7
firebase_storage: ^10.3.0


Then run flutter pub get.

Permissions: On Android add the required storage/media permission for image_picker (or use the new scoped storage approach). iOS requires NSPhotoLibraryUsageDescription in Info.plist.

Security note: I stored "remembered" email/password in GetStorage for simplicity because you asked for a 'remember' feature. This is not secure for production. For secure storage use flutter_secure_storage (encrypted) or platform secure keystore.

Firestore user doc: After successful register you may want to create a Firestore user document with name/phone/photo for in-app profile use.

Integration: Import register_screen.dart in your navigation or call Get.to(() => RegisterScreen()) (the login code already does that).