import 'package:flutter/material.dart';

import '../../../app/app.dart';
import '../../../app/router.dart';
import '../../../app/theme.dart';
import '../../../app/widgets.dart';
import '../../../l10n/app_localizations.dart';
import '../../result/presentation/results_list_screen.dart';
import '../../appeal/presentation/appeals_screen.dart';
import '../../practice/presentation/recordings_screen.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/graphql_client.dart';
import '../../../core/storage/preference_storage.dart';
import '../../../core/storage/secure_storage.dart';
import '../../auth/data/auth_api.dart';
import '../../auth/data/auth_repository.dart';
import '../data/models/profile.dart';
import '../data/profile_api.dart';
import '../data/profile_repository.dart';


class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _profileRepository = ProfileRepository(ProfileApi(GraphQLClient()));
  final _authRepository = AuthRepository(
    authApi: AuthApi(ApiClient()),
    secureStorage: SecureStorage(),
  );

  Profile? _profile;
  bool _loading = true;

  Future<void> _logout() async {
    await _authRepository.logout();
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil(
      AppRouter.login,
      (route) => false,
    );
  }

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _loading = true);
    try {
      final profile = await _profileRepository.getProfile();
      if (!mounted) return;
      setState(() => _profile = profile);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.profileLoadError)),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String? _roleLabel(AppLocalizations l10n) {
    switch (_profile?.roleCode) {
      case 'SYSTEM_ADMIN':
        return l10n.roleSystemAdmin;
      case 'SCHOOL_ADMIN':
        return l10n.roleSchoolAdmin;
      case 'TEACHER':
        return l10n.roleTeacher;
      case 'STUDENT':
        return l10n.roleStudent;
      default:
        return _profile?.role;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Header ──
        Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          decoration: const BoxDecoration(
            color: AppColors.headerBg,
            border: Border(bottom: BorderSide(color: AppColors.border)),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.profileTitle,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                      ),
                    ),
                  ),
                  IconCircle(Icons.settings_outlined, onTap: () {}),
                ],
              ),
              const SizedBox(height: 10),
              const CircleAvatar(
                radius: 38,
                backgroundColor: Color(0xFFDDDDDD),
                child: Icon(Icons.person, size: 40, color: Color(0xFFAAAAAA)),
              ),
              const SizedBox(height: 10),
              if (_loading)
                const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      _profile?.fullName ?? _profile?.email ?? l10n.defaultUserName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                      ),
                    ),
                    if (_profile?.schoolName != null) ...[
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 6),
                        child: Text(
                          '·',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textGhost,
                          ),
                        ),
                      ),
                      Text(
                        _profile!.schoolName!,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textFaint,
                        ),
                      ),
                    ],
                  ],
                ),
              const SizedBox(height: 1),
              Text(
                _profile?.email ?? '',
                style: const TextStyle(fontSize: 13, color: AppColors.textFaint),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_roleLabel(l10n) != null) ...[
                    TagChip.blue(_roleLabel(l10n)!),
                    const SizedBox(width: 8),
                  ],
                  TagChip.green(l10n.statusActive),
                ],
              ),
            ],
          ),
        ),

        // ── Scroll body ──
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            children: [
              if (_profile?.roleCode != 'TEACHER') ...[
                Row(
                  children: [
                    Expanded(child: _StatBox(value: '24', label: l10n.statPracticesDone)),
                    const SizedBox(width: 10),
                    Expanded(child: _StatBox(value: '7.8', label: l10n.statAverageScore)),
                    const SizedBox(width: 10),
                    Expanded(child: _StatBox(value: '12', label: l10n.statDayStreak)),
                  ],
                ),
                const SizedBox(height: 20),
              ],

              SectionLabel(l10n.sectionAccount),
              const SizedBox(height: 10),
              _MenuGroup(items: [
                if (_profile?.roleCode != 'TEACHER') ...[
                  _MenuItem(
                    icon: Icons.description_outlined,
                    label: l10n.menuMyResults,
                    target: _Target.results,
                  ),
                  _MenuItem(
                    icon: Icons.mic_none,
                    label: l10n.menuRecordings,
                    target: _Target.recordings,
                  ),
                ],
                _MenuItem(
                  icon: Icons.error_outline,
                  label: l10n.menuAppeals,
                  target: _Target.appeals,
                ),
              ]),
              const SizedBox(height: 20),

              SectionLabel(l10n.sectionSettings),
              const SizedBox(height: 10),
              _SettingsMenuGroup(onLogout: _logout),
            ],
          ),
        ),
      ],
    );
  }
}

