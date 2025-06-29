part of 'document_verification_cubit.dart';

abstract class DocumentVerificationState{}
class DocumentVerificationInit extends DocumentVerificationState {}

class DocumentationVerificationInProgress extends DocumentVerificationState{}

class DocumentationVerificationProcessing extends DocumentVerificationState{
  DocumentationVerificationProcessing({this.completer});
  final dynamic completer;
}