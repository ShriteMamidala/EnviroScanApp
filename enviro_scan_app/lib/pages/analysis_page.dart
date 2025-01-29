import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'home_page.dart'; // Ensure this is at the top

class AnalysisPage extends StatelessWidget {
  final List<dynamic> results; // List of results (each with imageUrl and detections)

  const AnalysisPage({Key? key, required this.results}) : super(key: key);

  // Function to clear the output folder on the backend
  Future<void> _clearOutputs() async {
    try {
      final Uri uri = Uri.parse("http://10.0.2.2:8000/clear-outputs/");
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        debugPrint("Output folder cleared successfully.");
      } else {
        debugPrint("Failed to clear output folder: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("Error clearing output folder: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Analysis Results')),
      body: ListView.builder(
        itemCount: results.length,
        itemBuilder: (context, index) {
          final result = results[index];
          final imageUrl = "http://10.0.2.2:8000${result['image']}"; // Update with actual IP
          final detections = result['detections'] ?? []; // Ensure it doesn't crash on null

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Display the annotated image
                Image.network(imageUrl, fit: BoxFit.cover),

                const SizedBox(height: 10), // Spacing

                // Display "No detections found" if empty
                if (detections.isEmpty || !(detections is List))
                  const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text(
                      "No detections found",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.red),
                    ),
                  ),

                // ✅ Ensure `detections` is a List before mapping
                if (detections != null && detections is List && detections.isNotEmpty)
                  Column(
                    children: detections.map((detection) {
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: ListTile(
                          title: Text(
                            "Class: ${detection['class'] ?? 'Unknown'}",
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Confidence: ${(detection['confidence'] * 100).toStringAsFixed(2)}%",
                              ),
                              const SizedBox(height: 5),
                              Text(
                                "Advice: ${detection['advice'] ?? 'No advice available.'}",
                                style: const TextStyle(color: Colors.blueGrey),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                const Divider(), // Separate results for each image
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton(
          onPressed: () async {
            await _clearOutputs(); // Clear the output folder

            // Navigate back to the Home Page and remove all previous screens
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const HomePage()),
              (route) => false, // Removes all previous routes
            );
          },
          child: const Text("Back to Home"),
        ),
      ),
    );
  }
}
