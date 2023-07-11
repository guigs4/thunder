import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lemmy_api_client/v3.dart';

import 'package:thunder/core/enums/font_scale.dart';
import 'package:thunder/core/models/comment_view_tree.dart';
import 'package:thunder/account/bloc/account_bloc.dart' as account_bloc;
import 'package:thunder/thunder/bloc/thunder_bloc.dart';
import 'package:thunder/utils/date_time.dart';
import 'package:thunder/utils/numbers.dart';
import 'package:thunder/user/pages/user_page.dart';

import '../../core/auth/bloc/auth_bloc.dart';

class CommentHeader extends StatelessWidget {
  final CommentViewTree commentViewTree;
  final bool useDisplayNames;
  final bool isOwnComment;
  final bool isHidden;
  final int sinceCreated;

  const CommentHeader({
    super.key,
    required this.commentViewTree,
    required this.useDisplayNames,
    required this.sinceCreated,
    this.isOwnComment = false,
    this.isHidden = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ThunderState state = context.read<ThunderBloc>().state;

    bool collapseParentCommentOnGesture = state.collapseParentCommentOnGesture;

    VoteType? myVote = commentViewTree.comment?.myVote;
    bool? saved = commentViewTree.comment?.saved;
    bool? hasBeenEdited = commentViewTree.comment!.comment.updated != null ? true : false;
    //int score = commentViewTree.commentViewTree.comment?.counts.score ?? 0; maybe make combined scores an option?
    int upvotes = commentViewTree.comment?.counts.upvotes ?? 0;
    int downvotes = commentViewTree.comment?.counts.downvotes ?? 0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 8.0),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                GestureDetector(
                  onTap: () {
                    account_bloc.AccountBloc accountBloc =
                    context.read<account_bloc.AccountBloc>();
                    AuthBloc authBloc = context.read<AuthBloc>();
                    ThunderBloc thunderBloc = context.read<ThunderBloc>();

                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => MultiBlocProvider(
                          providers: [
                            BlocProvider.value(value: accountBloc),
                            BlocProvider.value(value: authBloc),
                            BlocProvider.value(value: thunderBloc),
                          ],
                          child: UserPage(userId: commentViewTree.comment!.creator.id),
                        ),
                      ),
                    );
                  },
                  child: Text(
                    commentViewTree.comment!.creator.displayName != null && useDisplayNames ? commentViewTree.comment!.creator.displayName! : commentViewTree.comment!.creator.name,
                    textScaleFactor: state.contentFontSizeScale.textScaleFactor,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: fetchUsernameColor(context, isOwnComment) ?? theme.colorScheme.onBackground,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: 8.0),
                Icon(
                  Icons.north_rounded,
                  size: 12.0 * state.contentFontSizeScale.textScaleFactor,
                  color: myVote == VoteType.up ? Colors.orange : theme.colorScheme.onBackground,
                ),
                const SizedBox(width: 2.0),
                Text(
                  formatNumberToK(upvotes),
                  textScaleFactor: state.contentFontSizeScale.textScaleFactor,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: myVote == VoteType.up ? Colors.orange : theme.colorScheme.onBackground,
                  ),
                ),
                const SizedBox(width: 10.0),
                Icon(
                  Icons.south_rounded,
                  size: 12.0 * state.contentFontSizeScale.textScaleFactor,
                  color: downvotes != 0 ? (myVote == VoteType.down ? Colors.blue : theme.colorScheme.onBackground) : Colors.transparent,
                ),
                const SizedBox(width: 2.0),
                Text(
                  formatNumberToK(downvotes),
                  textScaleFactor: state.contentFontSizeScale.textScaleFactor,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: downvotes != 0 ? (myVote == VoteType.down ? Colors.blue : theme.colorScheme.onBackground) : Colors.transparent,
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              AnimatedOpacity(
                opacity: (isHidden && (collapseParentCommentOnGesture || commentViewTree.replies.isNotEmpty == true))
                  ? 1
                  : 0,
                // Matches the collapse animation
                duration: const Duration(milliseconds: 130),
                child: Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: const BorderRadius.all(Radius.elliptical(5, 5)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.only(left: 5, right: 5),
                    child: Text(
                      '+${commentViewTree.replies.length}',
                      textScaleFactor: state.contentFontSizeScale.textScaleFactor,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8.0),
              Icon(
                saved == true ? Icons.star_rounded : null,
                color: saved == true ? Colors.purple : null,
                size: saved == true ? 18.0 : 0,
              ),
              SizedBox(
                width: hasBeenEdited ? 32.0 : 8,
                child: Icon(
                  hasBeenEdited ? Icons.create_rounded : null,
                  color: theme.colorScheme.onBackground.withOpacity(0.75),
                  size: 16.0,
                ),
              ),
              Container(
                decoration: sinceCreated < 15 ? BoxDecoration(
                    color: theme.primaryColorLight,
                    borderRadius: const BorderRadius.all(Radius.elliptical(5, 5))
                ) : null,
                child: sinceCreated < 15 ? Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 5.0),
                  child: Text(
                    'New!',
                    textScaleFactor: state.contentFontSizeScale.textScaleFactor,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.background,
                    )
                  ),
                ) : Text(
                  formatTimeToString(dateTime: hasBeenEdited ? commentViewTree.comment!.comment.updated!.toIso8601String() : commentViewTree.comment!.comment.published.toIso8601String() ),
                  textScaleFactor: state.contentFontSizeScale.textScaleFactor,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onBackground,
                  ),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  Color? fetchUsernameColor(BuildContext context, bool isOwnComment) {
    CommentView commentView = commentViewTree.comment!;
    final theme = Theme.of(context);

    if (isOwnComment) return theme.colorScheme.primary;
    if (commentView.creator.admin == true) return theme.colorScheme.tertiary;
    if (commentView.post.creatorId == commentView.comment.creatorId) return theme.colorScheme.secondary;

    return null;
  }
}
