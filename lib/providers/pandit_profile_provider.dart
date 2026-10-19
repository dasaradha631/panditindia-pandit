import 'package:flutter/foundation.dart';

import '../models/pandit_profile.dart';
import '../services/pandit_service.dart';

class PanditProfileProvider extends ChangeNotifier {
  PanditProfileProvider();

  final PanditService _service = PanditService();

  PanditProfile? profile;
  String availability = 'available';
  List<DevoteeReview> reviews = [];
  bool loading = false;

  /// True once the first [load] attempt has finished (even if it returned no
  /// profile), so UIs can tell "not fetched yet" from "fetched but incomplete"
  /// — e.g. the home screen's incomplete-profile prompt.
  bool loaded = false;
  bool saving = false;
  bool loadingReviews = false;

  double get averageRating {
    final rated = reviews.where((r) => r.rating != null).toList();
    if (rated.isEmpty) return 0;
    final sum = rated.fold<int>(0, (s, r) => s + (r.rating ?? 0));
    return sum / rated.length;
  }

  Future<void> load() async {
    loading = true;
    notifyListeners();
    profile = await _service.getProfile();
    if (profile?.availability != null && profile!.availability!.isNotEmpty) {
      availability = profile!.availability!;
    }
    loading = false;
    loaded = true;
    notifyListeners();
  }

  Future<bool> save(Map<String, dynamic> payload) async {
    saving = true;
    notifyListeners();
    final ok = await _service.updateProfile(payload);
    if (ok) await load();
    saving = false;
    notifyListeners();
    return ok;
  }

  Future<bool> setAvailability(String value) async {
    final previous = availability;
    availability = value;
    notifyListeners();
    final ok = await _service.setAvailability(value);
    if (!ok) {
      availability = previous;
      notifyListeners();
    }
    return ok;
  }

  Future<void> loadReviews() async {
    loadingReviews = true;
    notifyListeners();
    reviews = await _service.reviews();
    loadingReviews = false;
    notifyListeners();
  }
}