class _SettingsMenuGroup extends StatefulWidget {
  const _SettingsMenuGroup({required this.onLogout});
  final VoidCallback onLogout;

  @override
  State<_SettingsMenuGroup> createState() => _SettingsMenuGroupState();
}

class _SettingsMenuGroupState extends State<_SettingsMenuGroup> {
  bool _notificationsEnabled = true;

  @override
  void initState() {
    super.initState();
    PreferenceStorage().getNotificationsEnabled().then((value) {
      if (mounted) setState(() => _notificationsEnabled = value);
    });
  }

  Future<void> _pickLanguage() async {
    final l10n = AppLocalizations.of(context)!;
    final current = Localizations.localeOf(context).languageCode;
    final selected = await showModalBottomSheet<String>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(l10n.chooseLanguage,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            ),
            ListTile(
              title: Text(l10n.languageEnglish),
              trailing: current == 'en' ? const Icon(Icons.check) : null,
              onTap: () => Navigator.of(sheetContext).pop('en'),
            ),
            ListTile(
              title: Text(l10n.languageVietnamese),
              trailing: current == 'vi' ? const Icon(Icons.check) : null,
              onTap: () => Navigator.of(sheetContext).pop('vi'),
            ),
          ],
        ),
      ),
    );
    if (selected != null && mounted) {
      App.setLocale(context, Locale(selected));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return _MenuGroup(items: [
      _MenuItem(
        icon: Icons.language,
        label: l10n.menuLanguage,
        onTap: _pickLanguage,
      ),
      _MenuItem(
        icon: Icons.notifications_none,
        label: l10n.menuNotifications,
        showArrow: false,
        trailing: Switch(
          value: _notificationsEnabled,
          onChanged: (value) async {
            await PreferenceStorage().saveNotificationsEnabled(value);
            if (mounted) setState(() => _notificationsEnabled = value);
          },
        ),
      ),
      _MenuItem(
        icon: Icons.logout,
        label: l10n.menuLogOut,
        danger: true,
        showArrow: false,
        onTap: widget.onLogout,
      ),
    ]);
  }
}

class _StatBox extends StatelessWidget {
  const _StatBox({required this.value, required this.label});
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 1.5),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label.toUpperCase(),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.4,
              color: AppColors.textGhost,
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuGroup extends StatelessWidget {
  const _MenuGroup({required this.items});
  final List<_MenuItem> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (int i = 0; i < items.length; i++)
          Container(
            decoration: BoxDecoration(
              border: i == items.length - 1
                  ? null
                  : const Border(
                      bottom: BorderSide(color: AppColors.borderSoft),
                    ),
            ),
            child: items[i],
          ),
      ],
    );
  }
}

enum _Target { none, results, appeals, recordings }

class _MenuItem extends StatelessWidget {
  const _MenuItem({
    required this.icon,
    required this.label,
    this.danger = false,
    this.showArrow = true,
    this.target = _Target.none,
    this.onTap,
    this.trailing,
  });

  final IconData icon;
  final String label;
  final bool danger;
  final bool showArrow;
  final _Target target;
  final VoidCallback? onTap;
  final Widget? trailing;

  void _go(BuildContext context) {
    if (onTap != null) {
      onTap!();
      return;
    }
    switch (target) {
      case _Target.results:
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const ResultsListScreen()),
        );
      case _Target.appeals:
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const AppealsScreen()),
        );
      case _Target.recordings:
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const RecordingsScreen()),
        );
      case _Target.none:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final fg = danger ? AppColors.danger : const Color(0xFF555555);
    return InkWell(
      onTap: () => _go(context),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: danger ? AppColors.dangerBg : AppColors.fieldBg,
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(icon, size: 18, color: fg),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: danger ? AppColors.danger : const Color(0xFF222222),
                ),
              ),
            ),
            if (trailing != null)
              trailing!
            else if (showArrow)
              const Icon(Icons.chevron_right,
                  size: 18, color: Color(0xFFCCCCCC)),
          ],
        ),
      ),
    );
  }
}