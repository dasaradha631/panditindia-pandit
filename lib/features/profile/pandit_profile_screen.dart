import 'dart:async';

import 'package:flutter/material.dart' hide Text;
import 'package:provider/provider.dart';

import '../../core/l10n/app_l10n.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/gps_prompts.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/language_selector.dart';
import '../../providers/auth_provider.dart';
import '../../providers/pandit_profile_provider.dart';
import '../../services/geo_service.dart';
import '../../services/tracking_service.dart';
import '../auth/login_screen.dart';
import '../home/widgets/dashboard_widgets.dart';
import '../notifications/notifications_screen.dart';
import '../reviews/reviews_screen.dart';
import 'support_screen.dart';
import 'package:pandit_app/core/l10n/localized_text.dart';

/// Acharya Profile pane (images 9-12 of the UI pack): personal identity,
/// Vedic credentials, live GPS anchor and dakshina payout settings.
class PanditProfileScreen extends StatefulWidget {
  const PanditProfileScreen({super.key});

  @override
  State<PanditProfileScreen> createState() => _PanditProfileScreenState();
}

class _PanditProfileScreenState extends State<PanditProfileScreen> {
  final _form = <String, TextEditingController>{};
  final PanditTrackingService _tracking = PanditTrackingService();
  late final PanditProfileProvider _profileProvider;
  bool _initialised = false;
  bool _loadRequested = false;
  bool _detecting = false;

  /// True while "Others" is selected in the Gurukul dropdown — shows the
  /// manual text input (web parity) bound to the same `gurukul` field.
  bool _gurukulOther = false;
  double? _latitude;
  double? _longitude;

  /// Debounced forward-geocode after city / state / pincode edits (the web
  /// dashboard re-geocodes onBlur; AppTextField exposes no focus hook, so we
  /// wait for typing to settle instead).
  Timer? _addressGeocodeTimer;

  /// Bumped whenever a newer location source wins (fresh edit, GPS fix,
  /// hydration) so a slower in-flight geocode cannot overwrite it.
  int _geoSession = 0;

  static const _vedaBranches = [
    'Rigveda Specialist',
    'Yajurveda Specialist',
    'Samaveda Specialist',
    'Atharvaveda Specialist',
    'Vedic Astrology (Jyotish)',
    'Vastu Shastra Specialist',
  ];

  static const _gurukuls = [
    'Kanchi Kamakoti Peetham',
    'Gita Bhavan Gurukulam',
    'Sri Venkateswara Veda Patashala',
    'Puri Shankaracharya Peetham',
    'Bharatiya Vidya Bhavan',
    'Others',
  ];

  static const _fieldKeys = [
    'full_name',
    'phonenumber',
    'email',
    'date_of_birth',
    'gotra',
    'gurukul',
    'any_government_id',
    'experance_certificate_number',
    'experience_years',
    'languages',
    'veda_branch',
    'specializations',
    'city',
    'state',
    'pincode',
    'latitude',
    'longitude',
    'upi_id',
    'bank_account',
    'ifsc_code',
    'bio',
  ];

  @override
  void initState() {
    super.initState();
    for (final k in _fieldKeys) {
      _form[k] = TextEditingController();
    }
    // `read` is safe in initState (it does not subscribe to rebuilds); the
    // listener lets the form re-hydrate whenever the provider notifies — the
    // profile often finishes loading *after* this screen first builds
    // (previously the form then stayed empty forever).
    _profileProvider = context.read<PanditProfileProvider>();
    _profileProvider.addListener(_hydrate);
    WidgetsBinding.instance.addPostFrameCallback((_) => _hydrate());
  }

