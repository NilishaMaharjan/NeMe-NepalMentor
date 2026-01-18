import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nepalmentors/screens/profile.dart';
import 'package:nepalmentors/screens/splashview.dart';
import 'package:nepalmentors/screens/login.dart';
import 'package:nepalmentors/screens/mentorregister1.dart';
import 'package:nepalmentors/screens/mentordashboard.dart';
import 'package:nepalmentors/screens/signup.dart';
import 'package:nepalmentors/screens/forgetpw.dart';
import 'package:nepalmentors/screens/primary.dart' ;
import 'package:nepalmentors/screens/secondary.dart';
import 'package:nepalmentors/screens/bachelor.dart';
import 'package:nepalmentors/screens/masters.dart';
import 'package:nepalmentors/screens/ctevt.dart';
import 'package:nepalmentors/screens/diploma.dart';
import 'package:nepalmentors/screens/resetpw.dart';
import 'package:nepalmentors/screens/chat_page.dart'; // Mentor chat page
import 'package:nepalmentors/screens/mentee_chat_page.dart';
import 'package:nepalmentors/screens/menteeprofile.dart';
import 'package:nepalmentors/screens/common_bottom_navigation.dart';
import 'package:nepalmentors/screens/mentees_list_screen.dart';
//import 'package:nepalmentors/screens/esewascreen.dart'; // Import for the eSewa screen

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: '/splash',
      getPages: [
        GetPage(name: '/splash', page: () => const MySplash()),
        GetPage(name: '/login', page: () => const LoginScreen()),
        GetPage(name: '/signupmentee', page: () => const SignupPage()),
        GetPage(
            name: '/forgetpassword', page: () => const ForgotPasswordPage()),
        GetPage(
            name: '/mentorregistration',
            page: () => const MentorRegistrationAndAdditionalInfo()),
        GetPage(
          name: '/dashboard',
          page: () => const CommonBottomNavigation(),
        ),

        GetPage(name: '/mentordashboard', page: () => const MentorDashboard()),
        GetPage(
          name: '/primarylevel',
          page: () => PrimaryLevelPage(key: UniqueKey()),
        ),
        GetPage(
            name: '/secondarylevel', page: () => const SecondaryLevelPage()),
        GetPage(name: '/bachelorlevel', page: () => const BachelorLevelPage()),
        GetPage(name: '/diplomalevel', page: () => const DiplomaLevelPage()),
        GetPage(name: '/ctevtlevel', page: () => const CTEVTLevelPage()),
        GetPage(name: '/masterslevel', page: () => const MastersLevelPage()),

        GetPage(
          name: '/mentorprofile',
          page: () {
            final mentorId = Get.parameters['mentorId'] ?? '';
            return MentorProfilePage(userId: mentorId);
          },
        ),
        GetPage(
          name: '/reset-password/:token',
          page: () {
            final token = Get.parameters['token']!;
            return ResetPasswordPage(token: token);
          },
        ),
        // Mentor chat page (existing)
        GetPage(
          name: '/chat',
          page: () {
            final slot = Get.arguments['slot'];
            final receiverId = Get.arguments['receiverId'];
            return CommunityChatScreen(slot: slot, receiverId: receiverId);
          },
        ),
        // New mentee chat page route
        GetPage(
          name: '/mentee_chat',
          page: () {
            final slot = Get.arguments['slot'];
            final receiverId = Get.arguments['receiverId'];
            return MenteeChatScreen(slot: slot, receiverId: receiverId);
          },
        ),
        GetPage(name: '/menteeslist', page: () => const MenteesListScreen()),
        GetPage(
          name: '/menteeprofile',
          page: () {
            final userId = Get.parameters['userId'] ?? '';
            return MenteeProfilePage(userId: userId);
          },
        ),
      ],
    );
  }
}