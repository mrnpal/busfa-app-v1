import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '/services/auth_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  String? message;
  bool isLoading = false;
  bool showErrorAnimation = false;
  bool showErrorIcon = false;

  void _login() async {
    setState(() {
      isLoading = true;
      showErrorAnimation = false;
      showErrorIcon = false;
    });

    final result = await loginAlumni(
      emailController.text.trim(),
      passwordController.text.trim(),
    );

    if (result != null) {
      setState(() {
        message = result;
        showErrorAnimation = true;
        showErrorIcon = true;
        isLoading = false;
      });

      // Snackbar error
      showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
              backgroundColor: Colors.red[50],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Row(
                children: [
                  SizedBox(width: 8),
                  Text(
                    "Login Gagal",
                    style: TextStyle(color: Colors.redAccent),
                  ),
                ],
              ),
              content: Text(result, style: TextStyle(color: Colors.black87)),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text("Tutup"),
                ),
              ],
            ),
      );
    } else {
      Get.offAllNamed('/user-dashboard');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(Icons.arrow_back_ios, size: 20, color: Colors.black),
        ),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 40),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  SizedBox(height: 20),
                  FadeInUp(
                    duration: Duration(milliseconds: 1000),
                    child: Text(
                      "Login",
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  FadeInUp(
                    duration: Duration(milliseconds: 1200),
                    child: Text(
                      "Login to your account",
                      style: TextStyle(fontSize: 15, color: Colors.grey[700]),
                    ),
                  ),
                  SizedBox(height: 40),
                  FadeInUp(
                    duration: Duration(milliseconds: 1200),
                    child: makeInput(
                      label: "Email",
                      controller: emailController,
                    ),
                  ),
                  FadeInUp(
                    duration: Duration(milliseconds: 1300),
                    child: makeInput(
                      label: "Password",
                      obscureText: true,
                      controller: passwordController,
                    ),
                  ),
                  FadeInUp(
                    duration: Duration(milliseconds: 1400),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: <Widget>[
                        GestureDetector(
                          onTap: () {
                            Get.toNamed('/forgot-pw');
                          },
                          child: Text(
                            "Lupa Password?",
                            style: TextStyle(fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  ),

                  FadeInUp(
                    duration: Duration(milliseconds: 1500),
                    child: Container(
                      margin: EdgeInsets.only(top: 20),
                      padding: EdgeInsets.only(top: 3, left: 3),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(50),
                        border: Border.all(color: Colors.black),
                      ),
                      child: MaterialButton(
                        minWidth: double.infinity,
                        height: 60,
                        onPressed: isLoading ? null : _login,
                        color: Colors.greenAccent,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(50),
                        ),
                        child: Text(
                          isLoading ? "Memproses..." : "Login",
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          FadeInUp(
            duration: Duration(milliseconds: 1700),
            child: Container(
              height: MediaQuery.of(context).size.height / 3,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/background.png'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget makeInput({
    required String label,
    bool obscureText = false,
    required TextEditingController controller,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w400,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: 5),
        TextField(
          controller: controller,
          obscureText: obscureText,
          decoration: InputDecoration(
            contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 10),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.grey.shade400),
            ),
            border: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.grey.shade400),
            ),
          ),
        ),
        SizedBox(height: 30),
      ],
    );
  }
}
