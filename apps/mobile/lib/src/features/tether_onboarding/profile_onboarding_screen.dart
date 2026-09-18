import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:photo_manager/photo_manager.dart';

import '../../api/generated/models/user_response.dart';
import '../../auth/auth_controller.dart';
import '../../core/dio_provider.dart';
import '../settings/legal_policy_screen.dart';
import '../../theme/bub_colors.dart';

class ProfileOnboardingSubmission {
  const ProfileOnboardingSubmission({
    required this.fullName,
    required this.age,
    required this.discoveredAppVia,
    required this.relationshipStatus,
    required this.relationshipLength,
  });

  final String fullName;
  final int age;
  final String discoveredAppVia;
  final String relationshipStatus;
  final String relationshipLength;
}

abstract interface class ProfileOnboardingSubmitter {
  Future<UserResponse> submit(ProfileOnboardingSubmission submission);
}

class DioProfileOnboardingSubmitter implements ProfileOnboardingSubmitter {
  DioProfileOnboardingSubmitter(this._dio);

  final Dio _dio;

  @override
  Future<UserResponse> submit(ProfileOnboardingSubmission submission) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      '/api/v1/users/me',
      data: {
        'displayName': submission.fullName,
        'age': submission.age,
        'discoveredAppVia': submission.discoveredAppVia,
        'relationshipStatus': submission.relationshipStatus,
        'relationshipLength': submission.relationshipLength,
        'termsAccepted': true,
      },
    );
    return UserResponse.fromJson(response.data ?? const {});
  }
}

abstract interface class OnboardingPermissionRequester {
  Future<void> requestInitialMediaPermissions();
}

class DeviceOnboardingPermissionRequester
    implements OnboardingPermissionRequester {
  @override
  Future<void> requestInitialMediaPermissions() async {
    await PhotoManager.requestPermissionExtend();

    final scanner = MobileScannerController(autoStart: false);
    try {
      await scanner.start();
      await scanner.stop();
    } catch (_) {
      // The app can still continue; feature screens will show focused errors.
    } finally {
      await scanner.dispose();
    }
  }
}

final profileOnboardingSubmitterProvider = Provider<ProfileOnboardingSubmitter>(
  (ref) => DioProfileOnboardingSubmitter(ref.watch(dioProvider)),
);

final onboardingPermissionRequesterProvider =
    Provider<OnboardingPermissionRequester>(
      (ref) => DeviceOnboardingPermissionRequester(),
    );

class ProfileOnboardingScreen extends ConsumerStatefulWidget {
  const ProfileOnboardingScreen({super.key});

  @override
  ConsumerState<ProfileOnboardingScreen> createState() =>
      _ProfileOnboardingScreenState();
}

