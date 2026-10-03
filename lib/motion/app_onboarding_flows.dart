import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_motion.dart';
import 'app_onboarding.dart';
import 'app_onboarding_parts.dart';
import 'app_pressable.dart';
import 'app_reveal.dart';
import 'app_scene_parts.dart';
import 'app_text_motion.dart';

// Onboarding *flows*: different skeletons, not only different art. The design
// direction picks ONE flow per app from its concept
// (skills/fluttergo-motion-system/references/onboarding-scenes.md):
//   carousel  → AppOnboarding           (utility, productivity)
//   story     → AppStoryOnboarding      (food, travel, lifestyle, photo-led)
//   chat      → AppChatOnboarding       (AI, coaching, health, companions)
//   quiz      → AppQuizOnboarding       (fitness, nutrition, learning)
//   editorial → AppEditorialOnboarding  (finance, premium, fashion)
//   scene     → AppSceneOnboarding      (maps, delivery, trackers, finance)

/// Shared full-width call to action used by the flows.
class _FlowButton extends StatelessWidget {
  const _FlowButton({required this.label, required this.onTap, required this.color, required this.textColor});

  final String label;
  final VoidCallback? onTap;
  final Color color;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return AnimatedOpacity(
      opacity: enabled ? 1 : 0.38,
      duration: AppMotion.md,
      child: AppPressable(
        onTap: onTap,
        semanticLabel: label,
        child: Container(
          height: 54,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(999)),
          child: AnimatedSwitcher(
            duration: AppMotion.sm,
            child: Text(
              label,
              key: ValueKey(label),
              style: TextStyle(color: textColor, fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// STORY — full-screen photo story, progress segments at the top.
// ─────────────────────────────────────────────────────────────────────────

/// Instagram-story style onboarding: each step's [AppOnboardingStep.art]
/// fills the screen (a photo / photo + one UI card) with a slow push-in,
/// segments fill at the top, tap right = next, tap left = back, hold = pause.
/// The call to action only appears on the last story.
class AppStoryOnboarding extends StatefulWidget {
  const AppStoryOnboarding({
    super.key,
    required this.steps,
    required this.onDone,
    this.stepDuration = const Duration(seconds: 5),
    this.autoAdvance = true,
    this.nextLabel = 'Next',
    this.doneLabel = 'Get started',
    this.skipLabel = 'Skip',
    this.accent,
    this.titleStyle,
    this.bodyStyle,
  });

  final List<AppOnboardingStep> steps;
  final VoidCallback onDone;
  final Duration stepDuration;

  /// Advance on a timer (off under reduced motion; hold to pause).
  final bool autoAdvance;
  final String nextLabel;
  final String doneLabel;
  final String skipLabel;
  final Color? accent;
  final TextStyle? titleStyle;
  final TextStyle? bodyStyle;

  @override
  State<AppStoryOnboarding> createState() => _AppStoryOnboardingState();
}

class _AppStoryOnboardingState extends State<AppStoryOnboarding> with SingleTickerProviderStateMixin {
  late final AnimationController _timer = AnimationController(vsync: this, duration: widget.stepDuration)
    ..addStatusListener(_onTimer);
  int _index = 0;
  bool _started = false;

  bool get _last => _index == widget.steps.length - 1;
  bool get _auto => widget.autoAdvance && !AppMotion.reduced(context);

  void _onTimer(AnimationStatus s) {
    if (s == AnimationStatus.completed && !_last) _goTo(_index + 1);
  }

  void _restart() {
    _timer.stop();
    _timer.value = 0;
    if (_auto && !_last) _timer.forward();
  }

  void _goTo(int i) {
    if (i < 0 || i >= widget.steps.length || i == _index) return;
    HapticFeedback.selectionClick();
    setState(() => _index = i);
    _restart();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _restart();
  }

  @override
  void dispose() {
    _timer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final accent = widget.accent ?? scheme.primary;
    final pad = MediaQuery.paddingOf(context);
    final width = MediaQuery.sizeOf(context).width;
    final reduce = AppMotion.reduced(context);
    final step = widget.steps[_index];
    const white = Color(0xFFFFFFFF);
    return Material(
      color: const Color(0xFF000000),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapUp: (d) {
          if (d.localPosition.dx < width * 0.3) {
            _goTo(_index - 1);
          } else {
            _goTo(_index + 1);
          }
        },
        onLongPressStart: (_) => _timer.stop(),
        onLongPressEnd: (_) {
          if (_auto && !_last) _timer.forward();
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            AnimatedSwitcher(
              duration: AppMotion.resolve(context, AppMotion.xl),
              switchInCurve: AppMotion.enter,
              switchOutCurve: AppMotion.exitCurve,
              transitionBuilder: (child, a) => FadeTransition(opacity: a, child: child),
              child: TweenAnimationBuilder<double>(
                key: ValueKey('story-art-$_index'),
                tween: Tween<double>(begin: 1, end: reduce ? 1 : 1.06),
                duration: widget.stepDuration,
                builder: (context, s, child) => Transform.scale(scale: s, child: child),
                child: Builder(builder: step.art),
              ),
            ),
            const IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: [0, 0.18, 0.5, 1],
                    colors: [Color(0x80000000), Color(0x00000000), Color(0x00000000), Color(0xD9000000)],
                  ),
                ),
              ),
            ),
            Positioned(
              top: pad.top + 10,
              left: 12,
              right: 12,
              child: Semantics(
                label: 'Story ${_index + 1} of ${widget.steps.length}',
                child: Row(
                  children: [
                    for (var i = 0; i < widget.steps.length; i++)
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(2),
                            child: SizedBox(
                              height: 3,
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  const ColoredBox(color: Color(0x59FFFFFF)),
                                  if (i < _index)
                                    const ColoredBox(color: white)
                                  else if (i == _index)
                                    AnimatedBuilder(
                                      animation: _timer,
                                      builder: (context, _) => FractionallySizedBox(
                                        alignment: Alignment.centerLeft,
                                        widthFactor: _last || !_auto ? 1 : _timer.value,
                                        child: const ColoredBox(color: white),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Positioned(
              top: pad.top + 18,
              right: 8,
              child: AnimatedOpacity(
                opacity: _last ? 0 : 1,
                duration: AppMotion.md,
                child: TextButton(
                  onPressed: _last ? null : widget.onDone,
                  child: Text(widget.skipLabel, style: const TextStyle(color: white, fontWeight: FontWeight.w600)),
                ),
              ),
            ),
            Positioned(
              left: 24,
              right: 24,
              bottom: pad.bottom + 20,
              child: Column(
                key: ValueKey('story-copy-$_index'),
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppReveal(
                    delay: const Duration(milliseconds: 160),
                    child: Text(
                      step.title,
                      style: (widget.titleStyle ?? text.headlineMedium ?? const TextStyle())
                          .copyWith(color: white, fontWeight: FontWeight.w700, height: 1.08),
                    ),
                  ),
                  const SizedBox(height: 8),
                  AppReveal(
                    index: 1,
                    delay: const Duration(milliseconds: 160),
                    child: Text(
                      step.body,
                      style: (widget.bodyStyle ?? text.bodyLarge ?? const TextStyle())
                          .copyWith(color: const Color(0xD9FFFFFF), height: 1.4),
                    ),
                  ),
                  const SizedBox(height: 22),
                  if (_last)
                    AppReveal.pop(
                      delay: const Duration(milliseconds: 260),
                      child: _FlowButton(
                        label: widget.doneLabel,
                        onTap: widget.onDone,
                        color: accent,
                        textColor: scheme.onPrimary,
                      ),
                    )
                  else
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => _goTo(_index + 1),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(widget.nextLabel, style: const TextStyle(color: white, fontWeight: FontWeight.w600)),
                            const SizedBox(width: 6),
                            const Icon(Icons.arrow_forward_rounded, color: white, size: 18),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// CHAT — the app introduces itself in a conversation.
// ─────────────────────────────────────────────────────────────────────────

/// One assistant message in [AppChatOnboarding]. With [replies] the user
/// answers by tapping a quick-reply chip; without, the assistant continues.
class AppChatTurn {
  const AppChatTurn({required this.message, this.replies = const [], this.card});

  final String message;
  final List<String> replies;

  /// Optional rich card under the message (a plan preview, a scanned meal,
  /// a mini chart) — this is where the product shows itself working.
  final WidgetBuilder? card;
}

/// Conversational onboarding: typing dots → the assistant's bubble pops in →
/// quick replies rise → the chosen reply flies in from the right. Collects
/// the answers (null for turns without replies) and passes them to [onDone].
class AppChatOnboarding extends StatefulWidget {
  const AppChatOnboarding({
    super.key,
    required this.turns,
    required this.onDone,
    this.assistantName = 'Assistant',
    this.assistantStatus = 'online',
    this.avatar,
    this.doneLabel = 'Get started',
    this.skipLabel = 'Skip',
    this.accent,
    this.bubbleColor,
  });

  final List<AppChatTurn> turns;
  final void Function(List<String?> answers) onDone;
  final String assistantName;
  final String assistantStatus;
  final Widget? avatar;
  final String doneLabel;
  final String skipLabel;
  final Color? accent;

  /// Assistant bubble colour (defaults to a soft surface tone).
  final Color? bubbleColor;

  @override
  State<AppChatOnboarding> createState() => _AppChatOnboardingState();
}

class _ChatLine {
  const _ChatLine.bot(this.turn) : text = null;
  const _ChatLine.me(String this.text) : turn = -1;

  final int turn;
  final String? text;
}

class _AppChatOnboardingState extends State<AppChatOnboarding> {
  final _lines = <_ChatLine>[];
  final _answers = <String?>[];
  final _scroll = ScrollController();
  Timer? _t;
  int _turn = 0;
  bool _typing = false;
  bool _awaiting = false;
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _play());
  }

  @override
  void dispose() {
    _t?.cancel();
    _scroll.dispose();
    super.dispose();
  }

  void _play() {
    if (!mounted) return;
    if (_turn >= widget.turns.length) {
      setState(() => _finished = true);
      _scrollToEnd();
      return;
    }
    final reduce = AppMotion.reduced(context);
    setState(() => _typing = true);
    _scrollToEnd();
    _t?.cancel();
    _t = Timer(Duration(milliseconds: reduce ? 150 : 850), () {
      if (!mounted) return;
      final turn = widget.turns[_turn];
      setState(() {
        _typing = false;
        _lines.add(_ChatLine.bot(_turn));
        _awaiting = turn.replies.isNotEmpty;
      });
      _scrollToEnd();
      if (turn.replies.isEmpty) {
        _answers.add(null);
        _turn++;
        // Reading time before the next message.
        final ms = (450 + turn.message.length * 22).clamp(600, 2200);
        _t = Timer(Duration(milliseconds: ms), _play);
      }
    });
  }

  void _reply(String r) {
    if (!_awaiting) return;
    HapticFeedback.selectionClick();
    setState(() {
      _awaiting = false;
      _lines.add(_ChatLine.me(r));
      _answers.add(r);
      _turn++;
    });
    _scrollToEnd();
    _t?.cancel();
    _t = Timer(const Duration(milliseconds: 350), _play);
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: AppMotion.resolve(context, AppMotion.lg, essential: true),
        curve: AppMotion.standard,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final accent = widget.accent ?? scheme.primary;
    final pad = MediaQuery.paddingOf(context);
    final maxW = MediaQuery.sizeOf(context).width * 0.74;
    final bubble = widget.bubbleColor ?? scheme.surfaceContainerHighest;
    return Material(
      color: scheme.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(height: pad.top + 8),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 8, 8),
            child: Row(
              children: [
                widget.avatar ??
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
                      child: Icon(Icons.auto_awesome_rounded, color: scheme.onPrimary, size: 20),
                    ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.assistantName, style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                      AnimatedSwitcher(
                        duration: AppMotion.sm,
                        child: Text(
                          _typing ? 'typing…' : widget.assistantStatus,
                          key: ValueKey(_typing),
                          style: text.bodySmall?.copyWith(color: _typing ? accent : scheme.onSurfaceVariant),
                        ),
                      ),
                    ],
                  ),
                ),
                AnimatedOpacity(
                  opacity: _finished ? 0 : 1,
                  duration: AppMotion.md,
                  child: TextButton(
                    onPressed: _finished ? null : () => widget.onDone(List<String?>.unmodifiable(_answers)),
                    child: Text(widget.skipLabel, style: TextStyle(color: scheme.onSurface, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              controller: _scroll,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              children: [
                for (var i = 0; i < _lines.length; i++)
                  Padding(
                    key: ValueKey('chat-line-$i'),
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _lines[i].text != null
                        ? Align(
                            alignment: Alignment.centerRight,
                            child: AppChatBubble(
                              fromMe: true,
                              color: accent,
                              maxWidth: maxW,
                              child: Text(_lines[i].text!, style: text.bodyLarge?.copyWith(color: scheme.onPrimary)),
                            ),
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AppChatBubble(
                                color: bubble,
                                maxWidth: maxW,
                                child: Text(
                                  widget.turns[_lines[i].turn].message,
                                  style: text.bodyLarge?.copyWith(color: scheme.onSurface, height: 1.35),
                                ),
                              ),
                              if (widget.turns[_lines[i].turn].card != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: AppReveal(
                                    delay: const Duration(milliseconds: 180),
                                    child: Builder(builder: widget.turns[_lines[i].turn].card!),
                                  ),
                                ),
                            ],
                          ),
                  ),
                if (_typing)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                      decoration: BoxDecoration(color: bubble, borderRadius: BorderRadius.circular(18)),
                      child: const AppTypingDots(),
                    ),
                  ),
              ],
            ),
          ),
          AnimatedSize(
            duration: AppMotion.resolve(context, AppMotion.md),
            curve: AppMotion.standard,
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, pad.bottom + 16),
              child: _finished
                  ? AppReveal.pop(
                      child: _FlowButton(
                        label: widget.doneLabel,
                        onTap: () => widget.onDone(List<String?>.unmodifiable(_answers)),
                        color: accent,
                        textColor: scheme.onPrimary,
                      ),
                    )
                  : _awaiting
                      ? Wrap(
                          key: ValueKey('replies-$_turn'),
                          alignment: WrapAlignment.end,
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (var i = 0; i < widget.turns[_turn].replies.length; i++)
                              AppReveal(
                                index: i,
                                child: AppPressable(
                                  onTap: () => _reply(widget.turns[_turn].replies[i]),
                                  semanticLabel: widget.turns[_turn].replies[i],
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(999),
                                      border: Border.all(color: accent, width: 1.4),
                                    ),
                                    child: Text(
                                      widget.turns[_turn].replies[i],
                                      style: text.titleSmall?.copyWith(color: accent, fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        )
                      : const SizedBox(width: double.infinity),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// QUIZ — personalise with one question per screen.
// ─────────────────────────────────────────────────────────────────────────

/// One question in [AppQuizOnboarding].
class AppQuizQuestion {
  const AppQuizQuestion({
    required this.title,
    required this.options,
    this.subtitle,
    this.multiSelect = false,
    this.icons,
  });

  final String title;
  final String? subtitle;
  final List<String> options;
  final bool multiSelect;

  /// Optional leading icon per option (same length as [options]).
  final List<IconData>? icons;
}

/// How quiz options are laid out.
enum AppQuizLayout {
  /// Full-width pill choices (calm).
  list,

  /// Two-column tiles with the icon on top (playful, visual).
  grid,
}

/// Personalisation onboarding: a progress line fills at the top, each question
/// rises in, options stagger in, a single-choice tap auto-advances, Continue
/// stays dim until something is chosen. [finale] (optional) is shown after
/// the last answer — e.g. the plan being built from the answers.
class AppQuizOnboarding extends StatefulWidget {
  const AppQuizOnboarding({
    super.key,
    required this.questions,
    required this.onDone,
    this.finale,
    this.layout = AppQuizLayout.list,
    this.continueLabel = 'Continue',
    this.doneLabel = 'Get started',
    this.skipLabel = 'Skip',
    this.accent,
    this.titleStyle,
  });

  final List<AppQuizQuestion> questions;
  final void Function(List<Set<int>> answers) onDone;
  final WidgetBuilder? finale;
  final AppQuizLayout layout;
  final String continueLabel;
  final String doneLabel;
  final String skipLabel;
  final Color? accent;
  final TextStyle? titleStyle;

  @override
  State<AppQuizOnboarding> createState() => _AppQuizOnboardingState();
}

class _AppQuizOnboardingState extends State<AppQuizOnboarding> {
  late final List<Set<int>> _answers = [for (final _ in widget.questions) <int>{}];
  int _q = 0;
  Timer? _auto;

  bool get _inFinale => _q >= widget.questions.length;
  int get _pages => widget.questions.length + (widget.finale != null ? 1 : 0);

  @override
  void dispose() {
    _auto?.cancel();
    super.dispose();
  }

  void _done() => widget.onDone([for (final a in _answers) Set<int>.unmodifiable(a)]);

  void _next() {
    _auto?.cancel();
    if (_q + 1 >= _pages) {
      _done();
      return;
    }
    HapticFeedback.selectionClick();
    setState(() => _q++);
  }

  void _back() {
    _auto?.cancel();
    if (_q == 0) return;
    setState(() => _q--);
  }

  void _toggle(int option) {
    final q = widget.questions[_q];
    setState(() {
      final set = _answers[_q];
      if (q.multiSelect) {
        if (!set.remove(option)) set.add(option);
      } else {
        set
          ..clear()
          ..add(option);
      }
    });
    if (!q.multiSelect) {
      _auto?.cancel();
      _auto = Timer(const Duration(milliseconds: 360), () {
        if (mounted) _next();
      });
    }
  }

  Widget _gridTile(BuildContext context, AppQuizQuestion q, int i, Color accent) {
    final scheme = Theme.of(context).colorScheme;
    final on = _answers[_q].contains(i);
    return Semantics(
      button: true,
      selected: on,
      label: q.options[i],
      child: AppPressable(
        onTap: () => _toggle(i),
        child: AnimatedContainer(
          duration: AppMotion.md,
          curve: AppMotion.standard,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: on ? accent.withAlpha(28) : scheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: on ? accent : scheme.outlineVariant, width: on ? 2 : 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  if (q.icons != null && i < q.icons!.length)
                    Icon(q.icons![i], color: on ? accent : scheme.onSurface, size: 28),
                  const Spacer(),
                  AnimatedScale(
                    scale: on ? 1 : 0,
                    duration: AppMotion.sm,
                    curve: AppMotion.curve(context, AppMotion.pop),
                    child: Icon(Icons.check_circle_rounded, color: accent, size: 22),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                q.options[i],
                style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _question(BuildContext context, AppQuizQuestion q, Color accent) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return ListView(
      key: ValueKey('quiz-$_q'),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
      children: [
        AppReveal(
          child: Text(
            q.title,
            style: (widget.titleStyle ?? text.headlineSmall ?? const TextStyle())
                .copyWith(fontWeight: FontWeight.w700, height: 1.12),
          ),
        ),
        if (q.subtitle != null) ...[
          const SizedBox(height: 8),
          AppReveal(
            index: 1,
            child: Text(q.subtitle!, style: text.bodyLarge?.copyWith(color: scheme.onSurfaceVariant)),
          ),
        ],
        const SizedBox(height: 24),
        if (widget.layout == AppQuizLayout.grid)
          LayoutBuilder(
            builder: (context, c) {
              final w = (c.maxWidth - 12) / 2;
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  for (var i = 0; i < q.options.length; i++)
                    SizedBox(width: w, child: AppReveal(index: i + 2, child: _gridTile(context, q, i, accent))),
                ],
              );
            },
          )
        else
          for (var i = 0; i < q.options.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: AppReveal(
                index: i + 2,
                child: AppChoiceTile(
                  label: q.options[i],
                  selected: _answers[_q].contains(i),
                  onTap: () => _toggle(i),
                  leading: q.icons != null && i < q.icons!.length ? Icon(q.icons![i], size: 20) : null,
                ),
              ),
            ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accent = widget.accent ?? scheme.primary;
    final pad = MediaQuery.paddingOf(context);
    final progress = (_q + 1) / _pages;
    final canContinue = _inFinale || _answers[_q].isNotEmpty;
    final lastPage = _q + 1 >= _pages;
    return Material(
      color: scheme.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(height: pad.top + 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                AnimatedOpacity(
                  opacity: _q == 0 ? 0 : 1,
                  duration: AppMotion.md,
                  child: IconButton(
                    onPressed: _q == 0 ? null : _back,
                    tooltip: 'Back',
                    icon: Icon(Icons.arrow_back_rounded, color: scheme.onSurface),
                  ),
                ),
                Expanded(
                  child: Semantics(
                    label: 'Question ${_q + 1} of $_pages',
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: SizedBox(
                        height: 5,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            ColoredBox(color: scheme.onSurface.withAlpha(24)),
                            TweenAnimationBuilder<double>(
                              tween: Tween<double>(end: progress),
                              duration: AppMotion.resolve(context, AppMotion.lg, essential: true),
                              curve: AppMotion.enter,
                              builder: (context, v, _) => FractionallySizedBox(
                                alignment: Alignment.centerLeft,
                                widthFactor: v,
                                child: ColoredBox(color: accent),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                AnimatedOpacity(
                  opacity: _inFinale ? 0 : 1,
                  duration: AppMotion.md,
                  child: TextButton(
                    onPressed: _inFinale ? null : _done,
                    child: Text(widget.skipLabel, style: TextStyle(color: scheme.onSurface, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: AnimatedSwitcher(
              duration: AppMotion.resolve(context, AppMotion.lg),
              switchInCurve: AppMotion.enter,
              switchOutCurve: AppMotion.exitCurve,
              layoutBuilder: (current, previous) => Stack(
                alignment: Alignment.topCenter,
                children: [...previous, ?current],
              ),
              transitionBuilder: (child, a) => FadeTransition(
                opacity: a,
                child: SlideTransition(
                  position: Tween<Offset>(begin: const Offset(0, 0.03), end: Offset.zero).animate(a),
                  child: child,
                ),
              ),
              child: _inFinale
                  ? KeyedSubtree(key: const ValueKey('quiz-finale'), child: Builder(builder: widget.finale!))
                  : _question(context, widget.questions[_q], accent),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(20, 8, 20, pad.bottom + 18),
            child: _FlowButton(
              label: lastPage ? widget.doneLabel : widget.continueLabel,
              onTap: canContinue ? _next : null,
              color: lastPage ? accent : scheme.onSurface,
              textColor: lastPage ? scheme.onPrimary : scheme.surface,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// EDITORIAL — oversized type is the hero.
// ─────────────────────────────────────────────────────────────────────────

/// One step of [AppEditorialOnboarding].
class AppEditorialStep {
  const AppEditorialStep({required this.headline, this.body, this.highlight, this.art});

  /// Short (2–6 words). Its words rise out of a mask one by one.
  final String headline;
  final String? body;

  /// One word of [headline] painted in the accent.
  final String? highlight;

  /// Optional visual that fills the space above the headline — a real photo
  /// or product shot (use `fit: BoxFit.cover`). Without it the headline sits
  /// lower on a plain page; never a small floating thumbnail.
  final WidgetBuilder? art;
}

/// Editorial onboarding: huge headline revealed word by word, a "01 / 04"
/// counter, a round arrow button whose ring fills with progress. Swipe or tap
/// the button to advance.
class AppEditorialOnboarding extends StatefulWidget {
  const AppEditorialOnboarding({
    super.key,
    required this.steps,
    required this.onDone,
    this.doneLabel = 'Get started',
    this.skipLabel = 'Skip',
    this.accent,
    this.background,
    this.ink,
    this.headlineStyle,
  });

  final List<AppEditorialStep> steps;
  final VoidCallback onDone;
  final String doneLabel;
  final String skipLabel;
  final Color? accent;
  final Color? background;
  final Color? ink;
  final TextStyle? headlineStyle;

  @override
  State<AppEditorialOnboarding> createState() => _AppEditorialOnboardingState();
}

class _AppEditorialOnboardingState extends State<AppEditorialOnboarding> {
  int _index = 0;

  bool get _last => _index == widget.steps.length - 1;

  void _goTo(int i) {
    if (i < 0 || i >= widget.steps.length || i == _index) return;
    HapticFeedback.selectionClick();
    setState(() => _index = i);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final accent = widget.accent ?? scheme.primary;
    final bg = widget.background ?? scheme.surface;
    final ink = widget.ink ?? scheme.onSurface;
    final pad = MediaQuery.paddingOf(context);
    final step = widget.steps[_index];
    // Oversized type is the point of this flow: never smaller than ~12% of
    // the screen width (40–64), even when the app passes a smaller style.
    final big = (MediaQuery.sizeOf(context).width * 0.125).clamp(40.0, 64.0);
    var headline = (text.displayLarge ?? const TextStyle())
        .merge(widget.headlineStyle)
        .copyWith(color: ink, fontWeight: FontWeight.w800, letterSpacing: -1.2, height: 1.0);
    if ((headline.fontSize ?? 0) < big * 0.85) headline = headline.copyWith(fontSize: big);
    return Material(
      color: bg,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onHorizontalDragEnd: (d) {
          final v = d.primaryVelocity ?? 0;
          if (v < -250) _goTo(_index + 1);
          if (v > 250) _goTo(_index - 1);
        },
        child: Padding(
          padding: EdgeInsets.fromLTRB(28, pad.top + 12, 24, pad.bottom + 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  AppStepCounter(index: _index, total: widget.steps.length, color: ink),
                  const Spacer(),
                  AnimatedOpacity(
                    opacity: _last ? 0 : 1,
                    duration: AppMotion.md,
                    child: TextButton(
                      onPressed: _last ? null : widget.onDone,
                      child: Text(widget.skipLabel, style: TextStyle(color: ink, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
              Expanded(
                child: AnimatedSwitcher(
                  duration: AppMotion.resolve(context, AppMotion.md),
                  switchInCurve: AppMotion.enter,
                  switchOutCurve: AppMotion.exitCurve,
                  layoutBuilder: (current, previous) => Stack(
                    fit: StackFit.expand,
                    alignment: Alignment.bottomLeft,
                    children: [...previous, ?current],
                  ),
                  transitionBuilder: (child, a) => FadeTransition(opacity: a, child: child),
                  child: Column(
                    key: ValueKey('editorial-$_index'),
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (step.art != null)
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 16, bottom: 28),
                            child: AppReveal.fade(
                              delay: const Duration(milliseconds: 120),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(24),
                                child: SizedBox.expand(child: Builder(builder: step.art!)),
                              ),
                            ),
                          ),
                        )
                      else
                        const Spacer(),
                      AppMaskedHeadline(
                        text: step.headline,
                        style: headline,
                        highlight: step.highlight,
                        highlightColor: accent,
                      ),
                      if (step.body != null) ...[
                        const SizedBox(height: 16),
                        AppReveal(
                          delay: Duration(milliseconds: 260 + 60 * step.headline.split(' ').length),
                          child: Text(
                            step.body!,
                            style: text.bodyLarge?.copyWith(color: ink.withAlpha(170), height: 1.45),
                          ),
                        ),
                      ],
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: AppMotion.md,
                      child: _last
                          ? Align(
                              key: const ValueKey('done-label'),
                              alignment: Alignment.centerLeft,
                              child: Text(
                                widget.doneLabel,
                                style: text.titleMedium?.copyWith(color: ink, fontWeight: FontWeight.w700),
                              ),
                            )
                          : const SizedBox(key: ValueKey('no-label')),
                    ),
                  ),
                  AppRingArrowButton(
                    progress: (_index + 1) / widget.steps.length,
                    color: accent,
                    done: _last,
                    semanticLabel: _last ? widget.doneLabel : 'Next',
                    onTap: () => _last ? widget.onDone() : _goTo(_index + 1),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// SCENE — one continuous picture that moves forward with the steps.
// ─────────────────────────────────────────────────────────────────────────

/// Caption for one beat of [AppSceneOnboarding].
class AppSceneCaption {
  const AppSceneCaption({required this.title, required this.body});

  final String title;
  final String body;
}

/// One continuous scene instead of separate pages: [scene] is rebuilt with a
/// fractional `progress` (0 … captions.length − 1) as the user drags or taps
/// Next, so a courier can travel the route, a balance can grow, a room can
/// fill — the picture never cuts. Keep [scene] cheap (CustomPaint, Transforms,
/// lerpDouble / Offset.lerp between keyframes).
class AppSceneOnboarding extends StatefulWidget {
  const AppSceneOnboarding({
    super.key,
    required this.captions,
    required this.scene,
    required this.onDone,
    this.nextLabel = 'Next',
    this.doneLabel = 'Get started',
    this.skipLabel = 'Skip',
    this.accent,
    this.sceneFraction = 0.62,
  });

  final List<AppSceneCaption> captions;
  final Widget Function(BuildContext context, double progress) scene;
  final VoidCallback onDone;
  final String nextLabel;
  final String doneLabel;
  final String skipLabel;
  final Color? accent;

  /// Share of the height the scene takes (the captions sit below it).
  final double sceneFraction;

  @override
  State<AppSceneOnboarding> createState() => _AppSceneOnboardingState();
}

class _AppSceneOnboardingState extends State<AppSceneOnboarding> with SingleTickerProviderStateMixin {
  late final AnimationController _p = AnimationController(
    vsync: this,
    lowerBound: 0,
    upperBound: (widget.captions.length - 1).toDouble(),
  )..addListener(_onTick);
  int _shown = 0;

  int get _max => widget.captions.length - 1;
  int get _index => _p.value.round().clamp(0, _max);
  bool get _last => _index == _max;

  void _onTick() {
    if (_index != _shown) {
      HapticFeedback.selectionClick();
      setState(() => _shown = _index);
    }
  }

  void _go(int i) {
    final target = i.clamp(0, _max).toDouble();
    _p.animateTo(
      target,
      duration: AppMotion.resolve(context, AppMotion.xl, essential: true),
      curve: AppMotion.enter,
    );
  }

  @override
  void dispose() {
    _p.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final accent = widget.accent ?? scheme.primary;
    final pad = MediaQuery.paddingOf(context);
    final size = MediaQuery.sizeOf(context);
    final caption = widget.captions[_shown];
    return Material(
      color: scheme.surface,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onHorizontalDragUpdate: (d) {
          _p.value = (_p.value - (d.primaryDelta ?? 0) / (size.width * 0.8)).clamp(0.0, _max.toDouble());
        },
        onHorizontalDragEnd: (d) {
          final v = d.primaryVelocity ?? 0;
          final at = _p.value;
          final target = v < -300
              ? at.floor() + 1
              : v > 300
                  ? at.ceil() - 1
                  : at.round();
          _go(target);
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: pad.top + 10),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 8, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Semantics(
                      label: 'Step ${_shown + 1} of ${widget.captions.length}',
                      child: AnimatedBuilder(
                        animation: _p,
                        builder: (context, _) => Row(
                          children: [
                            for (var i = 0; i < widget.captions.length; i++)
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 2),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(3),
                                    child: SizedBox(
                                      height: 4,
                                      child: Stack(
                                        fit: StackFit.expand,
                                        children: [
                                          ColoredBox(color: scheme.onSurface.withAlpha(24)),
                                          FractionallySizedBox(
                                            alignment: Alignment.centerLeft,
                                            widthFactor: i == 0 ? 1 : (_p.value - (i - 1)).clamp(0.0, 1.0),
                                            child: ColoredBox(color: accent),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  AnimatedOpacity(
                    opacity: _last ? 0 : 1,
                    duration: AppMotion.md,
                    child: TextButton(
                      onPressed: _last ? null : widget.onDone,
                      child: Text(widget.skipLabel, style: TextStyle(color: scheme.onSurface, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: (size.height - pad.top - pad.bottom) * widget.sceneFraction,
              child: RepaintBoundary(
                child: AnimatedBuilder(
                  animation: _p,
                  builder: (context, _) => widget.scene(context, _p.value),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
                child: AnimatedSwitcher(
                  duration: AppMotion.resolve(context, AppMotion.md),
                  layoutBuilder: (current, previous) => Stack(
                    alignment: Alignment.topLeft,
                    children: [...previous, ?current],
                  ),
                  child: Column(
                    key: ValueKey('scene-caption-$_shown'),
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppReveal(
                        child: Text(
                          caption.title,
                          style: text.headlineSmall?.copyWith(fontWeight: FontWeight.w700, height: 1.12),
                        ),
                      ),
                      const SizedBox(height: 8),
                      AppReveal(
                        index: 1,
                        child: Text(caption.body, style: text.bodyLarge?.copyWith(color: scheme.onSurfaceVariant, height: 1.4)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(20, 0, 20, pad.bottom + 18),
              child: _FlowButton(
                label: _last ? widget.doneLabel : widget.nextLabel,
                onTap: () => _last ? widget.onDone() : _go(_index + 1),
                color: _last ? accent : scheme.onSurface,
                textColor: _last ? scheme.onPrimary : scheme.surface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
