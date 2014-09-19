module Reddit.API.Login
  ( login ) where

import Reddit.API.Types.Error
import Reddit.API.Types.Reddit

import Control.Concurrent (threadDelay)
import Control.Exception (try)
import Control.Monad.IO.Class (MonadIO, liftIO)
import Control.Monad.Trans.Either
import Control.Monad.Trans.State
import Data.Bifunctor (first)
import Data.Text (Text)
import Network.API.Builder
import Network.HTTP.Conduit

loginRoute :: Text -> Text -> Route
loginRoute user pass = Route [ "api", "login" ]
                             [ "rem" =. True
                             , "user" =. user
                             , "passwd" =. pass ]
                             "POST"

getLoginDetails :: MonadIO m => Text -> Text -> RedditT m LoginDetails
getLoginDetails user pass = do
  (limiting, _) <- RedditT $ liftState get
  if limiting
    then getLoginDetailsWithLimiting user pass
    else getLoginDetails' user pass

getLoginDetails' :: MonadIO m => Text -> Text -> RedditT m LoginDetails
getLoginDetails' user pass = do
  b <- RedditT $ liftBuilder get
  req <- RedditT $ hoistEither $ case routeRequest b (loginRoute user pass) of
    Just url -> Right url
    Nothing -> Left InvalidURLError
  resp <- liftIO $ try $ withManager $ httpLbs req
  resp' <- RedditT $ hoistEither $ first HTTPError resp
  let cj = responseCookieJar resp'
  mh <- RedditT $ hoistEither $ decode $ responseBody resp'
  return $ LoginDetails mh cj

getLoginDetailsWithLimiting :: MonadIO m => Text -> Text -> RedditT m LoginDetails
getLoginDetailsWithLimiting user pass = do
  b <- RedditT $ liftBuilder get
  req <- RedditT $ hoistEither $ case routeRequest b (loginRoute user pass) of
    Just url -> Right url
    Nothing -> Left InvalidURLError
  resp <- liftIO $ try $ withManager $ httpLbs req
  resp' <- RedditT $ hoistEither $ first HTTPError resp
  let cj = responseCookieJar resp'
  mh <- nest $ RedditT $ hoistEither $ decode $ responseBody resp'
  case mh of
    Left (APIError (RateLimitError wait _)) -> do
      liftIO $ threadDelay $ ((fromIntegral wait) + 5) * 1000000
      getLoginDetailsWithLimiting user pass
    Left x -> RedditT $ hoistEither $ Left x
    Right modhash -> return $ LoginDetails modhash cj

login :: MonadIO m => Text -> Text -> RedditT m LoginDetails
login user pass = do
  RedditT $ baseURL loginBaseURL
  d <- getLoginDetails user pass
  RedditT $ baseURL mainBaseURL
  return d
