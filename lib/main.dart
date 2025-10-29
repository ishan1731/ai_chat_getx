import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'app/routes/app_pages.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'AI Chat GetX',
      initialRoute: AppPages.initial,
      getPages: AppPages.routes,
      theme: ThemeData(primarySwatch: Colors.indigo),
    ),
  );
}
