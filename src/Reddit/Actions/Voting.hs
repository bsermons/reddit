-- | Contains actions for voting on posts and comments. There are functions
--   for upvoting ('upvotePost', 'upvoteComment'), downvoting ('downvotePost',
--   'downVoteComment') as well as removing votes that have already been cast
--   ('unvotePost', 'unvoteComment').
--
--   Please note that automated voting (i.e. by a bot, as opposed to being
--   specifically ordered to by a person) is strictly against the Reddit rules,
--   and is a very effective way of getting your bot shadowbanned.
module Reddit.Actions.Voting
  ( upvotePost
  , downvotePost
  , unvotePost
  , upvoteComment
  , downvoteComment
  , unvoteComment ) where

import Reddit.Routes.Run
import Reddit.Routes.Vote (VoteDirection(..))
import Reddit.Types
import Reddit.Types.Empty
import qualified Reddit.Routes as Route

import Control.Monad.IO.Class

vote :: (MonadIO m, Thing a) => VoteDirection -> a -> RedditT m ()
vote dir = nothing . runRoute . Route.vote dir

-- | Upvote a post.
upvotePost :: MonadIO m => PostID -> RedditT m ()
upvotePost = vote UpVote

-- | Downvote a post.
downvotePost :: MonadIO m => PostID -> RedditT m ()
downvotePost = vote DownVote

-- | Remove a vote from a post.
unvotePost :: MonadIO m => PostID -> RedditT m ()
unvotePost = vote RemoveVote

-- | Upvote a comment.
upvoteComment :: MonadIO m => CommentID -> RedditT m ()
upvoteComment = vote UpVote

-- | Downvote a comment.
downvoteComment :: MonadIO m => CommentID -> RedditT m ()
downvoteComment = vote RemoveVote

-- | Remove a previously-cast vote from a comment.
unvoteComment :: MonadIO m => CommentID -> RedditT m ()
unvoteComment = vote DownVote
