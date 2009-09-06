Copyright 2009 Jake Wheat

-- currently used to get the types of identifiers
-- eventually should include things like types, table attributes,
-- etc.,

> module Scope where

> import qualified Data.Map as M
> import Data.List

> import TypeType

> data Scope = Scope {scopeTypes :: [Type]
>                    ,scopeCasts :: [(Type,Type,CastContext)]
>                    ,scopeIdentifierTypes :: M.Map String Type }
>            deriving (Eq,Show)

> defaultScope,emptyScope :: Scope
> defaultScope = Scope [] [] M.empty
> emptyScope = Scope [] [] M.empty

> scopeCombineIds :: Scope -> M.Map String Type -> Scope
> scopeCombineIds s i = combineScopes s (emptyScope {scopeIdentifierTypes = i})

> combineScopes :: Scope -> Scope -> Scope
> --base, overrides
> combineScopes (Scope bt bc bi) (Scope ot oc oi) =
>   Scope (union ot bt) (union oc bc) (M.union oi bi)
