import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart'; // Import Lottie
import 'camera_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/pngtree-green-nature-page-border-image_13367772.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: Column(
          children: [
            SizedBox(height: 100), // Space where AppBar used to be

            // Heading text
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Welcome to EnviroScan!',
                style: TextStyle(
                  fontSize: 50,
                  fontWeight: FontWeight.bold,
                  color: Colors.green[800],
                ),
                textAlign: TextAlign.center,
              ),
            ),

            // Lottie Animation in the center
            Lottie.asset(
              'assets/scan_animation.json', // Path to your Lottie file
              height: 200,
              width: 200,
              fit: BoxFit.cover,
            ),

            // ✅ Move this text ABOVE the Spacer() so it doesn't get pushed down
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Text(
                "Easily scan and identify recyclable materials!",
                style: TextStyle(fontSize: 18, color: Colors.green[700], fontWeight: FontWeight.w500),
                textAlign: TextAlign.center,
              ),
            ),

            const Spacer(), // Push button to bottom

            // Button at the bottom center
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Center(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const CameraPage()),
                    );
                  },
                  icon: Icon(Icons.camera_alt, color: Colors.white),
                  label: Text(
                    'Scan Now',
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ),
              ),
            ),
          ],
        ),
        
      ),
    );
  }
}
