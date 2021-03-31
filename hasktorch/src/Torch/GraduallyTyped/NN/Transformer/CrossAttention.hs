{-# LANGUAGE AllowAmbiguousTypes #-}
{-# LANGUAGE ConstraintKinds #-}
{-# LANGUAGE DataKinds #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE GADTs #-}
{-# LANGUAGE KindSignatures #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE PartialTypeSignatures #-}
{-# LANGUAGE RecordWildCards #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE StandaloneKindSignatures #-}
{-# LANGUAGE TypeApplications #-}
{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE TypeOperators #-}
{-# LANGUAGE UndecidableInstances #-}
{-# LANGUAGE NoStarIsType #-}
{-# OPTIONS_GHC -fplugin TypeLevel.Rewrite
                -fplugin-opt=TypeLevel.Rewrite:Torch.GraduallyTyped.Unify.UnifyRightAssociativeL
                -fplugin-opt=TypeLevel.Rewrite:Torch.GraduallyTyped.Unify.UnifyIdempotenceL2
                -fplugin-opt=TypeLevel.Rewrite:Torch.GraduallyTyped.Unify.UnifyIdempotenceL2C
                -fplugin-opt=TypeLevel.Rewrite:Torch.GraduallyTyped.Unify.UnifyIdempotenceL3
                -fplugin-opt=TypeLevel.Rewrite:Torch.GraduallyTyped.Unify.UnifyIdempotenceL3C
                -fplugin-opt=TypeLevel.Rewrite:Torch.GraduallyTyped.Unify.UnifyIdempotenceL4
                -fplugin-opt=TypeLevel.Rewrite:Torch.GraduallyTyped.Unify.UnifyIdempotenceL4C
                -fplugin-opt=TypeLevel.Rewrite:Torch.GraduallyTyped.Unify.UnifyIdempotenceL5
                -fplugin-opt=TypeLevel.Rewrite:Torch.GraduallyTyped.Unify.UnifyIdempotenceL5C
                -fplugin-opt=TypeLevel.Rewrite:Torch.GraduallyTyped.Unify.UnifyIdempotenceL6
                -fplugin-opt=TypeLevel.Rewrite:Torch.GraduallyTyped.Unify.UnifyIdempotenceL6C
                -fplugin-opt=TypeLevel.Rewrite:Torch.GraduallyTyped.Unify.UnifyIdempotenceL7
                -fplugin-opt=TypeLevel.Rewrite:Torch.GraduallyTyped.Unify.UnifyIdempotenceL7C
                -fplugin-opt=TypeLevel.Rewrite:Torch.GraduallyTyped.Unify.UnifyIdempotenceL8
                -fplugin-opt=TypeLevel.Rewrite:Torch.GraduallyTyped.Unify.UnifyIdempotenceL8C #-}

module Torch.GraduallyTyped.NN.Transformer.CrossAttention where

import Control.Monad.Indexed (ireturn, (>>>=))
import Control.Monad.Indexed.State (IxState (..))
import Control.Monad.State.Strict (MonadState (state), runState)
import Data.Kind (Constraint, Type)
import GHC.TypeLits (Nat, Symbol)
import Torch.DType (DType (..))
import Torch.GraduallyTyped.DType (DataType, WithDataTypeC (..))
import Torch.GraduallyTyped.Device (Device (..), DeviceType (..), WithDeviceC (..))
import Torch.GraduallyTyped.Layout (Layout (Layout), LayoutType (Dense))
import Torch.GraduallyTyped.NN.Class (HasForward (..), HasInitialize (..))
import Torch.GraduallyTyped.NN.Dropout (Dropout)
import Torch.GraduallyTyped.NN.Functional.Linear (LinearWithoutBiasF)
import Torch.GraduallyTyped.NN.Functional.NonLinearActivation (SoftmaxF)
import Torch.GraduallyTyped.NN.Functional.Normalization (LayerNormWithoutBiasF)
import Torch.GraduallyTyped.NN.Normalization (HasInitializeLayerNormWithoutBiasC, LayerNorm)
import Torch.GraduallyTyped.NN.Transformer.MultiHeadAttention (HasInitializeMultiHeadAttentionC, MultiHeadAttention)
import Torch.GraduallyTyped.NN.Transformer.Type (TransformerStyle (..))
import Torch.GraduallyTyped.NN.Type (HasBias (..))
import Torch.GraduallyTyped.Random (Generator)
import Torch.GraduallyTyped.RequiresGradient (RequiresGradient (..))
import Torch.GraduallyTyped.Scalar (Scalar)
import Torch.GraduallyTyped.Shape.Class (BroadcastShapesF, type (!))
import Torch.GraduallyTyped.Shape.Type (By (..), Dim (..), KnownDim, KnownShape, Name (..), SelectDim (..), Shape (..), Size (..), WithDimC (..), WithShapeC (..))
import Torch.GraduallyTyped.Tensor (TransposeF)
import Torch.GraduallyTyped.Tensor.IndexingSlicingJoining (ReshapeF)
import Torch.GraduallyTyped.Tensor.MathOperations.BlasLapack (MatmulF)
import Torch.GraduallyTyped.Tensor.MathOperations.Pointwise (add)
import Torch.GraduallyTyped.Tensor.Type (Tensor)
import Torch.GraduallyTyped.Unify (type (<+>))

-- | Cross-attention layer.
data
  CrossAttention
    (style :: TransformerStyle)
    (device :: Device (DeviceType Nat))
    (dataType :: DataType DType)
    (headDim :: Dim (Name Symbol) (Size Nat))
    (headEmbedDim :: Dim (Name Symbol) (Size Nat))
    (embedDim :: Dim (Name Symbol) (Size Nat))
    (queryEmbedDim :: Dim (Name Symbol) (Size Nat))
    (keyEmbedDim :: Dim (Name Symbol) (Size Nat))
    (dropoutP :: Type)
  where
  -- | T5-style cross-attention layer without biases.
  T5CrossAttention ::
    forall device dataType headDim headEmbedDim embedDim queryEmbedDim keyEmbedDim dropoutP.
    { -- | cross-attention
      caMultiheadAttention :: MultiHeadAttention 'T5 device dataType headDim headEmbedDim embedDim queryEmbedDim keyEmbedDim keyEmbedDim dropoutP,
      -- | layer norm
      caLayerNorm :: LayerNorm 'WithoutBias device dataType ('Shape '[queryEmbedDim]),
      -- | dropout
      caDropout :: Dropout dropoutP
    } ->
    CrossAttention 'T5 device dataType headDim headEmbedDim embedDim queryEmbedDim keyEmbedDim dropoutP

type family
  HasInitializeCrossAttentionC'
    (style :: TransformerStyle)
    (device :: Device (DeviceType Nat))
    (dataType :: DataType DType)
    (headDim :: Dim (Name Symbol) (Size Nat))
    (headEmbedDim :: Dim (Name Symbol) (Size Nat))
    (embedDim :: Dim (Name Symbol) (Size Nat))
    (queryEmbedDim :: Dim (Name Symbol) (Size Nat))
    (keyEmbedDim :: Dim (Name Symbol) (Size Nat))
    (dropoutP :: Type) ::
    Constraint
  where
  HasInitializeCrossAttentionC' 'T5 device dataType headDim headEmbedDim embedDim queryEmbedDim keyEmbedDim dropoutP =
    HasInitializeLayerNormWithoutBiasC device dataType ('Shape '[queryEmbedDim])

type HasInitializeCrossAttentionC
  (style :: TransformerStyle)
  (device :: Device (DeviceType Nat))
  (dataType :: DataType DType)
  (headDim :: Dim (Name Symbol) (Size Nat))
  (headEmbedDim :: Dim (Name Symbol) (Size Nat))
  (embedDim :: Dim (Name Symbol) (Size Nat))
  (queryEmbedDim :: Dim (Name Symbol) (Size Nat))
  (keyEmbedDim :: Dim (Name Symbol) (Size Nat))
  (dropoutP :: Type) =
  ( HasInitializeMultiHeadAttentionC 'T5 device dataType headDim headEmbedDim embedDim queryEmbedDim keyEmbedDim keyEmbedDim dropoutP,
    HasInitializeLayerNormWithoutBiasC device dataType ('Shape '[queryEmbedDim]),
    Scalar dropoutP,
    WithDeviceC device (WithDataTypeF dataType (WithDimF headDim (WithDimF headEmbedDim (WithDimF embedDim (WithDimF queryEmbedDim (WithDimF keyEmbedDim (dropoutP -> Double -> Generator device -> (CrossAttention style device dataType headDim headEmbedDim embedDim queryEmbedDim keyEmbedDim dropoutP, Generator device)))))))),
    WithDataTypeC dataType (WithDimF headDim (WithDimF headEmbedDim (WithDimF embedDim (WithDimF queryEmbedDim (WithDimF keyEmbedDim (dropoutP -> Double -> Generator device -> (CrossAttention style device dataType headDim headEmbedDim embedDim queryEmbedDim keyEmbedDim dropoutP, Generator device))))))),
    WithDimC headDim (WithDimF headEmbedDim (WithDimF embedDim (WithDimF queryEmbedDim (WithDimF keyEmbedDim (dropoutP -> Double -> Generator device -> (CrossAttention style device dataType headDim headEmbedDim embedDim queryEmbedDim keyEmbedDim dropoutP, Generator device)))))),
    WithDimC headEmbedDim (WithDimF embedDim (WithDimF queryEmbedDim (WithDimF keyEmbedDim (dropoutP -> Double -> Generator device -> (CrossAttention style device dataType headDim headEmbedDim embedDim queryEmbedDim keyEmbedDim dropoutP, Generator device))))),
    WithDimC embedDim (WithDimF queryEmbedDim (WithDimF keyEmbedDim (dropoutP -> Double -> Generator device -> (CrossAttention style device dataType headDim headEmbedDim embedDim queryEmbedDim keyEmbedDim dropoutP, Generator device)))),
    WithDimC queryEmbedDim (WithDimF keyEmbedDim (dropoutP -> Double -> Generator device -> (CrossAttention style device dataType headDim headEmbedDim embedDim queryEmbedDim keyEmbedDim dropoutP, Generator device))),
    WithDimC keyEmbedDim (dropoutP -> Double -> Generator device -> (CrossAttention style device dataType headDim headEmbedDim embedDim queryEmbedDim keyEmbedDim dropoutP, Generator device)),
    HasInitializeCrossAttentionC' 'T5 device dataType headDim headEmbedDim embedDim queryEmbedDim keyEmbedDim dropoutP
  )

instance
  HasInitializeCrossAttentionC 'T5 device dataType headDim headEmbedDim embedDim queryEmbedDim keyEmbedDim dropoutP =>
  HasInitialize (CrossAttention 'T5 device dataType headDim headEmbedDim embedDim queryEmbedDim keyEmbedDim dropoutP)
  where
  type
    InitializeF (CrossAttention 'T5 device dataType headDim headEmbedDim embedDim queryEmbedDim keyEmbedDim dropoutP) =
      WithDeviceF
        device
        ( WithDataTypeF
            dataType
            ( WithDimF
                headDim
                ( WithDimF
                    headEmbedDim
                    ( WithDimF
                        embedDim
                        ( WithDimF
                            queryEmbedDim
                            ( WithDimF
                                keyEmbedDim
                                (dropoutP -> Double -> Generator device -> (CrossAttention 'T5 device dataType headDim headEmbedDim embedDim queryEmbedDim keyEmbedDim dropoutP, Generator device))
                            )
                        )
                    )
                )
            )
        )
  initialize =
    withDevice @device $
      \deviceType ->
        withDataType @dataType $
          \dType ->
            withDim @headDim $
              \headDim ->
                withDim @headEmbedDim $
                  \headEmbedDim ->
                    withDim @embedDim $
                      \embedDim ->
                        withDim @queryEmbedDim $
                          \queryEmbedDim ->
                            withDim @keyEmbedDim @(dropoutP -> Double -> Generator device -> (CrossAttention 'T5 device dataType headDim headEmbedDim embedDim queryEmbedDim keyEmbedDim dropoutP, Generator device)) $
                              \keyEmbedDim ->
                                go deviceType dType headDim headEmbedDim embedDim queryEmbedDim keyEmbedDim
    where
      go deviceType dType headDim headEmbedDim embedDim queryEmbedDim keyEmbedDim dropoutP eps = runState $ do
        multiheadAttention <-
          state $
            withoutDim @keyEmbedDim
              ( withoutDim @keyEmbedDim
                  ( withoutDim @queryEmbedDim
                      ( withoutDim @embedDim
                          ( withoutDim @headEmbedDim
                              ( withoutDim @headDim
                                  ( withoutDataType @dataType
                                      ( withoutDevice @device
                                          ( initialize @(MultiHeadAttention 'T5 device dataType headDim headEmbedDim embedDim queryEmbedDim keyEmbedDim keyEmbedDim dropoutP)
                                          )
                                          deviceType
                                      )
                                      dType
                                  )
                                  headDim
                              )
                              headEmbedDim
                          )
                          embedDim
                      )
                      queryEmbedDim
                  )
                  keyEmbedDim
              )
              keyEmbedDim
              dropoutP
        let layerNorm =
              withoutShape @('Shape '[queryEmbedDim])
                ( withoutDataType @dataType
                    ( withoutDevice @device
                        ( initialize @(LayerNorm 'WithoutBias device dataType ('Shape '[queryEmbedDim]))
                        )
                        deviceType
                    )
                    dType
                )
                [queryEmbedDim]
                eps
        let dropout = initialize @(Dropout dropoutP) dropoutP
        pure $ T5CrossAttention multiheadAttention layerNorm dropout

type CrossAttentionTransposeAndReshape
  (embedDim :: Dim (Name Symbol) (Size Nat))
  (attentionBiasShape :: Shape [Dim (Name Symbol) (Size Nat)])
  (normedBatchDim :: Dim (Name Symbol) (Size Nat))
  (normedQuerySeqDim :: Dim (Name Symbol) (Size Nat))
  (transposed :: Shape [Dim (Name Symbol) (Size Nat)])
  (transposed' :: Shape [Dim (Name Symbol) (Size Nat)]) =
  TransposeF
    ('SelectDim ('ByIndex 1))
    ('SelectDim ('ByIndex 2))
    ( MatmulF
        ( SoftmaxF
            ('SelectDim ('ByIndex 3))
            ( BroadcastShapesF
                ( MatmulF
                    transposed
                    ( TransposeF
                        ('SelectDim ('ByIndex 2))
                        ('SelectDim ('ByIndex 3))
                        transposed'
                    )
                )
                attentionBiasShape
            )
        )
        transposed'
    )

type family
  CrossAttentionTransposeAndReshape'
    (style :: TransformerStyle)
    (headDim :: Dim (Name Symbol) (Size Nat))
    (headEmbedDim :: Dim (Name Symbol) (Size Nat))
    (embedDim :: Dim (Name Symbol) (Size Nat))
    (queryEmbedDim :: Dim (Name Symbol) (Size Nat))
    (keyEmbedDim :: Dim (Name Symbol) (Size Nat))
    (normedQueryShape :: Shape [Dim (Name Symbol) (Size Nat)])
    (keyShape :: Shape [Dim (Name Symbol) (Size Nat)])
    (attentionBiasShape :: Shape [Dim (Name Symbol) (Size Nat)])
    (normedBatchDim :: Dim (Name Symbol) (Size Nat))
    (normedQuerySeqDim :: Dim (Name Symbol) (Size Nat))
    (keySeqDim :: Dim (Name Symbol) (Size Nat)) ::
    Shape [Dim (Name Symbol) (Size Nat)]
  where
  CrossAttentionTransposeAndReshape' 'T5 headDim headEmbedDim embedDim queryEmbedDim keyEmbedDim normedQueryShape keyShape attentionBiasShape normedBatchDim normedQuerySeqDim keySeqDim =
    CrossAttentionTransposeAndReshape
      embedDim
      attentionBiasShape
      normedBatchDim
      normedQuerySeqDim
      ( TransposeF
          ('SelectDim ('ByIndex 1))
          ('SelectDim ('ByIndex 2))
          ( ReshapeF
              ( LinearWithoutBiasF
                  ('Shape '[embedDim, queryEmbedDim])
                  normedQueryShape
              )
              ( 'Shape
                  '[normedBatchDim, normedQuerySeqDim, headDim, headEmbedDim]
              )
          )
      )
      ( TransposeF
          ('SelectDim ('ByIndex 1))
          ('SelectDim ('ByIndex 2))
          ( ReshapeF
              ( LinearWithoutBiasF
                  ('Shape '[embedDim, keyEmbedDim])
                  keyShape
              )
              ( 'Shape
                  '[normedBatchDim, keySeqDim, headDim, headEmbedDim]
              )
          )
      )

type CrossAttentionTransposeAndReshape''
  (style :: TransformerStyle)
  (headDim :: Dim (Name Symbol) (Size Nat))
  (headEmbedDim :: Dim (Name Symbol) (Size Nat))
  (embedDim :: Dim (Name Symbol) (Size Nat))
  (queryEmbedDim :: Dim (Name Symbol) (Size Nat))
  (keyEmbedDim :: Dim (Name Symbol) (Size Nat))
  (normedQueryShape :: Shape [Dim (Name Symbol) (Size Nat)])
  (keyShape :: Shape [Dim (Name Symbol) (Size Nat)])
  (attentionBiasShape :: Shape [Dim (Name Symbol) (Size Nat)])
  (normedBatchDim :: Dim (Name Symbol) (Size Nat))
  (normedQuerySeqDim :: Dim (Name Symbol) (Size Nat))
  (keySeqDim :: Dim (Name Symbol) (Size Nat)) =
  ReshapeF
    ( CrossAttentionTransposeAndReshape'
        style
        headDim
        headEmbedDim
        embedDim
        queryEmbedDim
        keyEmbedDim
        normedQueryShape
        keyShape
        attentionBiasShape
        normedBatchDim
        normedQuerySeqDim
        keySeqDim
    )
    ('Shape '[normedBatchDim, normedQuerySeqDim, embedDim])

type CrossAttentionTransposeAndReshape'''
  (style :: TransformerStyle)
  (headDim :: Dim (Name Symbol) (Size Nat))
  (headEmbedDim :: Dim (Name Symbol) (Size Nat))
  (embedDim :: Dim (Name Symbol) (Size Nat))
  (queryEmbedDim :: Dim (Name Symbol) (Size Nat))
  (keyEmbedDim :: Dim (Name Symbol) (Size Nat))
  (normedQueryShape :: Shape [Dim (Name Symbol) (Size Nat)])
  (keyShape :: Shape [Dim (Name Symbol) (Size Nat)])
  (attentionBiasShape :: Shape [Dim (Name Symbol) (Size Nat)]) =
  CrossAttentionTransposeAndReshape''
    style
    headDim
    headEmbedDim
    embedDim
    queryEmbedDim
    keyEmbedDim
    normedQueryShape
    keyShape
    attentionBiasShape
    (normedQueryShape ! 0 <+> keyShape ! 0)
    (normedQueryShape ! 1)
    (keyShape ! 1)

type family
  CrossAttentionOutputShape
    (style :: TransformerStyle)
    (headDim :: Dim (Name Symbol) (Size Nat))
    (headEmbedDim :: Dim (Name Symbol) (Size Nat))
    (embedDim :: Dim (Name Symbol) (Size Nat))
    (queryEmbedDim :: Dim (Name Symbol) (Size Nat))
    (keyEmbedDim :: Dim (Name Symbol) (Size Nat))
    (queryShape :: Shape [Dim (Name Symbol) (Size Nat)])
    (keyShape :: Shape [Dim (Name Symbol) (Size Nat)])
    (attentionBiasShape :: Shape [Dim (Name Symbol) (Size Nat)]) ::
    Shape [Dim (Name Symbol) (Size Nat)]
  where
  CrossAttentionOutputShape 'T5 headDim headEmbedDim embedDim queryEmbedDim keyEmbedDim queryShape keyShape attentionBiasShape =
    BroadcastShapesF
      queryShape
      ( LinearWithoutBiasF
          ('Shape '[queryEmbedDim, embedDim])
          ( CrossAttentionTransposeAndReshape'''
              'T5
              headDim
              headEmbedDim
              embedDim
              queryEmbedDim
              keyEmbedDim
              ( LayerNormWithoutBiasF
                  ('Shape '[queryEmbedDim])
                  queryShape
              )
              keyShape
              attentionBiasShape
          )
      )

-- | 'HasForward' instance for @CrossAttention 'T5@.
--
-- @
--    ┌───────┐  ┌─────┐  ┌───────────────┐
--    │ query │  │ key │  │ attentionBias │
--    └───┬───┘  └──┬──┘  └───────┬───────┘
--        │         │             │
-- ┌──────┤         │             │
-- │      │         │             │
-- │      ▼         │             │
-- │ caLayerNorm    │             │
-- │      │         │             │
-- │      │      ┌──┴──┐          │
-- │      │      │     │          │
-- │      ▼      ▼     ▼          │
-- │   caMultiheadAttention◄──────┘
-- │             │
-- │             ▼
-- │         caDropout
-- │             │
-- └────►add◄────┘
--        │
--        ▼
--    ┌───────┐
--    │ query │
--    └───────┘
-- @
instance
  ( KnownShape queryShape,
    KnownDim embedDim,
    KnownDim queryEmbedDim,
    KnownDim keyEmbedDim,
    KnownShape keyShape,
    normedQueryShape ~ LayerNormWithoutBiasF ('Shape '[queryEmbedDim]) queryShape,
    KnownShape normedQueryShape,
    normedBatchDim ~ ((normedQueryShape ! 0) <+> (keyShape ! 0)),
    KnownDim normedBatchDim,
    normedQuerySeqDim ~ (normedQueryShape ! 1),
    KnownDim normedQuerySeqDim,
    keySeqDim ~ (keyShape ! 1),
    KnownDim keySeqDim,
    WithShapeC
      ('Shape '[normedBatchDim, normedQuerySeqDim, headDim, headEmbedDim])
      ( Tensor
          'WithGradient
          ('Layout 'Dense <+> queryLayout)
          (device <+> queryDevice)
          (dataType <+> queryDataType)
          ( LinearWithoutBiasF
              ('Shape '[embedDim, queryEmbedDim])
              normedQueryShape
          ) ->
        Tensor
          'WithGradient
          ('Layout 'Dense <+> queryLayout)
          (device <+> queryDevice)
          (dataType <+> queryDataType)
          ( ReshapeF
              ( LinearWithoutBiasF
                  ('Shape '[embedDim, queryEmbedDim])
                  normedQueryShape
              )
              ('Shape '[normedBatchDim, normedQuerySeqDim, headDim, headEmbedDim])
          )
      ),
    WithShapeC
      ('Shape '[normedBatchDim, keySeqDim, headDim, headEmbedDim])
      ( Tensor
          'WithGradient
          ('Layout 'Dense <+> keyLayout)
          (device <+> keyDevice)
          (dataType <+> keyDataType)
          (LinearWithoutBiasF ('Shape '[embedDim, keyEmbedDim]) keyShape) ->
        Tensor
          'WithGradient
          ('Layout 'Dense <+> keyLayout)
          (device <+> keyDevice)
          (dataType <+> keyDataType)
          ( ReshapeF
              (LinearWithoutBiasF ('Shape '[embedDim, keyEmbedDim]) keyShape)
              ('Shape '[normedBatchDim, keySeqDim, headDim, headEmbedDim])
          )
      ),
    transposedAndReshaped
      ~ CrossAttentionTransposeAndReshape'
          'T5
          headDim
          headEmbedDim
          embedDim
          queryEmbedDim
          keyEmbedDim
          normedQueryShape
          keyShape
          attentionBiasShape
          normedBatchDim
          normedQuerySeqDim
          keySeqDim,
    WithShapeC
      ('Shape '[normedBatchDim, normedQuerySeqDim, embedDim])
      ( Tensor
          'WithGradient
          ('Layout 'Dense <+> queryLayout <+> keyLayout <+> attentionBiasLayout)
          (device <+> queryDevice <+> keyDevice <+> attentionBiasDevice <+> generatorDevice)
          (dataType <+> queryDataType <+> keyDataType <+> attentionBiasDataType)
          transposedAndReshaped ->
        Tensor
          'WithGradient
          ('Layout 'Dense <+> queryLayout <+> keyLayout <+> attentionBiasLayout)
          (device <+> queryDevice <+> keyDevice <+> attentionBiasDevice <+> generatorDevice)
          (dataType <+> queryDataType <+> keyDataType <+> attentionBiasDataType)
          ( ReshapeF
              transposedAndReshaped
              ('Shape '[normedBatchDim, normedQuerySeqDim, embedDim])
          )
      ),
    Scalar dropoutP,
    output
      ~ Tensor
          'WithGradient
          (queryLayout <+> 'Layout 'Dense <+> keyLayout <+> attentionBiasLayout)
          (queryDevice <+> device <+> keyDevice <+> attentionBiasDevice <+> generatorDevice)
          (queryDataType <+> dataType <+> keyDataType <+> attentionBiasDataType)
          (CrossAttentionOutputShape 'T5 headDim headEmbedDim embedDim queryEmbedDim keyEmbedDim queryShape keyShape attentionBiasShape),
    generatorOutput ~ Generator (device <+> queryDevice <+> keyDevice <+> attentionBiasDevice <+> generatorDevice)
  ) =>
  HasForward
    (CrossAttention 'T5 device dataType headDim headEmbedDim embedDim queryEmbedDim keyEmbedDim dropoutP)
    ( Tensor queryRequiresGradient queryLayout queryDevice queryDataType queryShape,
      Tensor keyRequiresGradient keyLayout keyDevice keyDataType keyShape,
      Tensor attentionBiasRequiresGradient attentionBiasLayout attentionBiasDevice attentionBiasDataType attentionBiasShape
    )
    (Generator generatorDevice)
    output
    generatorOutput
  where
  forward T5CrossAttention {..} (query, key, attentionBias) =
    runIxState $
      ireturn query
        >>>= IxState . forward caLayerNorm
        >>>= (\query' -> IxState $ forward caMultiheadAttention (query', key, key, attentionBias))
        >>>= IxState . forward caDropout
        >>>= ireturn . (query `add`)

-- | 'HasForward' instance for @CrossAttenton 'BART@.
--
-- @
--    ┌───────┐  ┌─────┐  ┌───────────────┐
--    │ query │  │ key │  │ attentionBias │
--    └───┬───┘  └──┬──┘  └───────┬───────┘
--        │         │             │
-- ┌──────┤      ┌──┴──┐          │
-- │      │      │     │          │
-- │      ▼      ▼     ▼          │
-- │  bcaMultiheadAttention◄──────┘
-- │             │
-- │             ▼
-- │        bcaDropout
-- │             │
-- └────►add◄────┘
--        │
--        ▼
--  bcaLayerNorm
--        │
--        ▼
--    ┌───────┐
--    │ query │
--    └───────┘
-- @