class _ProfileOnboardingScreenState
    extends ConsumerState<ProfileOnboardingScreen> {
  static const _totalSteps = 5;

  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  var _step = 0;
  var _accepted = false;
  var _submitting = false;
  String? _source;
  String? _relationshipStatus;
  String? _relationshipLength;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLastStep = _step == _totalSteps - 1;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  key: const Key('profile-onboarding-stepper'),
                  children: [
                    _Header(step: _step, totalSteps: _totalSteps),
                    const SizedBox(height: 20),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 180),
                      child: switch (_step) {
                        0 => _IdentityStep(
                          nameController: _nameController,
                          ageController: _ageController,
                        ),
                        1 => _SourceStep(
                          selected: _source,
                          onChanged: _setSource,
                        ),
                        2 => _RelationshipStatusStep(
                          selected: _relationshipStatus,
                          onChanged: _setRelationshipStatus,
                        ),
                        3 => _RelationshipLengthStep(
                          selected: _relationshipLength,
                          onChanged: _setRelationshipLength,
                        ),
                        _ => _TermsStep(
                          accepted: _accepted,
                          onChanged: (value) =>
                              setState(() => _accepted = value ?? false),
                        ),
                      },
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xFFB91C1C),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FilledButton(
                    key: Key(
                      isLastStep
                          ? 'profile-finish-button'
                          : 'profile-next-button',
                    ),
                    onPressed: _submitting
                        ? null
                        : isLastStep
                        ? _finish
                        : _next,
                    child: _submitting
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(isLastStep ? 'Continue' : 'Next'),
                  ),
                  if (_step > 0) ...[
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: _submitting
                          ? null
                          : () => setState(() {
                              _step -= 1;
                              _error = null;
                            }),
                      child: const Text('Back'),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _setSource(String value) {
    setState(() {
      _source = value;
      _error = null;
    });
  }

  void _setRelationshipStatus(String value) {
    setState(() {
      _relationshipStatus = value;
      _error = null;
    });
  }

  void _setRelationshipLength(String value) {
    setState(() {
      _relationshipLength = value;
      _error = null;
    });
  }

  void _next() {
    if (_step == 0 && !_identityValid()) {
      return;
    }
    if (_step == 1 && _source == null) {
      setState(() => _error = 'Choose where you found Bub');
      return;
    }
    if (_step == 2 && _relationshipStatus == null) {
      setState(() => _error = 'Choose your relationship status');
      return;
    }
    if (_step == 3 && _relationshipLength == null) {
      setState(() => _error = 'Choose how long you have been together');
      return;
    }
    setState(() {
      _step += 1;
      _error = null;
    });
  }

  bool _identityValid() {
    final age = int.tryParse(_ageController.text.trim());
    if (_nameController.text.trim().isEmpty) {
      setState(() => _error = 'Enter your full name');
      return false;
    }
    if (age == null || age < 13 || age > 120) {
      setState(() => _error = 'Enter an age from 13 to 120');
      return false;
    }
    return true;
  }

  Future<void> _finish() async {
    if (!_accepted) {
      setState(
        () => _error = 'Accept the Terms and Privacy Policy to continue',
      );
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await ref
          .read(onboardingPermissionRequesterProvider)
          .requestInitialMediaPermissions();
      final user = await ref
          .read(profileOnboardingSubmitterProvider)
          .submit(
            ProfileOnboardingSubmission(
              fullName: _nameController.text.trim(),
              age: int.parse(_ageController.text.trim()),
              discoveredAppVia: _source!,
              relationshipStatus: _relationshipStatus!,
              relationshipLength: _relationshipLength!,
            ),
          );
      await ref
          .read(authControllerProvider.notifier)
          .completeProfileOnboarding(user);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Could not save your profile');
      }
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.step, required this.totalSteps});

  final int step;
  final int totalSteps;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Image.asset(
          'assets/illustrations/bears/bear2.png',
          height: 132,
          fit: BoxFit.contain,
        ),
        const SizedBox(height: 10),
        Text(
          'Set up your profile',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Theme.of(context).textTheme.displayMedium?.color,
            fontSize: 28,
            fontWeight: FontWeight.w900,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            totalSteps,
            (index) => Container(
              width: index == step ? 28 : 9,
              height: 9,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: index == step
                    ? BubColors.purple
                    : BubColors.purple.withValues(alpha: 0.24),
                borderRadius: BorderRadius.circular(9),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _IdentityStep extends StatelessWidget {
  const _IdentityStep({
    required this.nameController,
    required this.ageController,
  });

  final TextEditingController nameController;
  final TextEditingController ageController;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey('identity-step'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          key: const Key('profile-full-name-field'),
          controller: nameController,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(labelText: 'Full name'),
        ),
        const SizedBox(height: 14),
        TextField(
          key: const Key('profile-age-field'),
          controller: ageController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Age'),
        ),
      ],
    );
  }
}

class _SourceStep extends StatelessWidget {
  const _SourceStep({required this.selected, required this.onChanged});

  final String? selected;
  final ValueChanged<String> onChanged;

  static const _options = <_SelectableOptionData>[
    _SelectableOptionData(
      value: 'tiktok',
      label: 'TikTok',
      keyName: 'source-tiktok-option',
      materialIcon: Icons.tiktok,
    ),
    _SelectableOptionData(
      value: 'playstore',
      label: 'Play Store',
      keyName: 'source-playstore-option',
      brandIcon: FontAwesomeIcons.googlePlay,
    ),
    _SelectableOptionData(
      value: 'recommendation',
      label: 'Recommendation',
      keyName: 'source-recommendation-option',
      materialIcon: Icons.favorite_outline_rounded,
    ),
    _SelectableOptionData(
      value: 'others',
      label: 'Others',
      keyName: 'source-others-option',
      materialIcon: Icons.more_horiz_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey('source-step'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Where did you find Bub?',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        for (final option in _options)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _SelectableOptionTile(
              option: option,
              selected: selected == option.value,
              onTap: () => onChanged(option.value),
            ),
          ),
      ],
    );
  }
}

class _RelationshipStatusStep extends StatelessWidget {
  const _RelationshipStatusStep({
    required this.selected,
    required this.onChanged,
  });

  final String? selected;
  final ValueChanged<String> onChanged;

