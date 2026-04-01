import 'package:flutter_test/flutter_test.dart';

import 'package:aether_block_blast/src/app.dart';
import 'package:aether_block_blast/src/telemetry.dart';

void main() {
  test('piece library includes diagonal and single-cell pieces', () {
    expect(pieceLibrary.any((piece) => piece.id == 'single'), isTrue);
    expect(pieceLibrary.any((piece) => piece.id == 'diag_r'), isTrue);
    expect(pieceLibrary.any((piece) => piece.id == 'diag3_l'), isTrue);
    expect(kGridSizes.first, 8);
    expect(kGridSizes.last, 32);
  });

  test('persisted session round-trips consent and onboarding flags', () {
    const session = PersistedSession(
      playerId: 'guest-1',
      boardSize: 8,
      board: <List<int>>[
        <int>[0, 1],
        <int>[1, 0],
      ],
      offerIds: <String>['single'],
      score: 10,
      combo: 1,
      moveCount: 2,
      bestScores: <int, int>{8: 10},
      musicEnabled: true,
      sfxEnabled: false,
      voiceEnabled: true,
      hapticsEnabled: true,
      reducedMotion: false,
      highContrast: false,
      gameOver: false,
      boardWipeAchieved: false,
      privacyConsentGiven: true,
      hasSeenOnboarding: true,
      premiumUnlocked: true,
      reviveTokens: 3,
      adReady: true,
      maxComboReached: 4,
      totalRowsCleared: 6,
      totalColumnsCleared: 5,
      totalBlocksCleared: 2,
      dailyProgressDateKey: '2026-04-01',
      dailyBestScore: 420,
      lastDailyCompletionKey: '2026-04-01',
      dailyStreak: 3,
      dailyRewardClaimed: true,
    );

    final decoded = PersistedSession.fromJson(session.toJson());

    expect(decoded.privacyConsentGiven, isTrue);
    expect(decoded.hasSeenOnboarding, isTrue);
    expect(decoded.premiumUnlocked, isTrue);
    expect(decoded.reviveTokens, 3);
    expect(decoded.adReady, isTrue);
    expect(decoded.maxComboReached, 4);
    expect(decoded.totalRowsCleared, 6);
    expect(decoded.totalColumnsCleared, 5);
    expect(decoded.totalBlocksCleared, 2);
    expect(decoded.dailyProgressDateKey, '2026-04-01');
    expect(decoded.dailyBestScore, 420);
    expect(decoded.lastDailyCompletionKey, '2026-04-01');
    expect(decoded.dailyStreak, 3);
    expect(decoded.dailyRewardClaimed, isTrue);
    expect(decoded.offerIds, equals(<String>['single']));
  });

  test('daily challenge generation is deterministic and bounded', () {
    final first = DailyChallengeSpec.forDate(DateTime.utc(2026, 4, 1));
    final second = DailyChallengeSpec.forDate(DateTime.utc(2026, 4, 1));

    expect(second.dateKey, first.dateKey);
    expect(second.boardSize, first.boardSize);
    expect(second.targetScore, first.targetScore);
    expect(kGridSizes.contains(first.boardSize), isTrue);
    expect(first.targetScore, greaterThan(0));
    expect(first.rewardTokens, greaterThanOrEqualTo(1));
  });

  test('telemetry client captures ordered events', () {
    final telemetry = TelemetryClient();

    telemetry.logEvent('first');
    telemetry.logEvent('second', properties: <String, Object?>{'count': 2});

    expect(telemetry.events.length, 2);
    expect(telemetry.events.first.name, 'first');
    expect(telemetry.events.last.properties['count'], 2);
  });
}
