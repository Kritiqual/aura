//! Utilities for localizing messages printed by the Aura executable.

use crate::utils::PathStr;
use aura_core::aur::dependencies as deps;
use aura_core::Apply;
use i18n_embed::fluent::{fluent_language_loader, FluentLanguageLoader};
use i18n_embed::{I18nEmbedError, LanguageLoader};
use i18n_embed_fl::fl;
use rust_embed::RustEmbed;
use std::collections::HashMap;
use unic_langid::LanguageIdentifier;

#[derive(RustEmbed)]
#[folder = "i18n"]
struct Translations;

// TODO Pull `LANG`, etc., variables from the environment myself. There are
// libraries that do this, but they incur heavy dependencies.

// TODO
// pl-PL Polish
// hr-HR Crotian
// sv-SE Swedish
// de-DE German
// es-ES Spanish
// pt-PT Portuguese
// fr-FR French
// ru-RU Russian
// it-IT Italian
// sr-SP Serbian
// nb-NO Norwegian
// id-ID Indonesian
// zh-CN Chinese
// nl-NL Dutch
// ??? Esperanto ???

/// Any type whose contents can be localised in a meaningful way.
pub(crate) trait Localised {
    /// Localise the content of a type.
    fn localise(&self, fll: &FluentLanguageLoader) -> String;
}

impl Localised for aura_core::git::Error {
    fn localise(&self, fll: &FluentLanguageLoader) -> String {
        match self {
            aura_core::git::Error::Io(_) => fl!(fll, "git-io"),
            aura_core::git::Error::Clone(p) => fl!(fll, "git-clone", dir = p.utf8()),
            aura_core::git::Error::Pull(p) => fl!(fll, "git-pull", dir = p.utf8()),
            aura_core::git::Error::Diff(p) => fl!(fll, "git-diff", file = p.utf8()),
            aura_core::git::Error::ReadHash(_) => fl!(fll, "git-hash"),
        }
    }
}

impl Localised for aura_core::aur::Error {
    fn localise(&self, fll: &FluentLanguageLoader) -> String {
        match self {
            aura_core::aur::Error::Git(e) => e.localise(fll),
            aura_core::aur::Error::FaurFetch(p) => fl!(fll, "faur-fetch", pkg = p.as_str()),
            aura_core::aur::Error::PackageDoesNotExist(p) => {
                fl!(fll, "faur-unknown", pkg = p.as_str())
            }
            aura_core::aur::Error::TooManyFaurResults(p) => {
                fl!(fll, "faur-too-many", pkg = p.as_str())
            }
        }
    }
}

impl<E> Localised for deps::Error<E>
where
    E: Localised,
{
    fn localise(&self, fll: &FluentLanguageLoader) -> String {
        match self {
            deps::Error::PoisonedMutex => fl!(fll, "err-mutex"),
            deps::Error::R2D2(_) => fl!(fll, "err-pool-get"),
            deps::Error::Srcinfo(p, _) => fl!(fll, "err-srcinfo", file = p.utf8()),
            deps::Error::Git(e) => e.localise(fll),
            deps::Error::Resolutions(es) => {
                let iter = es.iter().map(|e| format!(" - {}", e.localise(fll)));

                [fl!(fll, "dep-multi"), "".to_string()]
                    .into_iter()
                    .chain(iter)
                    // FIXME Thu Jun 23 10:21:03 2022
                    //
                    // Use built-in `intersperse` once it stabilizes.
                    .apply(|i| itertools::intersperse(i, "\n".to_string()))
                    .collect()
            }
            deps::Error::DoesntExist(p) => fl!(fll, "dep-exist", pkg = p.as_str()),
            deps::Error::DoesntExistWithParent(a, b) => {
                fl!(fll, "dep-exist-par", pkg = a.as_str(), par = b.as_str())
            }
            deps::Error::MalformedGraph => fl!(fll, "dep-graph"),
            deps::Error::CyclicDep(p) => fl!(fll, "dep-cycle", pkg = p.as_str()),
            deps::Error::Faur(e) => e.localise(fll),
        }
    }
}

/// Load the localizations for a particular language, or just fallback to
/// English.
///
/// ```
/// use i18n_embed_fl::fl;
///
/// let fll = aura::localization::load(None).unwrap();
/// let msg = fl!(fll, "orphans-adopt");
/// println!("{}", msg);
/// ```
pub(crate) fn load(
    lang: Option<LanguageIdentifier>,
) -> Result<FluentLanguageLoader, I18nEmbedError> {
    let loader = fluent_language_loader!();
    loader.load_languages(
        &Translations,
        &[lang.as_ref().unwrap_or_else(|| loader.fallback_language())],
    )?;
    loader.set_use_isolating(false);
    Ok(loader)
}

/// Like [`load`], but loads all available languages.
///
/// There is no guarantee about what language will end up the default, so this
/// shouldn't be used for normal localization purposes.
pub(crate) fn load_all() -> Result<HashMap<LanguageIdentifier, FluentLanguageLoader>, I18nEmbedError>
{
    available_languages()
        .into_iter()
        .map(|lang| {
            let loader = fluent_language_loader!();
            loader
                .load_languages(&Translations, &[&lang])
                .map(|_| (lang, loader))
        })
        .collect()
}

/// The list of languages that Aura has localization files for (e.g. `en-US`).
pub(crate) fn available_languages() -> Vec<LanguageIdentifier> {
    let mut vec: Vec<_> = Translations::iter()
        .filter_map(|l| l[0..5].parse().ok())
        .collect();
    vec.sort();
    vec
}

#[cfg(test)]
mod test {
    use super::*;

    /// Prove that localizations don't contain extra fields that aren't expected in
    /// English, the base language.
    #[test]
    fn no_extra_localizations() {
        let english = load(None).unwrap();
        let all = load_all().unwrap();
        for lang in available_languages() {
            all.get(&lang).unwrap().with_message_iter(&lang, |msgs| {
                for msg in msgs {
                    if !english.has(msg.id.name) {
                        panic!("{} has extra field: {}", lang, msg.id.name);
                    }
                }
            })
        }
    }
}