  static const _options = <_SelectableOptionData>[
    _SelectableOptionData(
      value: 'dating',
      label: 'Dating',
      keyName: 'relationship-status-dating',
      materialIcon: Icons.favorite_border_rounded,
    ),
    _SelectableOptionData(
      value: 'engaged',
      label: 'Engaged',
      keyName: 'relationship-status-engaged',
      materialIcon: Icons.diamond_outlined,
    ),
    _SelectableOptionData(
      value: 'married',
      label: 'Married',
      keyName: 'relationship-status-married',
      materialIcon: Icons.diversity_1_outlined,
    ),
    _SelectableOptionData(
      value: 'long_distance',
      label: 'Long distance',
      keyName: 'relationship-status-long-distance',
      materialIcon: Icons.flight_outlined,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey('relationship-status-step'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'What is your relationship status?',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        for (final option in _options)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _SelectableOptionTile(
              option: option,
              selected: selected == option.value,
              onTap: () => onChanged(option.value),
            ),
          ),
      ],
    );
  }
}

class _RelationshipLengthStep extends StatelessWidget {
  const _RelationshipLengthStep({
    required this.selected,
    required this.onChanged,
  });

  final String? selected;
  final ValueChanged<String> onChanged;

  static const _options = <_SelectableOptionData>[
    _SelectableOptionData(
      value: 'under_3_months',
      label: 'Under 3 months',
      keyName: 'relationship-length-under-3-months',
      materialIcon: Icons.hourglass_bottom_rounded,
    ),
    _SelectableOptionData(
      value: '3_to_12_months',
      label: '3–12 months',
      keyName: 'relationship-length-3-to-12-months',
      materialIcon: Icons.calendar_month_outlined,
    ),
    _SelectableOptionData(
      value: '1_to_3_years',
      label: '1–3 years',
      keyName: 'relationship-length-1-to-3-years',
      materialIcon: Icons.event_available_outlined,
    ),
    _SelectableOptionData(
      value: '3_plus_years',
      label: '3+ years',
      keyName: 'relationship-length-3-plus-years',
      materialIcon: Icons.workspace_premium_outlined,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey('relationship-length-step'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'How long have you been together?',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        for (final option in _options)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _SelectableOptionTile(
              option: option,
              selected: selected == option.value,
              onTap: () => onChanged(option.value),
            ),
          ),
      ],
    );
  }
}

class _SelectableOptionData {
  const _SelectableOptionData({
    required this.value,
    required this.label,
    required this.keyName,
    this.materialIcon,
    this.brandIcon,
  });

  final String value;
  final String label;
  final String keyName;
  final IconData? materialIcon;
  final FaIconData? brandIcon;
}

class _SelectableOptionTile extends StatelessWidget {
  const _SelectableOptionTile({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final _SelectableOptionData option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;
    final borderColor = selected
        ? BubColors.purple
        : BubColors.purple.withValues(alpha: 0.45);

    return Material(
      color: selected
          ? BubColors.purple.withValues(alpha: 0.08)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        key: Key(option.keyName),
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: borderColor, width: selected ? 2 : 1.5),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 28,
                child: Center(
                  child: option.brandIcon != null
                      ? FaIcon(
                          option.brandIcon,
                          size: 22,
                          color: BubColors.purple,
                        )
                      : Icon(
                          option.materialIcon,
                          size: 26,
                          color: BubColors.purple,
                        ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  option.label,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 16,
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  ),
                ),
              ),
              if (selected)
                const Icon(
                  Icons.check_circle_rounded,
                  color: BubColors.purple,
                  size: 22,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TermsStep extends StatelessWidget {
  const _TermsStep({required this.accepted, required this.onChanged});

  final bool accepted;
  final ValueChanged<bool?> onChanged;

  @override
  Widget build(BuildContext context) {
    return CheckboxListTile(
      key: const Key('terms-accept-checkbox'),
      controlAffinity: ListTileControlAffinity.leading,
      contentPadding: EdgeInsets.zero,
      value: accepted,
      onChanged: onChanged,
      title: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          const Text('I agree to Bub '),
          _PolicyLink(
            key: const Key('terms-policy-link'),
            label: 'Terms of Service',
            slug: 'terms-of-service',
          ),
          const Text(' and '),
          _PolicyLink(
            key: const Key('privacy-policy-link'),
            label: 'Privacy Policy',
            slug: 'privacy-policy',
          ),
        ],
      ),
      subtitle: const Text('You can review these anytime in Settings.'),
      checkboxShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

class _PolicyLink extends StatelessWidget {
  const _PolicyLink({super.key, required this.label, required this.slug});

  final String label;
  final String slug;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      style: TextButton.styleFrom(
        minimumSize: Size.zero,
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
      ),
      onPressed: () {
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => LegalPolicyScreen(slug: slug),
          ),
        );
      },
      child: Text(label),
    );
  }
}
