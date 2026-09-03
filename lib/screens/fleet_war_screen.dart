import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../l10n/app_language.dart';
import '../l10n/strings.dart';
import '../models/ship.dart';
import '../services/fleet_war_service.dart';
import '../services/season.dart';
import '../theme/app_theme.dart';
import '../widgets/count_up_number.dart';
import '../widgets/empty_state.dart';
import '../widgets/game_button.dart';
import '../widgets/game_panel.dart';
import '../widgets/maritime_icon.dart';

class FleetWarScreen extends StatefulWidget {
  final bool embedded;

  const FleetWarScreen({super.key, this.embedded = false});

  @override
  State<FleetWarScreen> createState() => _FleetWarScreenState();
}

class _FleetWarScreenState extends State<FleetWarScreen> {
  final _fleetWarService = FleetWarService();
  final _shipNameController = TextEditingController();
  String? _myShipId;
  bool _loadingShip = true;
  bool _joining = false;

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    _loadCurrentShip();
  }

  @override
  void dispose() {
    _shipNameController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentShip() async {
    final uid = _uid;
    if (uid == null) {
      setState(() => _loadingShip = false);
      return;
    }
    final shipId = await _fleetWarService.currentShip(uid);
    if (!mounted) return;
    setState(() {
      _myShipId = shipId;
      _loadingShip = false;
    });
  }

  Future<void> _joinShip(String name) async {
    final uid = _uid;
    if (uid == null || name.trim().isEmpty) return;
    setState(() => _joining = true);
    await _fleetWarService.joinShip(uid: uid, shipName: name);
    if (!mounted) return;
    setState(() {
      _myShipId = shipIdFromName(name);
      _joining = false;
      _shipNameController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final loggedIn = _uid != null;

    final body = ValueListenableBuilder<AppLanguage>(
      valueListenable: appLanguage,
      builder: (context, language, _) => Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            S.f('fleet_season_info', [currentSeasonKey()]),
            textAlign: TextAlign.center,
            style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.7)),
          ),
          const SizedBox(height: 20),
          if (!loggedIn)
            Text(
              S.t('fleet_no_account'),
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            )
          else if (_loadingShip)
            const Center(child: CircularProgressIndicator())
          else if (_myShipId == null)
            _buildJoinForm(colorScheme)
          else
            Text(
              S.f('fleet_my_ship', [_myShipId!]),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          const SizedBox(height: 24),
          Text(S.t('fleet_ranking_label'), style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.7))),
          const SizedBox(height: 8),
          Expanded(child: _buildLeaderboard(colorScheme)),
        ],
      ),
      ),
    );

    if (widget.embedded) return body;
    return Scaffold(
      appBar: AppBar(title: Text(S.t('tab_fleet'))),
      body: body,
    );
  }

  Widget _buildJoinForm(ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          S.t('fleet_join_prompt'),
          textAlign: TextAlign.center,
          style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.7)),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _shipNameController,
          decoration: InputDecoration(labelText: S.t('fleet_ship_name_label'), hintText: S.t('fleet_ship_name_hint')),
        ),
        const SizedBox(height: 16),
        Center(
          child: GameButton(
            label: _joining ? S.t('fleet_joining') : S.t('fleet_join_button'),
            icon: Icons.anchor,
            fontSize: 15,
            onPressed: _joining ? null : () => _joinShip(_shipNameController.text),
          ),
        ),
      ],
    );
  }

  Widget _buildLeaderboard(ColorScheme colorScheme) {
    return StreamBuilder<List<Ship>>(
      stream: _fleetWarService.watchLeaderboard(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return EmptyState(icon: Icons.wifi_off, message: S.t('ranking_unavailable'));
        }
        final ships = snapshot.data ?? [];
        if (ships.isEmpty) {
          return EmptyState(
            iconWidget: const MaritimeIcon(MaritimeIconShape.sailboat, size: 44, color: AppColors.brass),
            message: S.t('fleet_ranking_empty'),
          );
        }
        return ListView.separated(
          itemCount: ships.length,
          separatorBuilder: (context, index) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final ship = ships[index];
            final isMine = ship.id == _myShipId;
            final medalColor = switch (index) {
              0 => const Color(0xFFFFD54F),
              1 => const Color(0xFFCFD8DC),
              2 => const Color(0xFFD7A86E),
              _ => null,
            };
            return GamePanel(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              borderRadius: 14,
              borderColor: isMine ? AppColors.brassLight : null,
              gradient: isMine ? const LinearGradient(colors: [AppColors.deepSeaLight, AppColors.brassDark]) : null,
              child: Row(
                children: [
                  if (medalColor != null)
                    Icon(Icons.emoji_events, color: medalColor, size: 22)
                  else
                    Text('${index + 1}.', style: displayStyle(fontSize: 15, color: AppColors.canvas.withValues(alpha: 0.7))),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(ship.name, style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.canvas)),
                  ),
                  Row(
                    children: [
                      CountUpNumber(ship.seasonScore, style: displayStyle(fontSize: 14, color: AppColors.brassLight)),
                      Text(' ${S.t('fleet_points_suffix')}', style: displayStyle(fontSize: 14, color: AppColors.brassLight)),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
