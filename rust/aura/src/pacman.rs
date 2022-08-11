//! Sugar for interacting with Pacman.

use crate::error::Nested;
use crate::localization::Localised;
use i18n_embed_fl::fl;
use log::error;
use std::ffi::OsStr;
use std::process::Command;

pub(crate) enum Error {
    ExternalCmd(std::io::Error),
    InstallFromTarball,
    InstallFromRepos,
    Misc,
}

impl Nested for Error {
    fn nested(&self) {
        match self {
            Error::ExternalCmd(e) => error!("{e}"),
            Error::InstallFromTarball => {}
            Error::InstallFromRepos => {}
            Error::Misc => {}
        }
    }
}

impl Localised for Error {
    fn localise(&self, fll: &i18n_embed::fluent::FluentLanguageLoader) -> String {
        match self {
            Error::ExternalCmd(_) => fl!(fll, "pacman-external"),
            Error::InstallFromTarball => fl!(fll, "pacman-u"),
            Error::InstallFromRepos => fl!(fll, "pacman-s"),
            Error::Misc => fl!(fll, "pacman-misc"),
        }
    }
}

/// Make a shell call to `pacman`.
pub(crate) fn pacman<I, S>(args: I) -> Result<(), Error>
where
    I: IntoIterator<Item = S>,
    S: AsRef<OsStr>,
{
    Command::new("pacman")
        .args(args)
        .status()
        .map_err(Error::ExternalCmd)?
        .success()
        .then(|| ())
        .ok_or(Error::Misc)
}

/// Make an elevated shell call to `pacman`.
pub(crate) fn sudo_pacman<I, J, S, T>(command: &str, flags: I, args: J) -> Result<(), Error>
where
    I: IntoIterator<Item = S>,
    J: IntoIterator<Item = T>,
    S: AsRef<OsStr>,
    T: AsRef<OsStr>,
{
    Command::new("sudo")
        .arg("pacman")
        .arg(command)
        .args(flags)
        .args(args)
        .status()
        .map_err(Error::ExternalCmd)?
        .success()
        .then(|| ())
        .ok_or(Error::Misc)
}

/// Make an elevated shell call to `pacman`, passing all arguments to pacman as-is.
pub(crate) fn sudo_pacman_batch<I, S>(args: I) -> Result<(), Error>
where
    I: IntoIterator<Item = S>,
    S: AsRef<OsStr>,
{
    Command::new("sudo")
        .arg("pacman")
        .args(args)
        .status()
        .map_err(Error::ExternalCmd)?
        .success()
        .then(|| ())
        .ok_or(Error::Misc)
}

/// Call `sudo pacman -U`.
pub(crate) fn pacman_install_from_tarball<I, J, S, T>(flags: I, args: J) -> Result<(), Error>
where
    I: IntoIterator<Item = S>,
    J: IntoIterator<Item = T>,
    S: AsRef<OsStr>,
    T: AsRef<OsStr>,
{
    sudo_pacman("-U", flags, args).map_err(|_| Error::InstallFromTarball)
}

/// Call `sudo pacman -S`.
pub(crate) fn pacman_install_from_repos<I, J, S, T>(flags: I, args: J) -> Result<(), Error>
where
    I: IntoIterator<Item = S>,
    J: IntoIterator<Item = T>,
    S: AsRef<OsStr>,
    T: AsRef<OsStr>,
{
    sudo_pacman("-S", flags, args).map_err(|_| Error::InstallFromRepos)
}
