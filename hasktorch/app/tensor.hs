module Main  where

import qualified Torch as T

main :: IO ()
main = do
  let x = T.asTensor [1::Double,2,3]
  print x
