import 'package:flutter/material.dart';
import '../../core/theme.dart';

class VerseDuelSetupPage extends StatelessWidget {
  const VerseDuelSetupPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: OtakuColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text("CRÉER UN SALON", style: OtakuTypo.headlineSmall),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.people_alt_rounded, size: 80, color: OtakuColors.modeDuel),
              const SizedBox(height: 20),
              Text("GÉNÉRER UN CODE", style: OtakuTypo.headlineLarge),
              const SizedBox(height: 10),
              Text("Paramètre les règles de ton duel amical.", style: OtakuTypo.bodySmall, textAlign: TextAlign.center),
              const SizedBox(height: 40),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: OtakuColors.modeDuel),
                onPressed: () {},
                child: const Text("CRÉER LE SALON"),
              ),
              const SizedBox(height: 20),
              Text("OU", style: OtakuTypo.bodySmall),
              const SizedBox(height: 20),
              TextField(
                decoration: InputDecoration(
                  hintText: "ENTRER LE CODE D'UN AMI",
                  filled: true,
                  fillColor: OtakuColors.surface,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                textAlign: TextAlign.center,
                style: OtakuTypo.headlineSmall,
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[800]),
                onPressed: () {},
                child: const Text("REJOINDRE"),
              ),
            ],
            ),
          ),
        ),
      ),
    );
  }
}
