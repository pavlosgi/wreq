{-# LANGUAGE OverloadedStrings #-}
{-# OPTIONS_GHC -fno-warn-missing-signatures #-}

module Main (main) where

import Data.Aeson (encode, object, toJSON)
import Data.Text.Encoding (decodeUtf8)
import Snap.Core
import Snap.Http.Server
import qualified Data.Map as Map
import Data.CaseInsensitive (original)

get = do
  req <- getRequest
  let step m k v = Map.insert (decodeUtf8 k) (decodeUtf8 (head v)) m
      params = Map.foldlWithKey' step Map.empty .
               rqQueryParams $ req
      wibble (k,v) = (decodeUtf8 (original k), decodeUtf8 v)
      hdrs = Map.fromList . map wibble . listHeaders . headers $ req
  let obj = object [
          ("args", toJSON params)
        , ("headers", toJSON hdrs)
        ]
  modifyResponse $ setContentType "application/json"
  writeLBS (encode obj)

main = do
  cfg <- commandLineConfig
       . setAccessLog ConfigNoLog
       . setErrorLog ConfigNoLog
       $ defaultConfig
  httpServe cfg $ route [
      ("/get", get)
    ]