//! Types and modules that need to be shared across components.

pub mod flags;

use std::str::FromStr;

/// A wrapper around [`time::Date`] to supply some trait instances.
#[derive(Debug)]
pub struct Date(pub time::Date);

impl FromStr for Date {
    type Err = time::error::Parse;

    fn from_str(s: &str) -> Result<Self, Self::Err> {
        time::Date::parse(
            s,
            &time::macros::format_description!("[year]-[month]-[day]"),
        )
        .map(Date)
    }
}
