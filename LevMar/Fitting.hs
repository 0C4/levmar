{-# LANGUAGE ScopedTypeVariables #-}

--------------------------------------------------------------------------------
-- |
-- Module      :  LevMar.Fitting
-- Copyright   :  (c) 2009 Roel van Dijk & Bas van Dijk
-- License     :  BSD-style (see the file LICENSE)
--
-- Maintainer  :  vandijk.roel@gmail.com, v.dijk.bas@gmail.com
-- Stability   :  Experimental
--
-- This module provides the Levenberg-Marquardt algorithm specialised
-- for curve-fitting.
--
-- For additional documentation see the documentation of the levmar C
-- library which this library is based on:
-- <http://www.ics.forth.gr/~lourakis/levmar/>
--
--------------------------------------------------------------------------------

module LevMar.Fitting
    ( -- * Model & Jacobian.
      Model
    , Jacobian

      -- * Levenberg-Marquardt algorithm.
    , LMA.LevMarable
    , levmar

    , LMA.LinearConstraints
    , LMA.noLinearConstraints
    , LMA.Matrix

    -- * Minimization options.
    , LMA.Options(..)
    , LMA.defaultOpts

      -- * Output
    , LMA.Info(..)
    , LMA.StopReason(..)
    , LMA.CovarMatrix

    , LMA.LevMarError(..)

      -- *Type-level machinery
    , Z, S, Nat
    , SizedList(..)
    , NFunction
    ) where


import qualified LevMar as LMA

import TypeLevelNat (Z, S, Nat, witnessNat)
import SizedList    (SizedList)
import NFunction    (NFunction, ComposeN, compose)


--------------------------------------------------------------------------------
-- Model & Jacobian.
--------------------------------------------------------------------------------

{- | A function from @n@ parameters of type @r@ and an x-value of type
@a@ to a value of type @r@.

For example, the quadratic function @f(x) = a*x^2 + b*x + c@ can be
written as:

@
type N3 = 'S' ('S' ('S' 'Z'))

quad :: 'Num' r => 'Model' N3 r r
quad a b c x = a*x^2 + b*x + c
@
-}
type Model n r a = NFunction n r (a -> r)

{- | The jacobian of the 'Model' function. Expressed as a function from
@n@ parameters of type @r@ and an x-value of type @a@ to a vector
of @n@ values of type @r@.

See: <http://en.wikipedia.org/wiki/Jacobian_matrix_and_determinant>

For example, the jacobian of the quadratic function @f(x) = a*x^2 +
b*x + c@ can be written as:

@
type N3 = 'S' ('S' ('S' 'Z'))

quadJacob :: 'Num' r => 'Jacobian' N3 r r
quadJacob _ _ _ x =   x^2   -- with respect to a
                  ::: x     -- with respect to b
                  ::: 1     -- with respect to c
                  ::: 'Nil'
@

Notice you don't have to differentiate for @x@.
-}
type Jacobian n r a = NFunction n r (a -> SizedList n r)


--------------------------------------------------------------------------------
-- Levenberg-Marquardt algorithm.
--------------------------------------------------------------------------------

-- | The Levenberg-Marquardt algorithm specialised for curve-fitting.
levmar :: forall n k r a. (Nat n, ComposeN n, Nat k, LMA.LevMarable r)
       => (Model n r a)                          -- ^ Model
       -> Maybe (Jacobian n r a)                 -- ^ Optional jacobian
       -> SizedList n r                          -- ^ Initial parameters
       -> [(a, r)]                               -- ^ Samples
       -> Integer                                -- ^ Maximum number of iterations
       -> LMA.Options r                          -- ^ Options
       -> Maybe (SizedList n r)                  -- ^ Optional lower bounds
       -> Maybe (SizedList n r)                  -- ^ Optional upper bounds
       -> Maybe (LMA.LinearConstraints k n r)    -- ^ Optional linear constraints
       -> Maybe (SizedList n r)                  -- ^ Optional weights
       -> Either LMA.LevMarError (SizedList n r, LMA.Info r, LMA.CovarMatrix n r)
levmar model mJac params samples = LMA.levmar (convertModel model)
                                              (fmap convertJacob mJac)
                                              params
                                              ys
    where
      (xs, ys) = unzip samples

      convertModel :: Model n r a -> LMA.Model n r
      convertModel = compose (witnessNat :: n) (undefined :: r)
                             (\(f :: a -> r) -> map f xs)

      convertJacob :: Jacobian n r a -> LMA.Jacobian n r
      convertJacob = compose (witnessNat :: n) (undefined :: r)
                             (\(f :: a -> SizedList n r) -> map f xs)


-- The End ---------------------------------------------------------------------
