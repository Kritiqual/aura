{-

Copyright 2012, 2013 Colin Woodbury <colingw@gmail.com>

This file is part of Aura.

Aura is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

Aura is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with Aura.  If not, see <http://www.gnu.org/licenses/>.

-}

module Aura.Core where

import System.Directory (doesFileExist)
import Text.Regex.PCRE  ((=~))
import Control.Monad    (when)
import Data.Either      (partitionEithers)
import Data.List        (isSuffixOf)
import Data.Monoid      (Monoid(..))

import Aura.Bash (Namespace)
import Aura.Settings.Base
import Aura.Colour.Text
import Aura.Monad.Aura
import Aura.Languages
import Aura.Pacman
import Aura.Utils

import Utilities
import Shell

---

--------
-- TYPES
--------
type ErrMsg   = String
type Pkgbuild = String

data VersionDemand = LessThan String
                   | AtLeast String
                   | MoreThan String
                   | MustBe String
                   | Anything
                     deriving (Eq)

instance Show VersionDemand where
    show (LessThan v) = '<' : v
    show (AtLeast v)  = ">=" ++ v
    show (MoreThan v) = '>' : v
    show (MustBe  v)  = '=' : v
    show Anything     = ""

-- | A dependency on another package.
data Dep = Dep { depName          :: String
               , depVersionDemand :: VersionDemand }

-- | A package to be installed.
data Package = Package { pkgName        :: String
                       , pkgVersion     :: String
                       , pkgDeps        :: [Dep]
                       , pkgInstallType :: InstallType }

-- | The installation method.
data InstallType = Pacman String | Build Buildable

-- | A package installed by building.
data Buildable = Buildable
    { buildName   :: String
    , pkgbuildOf  :: Pkgbuild
    , namespaceOf :: Namespace
    , explicit    :: Bool
       -- | Fetch and extract the source code corresponding to the given package.
    , source      :: FilePath     -- ^ Directory in which to extract the package.
                  -> IO FilePath  -- ^ Path to the extracted source.
    }

-- | A 'Repository' is a place where packages may be fetched from. Multiple
-- repositories can be combined into a larger one with the 'Data.Monoid'
-- instance.
newtype Repository = Repository
    { lookupPkg :: String -> Aura (Maybe Package) }

instance Monoid Repository where
    mempty = Repository $ \_ -> return Nothing

    a `mappend` b = Repository $ \s -> do
        mpkg <- lookupPkg a s
        case mpkg of
            Nothing -> lookupPkg b s
            _       -> return mpkg

---------------------------------
-- Functions common to `Package`s
---------------------------------
-- | Partition a list of packages into pacman and buildable groups.
partitionPkgs :: [Package] -> ([String],[Buildable])
partitionPkgs = partitionEithers . map (toEither . pkgInstallType)
  where toEither (Pacman s) = Left  s
        toEither (Build  b) = Right b

parseDep :: String -> Dep
parseDep s = Dep name (getVersionDemand comp ver)
    where (name,comp,ver) = s =~ "(<|>=|>|=)" :: (String,String,String)
          getVersionDemand c v | c == "<"  = LessThan v
                               | c == ">=" = AtLeast v
                               | c == ">"  = MoreThan v
                               | c == "="  = MustBe v
                               | otherwise = Anything

-----------
-- THE WORK
-----------
-- | Action won't be allowed unless user is root, or using sudo.
sudo :: Aura () -> Aura ()
sudo action = do
  hasPerms <- asks (hasRootPriv . environmentOf)
  if hasPerms then action else scoldAndFail mustBeRoot_1

-- | Prompt if the user is the true Root. Building as it can be dangerous.
trueRoot :: Aura () -> Aura ()
trueRoot action = ask >>= \ss ->
  if isntTrueRoot $ environmentOf ss then action else do
       okay <- optionalPrompt trueRoot_1
       if okay then action else notify trueRoot_2

-- `-Qm` yields a list of sorted values.
getForeignPackages :: Aura [(String,String)]
getForeignPackages = (map fixName . lines) <$> pacmanOutput ["-Qm"]
    where fixName = hardBreak (== ' ')

getOrphans :: Aura [String]
getOrphans = lines <$> pacmanOutput ["-Qqdt"]

getDevelPkgs :: Aura [String]
getDevelPkgs = (filter isDevelPkg . map fst) <$> getForeignPackages

isDevelPkg :: String -> Bool
isDevelPkg p = any (`isSuffixOf` p) suffixes
    where suffixes = ["-git","-hg","-svn","-darcs","-cvs","-bzr"]

isIgnored :: String -> [String] -> Bool
isIgnored pkg toIgnore = pkg `elem` toIgnore

isInstalled :: String -> Aura Bool
isInstalled pkg = pacmanSuccess ["-Qq",pkg]

removePkgs :: [String] -> [String] -> Aura ()
removePkgs [] _         = return ()
removePkgs pkgs pacOpts = pacman  $ ["-Rsu"] ++ pkgs ++ pacOpts

-- Moving to a libalpm backend will make this less hacked.
-- | Returns if a package needs to be installed. If a package isn't installed,
-- `pacman -T` will yield a single name.
depTest :: String -> Aura Bool
depTest s = notNull <$> pacmanOutput ["-T", s]

-- | Block further action until the database is free.
checkDBLock :: Aura ()
checkDBLock = do
  locked <- liftIO $ doesFileExist lockFile
  when locked $ warn checkDBLock_1 >> liftIO getLine >> checkDBLock

-------
-- MISC  -- Too specific for `Utilities.hs` or `Aura.Utils`
-------
colouredMessage :: Colouror -> (Language -> String) -> Aura ()
colouredMessage c msg = ask >>= putStrLnA c . msg . langOf

renderColour :: Colouror -> (Language -> String) -> Aura String
renderColour c msg = asks (c . msg . langOf)

say :: (Language -> String) -> Aura ()
say = colouredMessage noColour

notify :: (Language -> String) -> Aura ()
notify = colouredMessage green

warn :: (Language -> String) -> Aura ()
warn = colouredMessage yellow

scold :: (Language -> String) -> Aura ()
scold = colouredMessage red

badReport :: (Language -> String) -> [String] -> Aura ()
badReport _ []     = return ()
badReport msg pkgs = ask >>= \ss -> printList red cyan (msg $ langOf ss) pkgs