import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/habit.dart';
import '../../motion/motion.dart';
import '../../providers/habits_provider.dart';
import '../../theme/app_chrome.dart';
import '../../theme/app_colors.dart';

class AddHabitScreen extends ConsumerStatefulWidget {
  const AddHabitScreen({super.key});

  @override
  ConsumerState<AddHabitScreen> createState() => _AddHabitScreenState();
}

class _AddHabitScreenState extends ConsumerState<AddHabitScreen> {
  final _controller = TextEditingController();
  IconData _icon = habitIconChoices.first;
  ActionStatus _status = ActionStatus.idle;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _controller.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Give this habit a short name.');
      return;
    }
    setState(() {
      _error = null;
      _status = ActionStatus.loading;
    });
    await Future<void>.delayed(AppMotion.md);
    if (!mounted) return;
    ref.read(habitsProvider.notifier).add(name: name, icon: _icon);
    setState(() => _status = ActionStatus.done);
    await Future<void>.delayed(AppMotion.lg);
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    const colors = AppColors.light;
    final text = Theme.of(context).textTheme;

    return ChromeScope(
      top: colors.background,
      bottom: colors.background,
      child: Scaffold(
        backgroundColor: colors.background,
        appBar: AppBar(
          title: const Text('Add habit'),
          leading: AppPressable(
            onTap: () => context.pop(),
            semanticLabel: 'Close',
            child: const Padding(
              padding: EdgeInsets.all(12),
              child: Icon(Icons.close_rounded),
            ),
          ),
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: [
              AppReveal(
                child: Text(
                  'What will you do every day?',
                  style: text.headlineSmall,
                ),
              ),
              const SizedBox(height: 8),
              AppReveal(
                index: 1,
                child: Text(
                  'Keep the name short — you\'ll see it on your checklist.',
                  style: text.bodyMedium?.copyWith(color: colors.muted),
                ),
              ),
              const SizedBox(height: 24),
              AppReveal(
                index: 2,
                child: TextField(
                  controller: _controller,
                  textCapitalization: TextCapitalization.sentences,
                  textInputAction: TextInputAction.done,
                  onChanged: (_) {
                    if (_error != null) setState(() => _error = null);
                  },
                  onSubmitted: (_) => _save(),
                  decoration: InputDecoration(
                    hintText: 'e.g. Stretch for 5 minutes',
                    errorText: _error,
                  ),
                ),
              ),
              const SizedBox(height: 28),
              AppReveal(
                index: 3,
                child: Text('Pick an icon', style: text.titleMedium),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (var i = 0; i < habitIconChoices.length; i++)
                    AppReveal(
                      index: i,
                      delay: const Duration(milliseconds: 80),
                      child: _IconChip(
                        icon: habitIconChoices[i],
                        selected: _icon == habitIconChoices[i],
                        onTap: () => setState(() => _icon = habitIconChoices[i]),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 36),
              AppReveal(
                index: 4,
                child: AppStatusButton(
                  status: _status,
                  label: 'Save habit',
                  doneLabel: 'Added',
                  color: colors.primary,
                  doneColor: colors.success,
                  onPressed: _status == ActionStatus.idle ? _save : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IconChip extends StatelessWidget {
  const _IconChip({
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const colors = AppColors.light;

    return AppPressable(
      onTap: onTap,
      haptic: true,
      child: AnimatedContainer(
        duration: AppMotion.md,
        curve: AppMotion.pop,
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: selected ? colors.primary : colors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? colors.primary : colors.line,
            width: selected ? 2 : 1,
          ),
        ),
        child: Icon(
          icon,
          color: selected ? colors.surface : colors.ink,
        ),
      ),
    );
  }
}
