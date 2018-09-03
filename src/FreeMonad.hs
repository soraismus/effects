{-# LANGUAGE DeriveFunctor #-}
{-# LANGUAGE LambdaCase #-}

module FreeMonad
  ( interpret
  , ioProgram
  , program
  ) where

{-
 - This example solves the challenge with a free monad. The use of free monads
 - to structure programs was popularized by [1].
 -
 - [1] Wouter Swierstra. 2008. Data types à la carte. J. Funct. Program. 18, 4
 -     (July 2008), 423-436. DOI=http://dx.doi.org/10.1017/S0956796808006758
 -}
import Control.Monad (replicateM_)
import Control.Monad.Free (Free(..), foldFree, liftF)
import Control.Monad.Random (getRandomR)
import Control.Monad.State (get, put)
import Control.Monad.Writer (tell)
import qualified MonadTransformers

-- The monad (constructed from a functor of operations)
data Operations a
  = GetRandom (Integer -> a)
  | GetAccumulator (Integer -> a)
  | SetAccumulator Integer
                   a
  | LogOutput String
              a
  deriving (Functor)

type Computation = Free Operations

-- The operations
getRandom :: Computation Integer
getRandom = Free (GetRandom return)

getAccumulator :: Computation Integer
getAccumulator = Free (GetAccumulator return)

setAccumulator :: Integer -> Computation ()
setAccumulator i = liftF (SetAccumulator i ())

logOutput :: String -> Computation ()
logOutput s = liftF (LogOutput s ())

-- The program
program :: Computation ()
program =
  replicateM_ 10 $ do
    i <- getAccumulator
    logOutput (show i ++ "\n")
    r <- getRandom
    setAccumulator (r + i)
    return ()

-- An interpreter
interpret :: Computation a -> MonadTransformers.Computation a
interpret =
  foldFree $ \case
    GetRandom k -> k <$> getRandomR (0, 9)
    GetAccumulator k -> k <$> get
    SetAccumulator i k -> k <$ put i
    LogOutput s k -> k <$ tell s

-- An interpretation of the program
ioProgram :: IO ()
ioProgram = MonadTransformers.interpret (interpret program)
