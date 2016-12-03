module Wiz.Environment (
  emptyEnv,
  envLookup,
  extendEnvironment,
  encloseEnvironment,
  Environment( Environment )
) where

import Wiz.Types
import qualified Data.Map as Map
import qualified Data.List as L

data Environment = Environment { env :: Map.Map String Expression
                               , parent :: Maybe Environment
                               } deriving (Eq)

instance Show Environment where
  show (Environment env parent) =
    L.unlines (map showPair (Map.toList env)) ++ "\n"
    where showPair (k, v) = show k ++ "\t->\t" ++ show v

type Binding = (String, Expression)

emptyEnv :: Environment
emptyEnv = Environment (Map.fromList []) Nothing

encloseEnvironment :: Environment -> Environment -> Environment
encloseEnvironment parentEnv childEnv = Environment (env childEnv) (Just parentEnv)

extendEnvironment :: Environment -> [Binding] -> Environment
extendEnvironment (Environment env parent) bindings =
  Environment (Map.union (Map.fromList bindings) env) parent

envLookup :: String -> Environment -> Expression
-- envLookup symbol env
--   | trace ("envlookup " ++ show symbol ++ " in\n" ++ show env) False = undefined

envLookup symbol (Environment env parent) =
  case res of
    Just res -> res
    Nothing -> case parent of
      Just p -> envLookup symbol p
      Nothing -> error ("Unbound symbol " ++ show symbol)
  where res = Map.lookup symbol env
