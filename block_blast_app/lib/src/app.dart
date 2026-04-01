import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:instantdb_flutter/instantdb_flutter.dart';

import 'session_store.dart';
import 'session_store.dart'
    if (dart.library.io) 'session_store_io.dart'
    if (dart.library.html) 'session_store_web.dart'
    as session_store_factory;
import 'telemetry.dart';

const List<int> kGridSizes = <int>[8, 10, 12, 16, 24, 32];
const String kAppVersion = String.fromEnvironment(
  'APP_VERSION',
  defaultValue: '1.0.0+1',
);
const String kReleaseFlavor = String.fromEnvironment(
  'FLAVOR',
  defaultValue: 'prod',
);

class AetherBlockBlastApp extends StatefulWidget {
  const AetherBlockBlastApp({super.key});

  @override
  State<AetherBlockBlastApp> createState() => _AetherBlockBlastAppState();
}

class _AetherBlockBlastAppState extends State<AetherBlockBlastApp> {
  late final GameController _controller;

  @override
  void initState() {
    super.initState();
    _controller = GameController(
      store: session_store_factory.createSessionStore(),
      audioController: AudioController(),
      syncService: AetherSyncService(),
    )..load();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Aether Block Blast',
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(),
      home: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return GameScreen(controller: _controller);
        },
      ),
    );
  }

  ThemeData _buildTheme() {
    const seed = Color(0xFF2DE2E6);
    final scheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: Brightness.dark,
      primary: const Color(0xFF2DE2E6),
      secondary: const Color(0xFF58F2C8),
      tertiary: const Color(0xFFFFC857),
      surface: const Color(0xFF10192B),
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: const Color(0xFF08111E),
      textTheme: Typography.whiteMountainView.copyWith(
        displaySmall: const TextStyle(
          fontSize: 40,
          fontWeight: FontWeight.w900,
          letterSpacing: -1.1,
        ),
        headlineSmall: const TextStyle(
          fontSize: 26,
          fontWeight: FontWeight.w800,
        ),
        titleMedium: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        bodyMedium: const TextStyle(fontSize: 15, height: 1.35),
      ),
    );
  }
}

class GameScreen extends StatelessWidget {
  const GameScreen({super.key, required this.controller});

