/// Country dialling data used by the phone input.
///
/// [nationalNumberLength] is the number of digits the subscriber types after
/// the dialling code. It is what the field caps input at and what validation
/// compares against, so switching country immediately changes both the limit
/// and the expected length.
class DialCountry {
  const DialCountry({
    required this.iso,
    required this.name,
    required this.dialCode,
    required this.nationalNumberLength,
  });

  /// ISO 3166-1 alpha-2 code, used for the flag emoji and lookup.
  final String iso;

  /// English name shown in the picker. Not localized: country names are
  /// proper nouns and the list is sorted alphabetically for scanning.
  final String name;

  /// Dialling code without the plus, e.g. `91`.
  final String dialCode;

  /// How many digits follow the dialling code.
  final int nationalNumberLength;

  /// `+91`
  String get displayDialCode => '+$dialCode';

  /// Flag emoji derived from the ISO code's regional indicator symbols.
  String get flag {
    final upper = iso.toUpperCase();
    return String.fromCharCodes(
      upper.codeUnits.map((c) => 0x1F1E6 + (c - 0x41)),
    );
  }
}

/// Countries offered in the phone picker, India first because it is the
/// primary market, then alphabetical.
const List<DialCountry> kDialCountries = <DialCountry>[
  DialCountry(
    iso: 'IN',
    name: 'India',
    dialCode: '91',
    nationalNumberLength: 10,
  ),
  DialCountry(
    iso: 'AE',
    name: 'United Arab Emirates',
    dialCode: '971',
    nationalNumberLength: 9,
  ),
  DialCountry(
    iso: 'AU',
    name: 'Australia',
    dialCode: '61',
    nationalNumberLength: 9,
  ),
  DialCountry(
    iso: 'BD',
    name: 'Bangladesh',
    dialCode: '880',
    nationalNumberLength: 10,
  ),
  DialCountry(
    iso: 'BH',
    name: 'Bahrain',
    dialCode: '973',
    nationalNumberLength: 8,
  ),
  DialCountry(
    iso: 'CA',
    name: 'Canada',
    dialCode: '1',
    nationalNumberLength: 10,
  ),
  DialCountry(
    iso: 'CH',
    name: 'Switzerland',
    dialCode: '41',
    nationalNumberLength: 9,
  ),
  DialCountry(
    iso: 'CN',
    name: 'China',
    dialCode: '86',
    nationalNumberLength: 11,
  ),
  DialCountry(
    iso: 'DE',
    name: 'Germany',
    dialCode: '49',
    nationalNumberLength: 10,
  ),
  DialCountry(
    iso: 'GB',
    name: 'United Kingdom',
    dialCode: '44',
    nationalNumberLength: 10,
  ),
  DialCountry(
    iso: 'GH',
    name: 'Ghana',
    dialCode: '233',
    nationalNumberLength: 9,
  ),
  DialCountry(
    iso: 'ID',
    name: 'Indonesia',
    dialCode: '62',
    nationalNumberLength: 10,
  ),
  DialCountry(
    iso: 'IT',
    name: 'Italy',
    dialCode: '39',
    nationalNumberLength: 10,
  ),
  DialCountry(
    iso: 'KE',
    name: 'Kenya',
    dialCode: '254',
    nationalNumberLength: 9,
  ),
  DialCountry(
    iso: 'KW',
    name: 'Kuwait',
    dialCode: '965',
    nationalNumberLength: 8,
  ),
  DialCountry(
    iso: 'LK',
    name: 'Sri Lanka',
    dialCode: '94',
    nationalNumberLength: 9,
  ),
  DialCountry(
    iso: 'MU',
    name: 'Mauritius',
    dialCode: '230',
    nationalNumberLength: 8,
  ),
  DialCountry(
    iso: 'MY',
    name: 'Malaysia',
    dialCode: '60',
    nationalNumberLength: 9,
  ),
  DialCountry(
    iso: 'NP',
    name: 'Nepal',
    dialCode: '977',
    nationalNumberLength: 10,
  ),
  DialCountry(
    iso: 'NL',
    name: 'Netherlands',
    dialCode: '31',
    nationalNumberLength: 9,
  ),
  DialCountry(
    iso: 'NZ',
    name: 'New Zealand',
    dialCode: '64',
    nationalNumberLength: 9,
  ),
  DialCountry(
    iso: 'OM',
    name: 'Oman',
    dialCode: '968',
    nationalNumberLength: 8,
  ),
  DialCountry(
    iso: 'PK',
    name: 'Pakistan',
    dialCode: '92',
    nationalNumberLength: 10,
  ),
  DialCountry(
    iso: 'PH',
    name: 'Philippines',
    dialCode: '63',
    nationalNumberLength: 10,
  ),
  DialCountry(
    iso: 'QA',
    name: 'Qatar',
    dialCode: '974',
    nationalNumberLength: 8,
  ),
  DialCountry(
    iso: 'SA',
    name: 'Saudi Arabia',
    dialCode: '966',
    nationalNumberLength: 9,
  ),
  DialCountry(
    iso: 'SG',
    name: 'Singapore',
    dialCode: '65',
    nationalNumberLength: 8,
  ),
  DialCountry(
    iso: 'US',
    name: 'United States',
    dialCode: '1',
    nationalNumberLength: 10,
  ),
  DialCountry(
    iso: 'ZA',
    name: 'South Africa',
    dialCode: '27',
    nationalNumberLength: 9,
  ),
];

/// Country used until the user picks another one.
const DialCountry kDefaultDialCountry = DialCountry(
  iso: 'IN',
  name: 'India',
  dialCode: '91',
  nationalNumberLength: 10,
);

/// Full international number for [country] and a local [nationalNumber].
String internationalNumber(DialCountry country, String nationalNumber) =>
    '${country.displayDialCode}${nationalNumber.replaceAll(RegExp(r'\D'), '')}';
