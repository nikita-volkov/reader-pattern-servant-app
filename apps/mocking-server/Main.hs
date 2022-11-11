module Main (main) where

import ReaderProtoBase.Prelude
import ReaderProtoMockDb qualified as MockDb
import ReaderProtoService qualified as Service

main :: IO ()
main = do
  db <- mockingServiceDb <$> MockDb.start
  Service.startLoggingServer 7070 stderr 4 db timer

mockingServiceDb :: MockDb.MockDb -> Service.Db
mockingServiceDb db =
  Service.Db save getById getByTag
  where
    adaptServiceMessage msg =
      MockDb.Message msg.content (fmap (.value) msg.tags) msg.time
    adaptServiceMessageId msgId = msgId.value
    adaptServiceTag tag = tag.value
    adaptDbMessage msg =
      Service.Message msg.content (fmap Service.Tag msg.tags) msg.time
    adaptDbMessageId = Service.MessageId
    save msg =
      Right . adaptDbMessageId <$> MockDb.insert db (adaptServiceMessage msg)
    getById id =
      Right . fmap adaptDbMessage <$> MockDb.lookup db (adaptServiceMessageId id)
    getByTag tag =
      Right . fmap adaptDbMessage <$> MockDb.lookupByTag db (adaptServiceTag tag)

timer :: Service.Timer
timer =
  Service.Timer getCurrentTime