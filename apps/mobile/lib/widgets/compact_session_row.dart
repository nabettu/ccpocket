import 'package:flutter/material.dart';

import '../models/messages.dart';
import '../theme/app_theme.dart';
import '../utils/command_parser.dart';
import 'adaptive_context_menu.dart';
import 'session_card.dart';
import 'session_visual_status.dart';

/// Single-line session entry for the multi-pane sidebar.
///
/// The full [RunningSessionCard] / [RecentSessionCard] stay on the phone home
/// screen; in the sidebar the detail pane is already visible, so each session
/// only needs a status marker and a title.
class CompactSessionRow extends StatefulWidget {
  final Widget leading;
  final String title;
  final String? trailingLabel;

  /// Shown while the row is hovered or selected (e.g. a stop button).
  final Widget? hoverAction;
  final bool isSelected;
  final bool emphasize;
  final bool isPinned;
  final bool isProcessing;
  final VoidCallback? onTap;
  final ValueChanged<Offset?>? onShowActions;

  const CompactSessionRow({
    super.key,
    required this.leading,
    required this.title,
    this.trailingLabel,
    this.hoverAction,
    this.isSelected = false,
    this.emphasize = false,
    this.isPinned = false,
    this.isProcessing = false,
    this.onTap,
    this.onShowActions,
  });

  @override
  State<CompactSessionRow> createState() => _CompactSessionRowState();
}

class _CompactSessionRowState extends State<CompactSessionRow> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final appColors = theme.extension<AppColors>()!;
    final isSelected = widget.isSelected;
    final isProcessing = widget.isProcessing;
    final trailingLabel = widget.trailingLabel;
    final showHoverAction =
        widget.hoverAction != null && (_hovering || isSelected);
    final row = Material(
      color: isSelected
          ? colorScheme.surfaceContainerHighest
          : Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: isProcessing ? null : widget.onTap,
        onHover: (hovering) => setState(() => _hovering = hovering),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
          child: Row(
            children: [
              SizedBox(
                width: 16,
                child: Center(
                  child: isProcessing
                      ? const SizedBox(
                          width: 10,
                          height: 10,
                          child: CircularProgressIndicator(strokeWidth: 1.5),
                        )
                      : widget.leading,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: widget.emphasize ? FontWeight.w700 : null,
                    color: isProcessing ? appColors.subtleText : null,
                  ),
                ),
              ),
              if (widget.isPinned) ...[
                const SizedBox(width: 6),
                Icon(Icons.push_pin, size: 12, color: appColors.subtleText),
              ],
              if (showHoverAction) ...[
                const SizedBox(width: 6),
                widget.hoverAction!,
              ] else if (trailingLabel != null) ...[
                const SizedBox(width: 8),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 110),
                  child: Text(
                    trailingLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: appColors.subtleText,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
    final onShowActions = widget.onShowActions;
    if (isProcessing || onShowActions == null) return row;
    return AdaptiveContextMenuRegion(onOpen: onShowActions, child: row);
  }
}

/// Status marker: filled for running sessions, hollow for recent ones.
class CompactSessionStatusDot extends StatelessWidget {
  final Color color;
  final bool filled;

  const CompactSessionStatusDot({
    super.key,
    required this.color,
    this.filled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: filled ? color : null,
        border: filled ? null : Border.all(color: color, width: 1.4),
      ),
    );
  }
}

class CompactRunningSessionRow extends StatelessWidget {
  final SessionInfo session;
  final String? projectNameOverride;
  final bool isSelected;
  final bool isUnseen;
  final bool isPinned;
  final VoidCallback onTap;
  final VoidCallback? onStop;
  final ValueChanged<Offset?>? onShowActions;

  const CompactRunningSessionRow({
    super.key,
    required this.session,
    this.projectNameOverride,
    this.isSelected = false,
    this.isUnseen = false,
    this.isPinned = false,
    required this.onTap,
    this.onStop,
    this.onShowActions,
  });

  @override
  Widget build(BuildContext context) {
    final visualStatus = sessionVisualStatusFor(
      rawStatus: session.status,
      permissionMode: session.effectivePermissionMode,
      planMode: session.resolvedPlanMode,
      pendingPermission: session.pendingPermission,
    );
    final projectName = projectNameOverride ?? session.projectName;
    final name = session.name?.trim();
    final message = formatCommandText(
      session.lastMessage.replaceAll(RegExp(r'\s+'), ' ').trim(),
    );
    final title = name != null && name.isNotEmpty
        ? name
        : message.isNotEmpty
        ? message
        : projectName;
    return CompactSessionRow(
      leading: CompactSessionStatusDot(
        color: sessionStatusColor(
          context,
          visualStatus.primary,
          isUnseen: isUnseen,
        ),
      ),
      title: title,
      trailingLabel: projectName,
      hoverAction: onStop == null
          ? null
          : RunningSessionStopButton(onPressed: onStop!),
      isSelected: isSelected,
      emphasize:
          isUnseen || visualStatus.primary == SessionPrimaryStatus.needsYou,
      isPinned: isPinned,
      onTap: onTap,
      onShowActions: onShowActions,
    );
  }
}

class CompactRecentSessionRow extends StatelessWidget {
  final RecentSession session;
  final SessionDisplayMode displayMode;
  final String? draftText;
  final bool isPinned;
  final bool isProcessing;
  final VoidCallback onTap;
  final ValueChanged<Offset?>? onShowActions;

  const CompactRecentSessionRow({
    super.key,
    required this.session,
    required this.displayMode,
    this.draftText,
    this.isPinned = false,
    this.isProcessing = false,
    required this.onTap,
    this.onShowActions,
  });

  @override
  Widget build(BuildContext context) {
    final appColors = Theme.of(context).extension<AppColors>()!;
    final name = session.name?.trim();
    final hasDraft = draftText != null && draftText!.trim().isNotEmpty;
    return CompactSessionRow(
      leading: hasDraft
          ? Icon(Icons.edit_note, size: 14, color: appColors.subtleText)
          : CompactSessionStatusDot(color: appColors.subtleText, filled: false),
      title: name != null && name.isNotEmpty
          ? name
          : recentSessionDisplayText(session, displayMode),
      isPinned: isPinned,
      isProcessing: isProcessing,
      onTap: onTap,
      onShowActions: onShowActions,
    );
  }
}
