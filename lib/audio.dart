import 'package:audioplayers/audioplayers.dart';

import 'settings.dart';

/// Apothecary audio: glass clinks, liquid glugs, cork pops, brass chimes —
/// all synthesized (tools/gen_audio.py). Music/SFX toggles and volumes take
/// effect immediately.
class ApothecaryAudio {
  ApothecaryAudio._();
  static final ApothecaryAudio instance = ApothecaryAudio._();

  final AudioPlayer _music = AudioPlayer();
  final List<AudioPlayer> _sfxPool =
      List.generate(4, (_) => AudioPlayer());
  int _sfxCursor = 0;

  bool _ready = false;
  String? _currentTrack;

  Future<void> init() async {
    if (_ready) return;
    try {
      await _music.setReleaseMode(ReleaseMode.loop);
    } catch (_) {}
    _ready = true;
  }

  void _applyVolumes() {
    final s = AppSettings.instance;
    try {
      _music.setVolume((s.musicVol * 0.7).clamp(0.0, 1.0));
    } catch (_) {}
  }

  Future<void> playMusic(String asset) async {
    if (!_ready) return;
    final s = AppSettings.instance;
    if (!s.musicOn) return;
    if (_currentTrack == asset) return;
    _currentTrack = asset;
    try {
      _applyVolumes();
      await _music.play(AssetSource('audio/$asset'));
    } catch (_) {
      _currentTrack = null;
    }
  }

  Future<void> stopMusic() async {
    _currentTrack = null;
    try {
      await _music.stop();
    } catch (_) {}
  }

  /// Re-apply toggle/volume state (call after settings change).
  Future<void> refresh() async {
    final s = AppSettings.instance;
    if (!s.musicOn) {
      await stopMusic();
    } else {
      _applyVolumes();
      if (_currentTrack != null) {
        final t = _currentTrack!;
        _currentTrack = null;
        await playMusic(t);
      }
    }
  }

  Future<void> _play(String asset,
      {double vol = 1.0, double rate = 1.0}) async {
    if (!_ready) return;
    final s = AppSettings.instance;
    if (!s.sfxOn) return;
    try {
      final p = _sfxPool[_sfxCursor];
      _sfxCursor = (_sfxCursor + 1) % _sfxPool.length;
      await p.setVolume((s.sfxVol * vol).clamp(0.0, 1.0));
      await p.setPlaybackRate(rate);
      await p.play(AssetSource('audio/$asset'));
    } catch (_) {}
  }

  /// Brass button click.
  Future<void> click() => _play('click.wav');

  /// Dull glass clink for invalid moves.
  Future<void> clink() => _play('clink.wav', vol: 0.85);

  /// Liquid pour glug; [fillFraction] (0..1) of the destination vial bends
  /// the pitch, per the apothecary audio identity.
  Future<void> pour(double fillFraction) =>
      _play('pour.wav', vol: 0.9, rate: (0.92 + 0.24 * fillFraction).clamp(0.8, 1.3));

  /// Cork pop for level complete.
  Future<void> pop() => _play('pop.wav');

  /// Brass chime arpeggio for a 3-star victory.
  Future<void> chime() => _play('chime.wav');

  /// Game start: cork + rising notes.
  Future<void> start() => _play('start.wav');

  /// Soft wooden creak for undo.
  Future<void> undo() => _play('undo.wav', vol: 0.7);

  void dispose() {
    for (final p in _sfxPool) {
      p.dispose();
    }
    _music.dispose();
  }
}
