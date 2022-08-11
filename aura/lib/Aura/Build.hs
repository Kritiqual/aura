{-# LANGUAGE BangPatterns #-}
{-# LANGUAGE LambdaCase   #-}

-- |
-- Module    : Aura.Build
-- Copyright : (c) Colin Woodbury, 2012 - 2021
-- License   : GPL3
-- Maintainer: Colin Woodbury <colin@fosskers.ca>
--
-- Agnostically builds packages, regardless of original source.

module Aura.Build
  ( installPkgFiles
  , buildPackages
  , srcPkgStore
  , vcsStore
  ) where

import           Aura.Core
import           Aura.IO
import           Aura.Languages
import           Aura.MakePkg
import           Aura.Packages.AUR (clone)
import           Aura.Pacman (pacman)
import           Aura.Settings
import           Aura.Shell (chown)
import           Aura.Types
import           Aura.Utils (edit)
import           Control.Monad.Trans.Except
import           Data.Hashable (hash)
import           RIO
import           RIO.Directory
import           RIO.FilePath
import qualified RIO.List as L
import qualified RIO.NonEmpty as NEL
import           RIO.Partial (fromJust)
import qualified RIO.Set as S
import qualified RIO.Text as T
import           RIO.Time
import           System.Process.Typed
import           System.Posix.User

---

-- | There are multiple outcomes to a single call to `makepkg`.
data BuildResult = AllSourced | Built !(NonEmpty PackagePath)

builtPPs :: BuildResult -> Maybe (NonEmpty PackagePath)
builtPPs (Built pps) = Just pps
builtPPs _           = Nothing

-- | Storage location for "source" packages built with @--allsource@.
-- Can be overridden in config or with @--allsourcepath@.
srcPkgStore :: FilePath
srcPkgStore = "/var/cache/aura/src"

-- | Storage/build location for VCS packages like @cool-retroterm-git@. Some of
-- these packages are quite large (e.g. kernels), and so recloning them in their
-- entirety upon each @-Au@ is wasteful.
vcsStore :: FilePath
vcsStore = "/var/cache/aura/vcs"

-- | Expects files like: \/var\/cache\/pacman\/pkg\/*.pkg.tar.xz
installPkgFiles :: NonEmpty PackagePath -> RIO Env ()
installPkgFiles files = do
  ss <- asks settings
  liftIO $ checkDBLock ss
  liftIO . pacman (envOf ss) $ ["-U"] <> map (T.pack . ppPath) (toList files) <> asFlag (commonConfigOf ss)

-- | All building occurs within temp directories, or in a location specified by
-- the user with flags.
buildPackages :: NonEmpty Buildable -> RIO Env [PackagePath]
buildPackages bs = mapMaybeA build (NEL.toList bs) >>= \case
  []    -> throwM . Failure $ FailMsg buildFail_10
  built -> pure . foldMap toList $ mapMaybe builtPPs built

-- | Handles the building of Packages. Fails nicely.
-- Assumed: All dependencies are already installed.
build :: Buildable -> RIO Env (Maybe BuildResult)
build p = do
  logDebug $ "Building: " <> display (pnName $ bName p)
  ss <- asks settings
  notify ss (buildPackages_1 $ bName p) *> hFlush stdout
  result <- build' p
  either buildFail (pure . Just) result

-- | Should never throw an IO Exception. In theory all errors will come back via
-- the @Language -> String@ function.
--
-- If the package is a VCS package (i.e. ending in -git, etc.), it will be built
-- and stored in a separate, deterministic location to prevent repeated clonings
-- during subsequent builds.
--
-- If `--allsource` was given, then the package isn't actually built.
-- Instead, a @.src.tar.gz@ file is produced and copied to `srcPkgStore`.
--
-- One `Buildable` can become multiple `PackagePath` due to "split packages".
-- i.e. a single call to `makepkg` can produce multiple related packages.
build' :: Buildable -> RIO Env (Either Failure BuildResult)
build' b = do
  ss <- asks settings
  let !isDevel = isDevelPkg $ bName b
      !pth | isDevel = fromMaybe vcsStore . vcsPathOf $ buildConfigOf ss
           | otherwise = fromMaybe defaultBuildDir . buildPathOf $ buildConfigOf ss
      !usr = fromMaybe (User "UNKNOWN") . buildUserOf $ buildConfigOf ss
  -- Create the build dir with open permissions so as to avoid issues involving git cloning.
  createWritableIfMissing pth
  -- Move into the final build dir.
  setCurrentDirectory pth
  buildDir <- liftIO $ getBuildDir b
  createWritableIfMissing buildDir
  setCurrentDirectory buildDir
  -- Build the package.
  r <- runExceptT $ do
    bs <- ExceptT $ do
      let !dir = buildDir </> T.unpack (pnName $ bName b)
      pulled <- doesDirectoryExist dir
      bool (cloneRepo b usr) (pure $ Right dir) pulled
    setCurrentDirectory bs
    when isDevel . ExceptT $ pullRepo usr
    logDebug "Potential hotediting..."
    liftIO $ overwritePkgbuild ss b
    liftIO $ overwriteInstall ss
    liftIO $ overwritePatches ss
    if S.member AllSource . makepkgFlagsOf $ buildConfigOf ss
      then do
        let !allsourcePath = fromMaybe srcPkgStore . allsourcePathOf $ buildConfigOf ss
        liftIO (makepkgSource usr >>= traverse_ (moveToSourcePath allsourcePath)) $> AllSourced
      else do
        logDebug "Building package."
        pNames <- ExceptT . liftIO $ makepkg ss usr
        liftIO . fmap Built $ traverse (moveToCachePath ss) pNames
  when (switch ss DeleteBuildDir) $ do
    logDebug . fromString $ "Deleting build directory: " <> buildDir
    removeDirectoryRecursive buildDir
  pure r

createWritableIfMissing :: FilePath -> RIO Env ()
createWritableIfMissing pth = do
  exists <- doesDirectoryExist pth
  if exists
    -- This is a migration strategy - it ensures that directories created with
    -- old versions of Aura automatically have their permissions fixed.
    then case pth of
      "/var/cache/aura/vcs" -> setMode "755"
      "/tmp"                -> setMode "1777"
      _                     -> pure ()
    -- The library function `createDirectoryIfMissing` seems to obey umasks when
    -- creating directories, which can cause problem later during the build
    -- processes of git packages. By manually creating the directory with the
    -- expected permissions, we avoid this problem.
    else void . runProcess . setStderr closed . setStdout closed $ proc "mkdir" ["-p", "-m755", pth]
  where
    setMode :: String -> RIO Env ()
    setMode mode = void . runProcess . setStderr closed . setStdout closed $ proc "chmod" [mode, pth]

-- | A unique directory name (within the greater "parent" build dir) in which to
-- copy sources and actually build a package.
getBuildDir :: Buildable -> IO FilePath
getBuildDir b
  | isDevelPkg $ bName b = vcsBuildDir $ bName b
  | otherwise = randomDirName b

vcsBuildDir :: PkgName -> IO FilePath
vcsBuildDir (PkgName pn) = do
  pwd <- getCurrentDirectory
  pure $ pwd </> T.unpack pn

-- | Create a temporary directory with a semi-random name based on
-- the `Buildable` we're working with.
randomDirName :: Buildable -> IO FilePath
randomDirName b = do
  pwd <- getCurrentDirectory
  UTCTime _ dt <- getCurrentTime
  let nh = hash . pnName $ bName b
      vh = hash $ bVersion b
      v  = abs $ nh + vh + floor dt
      dir = T.unpack (pnName $ bName b) <> "-" <> show v
  pure $ pwd </> dir

cloneRepo :: Buildable -> User -> RIO Env (Either Failure FilePath)
cloneRepo pkg usr = do
  currDir <- liftIO getCurrentDirectory
  logDebug $ "Currently in: " <> displayShow currDir
  scriptsDir <- liftIO $ chown usr currDir [] *> clone pkg
  logDebug "git: Initial cloning complete."
  case scriptsDir of
    Nothing -> pure . Left . Failure . FailMsg.  buildFail_7 $ bName pkg
    Just sd -> chown usr sd ["-R"] $> Right sd

-- | Assuming that we're already in a VCS-based package's build folder,
-- just pull the latest instead of cloning.
pullRepo :: User -> RIO Env (Either Failure ())
pullRepo usr = do
  logDebug "git: Clearing worktree. "
  void . runProcess . setStderr closed . setStdout closed $ proc "git" ["reset", "--hard", "HEAD"]
  logDebug $ "git: Pulling repo as " <> display (user usr)
  ue <- liftIO . getUserEntryForName . T.unpack . user $ usr
  let uid = userID ue
  let gid = userGroupID ue
  ec <- runProcess . setChildUser uid . setChildGroup gid . setStderr closed . setStdout closed $ proc "git" ["pull"]
  case ec of
    ExitFailure _ -> pure . Left . Failure $ FailMsg buildFail_12
    ExitSuccess   -> liftIO (chown usr "." ["-R"]) $> Right ()

-- | Edit the PKGBUILD in-place, if the user wants to.
overwritePkgbuild :: Settings -> Buildable -> IO ()
overwritePkgbuild ss b = when (switch ss HotEdit) . liftIO $ do
  ans <- optionalPrompt ss (hotEdit_1 $ bName b)
  when ans $ edit (editorOf ss) "PKGBUILD"

-- | Edit the .install file in-place, if the user wants to and it exists.
overwriteInstall :: Settings -> IO ()
overwriteInstall ss = when (switch ss HotEdit) . liftIO $ do
  files <- getCurrentDirectory >>= listDirectory
  case L.find ((== ".install") . takeFileName) files of
    Nothing -> pure ()
    Just _  -> do
      ans <- optionalPrompt ss hotEdit_2
      when ans $ edit (editorOf ss) ".install"

-- | Edit the all .patch files, if the user wants to and some exist.
overwritePatches :: Settings -> IO ()
overwritePatches ss = when (switch ss HotEdit) . liftIO $ do
  files <- getCurrentDirectory >>= listDirectory
  let !patches = filter ((== ".patch") . takeExtension) files
  traverse_ f patches
  where
    f :: FilePath -> IO ()
    f p = do
      ans <- optionalPrompt ss $ hotEdit_3 p
      when ans $ edit (editorOf ss) p

-- | Inform the user that building failed. Ask them if they want to
-- continue installing previous packages that built successfully.
buildFail :: Failure -> RIO Env (Maybe a)
buildFail err = do
  ss <- asks settings
  case err of
    Silent               -> pure ()
    Failure (FailMsg fm) -> scold ss fm
  withOkay ss buildFail_6 buildFail_5 $ pure Nothing

-- | Moves a file to the pacman package cache and returns its location.
moveToCachePath :: Settings -> FilePath -> IO PackagePath
moveToCachePath ss p = copy $> fromJust (packagePath newName)
  where newName = pth </> takeFileName p
        pth     = either id id . cachePathOf $ commonConfigOf ss
        copy    = runProcess . setStderr closed . setStdout closed
                  $ proc "cp" ["--reflink=auto", p, newName]

-- | Moves a file to the aura src package cache and returns its location.
moveToSourcePath :: FilePath -> FilePath -> IO FilePath
moveToSourcePath allsourcePath p = do
  createDirectoryIfMissing True allsourcePath
  copy $> newName
  where
    newName = allsourcePath </> takeFileName p
    copy    = runProcess . setStderr closed . setStdout closed
              $ proc "cp" ["--reflink=auto", p, newName]
