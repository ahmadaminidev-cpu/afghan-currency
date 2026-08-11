# Afghani Rates

A small Flutter app for checking popular currencies against the Afghan Afghani
(AFN) and converting between them.

## Data source

The app requests official daily reference rates from Da Afghanistan Bank (DAB)
through the no-key Frankfurter API. Requests are explicitly filtered to the DAB
provider; no blended, sample, cached, or hardcoded numeric rates are displayed.
If live data is unavailable, the app asks the user to connect to the internet
and try again.

Public Sarai Shahzada pages may show cash-market buy and sell prices, but no
documented, authorized API is currently integrated. The isolated data layer in
`lib/data/rate_repository.dart` can be switched to an authorized market feed
later without changing the UI.

## Run

```sh
flutter pub get
flutter run
```

Pull down on the rates screen to refresh. Use the Convert tab to convert AFN,
USD, EUR, GBP, CHF, AED, SAR, PKR, INR, CNY, and IRR.