  final GameController controller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[
              Color(0xFF050B14),
              Color(0xFF0A1730),
              Color(0xFF091423),
            ],
          ),
        ),
        child: Stack(
          children: <Widget>[
            const Positioned.fill(child: Starfield()),
            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth >= 1120;
                  final isCompact = constraints.maxWidth < 760;
                  final horizontalPadding = isCompact ? 16.0 : 24.0;
                  final boardMax = math.min(
                    isWide
                        ? constraints.maxWidth * 0.52
                        : constraints.maxWidth - (horizontalPadding * 2),
                    constraints.maxHeight * (isWide ? 0.68 : 0.43),
                  );
                  return Padding(
                    padding: EdgeInsets.fromLTRB(
                      horizontalPadding,
                      16,
                      horizontalPadding,
                      16,
                    ),
                    child: isWide
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Expanded(
                                flex: 6,
                                child: Column(
                                  children: <Widget>[
                                    HeaderPanel(controller: controller),
                                    const SizedBox(height: 18),
                                    Expanded(
                                      child: Center(
                                        child: BoardPanel(
                                          controller: controller,
                                          size: boardMax,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 18),
                                    PieceTray(controller: controller),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 20),
                              SizedBox(
                                width: 320,
                                child: SideRail(controller: controller),
                              ),
                            ],
                          )
                        : Column(
                            children: <Widget>[
                              HeaderPanel(controller: controller),
                              const SizedBox(height: 14),
                              BoardPanel(
                                controller: controller,
                                size: boardMax,
                              ),
                              const SizedBox(height: 14),
                              PieceTray(controller: controller),
                              const SizedBox(height: 14),
                              Expanded(
                                child: SingleChildScrollView(
                                  child: SideRail(controller: controller),
                                ),
                              ),
                            ],
                          ),
                  );
                },
              ),
            ),
            if (controller.praiseBanner != null)
              PraiseOverlay(
                text: controller.praiseBanner!,
                scoreDelta: controller.lastScoreDelta,
                boardCleared: controller.lastBoardWipe,
              ),
            if (controller.shouldShowRunSummary)
              RunSummaryOverlay(controller: controller),
            if (controller.needsPrivacyConsent)
              PrivacyConsentOverlay(controller: controller),
            if (controller.shouldShowOnboarding)
              OnboardingOverlay(controller: controller),
            if (controller.isLoading)
              const Positioned.fill(
                child: ColoredBox(
                  color: Color(0x88071118),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class HeaderPanel extends StatelessWidget {
  const HeaderPanel({super.key, required this.controller});

  final GameController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GlassPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Aether Block Blast',
                      style: theme.textTheme.displaySmall,
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: <Widget>[
                        Pill(
                          icon: Icons.cloud_sync_outlined,
                          label: controller.syncLabel,
                          tone: controller.syncTone,
                        ),
                        Pill(
                          icon: Icons.dashboard_customize_outlined,
                          label:
                              '${controller.boardSize}x${controller.boardSize}',
                          tone: const Color(0xFF2DE2E6),
                        ),
                        Pill(
                          icon: Icons.bolt_outlined,
                          label: controller.gameOver
                              ? 'Run Ended'
                              : 'Move ${controller.moveCount + 1}',
                          tone: controller.gameOver
                              ? const Color(0xFFFF6B6B)
                              : const Color(0xFFFFC857),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              AvatarBadge(seed: controller.playerId.hashCode),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: <Widget>[
              MetricCard(
                label: 'Score',
                value: controller.score.toString(),
                accent: const Color(0xFF2DE2E6),
              ),
              MetricCard(
                label: 'Best',
                value: controller.bestScoreForSize.toString(),
                accent: const Color(0xFFFFC857),
              ),
              MetricCard(
                label: 'Combo',
                value: 'x${controller.combo}',
                accent: const Color(0xFF58F2C8),
              ),
              MetricCard(
                label: 'Clear Power',
                value: controller.lastClearSummary,
                accent: const Color(0xFFFF8F6B),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class SideRail extends StatelessWidget {
  const SideRail({super.key, required this.controller});

  final GameController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        GlassPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('Pilot Profile', style: theme.textTheme.headlineSmall),
              const SizedBox(height: 10),
              Text(
                controller.playerCallsign,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: const Color(0xFF2DE2E6),
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  Pill(
                    icon: Icons.local_fire_department_outlined,
                    label: 'Daily Streak ${controller.dailyStreak}',
                    tone: const Color(0xFFFF8F6B),
                  ),
                  Pill(
                    icon: Icons.military_tech_outlined,
                    label: 'Best Combo x${controller.bestCombo}',
                    tone: const Color(0xFF58F2C8),
                  ),
                  Pill(
                    icon: Icons.leaderboard_outlined,
                    label: controller.leaderboardLabel,
                    tone: const Color(0xFF9FB6FF),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                'Cloud identity is still lightweight, but the profile rail now exposes streak and leaderboard status so returning players get immediate context.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        GlassPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('Grid Tiers', style: theme.textTheme.headlineSmall),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: kGridSizes
                    .map(
                      (size) => ChoiceChip(
                        label: Text('$size x $size'),
                        selected: controller.boardSize == size,
                        onSelected: (_) => controller.changeGrid(size),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 12),
              Text(
                'Larger grids reward harder play with stronger score scaling and more volatile board pressure.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        GlassPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('Challenge Pulse', style: theme.textTheme.headlineSmall),
              const SizedBox(height: 12),
              ChallengeCard(
                title: 'Daily Rift',
                subtitle: controller.dailyChallengeText,
                reward: controller.dailyChallengeReward,
                accent: const Color(0xFF58F2C8),
                status: controller.dailyChallengeStatus,
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  FilledButton.icon(
                    onPressed: controller.jumpToDailyChallenge,
                    icon: const Icon(Icons.rocket_launch_outlined),
                    label: const Text('Jump to Daily Grid'),
                  ),
                  OutlinedButton.icon(
                    onPressed: controller.canClaimDailyReward
                        ? controller.claimDailyReward
                        : null,
                    icon: const Icon(Icons.card_giftcard_outlined),
                    label: Text(
                      controller.canClaimDailyReward
                          ? 'Claim Daily Reward'
                          : 'Reward Claimed',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ChallengeCard(
                title: 'Streak Core',
                subtitle: controller.dailyStreakText,
                reward: controller.dailyStreakReward,
                accent: const Color(0xFF2DE2E6),
                status: controller.dailyStreakStatus,
              ),
              const SizedBox(height: 10),
              ChallengeCard(
                title: 'Aurora Cascade',
                subtitle: controller.cascadeChallengeText,
                reward: controller.cascadeChallengeReward,
                accent: const Color(0xFFFFC857),
                status: controller.cascadeChallengeStatus,
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        GlassPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('Audio Matrix', style: theme.textTheme.headlineSmall),
              const SizedBox(height: 12),
              ToggleRow(
                label: 'Music',
                value: controller.musicEnabled,
                onChanged: controller.toggleMusic,
              ),
              ToggleRow(
                label: 'SFX',
                value: controller.sfxEnabled,
                onChanged: controller.toggleSfx,
              ),
              ToggleRow(
                label: 'Voice',
                value: controller.voiceEnabled,
                onChanged: controller.toggleVoice,
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        GlassPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Accessibility and Comfort',
                style: theme.textTheme.headlineSmall,
              ),
              const SizedBox(height: 12),
              ToggleRow(
                label: 'Haptics',
                value: controller.hapticsEnabled,
                onChanged: controller.toggleHaptics,
              ),
              ToggleRow(
                label: 'Reduced Motion',
                value: controller.reducedMotion,
                onChanged: controller.toggleReducedMotion,
              ),
              ToggleRow(
                label: 'High Contrast',
                value: controller.highContrast,
                onChanged: controller.toggleHighContrast,
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        GlassPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Commercial Readiness',
                style: theme.textTheme.headlineSmall,
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  Pill(
                    icon: controller.privacyConsentGiven
                        ? Icons.verified_user_outlined
                        : Icons.shield_outlined,
                    label: controller.privacyConsentGiven
                        ? 'Privacy: Accepted'
                        : 'Privacy: Required',
                    tone: controller.privacyConsentGiven
                        ? const Color(0xFF58F2C8)
                        : const Color(0xFFFFC857),
                  ),
                  Pill(
                    icon: Icons.insights_outlined,
                    label: 'Events ${controller.telemetryEventCount}',
                    tone: const Color(0xFF2DE2E6),
                  ),
                  Pill(
                    icon: Icons.info_outline,
                    label: 'v$kAppVersion',
                    tone: const Color(0xFFFF8F6B),
                  ),
                  Pill(
                    icon: Icons.flag_outlined,
                    label: 'Flavor: $kReleaseFlavor',
                    tone: const Color(0xFF9FB6FF),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                'Privacy and terms apply to optional cloud sync usage. Consent is stored in your local session.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: () async {
                  await Clipboard.setData(
                    ClipboardData(text: controller.buildSessionSnapshot()),
                  );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Session snapshot copied')),
                    );
                  }
                },
                icon: const Icon(Icons.copy_all_outlined),
                label: const Text('Copy Session Snapshot'),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () async {
                  await Clipboard.setData(
                    ClipboardData(text: controller.buildDiagnosticsReport()),
                  );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Diagnostics report copied'),
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.fact_check_outlined),
                label: const Text('Copy Diagnostics'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        GlassPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Monetization Sandbox',
                style: theme.textTheme.headlineSmall,
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  Pill(
                    icon: controller.premiumUnlocked
                        ? Icons.workspace_premium_outlined
                        : Icons.lock_outline,
                    label: controller.premiumUnlocked
                        ? 'Premium: Unlocked'
                        : 'Premium: Locked',
                    tone: controller.premiumUnlocked
                        ? const Color(0xFFFFC857)
                        : const Color(0xFFFF8F6B),
                  ),
                  Pill(
                    icon: Icons.token_outlined,
                    label: 'Revive Tokens: ${controller.reviveTokens}',
                    tone: const Color(0xFF58F2C8),
                  ),
                  Pill(
                    icon: Icons.smart_display_outlined,
                    label: controller.adReady
                        ? 'Rewarded Ad: Ready'
                        : 'Ad: Busy',
                    tone: controller.adReady
                        ? const Color(0xFF2DE2E6)
                        : const Color(0xFFFFC857),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                'Hooks are simulation-only for now. They capture telemetry and session persistence so real billing/ads SDK wiring can be added safely.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  FilledButton.icon(
                    onPressed: controller.premiumUnlocked
                        ? null
                        : controller.unlockPremium,
                    icon: const Icon(Icons.workspace_premium),
                    label: const Text('Unlock Premium (Simulated)'),
                  ),
                  OutlinedButton.icon(
                    onPressed: controller.adReady
                        ? controller.watchRewardedAd
                        : null,
                    icon: const Icon(Icons.smart_display),
                    label: const Text('Watch Rewarded Ad (Simulated)'),
                  ),
                  OutlinedButton.icon(
                    onPressed: controller.canRevive
                        ? controller.useReviveToken
                        : null,
                    icon: const Icon(Icons.favorite_outline),
                    label: const Text('Use Revive Token'),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        GlassPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('Actions', style: theme.textTheme.headlineSmall),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: controller.startNewRun,
                icon: const Icon(Icons.refresh),
                label: const Text('New Run'),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: controller.gameOver
                    ? controller.startNewRun
                    : controller.clearSelection,
                icon: Icon(
                  controller.gameOver ? Icons.play_arrow : Icons.close,
                ),
                label: Text(
                  controller.gameOver
                      ? 'Restart Current Tier'
                      : 'Clear Selection',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class BoardPanel extends StatelessWidget {
  const BoardPanel({super.key, required this.controller, required this.size});

  final GameController controller;
  final double size;

  @override
  Widget build(BuildContext context) {
    final idleCellColor = controller.highContrast
        ? const Color(0xFF182235)
        : const Color(0x331B3356);
    final previewCellColor = controller.highContrast
        ? const Color(0xFF2A6B5C)
        : const Color(0x8858F2C8);
    final filledCellColor = controller.highContrast
        ? const Color(0xFFF3FAFF)
        : const Color(0xFF2DE2E6);
    final filledBorderColor = controller.highContrast
        ? const Color(0xFF040A14)
        : const Color(0xFF9AF8FF);
    return GlassPanel(
      padding: const EdgeInsets.all(16),
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          children: <Widget>[
            Column(
              children: List<Widget>.generate(controller.boardSize, (row) {
                return Expanded(
                  child: Row(
                    children: List<Widget>.generate(controller.boardSize, (
                      col,
                    ) {
                      final occupied = controller.board[row][col];
                      final preview = controller.previewCells.contains(
                        Cell(row, col),
                      );
                      return Expanded(
                        child: GestureDetector(
                          onTap: controller.gameOver
                              ? null
                              : () => controller.placeSelectedAt(row, col),
                          child: AnimatedContainer(
                            duration: controller.reducedMotion
                                ? Duration.zero
                                : const Duration(milliseconds: 140),
                            margin: const EdgeInsets.all(1.5),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(6),
                              color: occupied
                                  ? filledCellColor
                                  : preview
                                  ? previewCellColor
                                  : idleCellColor,
                              border: Border.all(
                                color: occupied
                                    ? filledBorderColor
                                    : preview
                                    ? const Color(0xFF58F2C8)
                                    : const Color(0x33416B9E),
                              ),
                              boxShadow: occupied
                                  ? <BoxShadow>[
                                      BoxShadow(
                                        color: const Color(
                                          0xAA2DE2E6,
                                        ).withValues(alpha: 0.35),
                                        blurRadius: 10,
                                        spreadRadius: 0.5,
                                      ),
                                    ]
                                  : const <BoxShadow>[],
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                );
              }),
            ),
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: const Color(0x444E7FC4),
                      width: 1.2,
                    ),
                  ),
                ),
              ),
            ),
            if (controller.selectedPiece != null)
              Positioned(
                left: 14,
                bottom: 14,
                child: Text(
                  'Tap a cell to anchor ${controller.selectedPiece!.name}',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
                ),
              ),
            if (controller.gameOver)
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: const Color(0xCC050B14),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        const Icon(
                          Icons.auto_awesome,
                          size: 44,
                          color: Color(0xFFFFC857),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Run Complete',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'The offer generator stayed fair. The board did not.',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class PieceTray extends StatelessWidget {
  const PieceTray({super.key, required this.controller});

  final GameController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GlassPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  'Aether Pieces',
                  style: theme.textTheme.headlineSmall,
                ),
              ),
              Text(
                controller.selectedPiece == null
                    ? 'Select a piece'
                    : 'Selected: ${controller.selectedPiece!.name}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white70,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 14,
            runSpacing: 14,
            children: List<Widget>.generate(controller.offers.length, (index) {
              final piece = controller.offers[index];
              return PieceCard(
                piece: piece,
                selected: controller.selectedOfferIndex == index,
                playable: controller.canPlaceAnywhere(piece),
                onTap: () => controller.selectOffer(index),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class PieceCard extends StatelessWidget {
  const PieceCard({
    super.key,
    required this.piece,
    required this.selected,
    required this.playable,
    required this.onTap,
  });

  final Piece piece;
  final bool selected;
  final bool playable;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        width: 126,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: selected
                ? const <Color>[Color(0xAA163A55), Color(0xAA0B2435)]
                : const <Color>[Color(0x66121D2C), Color(0x44213149)],
          ),
          border: Border.all(
            color: selected
                ? const Color(0xFF2DE2E6)
                : playable
                ? const Color(0x6648B8FF)
                : const Color(0x33FFFFFF),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(piece.name, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),
            AspectRatio(
              aspectRatio: 1,
              child: CustomPaint(painter: PiecePainter(piece: piece)),
            ),
            const SizedBox(height: 8),
            Text(
              playable ? 'Fits now' : 'Blocked',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: playable ? const Color(0xFF58F2C8) : Colors.white60,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PraiseOverlay extends StatelessWidget {
  const PraiseOverlay({
    super.key,
    required this.text,
    required this.scoreDelta,
    required this.boardCleared,
  });

  final String text;
  final int scoreDelta;
  final bool boardCleared;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              colors: boardCleared
                  ? const <Color>[Color(0xEEFFB347), Color(0xEEFF6A3D)]
                  : const <Color>[Color(0xEE2DE2E6), Color(0xEE1C9CFF)],
            ),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color:
                    (boardCleared
                            ? const Color(0xFFFFC857)
                            : const Color(0xFF2DE2E6))
                        .withValues(alpha: 0.45),
                blurRadius: 30,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                text,
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  fontSize: 34,
                  color: const Color(0xFF04101D),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '+$scoreDelta',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: const Color(0xFF04101D),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PrivacyConsentOverlay extends StatelessWidget {
  const PrivacyConsentOverlay({super.key, required this.controller});

  final GameController controller;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: ColoredBox(
        color: const Color(0xDD040A14),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: GlassPanel(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Privacy and Terms',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Aether Block Blast stores your run data locally and can optionally sync to InstantDB when configured. By continuing, you accept these terms.',
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
                    ),
                    const SizedBox(height: 12),
                    const Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: <Widget>[
                        Pill(
                          icon: Icons.gavel_outlined,
                          label: 'Terms: Included in app notice',
                          tone: Color(0xFFFFC857),
                        ),
                        Pill(
                          icon: Icons.privacy_tip_outlined,
                          label: 'No ad tracking by default',
                          tone: Color(0xFF58F2C8),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: controller.acceptPrivacyConsent,
                      icon: const Icon(Icons.check_circle_outline),
                      label: const Text('Accept and Continue'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class OnboardingOverlay extends StatelessWidget {
  const OnboardingOverlay({super.key, required this.controller});

  final GameController controller;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: ColoredBox(
        color: const Color(0xCC040A14),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: GlassPanel(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Welcome to Aether Block Blast',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Pick a piece, place it to clear rows, columns, and 2x2 blocks. Chain clears to boost combo. Larger grids increase pressure and score scaling.',
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
                    ),
                    const SizedBox(height: 14),
                    const Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: <Widget>[
                        Pill(
                          icon: Icons.dashboard_customize_outlined,
                          label: 'Tiered grid sizes',
                          tone: Color(0xFF2DE2E6),
                        ),
                        Pill(
                          icon: Icons.bolt_outlined,
                          label: 'Combo-based scoring',
                          tone: Color(0xFFFFC857),
                        ),
                        Pill(
                          icon: Icons.cloud_sync_outlined,
                          label: 'Optional cloud snapshot',
                          tone: Color(0xFF58F2C8),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: controller.completeOnboarding,
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('Start Playing'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class RunSummaryOverlay extends StatelessWidget {
  const RunSummaryOverlay({super.key, required this.controller});

  final GameController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Positioned.fill(
      child: ColoredBox(
        color: const Color(0xD9040A14),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: GlassPanel(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text('Run Summary', style: theme.textTheme.headlineSmall),
                    const SizedBox(height: 8),
                    Text(
                      'Sector ${controller.boardSize}x${controller.boardSize} completed. Review the run, lock in your daily progress, or spend a revive token to keep pushing.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: <Widget>[
                        MetricCard(
                          label: 'Final Score',
                          value: controller.score.toString(),
                          accent: const Color(0xFF2DE2E6),
                        ),
                        MetricCard(
                          label: 'Best Tier',
                          value: controller.bestScoreForSize.toString(),
                          accent: const Color(0xFFFFC857),
                        ),
                        MetricCard(
                          label: 'Peak Combo',
                          value: 'x${controller.maxComboReached}',
                          accent: const Color(0xFF58F2C8),
                        ),
                        MetricCard(
                          label: 'Total Clears',
                          value: controller.totalClears.toString(),
                          accent: const Color(0xFFFF8F6B),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    ChallengeCard(
                      title: 'Daily Rift Progress',
                      subtitle: controller.dailyChallengeText,
                      reward: controller.dailyChallengeReward,
                      accent: const Color(0xFF58F2C8),
                      status: controller.dailyChallengeStatus,
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: <Widget>[
                        Pill(
                          icon: Icons.grid_view_outlined,
                          label:
                              'Rows ${controller.totalRowsCleared}  Cols ${controller.totalColumnsCleared}',
                          tone: const Color(0xFF2DE2E6),
                        ),
                        Pill(
                          icon: Icons.crop_square_outlined,
                          label: '2x2 Clears ${controller.totalBlocksCleared}',
                          tone: const Color(0xFFFFC857),
                        ),
                        Pill(
                          icon: Icons.local_fire_department_outlined,
                          label: controller.dailyStreakStatus,
                          tone: const Color(0xFFFF8F6B),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: <Widget>[
                        FilledButton.icon(
                          onPressed: controller.startNewRun,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Start New Run'),
                        ),
                        OutlinedButton.icon(
                          onPressed: controller.canRevive
                              ? controller.useReviveToken
                              : null,
                          icon: const Icon(Icons.favorite_outline),
                          label: Text(
                            controller.canRevive
                                ? 'Use Revive Token'
                                : 'No Revive Tokens',
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed: controller.canClaimDailyReward
                              ? controller.claimDailyReward
                              : null,
                          icon: const Icon(Icons.card_giftcard_outlined),
                          label: Text(
                            controller.canClaimDailyReward
                                ? 'Claim Daily Reward'
                                : 'Daily Reward Claimed',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class GlassPanel extends StatelessWidget {
  const GlassPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
  });

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[Color(0xCC132236), Color(0xAA0A1522)],
        ),
        border: Border.all(color: const Color(0x33548AC9), width: 1),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x44000000),
            blurRadius: 32,
            offset: Offset(0, 20),
          ),
        ],
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}

class MetricCard extends StatelessWidget {
  const MetricCard({
    super.key,
    required this.label,
    required this.value,
    required this.accent,
  });

  final String label;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0x331A2E49),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accent.withValues(alpha: 0.45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(color: accent),
          ),
        ],
      ),
    );
  }
}

class Pill extends StatelessWidget {
  const Pill({
    super.key,
    required this.icon,
    required this.label,
    required this.tone,
  });

  final IconData icon;
  final String label;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: tone.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: tone.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 18, color: tone),
          const SizedBox(width: 8),
          Text(label),
        ],
      ),
    );
  }
}

class AvatarBadge extends StatelessWidget {
  const AvatarBadge({super.key, required this.seed});

  final int seed;

  @override
  Widget build(BuildContext context) {
    final palette = <Color>[
      const Color(0xFF2DE2E6),
      const Color(0xFF58F2C8),
      const Color(0xFFFFC857),
      const Color(0xFF8B80F9),
    ];
    final color = palette[seed.abs() % palette.length];
    return Container(
      width: 62,
      height: 62,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: <Color>[color, color.withValues(alpha: 0.35)],
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(color: color.withValues(alpha: 0.35), blurRadius: 22),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        'AB',
        style: Theme.of(
          context,
        ).textTheme.titleMedium?.copyWith(color: const Color(0xFF071118)),
      ),
    );
  }
}

class ChallengeCard extends StatelessWidget {
  const ChallengeCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.reward,
    required this.accent,
    required this.status,
  });

  final String title;
  final String subtitle;
  final String reward;
  final Color accent;
  final String status;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0x33111F32),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accent.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: 8),
          Text(
            reward,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: accent),
          ),
          const SizedBox(height: 6),
          Text(
            status,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.white60),
          ),
        ],
      ),
    );
  }
}

class ToggleRow extends StatelessWidget {
  const ToggleRow({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: <Widget>[
          Expanded(child: Text(label)),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

class PiecePainter extends CustomPainter {
  const PiecePainter({required this.piece});

  final Piece piece;

  @override
  void paint(Canvas canvas, Size size) {
    final bounds = piece.bounds;
    final cell = math.min(
      size.width / (bounds.width + 1),
      size.height / (bounds.height + 1),
    );
    final paint = Paint()
      ..shader = const LinearGradient(
        colors: <Color>[Color(0xFF2DE2E6), Color(0xFF58F2C8)],
      ).createShader(Offset.zero & size);
    final outline = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = const Color(0xFFB8FFFF);
    for (final cellOffset in piece.cells) {
      final dx =
          (cellOffset.col - bounds.minCol) * cell +
          (size.width - (bounds.width * cell)) / 2;
      final dy =
          (cellOffset.row - bounds.minRow) * cell +
          (size.height - (bounds.height * cell)) / 2;
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(dx, dy, cell - 4, cell - 4),
        const Radius.circular(8),
      );
      canvas.drawRRect(rect, paint);
      canvas.drawRRect(rect, outline);
    }
  }

  @override
  bool shouldRepaint(covariant PiecePainter oldDelegate) {
    return oldDelegate.piece != piece;
  }
}

class Starfield extends StatelessWidget {
  const Starfield({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: StarfieldPainter());
  }
}

class StarfieldPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final starPaint = Paint()..color = const Color(0x55FFFFFF);
    final highlightPaint = Paint()..color = const Color(0x552DE2E6);
    for (var index = 0; index < 75; index++) {
      final x = ((index * 173) % 997) / 997 * size.width;
      final y = ((index * 287) % 991) / 991 * size.height;
      final radius = index % 7 == 0 ? 1.8 : 0.9;
      canvas.drawCircle(
        Offset(x, y),
        radius,
        index.isEven ? starPaint : highlightPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class GameController extends ChangeNotifier {
  GameController({
    required this._store,
    required this._audioController,
    required this._syncService,
  });

  final SessionStore _store;
  final AudioController _audioController;
  final AetherSyncService _syncService;
  final math.Random _random = math.Random();
  final TelemetryClient _telemetry = TelemetryClient();

  bool isLoading = true;
  bool gameOver = false;
  int boardSize = 8;
  List<List<bool>> board = _emptyBoard(8);
  List<Piece> offers = const <Piece>[];
  int? selectedOfferIndex;
  int score = 0;
  int combo = 0;
  int moveCount = 0;
  bool musicEnabled = true;
  bool sfxEnabled = true;
  bool voiceEnabled = true;
  bool hapticsEnabled = true;
  bool reducedMotion = false;
  bool highContrast = false;
  String? praiseBanner;
  Timer? _praiseTimer;
  int lastScoreDelta = 0;
  bool lastBoardWipe = false;
  bool boardWipeAchieved = false;
  String lastClearSummary = 'Stable';
  String playerId = 'guest';
  final Map<int, int> bestScores = <int, int>{};
  bool privacyConsentGiven = false;
  bool hasSeenOnboarding = false;
  bool premiumUnlocked = false;
  int reviveTokens = 1;
  bool adReady = true;
  int maxComboReached = 0;
  int totalRowsCleared = 0;
  int totalColumnsCleared = 0;
  int totalBlocksCleared = 0;
  String dailyProgressDateKey = '';
  int dailyBestScore = 0;
  String? lastDailyCompletionKey;
  int dailyStreak = 0;
  bool dailyRewardClaimed = false;
  bool _loadedOnce = false;

  Future<void> load() async {
    if (_loadedOnce) {
      return;
    }
    _loadedOnce = true;
    final jsonText = await _store.loadSessionJson();
    if (jsonText != null) {
      final persisted = PersistedSession.fromJson(
        json.decode(jsonText) as Map<String, dynamic>,
      );
      _hydrate(persisted);
      _telemetry.logEvent(
        'local_session_loaded',
        properties: <String, Object?>{'boardSize': boardSize, 'score': score},
      );
    } else {
      playerId = 'guest-${DateTime.now().millisecondsSinceEpoch}';
      _initializeFreshRun();
      _telemetry.logEvent('new_local_session_created');
    }
    await _audioController.initialize();
    await _audioController.setSettings(
      musicEnabled: musicEnabled,
      sfxEnabled: sfxEnabled,
      voiceEnabled: voiceEnabled,
    );
    await _audioController.playMenuMusic();
    await _syncService.initialize(playerId: playerId);
    _refreshDailyChallengeState();
    if (jsonText == null) {
      final cloudSnapshot = await _syncService.pullSnapshot();
      if (cloudSnapshot != null) {
        _hydrate(cloudSnapshot);
        _refreshDailyChallengeState();
        _telemetry.logEvent(
          'cloud_snapshot_restored',
          properties: <String, Object?>{'boardSize': boardSize, 'score': score},
        );
      }
    }
    await _persist(reason: 'load_complete');
    isLoading = false;
    notifyListeners();
  }

  int get bestScoreForSize => bestScores[boardSize] ?? 0;

  Piece? get selectedPiece =>
      selectedOfferIndex == null ? null : offers[selectedOfferIndex!];

  Set<Cell> get previewCells {
    final piece = selectedPiece;
    if (piece == null) {
      return <Cell>{};
    }
    final fit = _firstFit(piece);
    return fit == null ? <Cell>{} : piece.anchoredAt(fit.row, fit.col).toSet();
  }

  String get syncLabel => _syncService.statusLabel;

  bool get needsPrivacyConsent => !privacyConsentGiven;

  bool get shouldShowOnboarding =>
      !isLoading && privacyConsentGiven && !hasSeenOnboarding;

  int get telemetryEventCount => _telemetry.events.length;

  bool get canRevive => gameOver && reviveTokens > 0;

  int get bestCombo => maxComboReached;

  String get playerCallsign =>
      playerId.startsWith('guest-') ? 'Guest Pilot' : playerId;

  String get leaderboardLabel =>
      _syncService.connected ? 'Cloud Sync Ready' : 'Local Bests Only';

  bool get shouldShowRunSummary =>
      !isLoading && gameOver && privacyConsentGiven && hasSeenOnboarding;

  Color get syncTone => _syncService.connected
      ? const Color(0xFF58F2C8)
      : const Color(0xFFFFC857);

  DailyChallengeSpec get dailyChallenge =>
      DailyChallengeSpec.forDate(DateTime.now().toUtc());

  int get totalClears =>
      totalRowsCleared + totalColumnsCleared + totalBlocksCleared;

  bool get isDailyChallengeGrid => boardSize == dailyChallenge.boardSize;

  bool get isDailyChallengeComplete =>
      dailyProgressDateKey == dailyChallenge.dateKey &&
      dailyBestScore >= dailyChallenge.targetScore;

  bool get canClaimDailyReward =>
      isDailyChallengeComplete && !dailyRewardClaimed;

  String get dailyChallengeText =>
      'Today: clear the ${dailyChallenge.boardSize}x${dailyChallenge.boardSize} sector and reach ${dailyChallenge.targetScore} points.';

  String get dailyChallengeReward =>
      '${dailyChallenge.rewardTokens} revive token${dailyChallenge.rewardTokens == 1 ? '' : 's'}';

  String get dailyChallengeStatus {
    if (dailyProgressDateKey != dailyChallenge.dateKey) {
      return 'Progress: 0 / ${dailyChallenge.targetScore}';
    }
    if (isDailyChallengeComplete) {
      return dailyRewardClaimed
          ? 'Complete. Reward claimed.'
          : 'Complete. Reward ready to claim.';
    }
    return 'Progress: $dailyBestScore / ${dailyChallenge.targetScore}';
  }

  String get dailyStreakText => dailyStreak == 0
      ? 'Complete today\'s rift to start a return streak.'
      : 'You have completed $dailyStreak daily rift${dailyStreak == 1 ? '' : 's'} in succession.';

  String get dailyStreakReward => dailyStreak >= 3
      ? 'Streak momentum active'
      : 'Build toward a 3-day chain';

  String get dailyStreakStatus =>
      dailyStreak == 0 ? 'No streak yet' : '$dailyStreak day streak';

  String get cascadeChallengeText =>
      'Land two clears in a row on the ${boardSize}x$boardSize board.';

  String get cascadeChallengeReward => '${boardSize * 40} bonus points';

  String get cascadeChallengeStatus => combo >= 2
      ? 'Completed in this run'
      : 'Progress: $combo / 2 chained clears';

  String get wipeChallengeText =>
      'Empty the board completely for a rare full-field celebration.';

  String get wipeChallengeReward => '${boardSize * 65} bonus points';

  String get wipeChallengeStatus => boardWipeAchieved
      ? 'Completed in this run'
      : 'Awaiting a full-board wipe';

  Future<void> startNewRun() async {
    _initializeFreshRun();
    await _audioController.playMenuMusic();
    await _lightHaptic();
    _telemetry.logEvent(
      'run_started',
      properties: <String, Object?>{'boardSize': boardSize},
    );
    await _persist(reason: 'new_run');
    notifyListeners();
  }

  Future<void> changeGrid(int size) async {
    if (boardSize == size) {
      return;
    }
    boardSize = size;
    _refreshDailyChallengeState();
    await startNewRun();
  }

  Future<void> jumpToDailyChallenge() async {
    if (boardSize == dailyChallenge.boardSize) {
      return;
    }
    await changeGrid(dailyChallenge.boardSize);
  }

  void selectOffer(int index) {
    if (index >= offers.length) {
      return;
    }
    selectedOfferIndex = selectedOfferIndex == index ? null : index;
    notifyListeners();
  }

  void clearSelection() {
    selectedOfferIndex = null;
    notifyListeners();
  }

  bool canPlaceAnywhere(Piece piece) => _firstFit(piece) != null;

  Future<void> placeSelectedAt(int row, int col) async {
    final piece = selectedPiece;
    if (piece == null || gameOver) {
      return;
    }
    if (!_canPlace(piece, row, col)) {
      await _audioController.playInvalid();
      await _selectionHaptic();
      return;
    }
    for (final cell in piece.anchoredAt(row, col)) {
      board[cell.row][cell.col] = true;
    }
    offers.removeAt(selectedOfferIndex!);
    selectedOfferIndex = null;
    moveCount++;

    final clearResult = _resolveClears();
    final delta = _scorePlacement(piece, clearResult);
    score += delta;
    _telemetry.logEvent(
      'move_placed',
      properties: <String, Object?>{
        'boardSize': boardSize,
        'scoreDelta': delta,
        'score': score,
        'combo': combo,
      },
    );
    if (score > bestScoreForSize) {
      bestScores[boardSize] = score;
    }

    if (clearResult.clearedCells.isNotEmpty) {
      combo += 1;
      maxComboReached = math.max(maxComboReached, combo);
      totalRowsCleared += clearResult.rows;
      totalColumnsCleared += clearResult.columns;
      totalBlocksCleared += clearResult.blocks2x2;
      final praise = _praiseFor(clearResult);
      lastClearSummary = praise;
      lastBoardWipe = clearResult.boardWipe;
      boardWipeAchieved = boardWipeAchieved || clearResult.boardWipe;
      lastScoreDelta = delta;
      _showPraise(praise);
      await _audioController.playPraise(
        clear: clearResult,
        combo: combo,
        voiceEnabled: voiceEnabled,
      );
      await _successHaptic(clearResult.boardWipe);
    } else {
      combo = 0;
      lastClearSummary = 'Stable';
      lastBoardWipe = false;
      lastScoreDelta = delta;
      await _audioController.playPlacement();
      await _lightHaptic();
    }
    _refreshDailyChallengeState();
    _updateDailyProgress();

    while (offers.length < 3) {
      final generated = _generateOfferSet();
      if (generated.isEmpty) {
        break;
      }
      offers.addAll(generated);
      offers = offers.take(3).toList();
    }
    if (offers.isEmpty || !offers.any(canPlaceAnywhere)) {
      gameOver = true;
      clearSelection();
      _telemetry.logEvent(
        'game_over',
        properties: <String, Object?>{
          'boardSize': boardSize,
          'finalScore': score,
          'moves': moveCount,
        },
      );
      await _audioController.playGameOver();
      await _audioController.playMenuMusic();
      await _warningHaptic();
    } else {
      await _audioController.playGameplayMusic();
    }
    await _persist(reason: 'move_placed');
    notifyListeners();
  }

  Future<void> toggleMusic(bool value) async {
    musicEnabled = value;
    await _applyAudioSettings();
  }

  Future<void> toggleSfx(bool value) async {
    sfxEnabled = value;
    await _applyAudioSettings();
  }

  Future<void> toggleVoice(bool value) async {
    voiceEnabled = value;
    await _applyAudioSettings();
  }

  Future<void> toggleHaptics(bool value) async {
    hapticsEnabled = value;
    await _persist(reason: 'haptics_changed');
    notifyListeners();
  }

  Future<void> toggleReducedMotion(bool value) async {
    reducedMotion = value;
    await _persist(reason: 'reduced_motion_changed');
    notifyListeners();
  }

  Future<void> toggleHighContrast(bool value) async {
    highContrast = value;
    await _persist(reason: 'high_contrast_changed');
    notifyListeners();
  }

  Future<void> unlockPremium() async {
    if (premiumUnlocked) {
      return;
    }
    premiumUnlocked = true;
    _telemetry.logEvent('premium_unlocked_simulated');
    await _persist(reason: 'premium_unlocked');
    notifyListeners();
  }

  Future<void> watchRewardedAd() async {
    if (!adReady) {
      return;
    }
    adReady = false;
    _telemetry.logEvent('rewarded_ad_started');
    await Future<void>.delayed(const Duration(milliseconds: 500));
    reviveTokens += 1;
    adReady = true;
    _telemetry.logEvent(
      'rewarded_ad_completed',
      properties: <String, Object?>{'reviveTokens': reviveTokens},
    );
    await _persist(reason: 'rewarded_ad_completed');
    notifyListeners();
  }

  Future<void> useReviveToken() async {
    if (!canRevive) {
      return;
    }
    reviveTokens -= 1;
    gameOver = false;
    selectedOfferIndex = null;
    if (offers.isEmpty || !offers.any(canPlaceAnywhere)) {
      offers = _generateOfferSet();
    }
    if (!offers.any(canPlaceAnywhere)) {
      offers = _generateOfferSet();
    }
    await _audioController.playGameplayMusic();
    _telemetry.logEvent(
      'revive_token_used',
      properties: <String, Object?>{'reviveTokensRemaining': reviveTokens},
    );
    await _persist(reason: 'revive_token_used');
    notifyListeners();
  }

  Future<void> acceptPrivacyConsent() async {
    if (privacyConsentGiven) {
      return;
    }
    privacyConsentGiven = true;
    _telemetry.logEvent('privacy_consent_accepted');
    await _persist(reason: 'privacy_consent');
    notifyListeners();
  }

  Future<void> completeOnboarding() async {
    if (hasSeenOnboarding) {
      return;
    }
    hasSeenOnboarding = true;
    _telemetry.logEvent('onboarding_completed');
    await _persist(reason: 'onboarding_completed');
    notifyListeners();
  }

  Future<void> claimDailyReward() async {
    if (!canClaimDailyReward) {
      return;
    }
    reviveTokens += dailyChallenge.rewardTokens;
    dailyRewardClaimed = true;
    _showPraise('Reward Claimed');
    _telemetry.logEvent(
      'daily_reward_claimed',
      properties: <String, Object?>{
        'dateKey': dailyChallenge.dateKey,
        'rewardTokens': dailyChallenge.rewardTokens,
      },
    );
    await _persist(reason: 'daily_reward_claimed');
    notifyListeners();
  }

  String buildDiagnosticsReport() {
    final report = <String, Object?>{
      'generatedAt': DateTime.now().toIso8601String(),
      'appVersion': kAppVersion,
      'releaseFlavor': kReleaseFlavor,
      'syncLabel': syncLabel,
      'telemetry': _telemetry.toJson(),
      'session': _currentSession().toJson(),
    };
    return const JsonEncoder.withIndent('  ').convert(report);
  }

  String buildSessionSnapshot() {
    return const JsonEncoder.withIndent(
      '  ',
    ).convert(_currentSession().toJson());
  }

  @override
  void dispose() {
    _praiseTimer?.cancel();
    _audioController.dispose();
    _syncService.dispose();
    super.dispose();
  }

  void _hydrate(PersistedSession persisted) {
    playerId = persisted.playerId;
    boardSize = persisted.boardSize;
    board = persisted.board
        .map((row) => row.map((value) => value == 1).toList())
        .toList();
    offers = persisted.offerIds.map(_pieceFromId).whereType<Piece>().toList();
    if (offers.length < 3) {
      offers = _generateOfferSet();
    }
    score = persisted.score;
    combo = persisted.combo;
    moveCount = persisted.moveCount;
    bestScores
      ..clear()
      ..addAll(persisted.bestScores);
    musicEnabled = persisted.musicEnabled;
    sfxEnabled = persisted.sfxEnabled;
    voiceEnabled = persisted.voiceEnabled;
    hapticsEnabled = persisted.hapticsEnabled;
    reducedMotion = persisted.reducedMotion;
    highContrast = persisted.highContrast;
    gameOver = persisted.gameOver;
    boardWipeAchieved = persisted.boardWipeAchieved;
    privacyConsentGiven = persisted.privacyConsentGiven;
    hasSeenOnboarding = persisted.hasSeenOnboarding;
    premiumUnlocked = persisted.premiumUnlocked;
    reviveTokens = persisted.reviveTokens;
    adReady = persisted.adReady;
    maxComboReached = persisted.maxComboReached;
    totalRowsCleared = persisted.totalRowsCleared;
    totalColumnsCleared = persisted.totalColumnsCleared;
    totalBlocksCleared = persisted.totalBlocksCleared;
    dailyProgressDateKey = persisted.dailyProgressDateKey;
    dailyBestScore = persisted.dailyBestScore;
    lastDailyCompletionKey = persisted.lastDailyCompletionKey;
    dailyStreak = persisted.dailyStreak;
    dailyRewardClaimed = persisted.dailyRewardClaimed;
  }

  void _initializeFreshRun() {
    _refreshDailyChallengeState();
    board = _emptyBoard(boardSize);
    offers = _generateOfferSet();
    selectedOfferIndex = null;
    score = 0;
    combo = 0;
    moveCount = 0;
    gameOver = false;
    praiseBanner = null;
    lastScoreDelta = 0;
    lastBoardWipe = false;
    boardWipeAchieved = false;
    lastClearSummary = 'Stable';
    maxComboReached = 0;
    totalRowsCleared = 0;
    totalColumnsCleared = 0;
    totalBlocksCleared = 0;
  }

  Future<void> _persist({required String reason}) async {
    final session = _currentSession();
    _telemetry.logEvent(
      'session_persisted',
      properties: <String, Object?>{
        'reason': reason,
        'boardSize': boardSize,
        'score': score,
      },
    );
    final jsonText = json.encode(session.toJson());
    await _store.saveSessionJson(jsonText);
    await _syncService.pushSnapshot(session);
  }

  Future<void> _applyAudioSettings() async {
    await _audioController.setSettings(
      musicEnabled: musicEnabled,
      sfxEnabled: sfxEnabled,
      voiceEnabled: voiceEnabled,
    );
    await _persist(reason: 'audio_settings_changed');
    notifyListeners();
  }

  PersistedSession _currentSession() {
    return PersistedSession(
      playerId: playerId,
      boardSize: boardSize,
      board: board
          .map((row) => row.map((value) => value ? 1 : 0).toList())
          .toList(),
      offerIds: offers.map((piece) => piece.id).toList(),
      score: score,
      combo: combo,
      moveCount: moveCount,
      bestScores: Map<int, int>.from(bestScores),
      musicEnabled: musicEnabled,
      sfxEnabled: sfxEnabled,
      voiceEnabled: voiceEnabled,
      hapticsEnabled: hapticsEnabled,
      reducedMotion: reducedMotion,
      highContrast: highContrast,
      gameOver: gameOver,
      boardWipeAchieved: boardWipeAchieved,
      privacyConsentGiven: privacyConsentGiven,
      hasSeenOnboarding: hasSeenOnboarding,
      premiumUnlocked: premiumUnlocked,
      reviveTokens: reviveTokens,
      adReady: adReady,
      maxComboReached: maxComboReached,
      totalRowsCleared: totalRowsCleared,
      totalColumnsCleared: totalColumnsCleared,
      totalBlocksCleared: totalBlocksCleared,
      dailyProgressDateKey: dailyProgressDateKey,
      dailyBestScore: dailyBestScore,
      lastDailyCompletionKey: lastDailyCompletionKey,
      dailyStreak: dailyStreak,
      dailyRewardClaimed: dailyRewardClaimed,
    );
  }

  void _refreshDailyChallengeState() {
    final todayKey = dailyChallenge.dateKey;
    if (dailyProgressDateKey == todayKey) {
      return;
    }
    dailyProgressDateKey = todayKey;
    dailyBestScore = 0;
    dailyRewardClaimed = false;
  }

  void _updateDailyProgress() {
    if (!isDailyChallengeGrid) {
      return;
    }
    if (score > dailyBestScore) {
      dailyBestScore = score;
    }
    if (dailyBestScore >= dailyChallenge.targetScore &&
        lastDailyCompletionKey != dailyChallenge.dateKey) {
      final previousKey = lastDailyCompletionKey;
      final yesterdayKey = _dateKey(
        DateTime.now().toUtc().subtract(const Duration(days: 1)),
      );
      dailyStreak = previousKey == yesterdayKey ? dailyStreak + 1 : 1;
      lastDailyCompletionKey = dailyChallenge.dateKey;
      dailyRewardClaimed = false;
      _showPraise('Daily Complete');
      _telemetry.logEvent(
        'daily_challenge_completed',
        properties: <String, Object?>{
          'dateKey': dailyChallenge.dateKey,
          'boardSize': dailyChallenge.boardSize,
          'streak': dailyStreak,
        },
      );
    }
  }

  List<Piece> _generateOfferSet() {
    final fitting = pieceLibrary
        .where((piece) => canPlaceAnywhere(piece))
        .toList();
    if (fitting.isEmpty) {
      return const <Piece>[];
    }
    fitting.sort((left, right) {
      final leftScore = _futureFitScore(left);
      final rightScore = _futureFitScore(right);
      return rightScore.compareTo(leftScore);
    });
    final protectedPool = fitting.take(math.min(5, fitting.length)).toList();
    final guaranteed = protectedPool[_random.nextInt(protectedPool.length)];
    final all = <Piece>[guaranteed];
    while (all.length < 3) {
      final useFittingBias = _random.nextDouble() < 0.45;
      final source = useFittingBias && fitting.isNotEmpty
          ? fitting
          : pieceLibrary;
      all.add(source[_random.nextInt(source.length)]);
    }
    all.shuffle(_random);
    return all;
  }

  int _futureFitScore(Piece piece) {
    final anchor = _firstFit(piece);
    if (anchor == null) {
      return -1;
    }
    final projected = board.map((row) => row.toList()).toList(growable: false);
    for (final cell in piece.anchoredAt(anchor.row, anchor.col)) {
      projected[cell.row][cell.col] = true;
    }
    final cleared = _resolveProjectedClears(projected);
    for (final cell in cleared) {
      projected[cell.row][cell.col] = false;
    }
    var futureFits = 0;
    for (final candidate in pieceLibrary) {
      if (_canPlaceOnBoard(projected, candidate)) {
        futureFits += 1;
      }
    }
    return futureFits + cleared.length;
  }

  bool _canPlace(Piece piece, int anchorRow, int anchorCol) {
    for (final cell in piece.anchoredAt(anchorRow, anchorCol)) {
      if (cell.row < 0 ||
          cell.col < 0 ||
          cell.row >= boardSize ||
          cell.col >= boardSize ||
          board[cell.row][cell.col]) {
        return false;
      }
    }
    return true;
  }

  bool _canPlaceOnBoard(List<List<bool>> targetBoard, Piece piece) {
    for (var row = 0; row < boardSize; row++) {
      for (var col = 0; col < boardSize; col++) {
        var fits = true;
        for (final cell in piece.anchoredAt(row, col)) {
          if (cell.row < 0 ||
              cell.col < 0 ||
              cell.row >= boardSize ||
              cell.col >= boardSize ||
              targetBoard[cell.row][cell.col]) {
            fits = false;
            break;
          }
        }
        if (fits) {
          return true;
        }
      }
    }
    return false;
  }

  Cell? _firstFit(Piece piece) {
    for (var row = 0; row < boardSize; row++) {
      for (var col = 0; col < boardSize; col++) {
        if (_canPlace(piece, row, col)) {
          return Cell(row, col);
        }
      }
    }
    return null;
  }

  ClearResult _resolveClears() {
    final cleared = <Cell>{};
    var rows = 0;
    var cols = 0;
    var blocks = 0;
    for (var row = 0; row < boardSize; row++) {
      if (board[row].every((value) => value)) {
        rows++;
        for (var col = 0; col < boardSize; col++) {
          cleared.add(Cell(row, col));
        }
      }
    }
    for (var col = 0; col < boardSize; col++) {
      var full = true;
      for (var row = 0; row < boardSize; row++) {
        if (!board[row][col]) {
          full = false;
          break;
        }
      }
      if (full) {
        cols++;
        for (var row = 0; row < boardSize; row++) {
          cleared.add(Cell(row, col));
        }
      }
    }
    for (var row = 0; row < boardSize - 1; row++) {
      for (var col = 0; col < boardSize - 1; col++) {
        final full =
            board[row][col] &&
            board[row + 1][col] &&
            board[row][col + 1] &&
            board[row + 1][col + 1];
        if (full) {
          blocks++;
          cleared
            ..add(Cell(row, col))
            ..add(Cell(row + 1, col))
            ..add(Cell(row, col + 1))
            ..add(Cell(row + 1, col + 1));
        }
      }
    }
    for (final cell in cleared) {
      board[cell.row][cell.col] = false;
    }
    final boardWipe = board.every((row) => row.every((value) => !value));
    return ClearResult(
      clearedCells: cleared,
      rows: rows,
      columns: cols,
      blocks2x2: blocks,
      boardWipe: boardWipe && cleared.isNotEmpty,
    );
  }

  Set<Cell> _resolveProjectedClears(List<List<bool>> targetBoard) {
    final cleared = <Cell>{};
    for (var row = 0; row < boardSize; row++) {
      if (targetBoard[row].every((value) => value)) {
        for (var col = 0; col < boardSize; col++) {
          cleared.add(Cell(row, col));
        }
      }
    }
    for (var col = 0; col < boardSize; col++) {
      var full = true;
      for (var row = 0; row < boardSize; row++) {
        if (!targetBoard[row][col]) {
          full = false;
          break;
        }
      }
      if (full) {
        for (var row = 0; row < boardSize; row++) {
          cleared.add(Cell(row, col));
        }
      }
    }
    for (var row = 0; row < boardSize - 1; row++) {
      for (var col = 0; col < boardSize - 1; col++) {
        final full =
            targetBoard[row][col] &&
            targetBoard[row + 1][col] &&
            targetBoard[row][col + 1] &&
            targetBoard[row + 1][col + 1];
        if (full) {
          cleared
            ..add(Cell(row, col))
            ..add(Cell(row + 1, col))
            ..add(Cell(row, col + 1))
            ..add(Cell(row + 1, col + 1));
        }
      }
    }
    return cleared;
  }

  int _scorePlacement(Piece piece, ClearResult result) {
    final difficulty = boardSize / 8;
    final placedScore = (piece.cells.length * 10 * difficulty).round();
    final clearScore = (result.clearedCells.length * 18 * difficulty).round();
    final rowScore = ((result.rows + result.columns) * 42 * difficulty).round();
    final blockScore = (result.blocks2x2 * 28 * difficulty).round();
    final comboScore = result.clearedCells.isEmpty
        ? 0
        : (combo * 26 * difficulty).round();
    final wipeScore = result.boardWipe ? (220 * difficulty).round() : 0;
    return placedScore +
        clearScore +
        rowScore +
        blockScore +
        comboScore +
        wipeScore;
  }

  String _praiseFor(ClearResult result) {
    final intensity =
        result.rows +
        result.columns +
        result.blocks2x2 +
        (result.boardWipe ? 4 : 0) +
        combo;
    if (result.boardWipe) {
      return 'Aether Clear';
    }
    if (intensity >= 7) {
      return 'Incredible';
    }
    if (intensity >= 5) {
      return 'Amazing';
    }
    if (intensity >= 3) {
      return 'Excellent';
    }
    return 'Nice';
  }

  void _showPraise(String text) {
    praiseBanner = text;
    _praiseTimer?.cancel();
    _praiseTimer = Timer(const Duration(milliseconds: 1200), () {
      praiseBanner = null;
      notifyListeners();
    });
  }

  Future<void> _selectionHaptic() async {
    if (!hapticsEnabled) {
      return;
    }
    try {
      await HapticFeedback.selectionClick();
    } catch (_) {}
  }

  Future<void> _lightHaptic() async {
    if (!hapticsEnabled) {
      return;
    }
    try {
      await HapticFeedback.lightImpact();
    } catch (_) {}
  }

  Future<void> _successHaptic(bool strong) async {
    if (!hapticsEnabled) {
      return;
    }
    try {
      if (strong) {
        await HapticFeedback.heavyImpact();
      } else {
        await HapticFeedback.mediumImpact();
      }
    } catch (_) {}
  }

  Future<void> _warningHaptic() async {
    if (!hapticsEnabled) {
      return;
    }
    try {
      await HapticFeedback.vibrate();
    } catch (_) {}
  }
}

class PersistedSession {
  const PersistedSession({
    required this.playerId,
    required this.boardSize,
    required this.board,
    required this.offerIds,
    required this.score,
    required this.combo,
    required this.moveCount,
    required this.bestScores,
    required this.musicEnabled,
    required this.sfxEnabled,
    required this.voiceEnabled,
    required this.hapticsEnabled,
    required this.reducedMotion,
    required this.highContrast,
    required this.gameOver,
    required this.boardWipeAchieved,
    required this.privacyConsentGiven,
    required this.hasSeenOnboarding,
    required this.premiumUnlocked,
    required this.reviveTokens,
    required this.adReady,
    required this.maxComboReached,
    required this.totalRowsCleared,
    required this.totalColumnsCleared,
    required this.totalBlocksCleared,
    required this.dailyProgressDateKey,
    required this.dailyBestScore,
    required this.lastDailyCompletionKey,
    required this.dailyStreak,
    required this.dailyRewardClaimed,
  });

  final String playerId;
  final int boardSize;
  final List<List<int>> board;
  final List<String> offerIds;
  final int score;
  final int combo;
  final int moveCount;
  final Map<int, int> bestScores;
  final bool musicEnabled;
  final bool sfxEnabled;
  final bool voiceEnabled;
  final bool hapticsEnabled;
  final bool reducedMotion;
  final bool highContrast;
  final bool gameOver;
  final bool boardWipeAchieved;
  final bool privacyConsentGiven;
  final bool hasSeenOnboarding;
  final bool premiumUnlocked;
  final int reviveTokens;
  final bool adReady;
  final int maxComboReached;
  final int totalRowsCleared;
  final int totalColumnsCleared;
  final int totalBlocksCleared;
  final String dailyProgressDateKey;
  final int dailyBestScore;
  final String? lastDailyCompletionKey;
  final int dailyStreak;
  final bool dailyRewardClaimed;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'playerId': playerId,
      'boardSize': boardSize,
      'board': board,
      'offerIds': offerIds,
      'score': score,
      'combo': combo,
      'moveCount': moveCount,
      'bestScores': bestScores.map((key, value) => MapEntry('$key', value)),
      'musicEnabled': musicEnabled,
      'sfxEnabled': sfxEnabled,
      'voiceEnabled': voiceEnabled,
      'hapticsEnabled': hapticsEnabled,
      'reducedMotion': reducedMotion,
      'highContrast': highContrast,
      'gameOver': gameOver,
      'boardWipeAchieved': boardWipeAchieved,
      'privacyConsentGiven': privacyConsentGiven,
      'hasSeenOnboarding': hasSeenOnboarding,
      'premiumUnlocked': premiumUnlocked,
      'reviveTokens': reviveTokens,
      'adReady': adReady,
      'maxComboReached': maxComboReached,
      'totalRowsCleared': totalRowsCleared,
      'totalColumnsCleared': totalColumnsCleared,
      'totalBlocksCleared': totalBlocksCleared,
      'dailyProgressDateKey': dailyProgressDateKey,
      'dailyBestScore': dailyBestScore,
      'lastDailyCompletionKey': lastDailyCompletionKey,
      'dailyStreak': dailyStreak,
      'dailyRewardClaimed': dailyRewardClaimed,
    };
  }

  factory PersistedSession.fromJson(Map<String, dynamic> json) {
    final bestScoresMap = <int, int>{};
    for (final entry
        in (json['bestScores'] as Map<String, dynamic>? ?? <String, dynamic>{})
            .entries) {
      bestScoresMap[int.parse(entry.key)] = entry.value as int;
    }
    return PersistedSession(
      playerId: json['playerId'] as String? ?? 'guest',
      boardSize: json['boardSize'] as int? ?? 8,
      board: (json['board'] as List<dynamic>? ?? const <dynamic>[])
          .map((row) => (row as List<dynamic>).cast<int>())
          .toList(),
      offerIds: (json['offerIds'] as List<dynamic>? ?? const <dynamic>[])
          .cast<String>(),
      score: json['score'] as int? ?? 0,
      combo: json['combo'] as int? ?? 0,
      moveCount: json['moveCount'] as int? ?? 0,
      bestScores: bestScoresMap,
      musicEnabled: json['musicEnabled'] as bool? ?? true,
      sfxEnabled: json['sfxEnabled'] as bool? ?? true,
      voiceEnabled: json['voiceEnabled'] as bool? ?? true,
      hapticsEnabled: json['hapticsEnabled'] as bool? ?? true,
      reducedMotion: json['reducedMotion'] as bool? ?? false,
      highContrast: json['highContrast'] as bool? ?? false,
      gameOver: json['gameOver'] as bool? ?? false,
      boardWipeAchieved: json['boardWipeAchieved'] as bool? ?? false,
      privacyConsentGiven: json['privacyConsentGiven'] as bool? ?? false,
      hasSeenOnboarding: json['hasSeenOnboarding'] as bool? ?? false,
      premiumUnlocked: json['premiumUnlocked'] as bool? ?? false,
      reviveTokens: json['reviveTokens'] as int? ?? 1,
      adReady: json['adReady'] as bool? ?? true,
      maxComboReached: json['maxComboReached'] as int? ?? 0,
      totalRowsCleared: json['totalRowsCleared'] as int? ?? 0,
      totalColumnsCleared: json['totalColumnsCleared'] as int? ?? 0,
      totalBlocksCleared: json['totalBlocksCleared'] as int? ?? 0,
      dailyProgressDateKey: json['dailyProgressDateKey'] as String? ?? '',
      dailyBestScore: json['dailyBestScore'] as int? ?? 0,
      lastDailyCompletionKey: json['lastDailyCompletionKey'] as String?,
      dailyStreak: json['dailyStreak'] as int? ?? 0,
      dailyRewardClaimed: json['dailyRewardClaimed'] as bool? ?? false,
    );
  }
}

class DailyChallengeSpec {
  const DailyChallengeSpec({
    required this.dateKey,
    required this.boardSize,
    required this.targetScore,
    required this.rewardTokens,
  });

  factory DailyChallengeSpec.forDate(DateTime utcDate) {
    final dateKey = _dateKey(utcDate);
    final hash = dateKey.codeUnits.fold<int>(
      17,
      (value, codeUnit) => (value * 31) + codeUnit,
    );
    final boardSize = kGridSizes[hash % kGridSizes.length];
    final tierWeight = 14 + (hash % 6);
    final targetScore = (boardSize * tierWeight) + (boardSize * boardSize);
    final rewardTokens = math.max(1, boardSize ~/ 12);
    return DailyChallengeSpec(
      dateKey: dateKey,
      boardSize: boardSize,
      targetScore: targetScore,
      rewardTokens: rewardTokens,
    );
  }

  final String dateKey;
  final int boardSize;
  final int targetScore;
  final int rewardTokens;
}

String _dateKey(DateTime value) {
  final utc = value.toUtc();
  final month = utc.month.toString().padLeft(2, '0');
  final day = utc.day.toString().padLeft(2, '0');
  return '${utc.year}-$month-$day';
}

class ClearResult {
  const ClearResult({
    required this.clearedCells,
    required this.rows,
    required this.columns,
    required this.blocks2x2,
    required this.boardWipe,
  });

  final Set<Cell> clearedCells;
  final int rows;
  final int columns;
  final int blocks2x2;
  final bool boardWipe;
}

class AudioController {
  final AudioPlayer _musicPlayer = AudioPlayer(playerId: 'music');
  final AudioPlayer _sfxPlayer = AudioPlayer(playerId: 'sfx');
  final AudioPlayer _voicePlayer = AudioPlayer(playerId: 'voice');

  bool _ready = false;
  bool _musicEnabled = true;
  bool _sfxEnabled = true;
  bool _voiceEnabled = true;

  Future<void> initialize() async {
    if (_ready) {
      return;
    }
    try {
      await _musicPlayer.setReleaseMode(ReleaseMode.loop);
    } catch (_) {}
    _ready = true;
  }

  Future<void> setSettings({
    required bool musicEnabled,
    required bool sfxEnabled,
    required bool voiceEnabled,
  }) async {
    _musicEnabled = musicEnabled;
    _sfxEnabled = sfxEnabled;
    _voiceEnabled = voiceEnabled;
    try {
      await _musicPlayer.setVolume(_musicEnabled ? 0.32 : 0);
      await _sfxPlayer.setVolume(_sfxEnabled ? 0.75 : 0);
      await _voicePlayer.setVolume(_voiceEnabled ? 0.95 : 0);
      if (!_musicEnabled) {
        await _musicPlayer.pause();
      }
    } catch (_) {}
  }

  Future<void> playMenuMusic() async {
    if (!_musicEnabled) {
      return;
    }
    try {
      await _musicPlayer.stop();
      await _musicPlayer.play(AssetSource('audio/music/menu_loop.wav'));
    } catch (_) {}
  }

  Future<void> playGameplayMusic() async {
    if (!_musicEnabled) {
      return;
    }
    try {
      await _musicPlayer.stop();
      await _musicPlayer.play(AssetSource('audio/music/gameplay_loop.wav'));
    } catch (_) {}
  }

  Future<void> playPlacement() async {
    if (_sfxEnabled) {
      try {
        await _sfxPlayer.play(AssetSource('audio/sfx/place.wav'));
      } catch (_) {}
    }
  }

  Future<void> playInvalid() async {
    if (_sfxEnabled) {
      try {
        await _sfxPlayer.play(AssetSource('audio/sfx/invalid.wav'));
      } catch (_) {}
    }
  }

  Future<void> playGameOver() async {
    if (_sfxEnabled) {
      try {
        await _sfxPlayer.play(AssetSource('audio/sfx/game_over.wav'));
      } catch (_) {}
    }
  }

  Future<void> playPraise({
    required ClearResult clear,
    required int combo,
    required bool voiceEnabled,
  }) async {
    if (_sfxEnabled) {
      try {
        await _sfxPlayer.play(
          AssetSource(
            clear.boardWipe ? 'audio/sfx/wipe.wav' : 'audio/sfx/clear.wav',
          ),
        );
      } catch (_) {}
    }
    if (!_voiceEnabled || !voiceEnabled) {
      return;
    }
    try {
      await _voicePlayer.play(AssetSource(_voiceAsset(clear, combo)));
    } catch (_) {}
  }

  String _voiceAsset(ClearResult clear, int combo) {
    final intensity = clear.rows + clear.columns + clear.blocks2x2 + combo;
    if (clear.boardWipe) {
      return 'audio/voice/aether_clear.wav';
    }
    if (intensity >= 7) {
      return 'audio/voice/incredible.wav';
    }
    if (intensity >= 5) {
      return 'audio/voice/amazing.wav';
    }
    if (intensity >= 3) {
      return 'audio/voice/excellent.wav';
    }
    return 'audio/voice/nice.wav';
  }

  Future<void> dispose() async {
    try {
      await _musicPlayer.dispose();
      await _sfxPlayer.dispose();
      await _voicePlayer.dispose();
    } catch (_) {}
  }
}

class AetherSyncService {
  static const _appId = String.fromEnvironment('INSTANTDB_APP_ID');

  InstantDB? _db;
  bool _initialUploadDone = false;
  String? _playerId;
  String statusLabel = 'Offline Resume Only';

  bool get connected => _db != null;

  Future<void> initialize({required String playerId}) async {
    _playerId = playerId;
    if (_appId.isEmpty) {
      statusLabel = 'InstantDB Not Configured';
      return;
    }
    try {
      _db = await InstantDB.init(
        appId: _appId,
        config: const InstantConfig(syncEnabled: true),
      );
      statusLabel = 'Cloud Sync Live';
    } catch (_) {
      _db = null;
      statusLabel = 'Cloud Sync Fallback';
    }
  }

  Future<void> pushSnapshot(PersistedSession session) async {
    final db = _db;
    final playerId = _playerId;
    if (db == null || playerId == null) {
      return;
    }
    final payload = <String, dynamic>{
      'id': playerId,
      '__type': 'runs',
      'boardSize': session.boardSize,
      'board': session.board,
      'offerIds': session.offerIds,
      'score': session.score,
      'bestScore': session.bestScores[session.boardSize] ?? 0,
      'bestScores': session.bestScores.map(
        (key, value) => MapEntry('$key', value),
      ),
      'combo': session.combo,
      'moveCount': session.moveCount,
      'musicEnabled': session.musicEnabled,
      'sfxEnabled': session.sfxEnabled,
      'voiceEnabled': session.voiceEnabled,
      'hapticsEnabled': session.hapticsEnabled,
      'reducedMotion': session.reducedMotion,
      'highContrast': session.highContrast,
      'gameOver': session.gameOver,
      'boardWipeAchieved': session.boardWipeAchieved,
      'privacyConsentGiven': session.privacyConsentGiven,
      'hasSeenOnboarding': session.hasSeenOnboarding,
      'premiumUnlocked': session.premiumUnlocked,
      'reviveTokens': session.reviveTokens,
      'adReady': session.adReady,
      'savedAt': DateTime.now().millisecondsSinceEpoch,
    };
    try {
      if (!_initialUploadDone) {
        try {
          await db.transact(
            combineChunks(<TransactionChunk>[
              db.tx['profiles'].create(<String, dynamic>{
                'id': playerId,
                'displayName': 'Guest Pilot',
                'updatedAt': DateTime.now().millisecondsSinceEpoch,
              }),
              db.tx['runs'].create(payload),
            ]),
          );
        } catch (_) {}
        _initialUploadDone = true;
      }
      await db.transact(db.tx['runs'][playerId].merge(payload));
      statusLabel = db.isOnline.value ? 'Cloud Sync Live' : 'Cloud Sync Queued';
    } catch (_) {
      statusLabel = 'Cloud Sync Queued';
    }
  }

  Future<PersistedSession?> pullSnapshot() async {
    final db = _db;
    final playerId = _playerId;
    if (db == null || playerId == null) {
      return null;
    }
    try {
      final result = await db.queryOnce(<String, dynamic>{
        'runs': <String, dynamic>{
          'where': <String, dynamic>{'id': playerId},
        },
      });
      final runs = result.data?['runs'];
      if (runs is! List || runs.isEmpty) {
        return null;
      }
      final snapshot = runs.first;
      if (snapshot is! Map) {
        return null;
      }
      return PersistedSession.fromJson(Map<String, dynamic>.from(snapshot));
    } catch (_) {
      return null;
    }
  }

  Future<void> dispose() async {
    await _db?.dispose();
  }
}

@immutable
class Cell {
  const Cell(this.row, this.col);

  final int row;
  final int col;

  @override
  bool operator ==(Object other) {
    return other is Cell && other.row == row && other.col == col;
  }

  @override
  int get hashCode => Object.hash(row, col);
}

class PieceBounds {
  const PieceBounds({
    required this.minRow,
    required this.minCol,
    required this.maxRow,
    required this.maxCol,
  });

  final int minRow;
  final int minCol;
  final int maxRow;
  final int maxCol;

  double get width => (maxCol - minCol + 1).toDouble();

  double get height => (maxRow - minRow + 1).toDouble();
}

class Piece {
  const Piece({required this.id, required this.name, required this.cells});

  final String id;
  final String name;
  final List<Cell> cells;

  PieceBounds get bounds {
    final rows = cells.map((cell) => cell.row);
    final cols = cells.map((cell) => cell.col);
    return PieceBounds(
      minRow: rows.reduce(math.min),
      minCol: cols.reduce(math.min),
      maxRow: rows.reduce(math.max),
      maxCol: cols.reduce(math.max),
    );
  }

  List<Cell> anchoredAt(int row, int col) {
    final bounds = this.bounds;
    return cells
        .map(
          (cell) => Cell(
            row + cell.row - bounds.minRow,
            col + cell.col - bounds.minCol,
          ),
        )
        .toList();
  }
}

List<List<bool>> _emptyBoard(int size) =>
    List<List<bool>>.generate(size, (_) => List<bool>.filled(size, false));

Piece? _pieceFromId(String id) {
  for (final piece in pieceLibrary) {
    if (piece.id == id) {
      return piece;
    }
  }
  return null;
}

const List<Piece> pieceLibrary = <Piece>[
  Piece(id: 'single', name: 'Core', cells: <Cell>[Cell(0, 0)]),
  Piece(id: 'domino_h', name: 'Twin', cells: <Cell>[Cell(0, 0), Cell(0, 1)]),
  Piece(id: 'domino_v', name: 'Spire', cells: <Cell>[Cell(0, 0), Cell(1, 0)]),
  Piece(id: 'diag_r', name: 'Drift R', cells: <Cell>[Cell(0, 0), Cell(1, 1)]),
  Piece(id: 'diag_l', name: 'Drift L', cells: <Cell>[Cell(0, 1), Cell(1, 0)]),
  Piece(
    id: 'triple_h',
    name: 'Beam',
    cells: <Cell>[Cell(0, 0), Cell(0, 1), Cell(0, 2)],
  ),
  Piece(
    id: 'triple_v',
    name: 'Column',
    cells: <Cell>[Cell(0, 0), Cell(1, 0), Cell(2, 0)],
  ),
  Piece(
    id: 'l_se',
    name: 'Hook SE',
    cells: <Cell>[Cell(0, 0), Cell(1, 0), Cell(1, 1)],
  ),
  Piece(
    id: 'l_sw',
    name: 'Hook SW',
    cells: <Cell>[Cell(0, 1), Cell(1, 1), Cell(1, 0)],
  ),
  Piece(
    id: 'l_ne',
    name: 'Hook NE',
    cells: <Cell>[Cell(1, 0), Cell(0, 0), Cell(0, 1)],
  ),
  Piece(
    id: 'l_nw',
    name: 'Hook NW',
    cells: <Cell>[Cell(1, 1), Cell(0, 1), Cell(0, 0)],
  ),
  Piece(
    id: 'diag3_r',
    name: 'Rift R',
    cells: <Cell>[Cell(0, 0), Cell(1, 1), Cell(2, 2)],
  ),
  Piece(
    id: 'diag3_l',
    name: 'Rift L',
    cells: <Cell>[Cell(0, 2), Cell(1, 1), Cell(2, 0)],
  ),
  Piece(
    id: 'kite_r',
    name: 'Kite R',
    cells: <Cell>[Cell(0, 0), Cell(1, 1), Cell(2, 1)],
  ),
  Piece(
    id: 'kite_l',
    name: 'Kite L',
    cells: <Cell>[Cell(0, 1), Cell(1, 0), Cell(2, 0)],
  ),
];
