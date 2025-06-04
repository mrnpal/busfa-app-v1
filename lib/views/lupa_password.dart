import 'package:flutter/material.dart';
// import 'package:get/get_connect/http/src/utils/utils.dart';

class LupaPasswordScreens extends StatelessWidget {
  const LupaPasswordScreens({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Lupa Password",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
      ),
      body: Center(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const Text(
                    "Lupa Password?",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
                  ),
                  const Text(
                    "Masukkan email yang terdaftar",
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  const SizedBox(height: 32),
                  TextField(
                    decoration: InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.email),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        print("mengrim email");
                      },
                      child: const Text(
                        'Kirim Email',
                        style: TextStyle(color: Colors.white),
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
