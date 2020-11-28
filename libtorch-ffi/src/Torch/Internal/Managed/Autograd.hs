
module Torch.Internal.Managed.Autograd where

import Foreign.ForeignPtr

import qualified Torch.Internal.Unmanaged.Autograd as Unmanaged
import Torch.Internal.Type
import Torch.Internal.Class
import Torch.Internal.Cast
import Torch.Internal.Objects
import Foreign.C.Types (CBool)


grad :: ForeignPtr Tensor -> ForeignPtr TensorList -> IO (ForeignPtr TensorList)
grad = cast2 Unmanaged.grad


makeIndependent :: ForeignPtr Tensor -> CBool -> IO (ForeignPtr Tensor)
makeIndependent = cast2 Unmanaged.makeIndependent

dropVariable :: ForeignPtr Tensor -> IO (ForeignPtr Tensor)
dropVariable = cast1 Unmanaged.dropVariable
