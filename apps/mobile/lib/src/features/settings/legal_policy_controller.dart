import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/dio_provider.dart';

class LegalPolicy {
  const LegalPolicy({
    required this.slug,
    required this.title,
    required this.version,
    required this.effectiveDate,
    required this.body,
    this.stale = false,
  });

  factory LegalPolicy.fromJson(Map<String, dynamic> json) {
    return LegalPolicy(
      slug: json['slug'] as String? ?? '',
      title: json['title'] as String? ?? '',
      version: json['version'] as String? ?? '',
      effectiveDate: json['effectiveDate'] as String? ?? '',
      body: json['body'] as String? ?? '',
    );
  }

  final String slug;
  final String title;
  final String version;
  final String effectiveDate;
  final String body;
  final bool stale;
}

abstract interface class LegalPolicyRepository {
  Future<LegalPolicy> fetchPolicy(String slug);
}

class DioLegalPolicyRepository implements LegalPolicyRepository {
  DioLegalPolicyRepository(this._dio);

  final Dio _dio;

  @override
  Future<LegalPolicy> fetchPolicy(String slug) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/api/v1/legal/policies/$slug',
      );
      return LegalPolicy.fromJson(response.data ?? const {});
    } catch (_) {
      final fallback = _fallbackPolicies[slug];
      if (fallback != null) {
        return fallback;
      }
      rethrow;
    }
  }
}

final legalPolicyRepositoryProvider = Provider<LegalPolicyRepository>(
  (ref) => DioLegalPolicyRepository(ref.watch(dioProvider)),
);

final legalPolicyProvider = FutureProvider.family<LegalPolicy, String>(
  (ref, slug) => ref.watch(legalPolicyRepositoryProvider).fetchPolicy(slug),
);

const legalPolicySlugs = [
  'privacy-policy',
  'terms-of-service',
  'cookies-policy',
];

const _fallbackPolicies = {
  'terms-of-service': LegalPolicy(
    slug: 'terms-of-service',
    title: 'Terms of Service',
    version: '2026-07-22',
    effectiveDate: '2026-07-22',
    stale: true,
    body:
        'These terms describe the basic rules for using Bub. You are responsible for content you send, upload, save, or delete. Removing a tether can permanently delete shared history for that tether.',
  ),
  'privacy-policy': LegalPolicy(
    slug: 'privacy-policy',
    title: 'Privacy Policy',
    version: '2026-07-22',
    effectiveDate: '2026-07-22',
    stale: true,
    body:
        'Bub uses account, tether, chat, Safe, moment, notification, and settings information to provide app features and maintain reliability. Tether-scoped records may be deleted when destructive deletion features are completed.',
  ),
  'cookies-policy': LegalPolicy(
    slug: 'cookies-policy',
    title: 'Cookies Policy',
    version: '2026-07-22',
    effectiveDate: '2026-07-22',
    stale: true,
    body:
        'Bub may use secure local storage, platform caches, cookies, or similar storage for sign-in, preferences, reliability, recent chat cache, and media cache behavior.',
  ),
};
