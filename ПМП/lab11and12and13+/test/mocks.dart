import 'package:firebase_auth/firebase_auth.dart';
import 'package:lab11and12/bloc/appBLoC.dart';
import 'package:lab11and12/services/analyticsService.dart';
import 'package:lab11and12/services/authService.dart';
import 'package:lab11and12/services/connectivityService.dart';
import 'package:lab11and12/services/databaseService.dart';
import 'package:lab11and12/services/firestoreService.dart';
import 'package:lab11and12/services/hiveService.dart';
import 'package:lab11and12/services/remoteConfigService.dart';
import 'package:mockito/annotations.dart';

@GenerateMocks([
  FirestoreService,
  AuthService,
  DatabaseService,
  AnalyticsService,
  RemoteConfigService,
  HiveService,
  User,
  AppBloc,
  ConnectivityService,
])
void main() {}