# Catalog: a product catalog for merchants

A SwiftUI iOS app on the DummyJSON Products API. It is the first version of a catalog for
merchants who run their business from their phone: browse products, then open one for details.

## Build and verify
- Xcode 27.x, Swift 6 language mode, iOS 17.0 deployment target.
- Build and test: `xcodebuild test -scheme Catalog -destination 'platform=iOS Simulator,name=<an available iPhone>'`
  (pipe it through `xcsift` if that's installed).
- Before saying something works, build it, run it in the Simulator and look at a screenshot.
  A passing build is not a working screen.
- No signing team, API keys or setup steps. A fresh clone must build and run in the Simulator.

## Architecture
- Plain SwiftUI. Each screen has one `@Observable` view model on `@MainActor`, which holds an
  explicit state (loading / loaded / empty / failed).
- No TCA, no Coordinators and no DI framework.
- Navigation uses `NavigationStack` with value-based navigation.
- Networking is one small API client on `URLSession` with async/await. Models are `Sendable`
  value types decoded with `Codable`.
- Add a protocol only where a test needs a seam. Add no third-party dependency unless the plan
  justifies it.

## DummyJSON facts (checked against the live API, not assumed)
- `GET /products` returns `{products, total, skip, limit}`. The default page is 30 of 194
  products. `limit`, `skip` and `select=title,price,...` are supported, and `id` always comes
  back. `limit=0` returns every product.
- `GET /products/{id}` returns one product. An unknown id returns 404 with
  `{"message": "Product with id '9999' not found"}`.
- `brand` is missing on 92 of the 194 products. Model optionality from the real payload, not
  from the docs.
- `availabilityStatus` is one of "In Stock", "Low Stock" or "Out of Stock".
- Dates (`meta.createdAt`, review `date`) look like `2025-10-09T14:47:01.588Z`, with
  fractional seconds. `JSONDecoder`'s `.iso8601` strategy accepted that on macOS 26, but older
  Foundation versions reject it. Cover it with a fixture test, and run that test on the oldest
  iOS we support.
- The API never states a currency, and `discountPercentage` doesn't say whether `price` is
  before or after the discount. Both are product decisions; record what we chose.
- `?delay=3000` slows any response, and `/http/<code>` returns that status (checked with 404,
  500 and 503). Use them to check the slow and failed states by hand.
- Also available: `/products/search?q=`, `/products/categories`, `/products/category/{slug}`,
  the `sortBy` and `order` params, and `PUT /products/{id}`. The PUT is simulated: it returns
  the updated product but saves nothing.

## Testing
- Swift Testing.
- Use the red-green loop for logic. Write one failing test, run it and watch it fail, then write
  the least code that passes, then refactor. Never edit a test just to make it pass; if a test
  looks wrong, stop and say so.
- Networking tests use a `URLProtocol` stub with JSON fixtures captured from the real API,
  including a product without `brand` and the 404 body. No live network calls in tests.
- View-model tests drive the state changes (success, failure, retry, cancellation) with a fake
  loader.
- No UI tests or snapshot tests in v1. The README explains why.

## UI
- Follow the HIG: system lists and navigation, pull-to-refresh, and `ContentUnavailableView` for
  the empty and error states.
- Support Dynamic Type up to the accessibility sizes: rows reflow and nothing gets silently cut
  off.
- Put VoiceOver labels on rows and images, and support light and dark mode.
- Never show stock status with colour alone.
- Format prices with `FormatStyle`, and keep every user-facing string in a String Catalog.

## Working agreement
- Make small commits, one slice each, with a message that says why. Where TDD applies, the test
  lands before the code that passes it.
- Each time a suggestion is accepted, changed or rejected, add one line to `NOTES.md`
  (gitignored) saying why. The README's AI section is written from it.
- Ask before adding a dependency, a new layer, or a feature that isn't in the plan.
