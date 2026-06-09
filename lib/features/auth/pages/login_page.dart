import 'package:flutter/material.dart';
import '../widgets/login_form.dart'; // Path relatif yang bersih

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    final double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FA),
      body: Stack(
        children: [
          // Background dekorasi lingkaran atas
          Positioned(
            top: -screenHeight * 0.35,
            left: -200,
            right: -200,
            child: Container(
              height: screenHeight * 0.85,
              decoration: const BoxDecoration(
                color: Color(0xFF14A38B),
                shape: BoxShape.circle,
              ),
            ),
          ),

          // Konten Utama Form Login
          Center(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 25),
                padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 35),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    )
                  ],
                ),
                child: const LoginForm(), 
              ),
            ),
          ),
        ],
      ),
    );
  }
}