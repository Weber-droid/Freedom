// import 'dart:developer';
//
// import 'package:bloc/bloc.dart';
// import 'package:metamap_plugin_flutter/metamap_plugin_flutter.dart';
//
// part 'document_verification_state.dart';
//
// class DocumentationVerificationCubit extends Cubit<DocumentVerificationState> {
//   DocumentationVerificationCubit() : super(DocumentVerificationInit());
//
//   Future<void> verifyDocuments() async {
//     try {
//       emit(DocumentationVerificationInProgress());
//       await MetaMapFlutter.showMetaMapFlow(
//           clientId: 'Y67e155fa36455f74bdfcd994',
//           flowId: '67e155fa36455f06a5fcd993');
//       final completer = MetaMapFlutter.resultCompleter.future;
//       emit(DocumentationVerificationProcessing(completer: completer));
//     } catch (e) {
//       log('Error occured while verifying document');
//     }
//   }
// }