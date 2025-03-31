import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freedom/feature/user_verification/document_verification/document_verification_cubit/document_verification_cubit.dart';

class DocumentVerificationScreen extends StatefulWidget {
  const DocumentVerificationScreen({super.key});
  static const String routeName = '/doc-verification';
  @override
  State<DocumentVerificationScreen> createState() =>
      _DocumentVerificationScreenState();
}

class _DocumentVerificationScreenState
    extends State<DocumentVerificationScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
            onPressed: () {
              context.read<DocumentationVerificationCubit>().verifyDocuments();
            },
            child: const Text('Verify users document')),
      ),
    );
  }
}