  void _hydrate() {
    if (!mounted || _initialised) return;
    final p = _profileProvider;
    final prof = p.profile;
    if (prof == null) {
      if (p.loading) return; // wait for the in-flight load; the listener re-runs us
      if (!_loadRequested) {
        // Nobody has loaded the profile yet — start one and wait.
        _loadRequested = true;
        p.load();
        return;
      }
      // Load finished but returned no profile → hydrate with empty values.
    }
    _initialised = true;
    _set('full_name', prof?.fullName);
    _set('phonenumber', prof?.phonenumber);
    _set('email', prof?.email);
    _set('date_of_birth', Fmt.dobInput(prof?.dateOfBirth));
    _set('gotra', prof?.gotra);
    _set('gurukul', prof?.gurukul);
    final g = prof?.gurukul ?? '';
    if (g == 'Others') {
      // Legacy value saved by older builds: show as manual-entry mode.
      _gurukulOther = true;
      _form['gurukul']!.text = '';
    } else {
      _gurukulOther = g.isNotEmpty && !_gurukuls.contains(g);
    }
    _set('any_government_id', prof?.anyGovernmentId);
    _set('experance_certificate_number', prof?.experanceCertificateNumber);
    _set('experience_years', prof?.experienceYears?.toString());
    _set('languages', prof?.languages);
    // The "Veda Shakha / Specialization" dropdown owns `veda_branch` (web
    // parity); `specializations` has no input on web either — it is passively
    // re-submitted, so hydrate it untouched. The veda_branch fallback keeps
    // the dropdown showing what older builds saved into `specializations`.
    _set('veda_branch', prof?.vedaBranch ?? prof?.specializations);
    _set('specializations', prof?.specializations);
    _set('city', prof?.city);
    _set('state', prof?.state);
    _set('pincode', prof?.pincode);
    _set('upi_id', prof?.upiId);
    _set('bank_account', prof?.bankAccount);
    _set('ifsc_code', prof?.ifscCode);
    _set('bio', prof?.bio);
    _addressGeocodeTimer?.cancel();
    _geoSession++;
    _latitude = prof?.latitude;
    _longitude = prof?.longitude;
    _set('latitude', prof?.latitude?.toString());
    _set('longitude', prof?.longitude?.toString());
    if (mounted) setState(() {});
  }

  void _set(String key, String? value) {
    if (value != null && value.isNotEmpty) _form[key]!.text = value;
  }

