{-# LANGUAGE EmptyDataDecls #-}
{-# LANGUAGE ExistentialQuantification #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE ForeignFunctionInterface #-}
{-# LANGUAGE GADTs #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE TypeSynonymInstances #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE UndecidableInstances #-}



-----------------------------------------------------------------------------
-- |
-- Module      : ATen.Cast from FFICXX.Runtime.Cast
-- Copyright   : (c) 2011-2017 Ian-Woo Kim
--
-- License     : BSD3
-- Maintainer  : Junji Hashimoto<junji.hashimoto@gmail.com>
-- Stability   : experimental
-- Portability : GHC
--
-----------------------------------------------------------------------------

module Torch.Internal.Cast where

import Control.Monad         ((>=>))
import Data.ByteString.Char8 (ByteString,packCString, useAsCString)
import Data.String
import Data.Word
import Data.Int
import Foreign.C
import Foreign.C.String
import Foreign.ForeignPtr
import Foreign.Marshal.Array
import Foreign.Ptr
import Foreign.Storable
import Torch.Internal.Class
import Torch.Internal.GC

instance Castable a a where
  cast x f = f x
  {-# INLINE cast #-}
  uncast x f = f x
  {-# INLINE uncast #-}

instance Castable Bool CBool where
  cast x f = f (if x then 1 else 0)
  {-# INLINE cast #-}
  uncast x f = f (x /= 0)
  {-# INLINE uncast #-}

instance Castable Int CInt where
  cast x f = f (fromIntegral x)
  {-# INLINE cast #-}
  uncast x f = f (fromIntegral x)
  {-# INLINE uncast#-}

instance Castable Int Int64 where
  cast x f = f (fromIntegral x)
  {-# INLINE cast #-}
  -- TODO: Int64 might have a wider range than Int
  uncast x f = f (fromIntegral x)
  {-# INLINE uncast #-}

instance Castable Int16 CShort where
  cast x f = f (fromIntegral x)
  {-# INLINE cast #-}
  uncast x f = f (fromIntegral x)
  {-# INLINE uncast #-}

instance Castable Int8 CChar where
  cast x f = f (fromIntegral x)
  {-# INLINE cast #-}
  uncast x f = f (fromIntegral x)
  {-# INLINE uncast #-}

instance Castable Word CUInt where
  cast x f = f (fromIntegral x)
  {-# INLINE cast #-}
  uncast x f = f (fromIntegral x)
  {-# INLINE uncast #-}

instance Castable Word8 CChar where
  cast x f = f (fromIntegral x)
  {-# INLINE cast #-}
  uncast x f = f (fromIntegral x)
  {-# INLINE uncast #-}

instance Castable Double CDouble where
  cast x f = f (realToFrac x)
  {-# INLINE cast #-}
  uncast x f = f (realToFrac x)
  {-# INLINE uncast #-}

instance Castable [Double] (Ptr CDouble) where
  cast xs f = newArray (map realToFrac xs) >>= f
  {-# INLINE cast #-}
  uncast xs f = undefined
  {-# INLINE uncast #-}

instance Castable [Int] (Ptr CInt) where
  cast xs f = newArray (map fromIntegral xs) >>= f
  {-# INLINE cast #-}
  uncast xs f = undefined
  {-# INLINE uncast #-}

instance Castable ByteString CString where
  cast x f = useAsCString x f
  {-# INLINE cast #-}
  uncast x f = packCString x >>= f
  {-# INLINE uncast #-}

instance Castable [ByteString] (Ptr CString) where
  cast xs f = do ys <- mapM (\x -> useAsCString x return) xs
                 withArray ys $ \cptr -> f cptr
  {-# INLINE cast #-}
  uncast xs f = undefined
  {-# INLINE uncast #-}

instance Castable String CString where
  cast x f = withCString x f
  {-# INLINE cast #-}
  uncast x f = peekCString x >>= f
  {-# INLINE uncast #-}

instance (Castable a a') => Castable (Maybe a) (Maybe a') where
  cast Nothing f = f Nothing
  cast (Just v) f = cast v (\v -> f (Just v))
  {-# INLINE cast #-}
  uncast Nothing f = f Nothing
  uncast (Just v) f = uncast v (\v -> f (Just v)) 
  {-# INLINE uncast #-}

instance (CppObject a) => Castable (ForeignPtr a) (Ptr a) where
  cast x f = withForeignPtr x f
  {-# INLINE cast #-}
  uncast x f = fromPtr x >>= f
  {-# INLINE uncast #-}

--------------------------------------------------------------------------------
-- Tuples of Castable
--------------------------------------------------------------------------------

instance (Castable a a', Castable b b') => Castable (a,b) (a',b') where
  cast (t0,t1) f = do
    t0' <- cast t0 return
    t1' <- cast t1 return
    f (t0',t1')
  uncast (t0,t1) f = do
    t0' <- uncast t0 return
    t1' <- uncast t1 return
    f (t0',t1')
  {-# INLINE cast #-}
  {-# INLINE uncast #-}

instance (Castable a a', Castable b b', Castable c c') => Castable (a,b,c) (a',b',c') where
  cast (t0,t1,t2) f = do
    t0' <- cast t0 return
    t1' <- cast t1 return
    t2' <- cast t2 return
    f (t0',t1',t2')
  uncast (t0,t1,t2) f = do
    t0' <- uncast t0 return
    t1' <- uncast t1 return
    t2' <- uncast t2 return
    f (t0',t1',t2')
  {-# INLINE cast #-}
  {-# INLINE uncast #-}

instance (Castable a a', Castable b b', Castable c c', Castable d d') => Castable (a,b,c,d) (a',b',c',d') where
  cast (t0,t1,t2,t3) f = do
    t0' <- cast t0 return
    t1' <- cast t1 return
    t2' <- cast t2 return
    t3' <- cast t3 return
    f (t0',t1',t2',t3')
  uncast (t0,t1,t2,t3) f = do
    t0' <- uncast t0 return
    t1' <- uncast t1 return
    t2' <- uncast t2 return
    t3' <- uncast t3 return
    f (t0',t1',t2',t3')
  {-# INLINE cast #-}
  {-# INLINE uncast #-}

instance (Castable a a', Castable b b', Castable c c', Castable d d', Castable e e') => Castable (a,b,c,d,e) (a',b',c',d',e') where
  cast (t0,t1,t2,t3,t4) f = do
    t0' <- cast t0 return
    t1' <- cast t1 return
    t2' <- cast t2 return
    t3' <- cast t3 return
    t4' <- cast t4 return
    f (t0',t1',t2',t3',t4')
  uncast (t0,t1,t2,t3,t4) f = do
    t0' <- uncast t0 return
    t1' <- uncast t1 return
    t2' <- uncast t2 return
    t3' <- uncast t3 return
    t4' <- uncast t4 return
    f (t0',t1',t2',t3',t4')
  {-# INLINE cast #-}
  {-# INLINE uncast #-}

instance (Castable a a', Castable b b', Castable c c',
          Castable d d', Castable e e', Castable f f') => Castable (a,b,c,d,e,f) (a',b',c',d',e',f') where
  cast (t0,t1,t2,t3,t4,t5) f = do
    t0' <- cast t0 return
    t1' <- cast t1 return
    t2' <- cast t2 return
    t3' <- cast t3 return
    t4' <- cast t4 return
    t5' <- cast t5 return
    f (t0',t1',t2',t3',t4',t5')
  uncast (t0,t1,t2,t3,t4,t5) f = do
    t0' <- uncast t0 return
    t1' <- uncast t1 return
    t2' <- uncast t2 return
    t3' <- uncast t3 return
    t4' <- uncast t4 return
    t5' <- uncast t5 return
    f (t0',t1',t2',t3',t4',t5')
  {-# INLINE cast #-}
  {-# INLINE uncast #-}

--------------------------------------------------------------------------------
-- These casts convert the value from C++ Tuple(CppTuple) to Haskell Tuple.
-- Reverse side is not supported.
--------------------------------------------------------------------------------

instance (CppTuple2 c, Castable a (A c), Castable b (B c)) => Castable (a,b) c where
  cast (t0',t1') f = do
    cast t0' $ \t0 -> 
      cast t1' $ \t1 -> 
        makeTuple2 (t0,t1) >>= f
  uncast t f = do
    t0 <- get0 t
    t1 <- get1 t
    t0' <- uncast t0 return
    t1' <- uncast t1 return
    f (t0',t1')
  {-# INLINE cast #-}
  {-# INLINE uncast #-}

instance (CppTuple3 d, Castable a (A d), Castable b (B d), Castable c (C d)) => Castable (a,b,c) d where
  cast _ _ = error "Attempted to cast a 3-tuple from Haskell to C++, this is not supported."
  uncast t f = do
    t0 <- get0 t
    t1 <- get1 t
    t2 <- get2 t
    t0' <- uncast t0 return
    t1' <- uncast t1 return
    t2' <- uncast t2 return
    f (t0',t1',t2')
  {-# INLINE cast #-}
  {-# INLINE uncast #-}

instance (CppTuple4 e, Castable a (A e), Castable b (B e), Castable c (C e), Castable d (D e)) => Castable (a,b,c,d) e where
  cast _ _ = error "Attempted to cast a 4-tuple from Haskell to C++, this is not supported."
  uncast t f = do
    t0 <- get0 t
    t1 <- get1 t
    t2 <- get2 t
    t3 <- get3 t
    t0' <- uncast t0 return
    t1' <- uncast t1 return
    t2' <- uncast t2 return
    t3' <- uncast t3 return
    f (t0',t1',t2',t3')
  {-# INLINE cast #-}
  {-# INLINE uncast #-}

instance (CppTuple5 f, Castable a (A f), Castable b (B f), Castable c (C f), Castable d (D f), Castable e (E f)) => Castable (a,b,c,d,e) f where
  cast _ _ = error "Attempted to cast a 5-tuple from Haskell to C++, this is not supported."
  uncast t f = do
    t0 <- get0 t
    t1 <- get1 t
    t2 <- get2 t
    t3 <- get3 t
    t4 <- get4 t
    t0' <- uncast t0 return
    t1' <- uncast t1 return
    t2' <- uncast t2 return
    t3' <- uncast t3 return
    t4' <- uncast t4 return
    f (t0',t1',t2',t3',t4')
  {-# INLINE cast #-}
  {-# INLINE uncast #-}

instance (CppTuple6 g,
          Castable a (A g), Castable b (B g), Castable c (C g),
          Castable d (D g), Castable e (E g), Castable f (F g)) => Castable (a,b,c,d,e,f) g where
  cast _ _ = error "Attempted to cast a 6-tuple from Haskell to C++, this is not supported."
  uncast t f = do
    t0 <- get0 t
    t1 <- get1 t
    t2 <- get2 t
    t3 <- get3 t
    t4 <- get4 t
    t5 <- get5 t
    t0' <- uncast t0 return
    t1' <- uncast t1 return
    t2' <- uncast t2 return
    t3' <- uncast t3 return
    t4' <- uncast t4 return
    t5' <- uncast t5 return
    f (t0',t1',t2',t3',t4',t5')
  {-# INLINE cast #-}
  {-# INLINE uncast #-}

--------------------------------------------------------------------------------
-- Cast functions for various numbers of arguments without retryWithGC
--------------------------------------------------------------------------------

cast0 :: (Castable a ca) => (IO ca) -> IO a
cast0 f = (f) >>= \ca -> uncast ca return

cast1 :: (Castable a ca, Castable y cy)
       => (ca -> IO cy) -> a -> IO y
cast1 f a = cast a $ \ca -> (f ca) >>= \cy -> uncast cy return

cast2 :: (Castable a ca, Castable x1 cx1, Castable y cy)
       => (ca -> cx1 -> IO cy) -> a -> x1 -> IO y
cast2 f a x1 = cast a $ \ca ->
                  cast x1 $ \cx1 ->
                    (f ca cx1) >>= \cy -> uncast cy return

cast3 :: (Castable a ca, Castable x1 cx1, Castable x2 cx2, Castable y cy)
       => (ca -> cx1 -> cx2 -> IO cy) -> a -> x1 -> x2-> IO y
cast3 f a x1 x2 = cast a $ \ca ->
                     cast x1 $ \cx1 ->
                       cast x2 $ \cx2 ->
                         (f ca cx1 cx2) >>= \cy -> uncast cy return

cast4 :: (Castable a ca, Castable x1 cx1, Castable x2 cx2, Castable x3 cx3, Castable y cy)
       => (ca -> cx1 -> cx2 -> cx3 -> IO cy) -> a -> x1 -> x2 -> x3 -> IO y
cast4 f a x1 x2 x3 = cast a $ \ca ->
                        cast x1 $ \cx1 ->
                          cast x2 $ \cx2 ->
                            cast x3 $ \cx3 ->
                              (f ca cx1 cx2 cx3) >>= \cy -> uncast cy return

cast5 :: (Castable a ca, Castable x1 cx1, Castable x2 cx2, Castable x3 cx3, Castable x4 cx4, Castable y cy)
       => (ca -> cx1 -> cx2 -> cx3 -> cx4 -> IO cy) -> a -> x1 -> x2 -> x3 -> x4 -> IO y
cast5 f a x1 x2 x3 x4 =
  cast a $ \ca ->
    cast x1 $ \cx1 ->
      cast x2 $ \cx2 ->
        cast x3 $ \cx3 ->
          cast x4 $ \cx4 ->
            (f ca cx1 cx2 cx3 cx4) >>= \cy -> uncast cy return


cast6 :: (Castable a ca, Castable x1 cx1, Castable x2 cx2, Castable x3 cx3, Castable x4 cx4,
           Castable x5 cx5, Castable y cy)
       => (ca -> cx1 -> cx2 -> cx3 -> cx4 -> cx5 -> IO cy) -> a -> x1 -> x2 -> x3 -> x4 -> x5 -> IO y
cast6 f a x1 x2 x3 x4 x5 =
  cast a $ \ca ->
    cast x1 $ \cx1 ->
      cast x2 $ \cx2 ->
        cast x3 $ \cx3 ->
          cast x4 $ \cx4 ->
            cast x5 $ \cx5 ->
              (f ca cx1 cx2 cx3 cx4 cx5) >>= \cy -> uncast cy return

cast7 :: (Castable a ca, Castable x1 cx1, Castable x2 cx2, Castable x3 cx3, Castable x4 cx4,
           Castable x5 cx5, Castable x6 cx6, Castable y cy)
       => (ca -> cx1 -> cx2 -> cx3 -> cx4 -> cx5 -> cx6 -> IO cy)
          -> a -> x1 -> x2 -> x3 -> x4 -> x5 -> x6 -> IO y
cast7 f a x1 x2 x3 x4 x5 x6 =
  cast a $ \ca ->
    cast x1 $ \cx1 ->
      cast x2 $ \cx2 ->
        cast x3 $ \cx3 ->
          cast x4 $ \cx4 ->
            cast x5 $ \cx5 ->
              cast x6 $ \cx6 ->
                (f ca cx1 cx2 cx3 cx4 cx5 cx6) >>= \cy -> uncast cy return

cast8 :: (Castable a ca, Castable x1 cx1, Castable x2 cx2, Castable x3 cx3, Castable x4 cx4,
           Castable x5 cx5, Castable x6 cx6, Castable x7 cx7, Castable y cy)
       => (ca -> cx1 -> cx2 -> cx3 -> cx4 -> cx5 -> cx6 -> cx7 -> IO cy)
          -> a -> x1 -> x2 -> x3 -> x4 -> x5 -> x6 -> x7 -> IO y
cast8 f a x1 x2 x3 x4 x5 x6 x7 =
  cast a $ \ca ->
    cast x1 $ \cx1 ->
      cast x2 $ \cx2 ->
        cast x3 $ \cx3 ->
          cast x4 $ \cx4 ->
            cast x5 $ \cx5 ->
              cast x6 $ \cx6 ->
                cast x7 $ \cx7 ->
                  (f ca cx1 cx2 cx3 cx4 cx5 cx6 cx7) >>= \cy -> uncast cy return


cast9 :: (Castable a ca, Castable x1 cx1, Castable x2 cx2, Castable x3 cx3, Castable x4 cx4,
           Castable x5 cx5, Castable x6 cx6, Castable x7 cx7, Castable x8 cx8, Castable y cy)
       => (ca -> cx1 -> cx2 -> cx3 -> cx4 -> cx5 -> cx6 -> cx7 -> cx8 -> IO cy)
          -> a -> x1 -> x2 -> x3 -> x4 -> x5 -> x6 -> x7 -> x8 -> IO y
cast9 f a x1 x2 x3 x4 x5 x6 x7 x8 =
  cast a $ \ca ->
    cast x1 $ \cx1 ->
      cast x2 $ \cx2 ->
        cast x3 $ \cx3 ->
          cast x4 $ \cx4 ->
            cast x5 $ \cx5 ->
              cast x6 $ \cx6 ->
                cast x7 $ \cx7 ->
                  cast x8 $ \cx8 ->
                    (f ca cx1 cx2 cx3 cx4 cx5 cx6 cx7 cx8) >>= \cy -> uncast cy return

cast10 :: (Castable a ca, Castable x1 cx1, Castable x2 cx2, Castable x3 cx3, Castable x4 cx4,
           Castable x5 cx5, Castable x6 cx6, Castable x7 cx7, Castable x8 cx8, Castable x9 cx9,
           Castable y cy)
       => (ca -> cx1 -> cx2 -> cx3 -> cx4 -> cx5 -> cx6 -> cx7 -> cx8 -> cx9 -> IO cy)
          -> a -> x1 -> x2 -> x3 -> x4 -> x5 -> x6 -> x7 -> x8 -> x9 -> IO y
cast10 f a x1 x2 x3 x4 x5 x6 x7 x8 x9 =
  cast a $ \ca ->
    cast x1 $ \cx1 ->
      cast x2 $ \cx2 ->
        cast x3 $ \cx3 ->
          cast x4 $ \cx4 ->
            cast x5 $ \cx5 ->
              cast x6 $ \cx6 ->
                cast x7 $ \cx7 ->
                  cast x8 $ \cx8 ->
                    cast x9 $ \cx9 ->
                      (f ca cx1 cx2 cx3 cx4 cx5 cx6 cx7 cx8 cx9) >>= \cy -> uncast cy return

cast11 :: (Castable a ca, Castable x1 cx1, Castable x2 cx2, Castable x3 cx3, Castable x4 cx4,
            Castable x5 cx5, Castable x6 cx6, Castable x7 cx7, Castable x8 cx8, Castable x9 cx9,
            Castable x10 cx10, Castable y cy)
       => (ca -> cx1 -> cx2 -> cx3 -> cx4 -> cx5 -> cx6 -> cx7 -> cx8 -> cx9 -> cx10 -> IO cy)
          -> a -> x1 -> x2 -> x3 -> x4 -> x5 -> x6 -> x7 -> x8 -> x9 -> x10 -> IO y
cast11 f a x1 x2 x3 x4 x5 x6 x7 x8 x9 x10 =
  cast a $ \ca ->
    cast x1 $ \cx1 ->
      cast x2 $ \cx2 ->
        cast x3 $ \cx3 ->
          cast x4 $ \cx4 ->
            cast x5 $ \cx5 ->
              cast x6 $ \cx6 ->
                cast x7 $ \cx7 ->
                  cast x8 $ \cx8 ->
                    cast x9 $ \cx9 ->
                      cast x10 $ \cx10 ->
                        (f ca cx1 cx2 cx3 cx4 cx5 cx6 cx7 cx8 cx9 cx10) >>= \cy -> uncast cy return

cast12 :: (Castable a ca, Castable x1 cx1, Castable x2 cx2, Castable x3 cx3, Castable x4 cx4,
            Castable x5 cx5, Castable x6 cx6, Castable x7 cx7, Castable x8 cx8, Castable x9 cx9,
            Castable x10 cx10, Castable x11 cx11, Castable y cy)
       => (ca -> cx1 -> cx2 -> cx3 -> cx4 -> cx5 -> cx6 -> cx7 -> cx8 -> cx9 -> cx10 -> cx11 -> IO cy)
          -> a -> x1 -> x2 -> x3 -> x4 -> x5 -> x6 -> x7 -> x8 -> x9 -> x10 -> x11 -> IO y
cast12 f a x1 x2 x3 x4 x5 x6 x7 x8 x9 x10 x11 =
  cast a $ \ca ->
    cast x1 $ \cx1 ->
      cast x2 $ \cx2 ->
        cast x3 $ \cx3 ->
          cast x4 $ \cx4 ->
            cast x5 $ \cx5 ->
              cast x6 $ \cx6 ->
                cast x7 $ \cx7 ->
                  cast x8 $ \cx8 ->
                    cast x9 $ \cx9 ->
                      cast x10 $ \cx10 ->
                        cast x11 $ \cx11 ->
                         (f ca cx1 cx2 cx3 cx4 cx5 cx6 cx7 cx8 cx9 cx10 cx11) >>= \cy -> uncast cy return


cast13 :: (Castable a ca, Castable x1 cx1, Castable x2 cx2, Castable x3 cx3, Castable x4 cx4,
            Castable x5 cx5, Castable x6 cx6, Castable x7 cx7, Castable x8 cx8, Castable x9 cx9,
            Castable x10 cx10, Castable x11 cx11, Castable x12 cx12, Castable y cy)
       => (ca -> cx1 -> cx2 -> cx3 -> cx4 -> cx5 -> cx6 -> cx7 -> cx8 -> cx9 -> cx10 -> cx11 -> cx12 -> IO cy)
          -> a -> x1 -> x2 -> x3 -> x4 -> x5 -> x6 -> x7 -> x8 -> x9 -> x10 -> x11 -> x12 -> IO y
cast13 f a x1 x2 x3 x4 x5 x6 x7 x8 x9 x10 x11 x12 =
  cast a $ \ca ->
    cast x1 $ \cx1 ->
      cast x2 $ \cx2 ->
        cast x3 $ \cx3 ->
          cast x4 $ \cx4 ->
            cast x5 $ \cx5 ->
              cast x6 $ \cx6 ->
                cast x7 $ \cx7 ->
                  cast x8 $ \cx8 ->
                    cast x9 $ \cx9 ->
                      cast x10 $ \cx10 ->
                        cast x11 $ \cx11 ->
                          cast x12 $ \cx12 ->
                            (f ca cx1 cx2 cx3 cx4 cx5 cx6 cx7 cx8 cx9 cx10 cx11 cx12) >>= \cy -> uncast cy return

cast14 :: (Castable a ca, Castable x1 cx1, Castable x2 cx2, Castable x3 cx3, Castable x4 cx4,
            Castable x5 cx5, Castable x6 cx6, Castable x7 cx7, Castable x8 cx8, Castable x9 cx9,
            Castable x10 cx10, Castable x11 cx11, Castable x12 cx12, Castable x13 cx13, Castable y cy)
       => (ca -> cx1 -> cx2 -> cx3 -> cx4 -> cx5 -> cx6 -> cx7 -> cx8 -> cx9 -> cx10 -> cx11 -> cx12 -> cx13 -> IO cy)
          -> a -> x1 -> x2 -> x3 -> x4 -> x5 -> x6 -> x7 -> x8 -> x9 -> x10 -> x11 -> x12 -> x13 -> IO y
cast14 f a x1 x2 x3 x4 x5 x6 x7 x8 x9 x10 x11 x12 x13 =
  cast a $ \ca ->
    cast x1 $ \cx1 ->
      cast x2 $ \cx2 ->
        cast x3 $ \cx3 ->
          cast x4 $ \cx4 ->
            cast x5 $ \cx5 ->
              cast x6 $ \cx6 ->
                cast x7 $ \cx7 ->
                  cast x8 $ \cx8 ->
                    cast x9 $ \cx9 ->
                      cast x10 $ \cx10 ->
                        cast x11 $ \cx11 ->
                          cast x12 $ \cx12 ->
                          cast x13 $ \cx13 ->
                            (f ca cx1 cx2 cx3 cx4 cx5 cx6 cx7 cx8 cx9 cx10 cx11 cx12 cx13) >>= \cy -> uncast cy return


cast15 :: (Castable a ca, Castable x1 cx1, Castable x2 cx2, Castable x3 cx3, Castable x4 cx4,
            Castable x5 cx5, Castable x6 cx6, Castable x7 cx7, Castable x8 cx8, Castable x9 cx9,
            Castable x10 cx10, Castable x11 cx11, Castable x12 cx12, Castable x13 cx13, Castable x14 cx14, Castable y cy)
       => (ca -> cx1 -> cx2 -> cx3 -> cx4 -> cx5 -> cx6 -> cx7 -> cx8 -> cx9 -> cx10 -> cx11 -> cx12 -> cx13 -> cx14 -> IO cy)
          -> a -> x1 -> x2 -> x3 -> x4 -> x5 -> x6 -> x7 -> x8 -> x9 -> x10 -> x11 -> x12 -> x13 -> x14 -> IO y
cast15 f a x1 x2 x3 x4 x5 x6 x7 x8 x9 x10 x11 x12 x13 x14 =
  cast a $ \ca ->
    cast x1 $ \cx1 ->
      cast x2 $ \cx2 ->
        cast x3 $ \cx3 ->
          cast x4 $ \cx4 ->
            cast x5 $ \cx5 ->
              cast x6 $ \cx6 ->
                cast x7 $ \cx7 ->
                  cast x8 $ \cx8 ->
                    cast x9 $ \cx9 ->
                      cast x10 $ \cx10 ->
                        cast x11 $ \cx11 ->
                          cast x12 $ \cx12 ->
                          cast x13 $ \cx13 ->
                          cast x14 $ \cx14 ->
                            (f ca cx1 cx2 cx3 cx4 cx5 cx6 cx7 cx8 cx9 cx10 cx11 cx12 cx13 cx14) >>= \cy -> uncast cy return


cast16 :: (Castable a ca, Castable x1 cx1, Castable x2 cx2, Castable x3 cx3, Castable x4 cx4,
            Castable x5 cx5, Castable x6 cx6, Castable x7 cx7, Castable x8 cx8, Castable x9 cx9,
            Castable x10 cx10, Castable x11 cx11, Castable x12 cx12, Castable x13 cx13, Castable x14 cx14, Castable x15 cx15, Castable y cy)
       => (ca -> cx1 -> cx2 -> cx3 -> cx4 -> cx5 -> cx6 -> cx7 -> cx8 -> cx9 -> cx10 -> cx11 -> cx12 -> cx13 -> cx14 -> cx15 -> IO cy)
          -> a -> x1 -> x2 -> x3 -> x4 -> x5 -> x6 -> x7 -> x8 -> x9 -> x10 -> x11 -> x12 -> x13 -> x14 -> x15 -> IO y
cast16 f a x1 x2 x3 x4 x5 x6 x7 x8 x9 x10 x11 x12 x13 x14 x15 =
  cast a $ \ca ->
    cast x1 $ \cx1 ->
      cast x2 $ \cx2 ->
        cast x3 $ \cx3 ->
          cast x4 $ \cx4 ->
            cast x5 $ \cx5 ->
              cast x6 $ \cx6 ->
                cast x7 $ \cx7 ->
                  cast x8 $ \cx8 ->
                    cast x9 $ \cx9 ->
                      cast x10 $ \cx10 ->
                        cast x11 $ \cx11 ->
                          cast x12 $ \cx12 ->
                          cast x13 $ \cx13 ->
                          cast x14 $ \cx14 ->
                          cast x15 $ \cx15 ->
                            (f ca cx1 cx2 cx3 cx4 cx5 cx6 cx7 cx8 cx9 cx10 cx11 cx12 cx13 cx14 cx15) >>= \cy -> uncast cy return

cast17 :: (Castable a ca, Castable x1 cx1, Castable x2 cx2, Castable x3 cx3, Castable x4 cx4,
            Castable x5 cx5, Castable x6 cx6, Castable x7 cx7, Castable x8 cx8, Castable x9 cx9,
            Castable x10 cx10, Castable x11 cx11, Castable x12 cx12, Castable x13 cx13, Castable x14 cx14,
            Castable x15 cx15, Castable x16 cx16,
            Castable y cy)
       => (ca -> cx1 -> cx2 -> cx3 -> cx4 -> cx5 -> cx6 -> cx7 -> cx8 -> cx9 -> cx10 -> cx11 -> cx12 -> cx13 -> cx14 -> cx15 -> cx16 -> IO cy)
          -> a -> x1 -> x2 -> x3 -> x4 -> x5 -> x6 -> x7 -> x8 -> x9 -> x10 -> x11 -> x12 -> x13 -> x14 -> x15 -> x16 -> IO y
cast17 f a x1 x2 x3 x4 x5 x6 x7 x8 x9 x10 x11 x12 x13 x14 x15 x16 =
  cast a $ \ca ->
    cast x1 $ \cx1 ->
      cast x2 $ \cx2 ->
        cast x3 $ \cx3 ->
          cast x4 $ \cx4 ->
            cast x5 $ \cx5 ->
              cast x6 $ \cx6 ->
                cast x7 $ \cx7 ->
                  cast x8 $ \cx8 ->
                    cast x9 $ \cx9 ->
                      cast x10 $ \cx10 ->
                        cast x11 $ \cx11 ->
                          cast x12 $ \cx12 ->
                          cast x13 $ \cx13 ->
                          cast x14 $ \cx14 ->
                          cast x15 $ \cx15 ->
                          cast x16 $ \cx16 ->
                            (f ca cx1 cx2 cx3 cx4 cx5 cx6 cx7 cx8 cx9 cx10 cx11 cx12 cx13 cx14 cx15 cx16) >>= \cy -> uncast cy return

cast21 :: (Castable a ca, Castable x1 cx1, Castable x2 cx2, Castable x3 cx3, Castable x4 cx4,
            Castable x5 cx5, Castable x6 cx6, Castable x7 cx7, Castable x8 cx8, Castable x9 cx9,
            Castable x10 cx10, Castable x11 cx11, Castable x12 cx12, Castable x13 cx13, Castable x14 cx14, Castable x15 cx15,
            Castable x16 cx16, Castable x17 cx17, Castable x18 cx18, Castable x19 cx19, Castable x20 cx20,
            Castable y cy)
       => (ca -> cx1 -> cx2 -> cx3 -> cx4 -> cx5 -> cx6 -> cx7 -> cx8 -> cx9 ->
           cx10 -> cx11 -> cx12 -> cx13 -> cx14 -> cx15 -> cx16 -> cx17 -> cx18 -> cx19 ->
           cx20 -> IO cy) ->
          a -> x1 -> x2 -> x3 -> x4 -> x5 -> x6 -> x7 -> x8 -> x9 ->
          x10 -> x11 -> x12 -> x13 -> x14 -> x15 -> x16 -> x17 -> x18 -> x19 -> x20 -> IO y
cast21 f a x1 x2 x3 x4 x5 x6 x7 x8 x9 x10 x11 x12 x13 x14 x15 x16 x17 x18 x19 x20 =
  cast a $ \ca ->
    cast x1 $ \cx1 ->
      cast x2 $ \cx2 ->
        cast x3 $ \cx3 ->
          cast x4 $ \cx4 ->
            cast x5 $ \cx5 ->
              cast x6 $ \cx6 ->
                cast x7 $ \cx7 ->
                  cast x8 $ \cx8 ->
                    cast x9 $ \cx9 ->
                      cast x10 $ \cx10 ->
                        cast x11 $ \cx11 ->
                          cast x12 $ \cx12 ->
                          cast x13 $ \cx13 ->
                          cast x14 $ \cx14 ->
                          cast x15 $ \cx15 ->
                          cast x16 $ \cx16 ->
                          cast x17 $ \cx17 ->
                          cast x18 $ \cx18 ->
                          cast x19 $ \cx19 ->
                          cast x20 $ \cx20 ->
                            (f ca cx1 cx2 cx3 cx4 cx5 cx6 cx7 cx8 cx9
                              cx10 cx11 cx12 cx13 cx14 cx15 cx16 cx17 cx18 cx19
                              cx20) >>= \cy -> uncast cy return


cast22 :: (Castable a ca, Castable x1 cx1, Castable x2 cx2, Castable x3 cx3, Castable x4 cx4,
            Castable x5 cx5, Castable x6 cx6, Castable x7 cx7, Castable x8 cx8, Castable x9 cx9,
            Castable x10 cx10, Castable x11 cx11, Castable x12 cx12, Castable x13 cx13, Castable x14 cx14,
            Castable x15 cx15, Castable x16 cx16, Castable x17 cx17, Castable x18 cx18, Castable x19 cx19,
            Castable x20 cx20, Castable x21 cx21,
            Castable y cy)
       => (ca -> cx1 -> cx2 -> cx3 -> cx4 -> cx5 -> cx6 -> cx7 -> cx8 -> cx9 ->
           cx10 -> cx11 -> cx12 -> cx13 -> cx14 -> cx15 -> cx16 -> cx17 -> cx18 -> cx19 ->
           cx20 -> cx21 -> IO cy) ->
          a -> x1 -> x2 -> x3 -> x4 -> x5 -> x6 -> x7 -> x8 -> x9 ->
          x10 -> x11 -> x12 -> x13 -> x14 -> x15 -> x16 -> x17 -> x18 -> x19 -> x20 -> x21 -> IO y
cast22 f a x1 x2 x3 x4 x5 x6 x7 x8 x9 x10 x11 x12 x13 x14 x15 x16 x17 x18 x19 x20 x21 =
  cast a $ \ca ->
    cast x1 $ \cx1 ->
      cast x2 $ \cx2 ->
        cast x3 $ \cx3 ->
          cast x4 $ \cx4 ->
            cast x5 $ \cx5 ->
              cast x6 $ \cx6 ->
                cast x7 $ \cx7 ->
                  cast x8 $ \cx8 ->
                    cast x9 $ \cx9 ->
                      cast x10 $ \cx10 ->
                        cast x11 $ \cx11 ->
                          cast x12 $ \cx12 ->
                          cast x13 $ \cx13 ->
                          cast x14 $ \cx14 ->
                          cast x15 $ \cx15 ->
                          cast x16 $ \cx16 ->
                          cast x17 $ \cx17 ->
                          cast x18 $ \cx18 ->
                          cast x19 $ \cx19 ->
                          cast x20 $ \cx20 ->
                          cast x21 $ \cx21 ->
                            (f ca cx1 cx2 cx3 cx4 cx5 cx6 cx7 cx8 cx9
                              cx10 cx11 cx12 cx13 cx14 cx15 cx16 cx17 cx18 cx19
                              cx20 cx21) >>= \cy -> uncast cy return


{-# INLINE cast0 #-}
{-# INLINE cast1 #-}
{-# INLINE cast2 #-}
{-# INLINE cast3 #-}
{-# INLINE cast4 #-}
{-# INLINE cast5 #-}
{-# INLINE cast6 #-}
{-# INLINE cast7 #-}
{-# INLINE cast8 #-}
{-# INLINE cast9 #-}
{-# INLINE cast10 #-}
{-# INLINE cast11 #-}
{-# INLINE cast12 #-}
{-# INLINE cast13 #-}
{-# INLINE cast14 #-}
{-# INLINE cast15 #-}
{-# INLINE cast16 #-}
{-# INLINE cast17 #-}
{-# INLINE cast21 #-}
{-# INLINE cast22 #-}

--------------------------------------------------------------------------------
-- Cast functions with retryWithGC
--------------------------------------------------------------------------------

_cast0 :: (Castable a ca) => (IO ca) -> IO a
_cast0 f = retryWithGC (f) >>= \ca -> uncast ca return

_cast1 :: (Castable a ca, Castable y cy)
       => (ca -> IO cy) -> a -> IO y
_cast1 f a = cast a $ \ca -> retryWithGC (f ca) >>= \cy -> uncast cy return

_cast2 :: (Castable a ca, Castable x1 cx1, Castable y cy)
       => (ca -> cx1 -> IO cy) -> a -> x1 -> IO y
_cast2 f a x1 = cast a $ \ca ->
                  cast x1 $ \cx1 ->
                    retryWithGC (f ca cx1) >>= \cy -> uncast cy return

_cast3 :: (Castable a ca, Castable x1 cx1, Castable x2 cx2, Castable y cy)
       => (ca -> cx1 -> cx2 -> IO cy) -> a -> x1 -> x2-> IO y
_cast3 f a x1 x2 = cast a $ \ca ->
                     cast x1 $ \cx1 ->
                       cast x2 $ \cx2 ->
                         retryWithGC (f ca cx1 cx2) >>= \cy -> uncast cy return

_cast4 :: (Castable a ca, Castable x1 cx1, Castable x2 cx2, Castable x3 cx3, Castable y cy)
       => (ca -> cx1 -> cx2 -> cx3 -> IO cy) -> a -> x1 -> x2 -> x3 -> IO y
_cast4 f a x1 x2 x3 = cast a $ \ca ->
                        cast x1 $ \cx1 ->
                          cast x2 $ \cx2 ->
                            cast x3 $ \cx3 ->
                              retryWithGC (f ca cx1 cx2 cx3) >>= \cy -> uncast cy return

_cast5 :: (Castable a ca, Castable x1 cx1, Castable x2 cx2, Castable x3 cx3, Castable x4 cx4, Castable y cy)
       => (ca -> cx1 -> cx2 -> cx3 -> cx4 -> IO cy) -> a -> x1 -> x2 -> x3 -> x4 -> IO y
_cast5 f a x1 x2 x3 x4 =
  cast a $ \ca ->
    cast x1 $ \cx1 ->
      cast x2 $ \cx2 ->
        cast x3 $ \cx3 ->
          cast x4 $ \cx4 ->
            retryWithGC (f ca cx1 cx2 cx3 cx4) >>= \cy -> uncast cy return


_cast6 :: (Castable a ca, Castable x1 cx1, Castable x2 cx2, Castable x3 cx3, Castable x4 cx4,
           Castable x5 cx5, Castable y cy)
       => (ca -> cx1 -> cx2 -> cx3 -> cx4 -> cx5 -> IO cy) -> a -> x1 -> x2 -> x3 -> x4 -> x5 -> IO y
_cast6 f a x1 x2 x3 x4 x5 =
  cast a $ \ca ->
    cast x1 $ \cx1 ->
      cast x2 $ \cx2 ->
        cast x3 $ \cx3 ->
          cast x4 $ \cx4 ->
            cast x5 $ \cx5 ->
              retryWithGC (f ca cx1 cx2 cx3 cx4 cx5) >>= \cy -> uncast cy return

_cast7 :: (Castable a ca, Castable x1 cx1, Castable x2 cx2, Castable x3 cx3, Castable x4 cx4,
           Castable x5 cx5, Castable x6 cx6, Castable y cy)
       => (ca -> cx1 -> cx2 -> cx3 -> cx4 -> cx5 -> cx6 -> IO cy)
          -> a -> x1 -> x2 -> x3 -> x4 -> x5 -> x6 -> IO y
_cast7 f a x1 x2 x3 x4 x5 x6 =
  cast a $ \ca ->
    cast x1 $ \cx1 ->
      cast x2 $ \cx2 ->
        cast x3 $ \cx3 ->
          cast x4 $ \cx4 ->
            cast x5 $ \cx5 ->
              cast x6 $ \cx6 ->
                retryWithGC (f ca cx1 cx2 cx3 cx4 cx5 cx6) >>= \cy -> uncast cy return

_cast8 :: (Castable a ca, Castable x1 cx1, Castable x2 cx2, Castable x3 cx3, Castable x4 cx4,
           Castable x5 cx5, Castable x6 cx6, Castable x7 cx7, Castable y cy)
       => (ca -> cx1 -> cx2 -> cx3 -> cx4 -> cx5 -> cx6 -> cx7 -> IO cy)
          -> a -> x1 -> x2 -> x3 -> x4 -> x5 -> x6 -> x7 -> IO y
_cast8 f a x1 x2 x3 x4 x5 x6 x7 =
  cast a $ \ca ->
    cast x1 $ \cx1 ->
      cast x2 $ \cx2 ->
        cast x3 $ \cx3 ->
          cast x4 $ \cx4 ->
            cast x5 $ \cx5 ->
              cast x6 $ \cx6 ->
                cast x7 $ \cx7 ->
                  retryWithGC (f ca cx1 cx2 cx3 cx4 cx5 cx6 cx7) >>= \cy -> uncast cy return


_cast9 :: (Castable a ca, Castable x1 cx1, Castable x2 cx2, Castable x3 cx3, Castable x4 cx4,
           Castable x5 cx5, Castable x6 cx6, Castable x7 cx7, Castable x8 cx8, Castable y cy)
       => (ca -> cx1 -> cx2 -> cx3 -> cx4 -> cx5 -> cx6 -> cx7 -> cx8 -> IO cy)
          -> a -> x1 -> x2 -> x3 -> x4 -> x5 -> x6 -> x7 -> x8 -> IO y
_cast9 f a x1 x2 x3 x4 x5 x6 x7 x8 =
  cast a $ \ca ->
    cast x1 $ \cx1 ->
      cast x2 $ \cx2 ->
        cast x3 $ \cx3 ->
          cast x4 $ \cx4 ->
            cast x5 $ \cx5 ->
              cast x6 $ \cx6 ->
                cast x7 $ \cx7 ->
                  cast x8 $ \cx8 ->
                    retryWithGC (f ca cx1 cx2 cx3 cx4 cx5 cx6 cx7 cx8) >>= \cy -> uncast cy return

_cast10 :: (Castable a ca, Castable x1 cx1, Castable x2 cx2, Castable x3 cx3, Castable x4 cx4,
           Castable x5 cx5, Castable x6 cx6, Castable x7 cx7, Castable x8 cx8, Castable x9 cx9,
           Castable y cy)
       => (ca -> cx1 -> cx2 -> cx3 -> cx4 -> cx5 -> cx6 -> cx7 -> cx8 -> cx9 -> IO cy)
          -> a -> x1 -> x2 -> x3 -> x4 -> x5 -> x6 -> x7 -> x8 -> x9 -> IO y
_cast10 f a x1 x2 x3 x4 x5 x6 x7 x8 x9 =
  cast a $ \ca ->
    cast x1 $ \cx1 ->
      cast x2 $ \cx2 ->
        cast x3 $ \cx3 ->
          cast x4 $ \cx4 ->
            cast x5 $ \cx5 ->
              cast x6 $ \cx6 ->
                cast x7 $ \cx7 ->
                  cast x8 $ \cx8 ->
                    cast x9 $ \cx9 ->
                      retryWithGC (f ca cx1 cx2 cx3 cx4 cx5 cx6 cx7 cx8 cx9) >>= \cy -> uncast cy return

_cast11 :: (Castable a ca, Castable x1 cx1, Castable x2 cx2, Castable x3 cx3, Castable x4 cx4,
            Castable x5 cx5, Castable x6 cx6, Castable x7 cx7, Castable x8 cx8, Castable x9 cx9,
            Castable x10 cx10, Castable y cy)
       => (ca -> cx1 -> cx2 -> cx3 -> cx4 -> cx5 -> cx6 -> cx7 -> cx8 -> cx9 -> cx10 -> IO cy)
          -> a -> x1 -> x2 -> x3 -> x4 -> x5 -> x6 -> x7 -> x8 -> x9 -> x10 -> IO y
_cast11 f a x1 x2 x3 x4 x5 x6 x7 x8 x9 x10 =
  cast a $ \ca ->
    cast x1 $ \cx1 ->
      cast x2 $ \cx2 ->
        cast x3 $ \cx3 ->
          cast x4 $ \cx4 ->
            cast x5 $ \cx5 ->
              cast x6 $ \cx6 ->
                cast x7 $ \cx7 ->
                  cast x8 $ \cx8 ->
                    cast x9 $ \cx9 ->
                      cast x10 $ \cx10 ->
                        retryWithGC (f ca cx1 cx2 cx3 cx4 cx5 cx6 cx7 cx8 cx9 cx10) >>= \cy -> uncast cy return

_cast12 :: (Castable a ca, Castable x1 cx1, Castable x2 cx2, Castable x3 cx3, Castable x4 cx4,
            Castable x5 cx5, Castable x6 cx6, Castable x7 cx7, Castable x8 cx8, Castable x9 cx9,
            Castable x10 cx10, Castable x11 cx11, Castable y cy)
       => (ca -> cx1 -> cx2 -> cx3 -> cx4 -> cx5 -> cx6 -> cx7 -> cx8 -> cx9 -> cx10 -> cx11 -> IO cy)
          -> a -> x1 -> x2 -> x3 -> x4 -> x5 -> x6 -> x7 -> x8 -> x9 -> x10 -> x11 -> IO y
_cast12 f a x1 x2 x3 x4 x5 x6 x7 x8 x9 x10 x11 =
  cast a $ \ca ->
    cast x1 $ \cx1 ->
      cast x2 $ \cx2 ->
        cast x3 $ \cx3 ->
          cast x4 $ \cx4 ->
            cast x5 $ \cx5 ->
              cast x6 $ \cx6 ->
                cast x7 $ \cx7 ->
                  cast x8 $ \cx8 ->
                    cast x9 $ \cx9 ->
                      cast x10 $ \cx10 ->
                        cast x11 $ \cx11 ->
                         retryWithGC (f ca cx1 cx2 cx3 cx4 cx5 cx6 cx7 cx8 cx9 cx10 cx11) >>= \cy -> uncast cy return


_cast13 :: (Castable a ca, Castable x1 cx1, Castable x2 cx2, Castable x3 cx3, Castable x4 cx4,
            Castable x5 cx5, Castable x6 cx6, Castable x7 cx7, Castable x8 cx8, Castable x9 cx9,
            Castable x10 cx10, Castable x11 cx11, Castable x12 cx12, Castable y cy)
       => (ca -> cx1 -> cx2 -> cx3 -> cx4 -> cx5 -> cx6 -> cx7 -> cx8 -> cx9 -> cx10 -> cx11 -> cx12 -> IO cy)
          -> a -> x1 -> x2 -> x3 -> x4 -> x5 -> x6 -> x7 -> x8 -> x9 -> x10 -> x11 -> x12 -> IO y
_cast13 f a x1 x2 x3 x4 x5 x6 x7 x8 x9 x10 x11 x12 =
  cast a $ \ca ->
    cast x1 $ \cx1 ->
      cast x2 $ \cx2 ->
        cast x3 $ \cx3 ->
          cast x4 $ \cx4 ->
            cast x5 $ \cx5 ->
              cast x6 $ \cx6 ->
                cast x7 $ \cx7 ->
                  cast x8 $ \cx8 ->
                    cast x9 $ \cx9 ->
                      cast x10 $ \cx10 ->
                        cast x11 $ \cx11 ->
                          cast x12 $ \cx12 ->
                            retryWithGC (f ca cx1 cx2 cx3 cx4 cx5 cx6 cx7 cx8 cx9 cx10 cx11 cx12) >>= \cy -> uncast cy return

_cast14 :: (Castable a ca, Castable x1 cx1, Castable x2 cx2, Castable x3 cx3, Castable x4 cx4,
            Castable x5 cx5, Castable x6 cx6, Castable x7 cx7, Castable x8 cx8, Castable x9 cx9,
            Castable x10 cx10, Castable x11 cx11, Castable x12 cx12, Castable x13 cx13, Castable y cy)
       => (ca -> cx1 -> cx2 -> cx3 -> cx4 -> cx5 -> cx6 -> cx7 -> cx8 -> cx9 -> cx10 -> cx11 -> cx12 -> cx13 -> IO cy)
          -> a -> x1 -> x2 -> x3 -> x4 -> x5 -> x6 -> x7 -> x8 -> x9 -> x10 -> x11 -> x12 -> x13 -> IO y
_cast14 f a x1 x2 x3 x4 x5 x6 x7 x8 x9 x10 x11 x12 x13 =
  cast a $ \ca ->
    cast x1 $ \cx1 ->
      cast x2 $ \cx2 ->
        cast x3 $ \cx3 ->
          cast x4 $ \cx4 ->
            cast x5 $ \cx5 ->
              cast x6 $ \cx6 ->
                cast x7 $ \cx7 ->
                  cast x8 $ \cx8 ->
                    cast x9 $ \cx9 ->
                      cast x10 $ \cx10 ->
                        cast x11 $ \cx11 ->
                          cast x12 $ \cx12 ->
                          cast x13 $ \cx13 ->
                            retryWithGC (f ca cx1 cx2 cx3 cx4 cx5 cx6 cx7 cx8 cx9 cx10 cx11 cx12 cx13) >>= \cy -> uncast cy return


_cast15 :: (Castable a ca, Castable x1 cx1, Castable x2 cx2, Castable x3 cx3, Castable x4 cx4,
            Castable x5 cx5, Castable x6 cx6, Castable x7 cx7, Castable x8 cx8, Castable x9 cx9,
            Castable x10 cx10, Castable x11 cx11, Castable x12 cx12, Castable x13 cx13, Castable x14 cx14, Castable y cy)
       => (ca -> cx1 -> cx2 -> cx3 -> cx4 -> cx5 -> cx6 -> cx7 -> cx8 -> cx9 -> cx10 -> cx11 -> cx12 -> cx13 -> cx14 -> IO cy)
          -> a -> x1 -> x2 -> x3 -> x4 -> x5 -> x6 -> x7 -> x8 -> x9 -> x10 -> x11 -> x12 -> x13 -> x14 -> IO y
_cast15 f a x1 x2 x3 x4 x5 x6 x7 x8 x9 x10 x11 x12 x13 x14 =
  cast a $ \ca ->
    cast x1 $ \cx1 ->
      cast x2 $ \cx2 ->
        cast x3 $ \cx3 ->
          cast x4 $ \cx4 ->
            cast x5 $ \cx5 ->
              cast x6 $ \cx6 ->
                cast x7 $ \cx7 ->
                  cast x8 $ \cx8 ->
                    cast x9 $ \cx9 ->
                      cast x10 $ \cx10 ->
                        cast x11 $ \cx11 ->
                          cast x12 $ \cx12 ->
                          cast x13 $ \cx13 ->
                          cast x14 $ \cx14 ->
                            retryWithGC (f ca cx1 cx2 cx3 cx4 cx5 cx6 cx7 cx8 cx9 cx10 cx11 cx12 cx13 cx14) >>= \cy -> uncast cy return


_cast16 :: (Castable a ca, Castable x1 cx1, Castable x2 cx2, Castable x3 cx3, Castable x4 cx4,
            Castable x5 cx5, Castable x6 cx6, Castable x7 cx7, Castable x8 cx8, Castable x9 cx9,
            Castable x10 cx10, Castable x11 cx11, Castable x12 cx12, Castable x13 cx13, Castable x14 cx14, Castable x15 cx15, Castable y cy)
       => (ca -> cx1 -> cx2 -> cx3 -> cx4 -> cx5 -> cx6 -> cx7 -> cx8 -> cx9 -> cx10 -> cx11 -> cx12 -> cx13 -> cx14 -> cx15 -> IO cy)
          -> a -> x1 -> x2 -> x3 -> x4 -> x5 -> x6 -> x7 -> x8 -> x9 -> x10 -> x11 -> x12 -> x13 -> x14 -> x15 -> IO y
_cast16 f a x1 x2 x3 x4 x5 x6 x7 x8 x9 x10 x11 x12 x13 x14 x15 =
  cast a $ \ca ->
    cast x1 $ \cx1 ->
      cast x2 $ \cx2 ->
        cast x3 $ \cx3 ->
          cast x4 $ \cx4 ->
            cast x5 $ \cx5 ->
              cast x6 $ \cx6 ->
                cast x7 $ \cx7 ->
                  cast x8 $ \cx8 ->
                    cast x9 $ \cx9 ->
                      cast x10 $ \cx10 ->
                        cast x11 $ \cx11 ->
                          cast x12 $ \cx12 ->
                          cast x13 $ \cx13 ->
                          cast x14 $ \cx14 ->
                          cast x15 $ \cx15 ->
                            retryWithGC (f ca cx1 cx2 cx3 cx4 cx5 cx6 cx7 cx8 cx9 cx10 cx11 cx12 cx13 cx14 cx15) >>= \cy -> uncast cy return

_cast17 :: (Castable a ca, Castable x1 cx1, Castable x2 cx2, Castable x3 cx3, Castable x4 cx4,
            Castable x5 cx5, Castable x6 cx6, Castable x7 cx7, Castable x8 cx8, Castable x9 cx9,
            Castable x10 cx10, Castable x11 cx11, Castable x12 cx12, Castable x13 cx13, Castable x14 cx14,
            Castable x15 cx15, Castable x16 cx16,
            Castable y cy)
       => (ca -> cx1 -> cx2 -> cx3 -> cx4 -> cx5 -> cx6 -> cx7 -> cx8 -> cx9 -> cx10 -> cx11 -> cx12 -> cx13 -> cx14 -> cx15 -> cx16 -> IO cy)
          -> a -> x1 -> x2 -> x3 -> x4 -> x5 -> x6 -> x7 -> x8 -> x9 -> x10 -> x11 -> x12 -> x13 -> x14 -> x15 -> x16 -> IO y
_cast17 f a x1 x2 x3 x4 x5 x6 x7 x8 x9 x10 x11 x12 x13 x14 x15 x16 =
  cast a $ \ca ->
    cast x1 $ \cx1 ->
      cast x2 $ \cx2 ->
        cast x3 $ \cx3 ->
          cast x4 $ \cx4 ->
            cast x5 $ \cx5 ->
              cast x6 $ \cx6 ->
                cast x7 $ \cx7 ->
                  cast x8 $ \cx8 ->
                    cast x9 $ \cx9 ->
                      cast x10 $ \cx10 ->
                        cast x11 $ \cx11 ->
                          cast x12 $ \cx12 ->
                          cast x13 $ \cx13 ->
                          cast x14 $ \cx14 ->
                          cast x15 $ \cx15 ->
                          cast x16 $ \cx16 ->
                            retryWithGC (f ca cx1 cx2 cx3 cx4 cx5 cx6 cx7 cx8 cx9 cx10 cx11 cx12 cx13 cx14 cx15 cx16) >>= \cy -> uncast cy return

_cast21 :: (Castable a ca, Castable x1 cx1, Castable x2 cx2, Castable x3 cx3, Castable x4 cx4,
            Castable x5 cx5, Castable x6 cx6, Castable x7 cx7, Castable x8 cx8, Castable x9 cx9,
            Castable x10 cx10, Castable x11 cx11, Castable x12 cx12, Castable x13 cx13, Castable x14 cx14, Castable x15 cx15,
            Castable x16 cx16, Castable x17 cx17, Castable x18 cx18, Castable x19 cx19, Castable x20 cx20,
            Castable y cy)
       => (ca -> cx1 -> cx2 -> cx3 -> cx4 -> cx5 -> cx6 -> cx7 -> cx8 -> cx9 ->
           cx10 -> cx11 -> cx12 -> cx13 -> cx14 -> cx15 -> cx16 -> cx17 -> cx18 -> cx19 ->
           cx20 -> IO cy) ->
          a -> x1 -> x2 -> x3 -> x4 -> x5 -> x6 -> x7 -> x8 -> x9 ->
          x10 -> x11 -> x12 -> x13 -> x14 -> x15 -> x16 -> x17 -> x18 -> x19 -> x20 -> IO y
_cast21 f a x1 x2 x3 x4 x5 x6 x7 x8 x9 x10 x11 x12 x13 x14 x15 x16 x17 x18 x19 x20 =
  cast a $ \ca ->
    cast x1 $ \cx1 ->
      cast x2 $ \cx2 ->
        cast x3 $ \cx3 ->
          cast x4 $ \cx4 ->
            cast x5 $ \cx5 ->
              cast x6 $ \cx6 ->
                cast x7 $ \cx7 ->
                  cast x8 $ \cx8 ->
                    cast x9 $ \cx9 ->
                      cast x10 $ \cx10 ->
                        cast x11 $ \cx11 ->
                          cast x12 $ \cx12 ->
                          cast x13 $ \cx13 ->
                          cast x14 $ \cx14 ->
                          cast x15 $ \cx15 ->
                          cast x16 $ \cx16 ->
                          cast x17 $ \cx17 ->
                          cast x18 $ \cx18 ->
                          cast x19 $ \cx19 ->
                          cast x20 $ \cx20 ->
                            retryWithGC (f ca cx1 cx2 cx3 cx4 cx5 cx6 cx7 cx8 cx9
                              cx10 cx11 cx12 cx13 cx14 cx15 cx16 cx17 cx18 cx19
                              cx20) >>= \cy -> uncast cy return


_cast22 :: (Castable a ca, Castable x1 cx1, Castable x2 cx2, Castable x3 cx3, Castable x4 cx4,
            Castable x5 cx5, Castable x6 cx6, Castable x7 cx7, Castable x8 cx8, Castable x9 cx9,
            Castable x10 cx10, Castable x11 cx11, Castable x12 cx12, Castable x13 cx13, Castable x14 cx14,
            Castable x15 cx15, Castable x16 cx16, Castable x17 cx17, Castable x18 cx18, Castable x19 cx19,
            Castable x20 cx20, Castable x21 cx21,
            Castable y cy)
       => (ca -> cx1 -> cx2 -> cx3 -> cx4 -> cx5 -> cx6 -> cx7 -> cx8 -> cx9 ->
           cx10 -> cx11 -> cx12 -> cx13 -> cx14 -> cx15 -> cx16 -> cx17 -> cx18 -> cx19 ->
           cx20 -> cx21 -> IO cy) ->
          a -> x1 -> x2 -> x3 -> x4 -> x5 -> x6 -> x7 -> x8 -> x9 ->
          x10 -> x11 -> x12 -> x13 -> x14 -> x15 -> x16 -> x17 -> x18 -> x19 -> x20 -> x21 -> IO y
_cast22 f a x1 x2 x3 x4 x5 x6 x7 x8 x9 x10 x11 x12 x13 x14 x15 x16 x17 x18 x19 x20 x21 =
  cast a $ \ca ->
    cast x1 $ \cx1 ->
      cast x2 $ \cx2 ->
        cast x3 $ \cx3 ->
          cast x4 $ \cx4 ->
            cast x5 $ \cx5 ->
              cast x6 $ \cx6 ->
                cast x7 $ \cx7 ->
                  cast x8 $ \cx8 ->
                    cast x9 $ \cx9 ->
                      cast x10 $ \cx10 ->
                        cast x11 $ \cx11 ->
                          cast x12 $ \cx12 ->
                          cast x13 $ \cx13 ->
                          cast x14 $ \cx14 ->
                          cast x15 $ \cx15 ->
                          cast x16 $ \cx16 ->
                          cast x17 $ \cx17 ->
                          cast x18 $ \cx18 ->
                          cast x19 $ \cx19 ->
                          cast x20 $ \cx20 ->
                          cast x21 $ \cx21 ->
                            retryWithGC (f ca cx1 cx2 cx3 cx4 cx5 cx6 cx7 cx8 cx9
                              cx10 cx11 cx12 cx13 cx14 cx15 cx16 cx17 cx18 cx19
                              cx20 cx21) >>= \cy -> uncast cy return


{-# INLINE _cast0 #-}
{-# INLINE _cast1 #-}
{-# INLINE _cast2 #-}
{-# INLINE _cast3 #-}
{-# INLINE _cast4 #-}
{-# INLINE _cast5 #-}
{-# INLINE _cast6 #-}
{-# INLINE _cast7 #-}
{-# INLINE _cast8 #-}
{-# INLINE _cast9 #-}
{-# INLINE _cast10 #-}
{-# INLINE _cast11 #-}
{-# INLINE _cast12 #-}
{-# INLINE _cast13 #-}
{-# INLINE _cast14 #-}
{-# INLINE _cast15 #-}
{-# INLINE _cast16 #-}
{-# INLINE _cast17 #-}
{-# INLINE _cast21 #-}
{-# INLINE _cast22 #-}
