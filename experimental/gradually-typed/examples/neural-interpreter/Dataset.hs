{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE DerivingStrategies #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE RecordWildCards #-}

module Dataset where

import Control.Monad (guard)
import Control.Monad.State (MonadIO (liftIO), evalStateT)
import qualified Data.List as List
import Data.Set (Set)
import qualified Data.Set as Set
import Data.Text (Text)
import GHC.Generics (Generic)
import qualified Gen
import qualified Hedgehog.Internal.Gen as Gen
import Hedgehog.Internal.Seed (Seed)
import qualified Hedgehog.Internal.Seed as Seed
import qualified STLC
import qualified Tokenizers
import Torch.GraduallyTyped

type Tokenizer = String -> IO [Int]
type Detokenizer = [Int] -> IO String

data STLCData = STLCData
  { name :: Text,
    seeds :: Set Seed,
    maxInputLength :: Int,
    maxTargetLength :: Int,
    tokenize :: Tokenizer,
    detokenize :: Detokenizer
  }

data STLCExample a = STLCExample
  { exTy :: !STLC.Ty,
    exInputExp :: !(STLC.Exp a),
    exInputPPrint :: !String,
    exInputIds :: ![Int],
    exDecodedInputIds :: !String,
    exTargetExp :: !(STLC.Exp a),
    exTargetPPrint :: !String,
    exTargetIds :: ![Int],
    exDecodedTargetIds :: !String
  }
  deriving stock (Show, Eq, Ord, Generic)

mkExample ::
  Tokenizer ->
  Detokenizer ->
  Int ->
  Int ->
  Seed.Seed ->
  IO (STLCExample Int)
mkExample tokenize detokenize maxInputLength maxTargetLength seed = flip evalStateT seed . Gen.sample' $ do
  exTy <- Gen.genTy
  exInputExp <- Gen.generalize $ Gen.genWellTypedExp exTy
  let exInputPPrint = STLC.pprint exInputExp
      exTargetExp = STLC.nf exInputExp
      exTargetPPrint = STLC.pprint exTargetExp
  exInputIds <- liftIO . tokenize $ exInputPPrint <> "</s>"
  guard (List.length exInputIds <= maxInputLength)
  exTargetIds <- liftIO . tokenize $ exTargetPPrint <> "</s>"
  guard (List.length exTargetIds <= maxTargetLength)
  exDecodedInputIds <- liftIO $ detokenize exInputIds
  exDecodedTargetIds <- liftIO $ detokenize exTargetIds
  -- liftIO . putStrLn $ exInputPPrint <> " >>> " <> exTargetPPrint
  pure STLCExample {..}

instance Dataset IO STLCData Seed (STLCExample Int) where
  getItem STLCData {..} seed = do
    guard $ Set.member seed seeds
    mkExample tokenize detokenize maxInputLength maxTargetLength seed
  keys STLCData {..} = seeds