  /// Calendar picker for the Date of Birth field (web parity).
  Future<void> _pickDob() async {
    final now = DateTime.now();
    final current = DateTime.tryParse(Fmt.dobToIso(_form['date_of_birth']!.text));
    final picked = await showDatePicker(
      context: context,
      initialDate: (current == null || current.isAfter(now)) ? now : current,
      firstDate: DateTime(1900),
      lastDate: now,
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: Theme.of(ctx).colorScheme.copyWith(primary: AppColors.accent),
        ),
        child: child!,
      ),
    );
    if (picked == null || !mounted) return;
    setState(() => _form['date_of_birth']!.text = Fmt.dobInput(picked.toIso8601String()));
  }

  @override
  void dispose() {
    _addressGeocodeTimer?.cancel();
    _removeProfileListener();
    for (final c in _form.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _removeProfileListener() {
    try {
      _profileProvider.removeListener(_hydrate);
    } catch (_) {
      // `late` field never initialised (post-frame callback never ran) —
      // nothing to remove.
    }
  }

  Future<void> _detectGps({bool returningFromSettings = false}) async {
    // A manual GPS fix wins over any pending address geocode.
    _addressGeocodeTimer?.cancel();
    _geoSession++;
    setState(() => _detecting = true);
    final access = await _tracking.requestAccess();
    if (!mounted) return;
    if (access != GpsAccess.granted) {
      setState(() => _detecting = false);
      if (!returningFromSettings &&
          (access == GpsAccess.serviceDisabled || access == GpsAccess.deniedForever)) {
        final opened = await promptGpsUnblock(context, _tracking, access);
        if (opened && mounted) await _detectGps(returningFromSettings: true);
        return;
      }
      showAppToast(
        context,
        access == GpsAccess.denied
            ? 'Location permission is required to detect your current position. Please allow location access when the prompt appears.'
            : 'We could not reach the device GPS. Check that location services are on, then try again.',
        type: ToastType.error,
        title: 'Location',
      );
      return;
    }
    final pos = await _tracking.currentPosition();
    if (!mounted) return;
    setState(() {
      _detecting = false;
      if (pos != null) {
        _latitude = pos.latitude;
        _longitude = pos.longitude;
        _form['latitude']!.text = pos.latitude.toString();
        _form['longitude']!.text = pos.longitude.toString();
      }
    });
    showAppToast(
      context,
      pos == null
          ? 'Could not lock a GPS fix. Try again in open air.'
          : 'Live GPS anchor captured: ${pos.latitude.toStringAsFixed(5)}, ${pos.longitude.toStringAsFixed(5)} (±${pos.accuracy.round()}m).',
      type: pos == null ? ToastType.error : ToastType.success,
      title: 'Live Tracking Anchor',
    );
    if (pos == null) return;
    final addr = await GeoService().reverseGeocode(pos.latitude, pos.longitude);
    if (!mounted) return;
    if (addr == null || !addr.hasAny) {
      showAppToast(
        context,
        'GPS fix captured, but the city / state / pincode lookup failed. '
            'Check your internet connection and tap Detect again.',
        type: ToastType.warning,
        title: 'Location',
      );
      return;
    }
    setState(() {
      _fillField('city', addr.city);
      _fillField('state', addr.state);
      _fillField('pincode', addr.pincode);
    });
    showAppToast(
      context,
      [
        if ((addr.city ?? '').isNotEmpty) 'City: ${addr.city}',
        if ((addr.state ?? '').isNotEmpty) 'State: ${addr.state}',
        if ((addr.pincode ?? '').isNotEmpty) 'Pincode: ${addr.pincode}',
      ].join(' • '),
      type: ToastType.success,
      title: 'Address Fetched from Exact GPS',
    );
  }

  void _fillField(String key, String? value) {
    final v = value?.trim() ?? '';
    if (v.isNotEmpty) _form[key]!.text = v;
  }

  /// Web parity (`PanditDashboardPage.jsx` city/state/pincode onChange):
  /// editing the address immediately drops the stale anchor so it is never
  /// saved against a city it no longer belongs to, then re-resolves it once
  /// typing settles. The backend auto-geocodes from the city anyway when
  /// latitude/longitude are omitted, so a failed lookup is safe.
  void _onAddressChanged(String value) {
    _addressGeocodeTimer?.cancel();
    _geoSession++;
    _form['latitude']!.text = '';
    _form['longitude']!.text = '';
    setState(() {
      _latitude = null;
      _longitude = null;
    });
    _addressGeocodeTimer = Timer(const Duration(milliseconds: 900), _autoGeocode);
  }

  /// Manual edit of the Latitude / Longitude text fields wins over any pending
  /// address geocode and keeps the live-track anchor box in sync.
  void _onCoordinateChanged(String value) {
    _addressGeocodeTimer?.cancel();
    _geoSession++;
    final lat = double.tryParse(_form['latitude']!.text.trim());
    final lon = double.tryParse(_form['longitude']!.text.trim());
    setState(() {
      _latitude = lat;
      _longitude = lon;
    });
  }

  /// Best-effort forward geocode of the edited address (web
  /// `autoGeocodeLocation`): city/state/pincode -> fresh lat/lon.
  Future<void> _autoGeocode() async {
    final city = _form['city']!.text.trim();
    final state = _form['state']!.text.trim();
    final pincode = _form['pincode']!.text.trim();
    if (city.isEmpty && pincode.isEmpty) return;
    final session = ++_geoSession;
    final point = await GeoService().geocodeAddress(city: city, state: state, pincode: pincode);
    if (!mounted || point == null || session != _geoSession) return;
    setState(() {
      _latitude = point.latitude;
      _longitude = point.longitude;
      _form['latitude']!.text = point.latitude.toString();
      _form['longitude']!.text = point.longitude.toString();
    });
  }

  Future<void> _save() async {
    if (_form['full_name']!.text.trim().isEmpty) {
      showAppToast(context, 'Please enter your full Acharya name.', type: ToastType.warning, title: 'Profile');
      return;
    }
    if (_form['city']!.text.trim().isEmpty) {
      showAppToast(context, 'Please enter your primary city.', type: ToastType.warning, title: 'Profile');
      return;
    }
    if (_gurukulOther && _form['gurukul']!.text.trim().isEmpty) {
      showAppToast(context, 'Please enter your Gurukul / Sanskrit University name.',
          type: ToastType.warning, title: 'Profile');
      return;
    }
    final payload = <String, dynamic>{};
    for (final k in _fieldKeys) {
      final v = _form[k]!.text.trim();
      if (v.isEmpty) continue;
      if (k == 'experience_years') {
        payload[k] = int.tryParse(v) ?? 0;
      } else if (k == 'date_of_birth') {
        payload[k] = Fmt.dobToIso(v);
      } else if (k == 'latitude' || k == 'longitude') {
        final d = double.tryParse(v);
        if (d != null) payload[k] = d;
      } else {
        payload[k] = v;
      }
    }
    payload['experience_years'] = int.tryParse(_form['experience_years']!.text.trim()) ?? 0;
    payload['availability'] = context.read<PanditProfileProvider>().availability;
    // Coordinates are only ever the untouched saved anchor, a live GPS fix,
    // a fresh geocode of the current address, or a manual Latitude / Longitude
    // edit — editing city/state/pincode clears them, so a stale point can
    // never ride along in the payload.
    if (!payload.containsKey('latitude') && _latitude != null) {
      payload['latitude'] = _latitude;
    }
    if (!payload.containsKey('longitude') && _longitude != null) {
      payload['longitude'] = _longitude;
    }

    final ok = await context.read<PanditProfileProvider>().save(payload);
    if (!mounted) return;
    showAppToast(
      context,
      ok ? 'Acharya Profile Saved!' : 'Could not save your profile. Please try again.',
      type: ok ? ToastType.success : ToastType.error,
      title: 'Profile',
    );
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(context.tr('profile.signOutConfirm')),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(context.tr('common.cancel'))),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(context.tr('auth.signOut'),
                style: const TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await context.read<AuthProvider>().logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<PanditProfileProvider>();
    final auth = context.watch<AuthProvider>();
    final prof = p.profile;
    final loading = p.loading && prof == null;

    return SafeArea(
      child: RefreshIndicator(
        color: AppColors.accent,
        onRefresh: () async {
          await p.load();
          _initialised = false;
          _hydrate();
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
          children: [
            _identityHeader(prof, auth),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: KpiCard(
                    value: prof?.experienceYears == null ? '-' : '${prof!.experienceYears}',
                    label: 'Years Experience',
                    icon: Icons.workspace_premium_outlined,
                    color: AppColors.gold,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: KpiCard(
                    value: p.averageRating == 0 ? '-' : p.averageRating.toStringAsFixed(1),
                    label: 'Devotee Rating',
                    icon: Icons.star_rounded,
                    color: AppColors.warning,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (loading)
              const SectionCard(
                title: 'Loading Acharya Profile',
                emoji: '⏳',
                borderColor: AppColors.info,
                child: LoadingView(label: 'Fetching your credentials...'),
              )
            else ...[
              SectionCard(
                title: 'Personal Identity',
                emoji: '🪪',
                subtitle: 'Basic devotee facing identity shown on assignments.',
                badgeLabel: prof?.isVerified == true ? 'Verified' : 'Under Review',
                badgeColor: prof?.isVerified == true ? AppColors.success : AppColors.warning,
                borderColor: AppColors.info,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppTextField(label: 'Full Acharya Name *', controller: _form['full_name']!),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                            child: AppTextField(
                                label: 'Mobile (WhatsApp) *', controller: _form['phonenumber']!)),
                        const SizedBox(width: 12),
                        Expanded(child: AppTextField(label: 'Email', controller: _form['email']!)),
                      ],
                    ),
                    const SizedBox(height: 14),
                    AppTextField(
                      label: 'Date of Birth',
                      controller: _form['date_of_birth']!,
                      hint: 'DD-Mon-YYYY',
                      suffix: IconButton(
                        icon: const Icon(Icons.calendar_month_outlined, size: 20, color: AppColors.accent),
                        tooltip: 'Pick date of birth',
                        onPressed: _pickDob,
                      ),
                    ),
                    const SizedBox(height: 14),
                    AppTextField(
                      label: 'Bio / About Your Practice',
                      controller: _form['bio']!,
                      hint: 'Tell devotees about your Vedic practice, gurukul and specialisations',
                      maxLines: 4,
                      maxLength: 500,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SectionCard(
                title: 'Vedic Credentials',
                emoji: '🕉️',
                subtitle: 'Gurukul lineage, shakha and verified experience records.',
                badgeLabel: '${prof?.experienceYears ?? 0} Yrs',
                badgeColor: AppColors.gold,
                borderColor: AppColors.gold,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _dropdown('Veda Shakha / Specialization', _form['veda_branch']!.text, _vedaBranches,
                        (v) => setState(() => _form['veda_branch']!.text = v ?? '')),
                    const SizedBox(height: 14),
                    AppTextField(label: 'Gothra (Lineage)', controller: _form['gotra']!),
                    const SizedBox(height: 14),
                    _dropdown(
                      'Gurukul / Sanskrit University',
                      _gurukulOther ? 'Others' : _form['gurukul']!.text,
                      _gurukuls,
                      (v) => setState(() {
                        if (v == 'Others') {
                          _gurukulOther = true;
                          _form['gurukul']!.text = '';
                        } else {
                          _gurukulOther = false;
                          if (v != null) _form['gurukul']!.text = v;
                        }
                      }),
                    ),
                    if (_gurukulOther) ...[
                      const SizedBox(height: 14),
                      AppTextField(
                        label: 'Gurukul / Sanskrit University (Other) *',
                        controller: _form['gurukul']!,
                        hint: 'Please enter your Gurukul name',
                      ),
                    ],
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: AppTextField(
                            label: 'Years of Experience',
                            controller: _form['experience_years']!,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: AppTextField(label: 'Languages', controller: _form['languages']!)),
                      ],
                    ),
                    const SizedBox(height: 14),
                    AppTextField(
                        label: 'Government ID Proof *',
                        controller: _form['any_government_id']!,
                        hint: 'Aadhar / PAN / Voter ID'),
                    const SizedBox(height: 14),
                    AppTextField(
                        label: 'Experience Certificate No.',
                        controller: _form['experance_certificate_number']!),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SectionCard(
                title: 'Location & Live Tracking Anchor',
                emoji: '📍',
                subtitle: 'Primary service area plus the GPS point used for live radar.',
                badgeLabel: _latitude == null ? 'Anchor Missing' : 'Anchor Set',
                badgeColor: _latitude == null ? AppColors.danger : AppColors.success,
                borderColor: _latitude == null ? AppColors.danger : AppColors.success,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                            child: AppTextField(
                                label: 'City *', controller: _form['city']!, onChanged: _onAddressChanged)),
                        const SizedBox(width: 12),
                        Expanded(
                            child: AppTextField(
                                label: 'State', controller: _form['state']!, onChanged: _onAddressChanged)),
                      ],
                    ),
                    const SizedBox(height: 14),
                    AppTextField(label: 'Pincode', controller: _form['pincode']!, onChanged: _onAddressChanged),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                            child: AppTextField(
                                label: 'Latitude',
                                controller: _form['latitude']!,
                                hint: 'e.g. 17.3850',
                                keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                                onChanged: _onCoordinateChanged)),
                        const SizedBox(width: 12),
                        Expanded(
                            child: AppTextField(
                                label: 'Longitude',
                                controller: _form['longitude']!,
                                hint: 'e.g. 78.4867',
                                keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                                onChanged: _onCoordinateChanged)),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(13),
                      decoration: BoxDecoration(
                        color: _latitude == null ? const Color(0xFFFFF7ED) : const Color(0xFFF0FDF4),
                        borderRadius: BorderRadius.circular(13),
                        border: Border.all(
                            color: _latitude == null
                                ? const Color(0xFFFED7AA)
                                : const Color(0xFFBBF7D0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.gps_fixed_rounded,
                                  size: 16,
                                  color: _latitude == null
                                      ? const Color(0xFFC2410C)
                                      : AppColors.success),
                              const SizedBox(width: 7),
                              Text(
                                _latitude == null
                                    ? 'No GPS anchor captured yet'
                                    : 'Anchored at ${_latitude!.toStringAsFixed(5)}, ${_longitude!.toStringAsFixed(5)}',
                                style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w800,
                                    color: _latitude == null
                                        ? const Color(0xFF9A3412)
                                        : const Color(0xFF166534)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 5),
                          Text(
                            'Devotees tracking your live radar start from this point when a journey begins.',
                            style: TextStyle(
                                fontSize: 11,
                                color: (_latitude == null
                                        ? const Color(0xFF9A3412)
                                        : const Color(0xFF166534))
                                    .withValues(alpha: 0.9),
                                height: 1.4),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    AppButton(
                      label: _detecting ? 'Detecting GPS Fix…' : 'Detect My Current GPS Location',
                      loading: _detecting,
                      icon: Icons.my_location_rounded,
                      variant: AppButtonVariant.outline,
                      onPressed: _detectGps,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SectionCard(
                title: 'Dakshina Payment Settings',
                emoji: '💰',
                subtitle: 'Where your ceremony earnings are settled.',
                badgeLabel: (_form['upi_id']!.text.trim().isEmpty) ? 'UPI Pending' : 'UPI Linked',
                badgeColor: (_form['upi_id']!.text.trim().isEmpty) ? AppColors.warning : AppColors.success,
                borderColor: AppColors.accent,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppTextField(label: 'Direct UPI ID', controller: _form['upi_id']!, hint: 'name@okaxis'),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                            child: AppTextField(
                                label: 'Bank Account Number', controller: _form['bank_account']!)),
                        const SizedBox(width: 12),
                        Expanded(child: AppTextField(label: 'IFSC Code', controller: _form['ifsc_code']!)),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.accentLight,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.accent.withValues(alpha: 0.4)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.info_outline_rounded, size: 16, color: AppColors.accent),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Payouts are released within 24 working hours of each completed ceremony to this account.',
                              style: TextStyle(fontSize: 11.5, color: Color(0xFF7C4A03), height: 1.4),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              AppButton(
                label: p.saving ? 'Saving to Database...' : 'Save Acharya Profile to Database',
                loading: p.saving,
                onPressed: _save,
              ),
            ],
            const SizedBox(height: 24),
            SectionCard(
              title: 'More',
              emoji: '⚙️',
              borderColor: AppColors.info,
              badgeColor: AppColors.info,
              headerDivider: false,
              child: Column(
                children: [
                  _moreTile(Icons.star_outline_rounded, AppColors.warning, 'Devotee Reviews',
                      () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ReviewsScreen()))),
                  const Divider(indent: 56, height: 1),
                  _moreTile(Icons.translate_rounded, AppColors.accent, context.tr('common.changeLanguage'),
                      () => Navigator.of(context)
                          .push(MaterialPageRoute(builder: (_) => const LanguageSettingsScreen()))),
                  _moreTile(Icons.notifications_none_rounded, AppColors.info, context.tr('nav.notifications'),
                      () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const NotificationsScreen()))),
                  const Divider(indent: 56, height: 1),
                  _moreTile(Icons.support_agent_rounded, AppColors.success, context.tr('support.helpSupport'),
                      () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SupportScreen())),
                      subtitle: 'Raise a ticket with the Vedic Council'),
                  const Divider(indent: 56, height: 1),
                  _moreTile(Icons.logout_rounded, AppColors.danger, context.tr('auth.signOut'), _logout,
                      danger: true),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Center(
              child: Text('PanditIndia Acharya • v1.0.0',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _identityHeader(dynamic prof, AuthProvider auth) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [AppColors.primary, AppColors.primaryLight]),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.7), width: 1.6),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 38,
            backgroundColor: Colors.white.withValues(alpha: 0.15),
            backgroundImage:
                (prof?.profilePhotoUrl?.isNotEmpty ?? false) ? NetworkImage(prof!.profilePhotoUrl!) : null,
            child: (prof?.profilePhotoUrl?.isNotEmpty ?? false)
                ? null
                : const Text('🕉', style: TextStyle(fontSize: 32)),
          ),
          const SizedBox(height: 12),
          Text(
            prof?.fullName ?? auth.session?.name ?? 'Acharya',
            style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          Text(
            [
              if ((prof?.vedaBranch ?? '').isNotEmpty) prof!.vedaBranch!,
              if ((prof?.city ?? '').isNotEmpty) prof!.city!,
            ].join(' • ').isEmpty
                ? 'Verified Acharya'
                : [
                    if ((prof?.vedaBranch ?? '').isNotEmpty) prof!.vedaBranch!,
                    if ((prof?.city ?? '').isNotEmpty) prof!.city!,
                  ].join(' • '),
            style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 12.5),
          ),
          if ((prof?.bio ?? '').isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              prof!.bio!,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 12, height: 1.45),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              StatusBadge(
                label: prof?.isVerified == true ? 'Verified' : 'Under Verification',
                color: prof?.isVerified == true ? AppColors.success : AppColors.warning,
                dense: true,
              ),
              const SizedBox(width: 8),
              const StatusBadge(label: 'Acharya', color: AppColors.gold, dense: true),
            ],
          ),
        ],
      ),
    );
  }

  Widget _moreTile(IconData icon, Color color, String title, VoidCallback onTap, {String? subtitle, bool danger = false}) {
    return Material(
      type: MaterialType.transparency,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 4),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 20, color: color),
        ),
        title: Text(title,
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: danger ? AppColors.danger : AppColors.textDark)),
        subtitle: subtitle == null
            ? null
            : Text(subtitle, style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted)),
        trailing: Icon(Icons.chevron_right_rounded, color: danger ? AppColors.danger : AppColors.textMuted),
        onTap: onTap,
      ),
    );
  }

  Widget _dropdown(String label, String value, List<String> items, ValueChanged<String?> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(),
            style: const TextStyle(
                fontSize: 10.5, fontWeight: FontWeight.w800, letterSpacing: 1.1, color: AppColors.textMuted)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: items.contains(value) ? value : null,
              isExpanded: true,
              hint: Text('Select ${label.toLowerCase()}',
                  style: const TextStyle(fontSize: 13, color: AppColors.textMuted)),
              style: const TextStyle(fontSize: 13, color: AppColors.textDark, fontWeight: FontWeight.w600),
              items: items.map((i) => DropdownMenuItem(value: i, child: Text(i, overflow: TextOverflow.ellipsis))).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}
