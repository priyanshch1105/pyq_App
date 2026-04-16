import 'package:flutter_riverpod/flutter_riverpod.dart';

// Central place to expose app-level providers.
final appBootstrapProvider = Provider<bool>((ref) => true);
