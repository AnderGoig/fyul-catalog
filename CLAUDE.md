# Catalog: a product catalog for merchants

A SwiftUI iOS app on the DummyJSON Products API. It is the first version of a catalog for
merchants who run their business from their phone: browse products, then open one for details.

## Build and verify
- Xcode 26.6 (Swift 6.3), Swift 6 language mode, iOS 17.0 deployment target, iPhone only.
- Build and test: `xcodebuild test -scheme Catalog -destination 'platform=iOS Simulator,name=<an available iPhone>' -collect-test-diagnostics never`.
  Without the flag, a failing test makes `xcodebuild` collect simulator diagnostics for up to 10 minutes.
- Run the date fixture test on the oldest iOS runtime installed, and check the accessibility
  sizes on the narrowest iPhone available.
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

## Decisions (v1)
Agreed on 2026-11-17. Each says what we do, what we didn't do, and why. `NOTES.md` has the trail.
- **List loading: paging.** `limit=30` with `skip`; the next page loads when the bottom row
  appears. Not one `limit=0` call: a real merchant catalog has no upper bound and production APIs
  cap page size. The bottom row shows the spinner, "Couldn't load more" with Retry, and the
  product count at the end. Skip ids already loaded; a refresh cancels the page in flight.
  Search, category filter and sort go to the server, never filtering the loaded pages.
- **List payload: summary first, then detail.** Pages
  `select=title,price,stock,availabilityStatus,category,thumbnail` into `ProductSummary`. Detail
  shows the summary at once and fetches `/products/{id}` into `Product`. Not for size (a full page
  of 30 is about 8 KB gzipped): detail stock is current when opened, real catalog APIs split summary
  and detail, and a deleted product gets `notFound`. The list row isn't updated from detail; it
  catches up on refresh.
- **Images: our own `ImageLoader`, in CatalogKit.** URLSession plus an `NSCache` of decoded
  images, cost limit about 50 MB, memory only. The CDN sends `no-store`, so URLCache won't store
  images, and AsyncImage would download them again on scroll-back (inferred from the header; we
  never built the AsyncImage version).
  Holding images for the session is our call, never on disk. Views read
  the cache synchronously, so cached images don't flash the placeholder. Cancellation never shows
  as failure. No downsampling (300 px thumbnails, 1000 px photos). `ProductImage` in the app owns
  placeholder, failure and VoiceOver. No Kingfisher or Nuke until we need a disk cache,
  prefetching or downsampling.
- **Errors.** `APIError`: `network` (any `URLError` except cancelled), `server(status:)`,
  `notFound` (404), `decoding`. `URLError.cancelled` becomes `CancellationError`, which view
  models ignore. A refresh never goes back to `.loading`, because replacing the List cancels
  `.refreshable`. First-load failure: `ContentUnavailableView` with Retry. Failed refresh or page:
  loaded content stays, with an inline row and Retry. Detail 404: "no longer available", no Retry.
  Any other detail failure: the summary stays, with an inline error and Retry.
  No server messages or status codes on screen; details go to `Logger`. Request timeout 15 s.
- **Structure.** App target `Catalog`: views, view models, `ProductImage`. Local iOS-only package
  `CatalogKit`: models, `APIClient`, `APIError`, `ProductLoading`, `ImageLoader`, so `public`
  enforces the boundary. `CatalogKitTests` cover networking with `StubURLProtocol` and fixtures;
  `CatalogTests` cover view models with `FakeProductLoader`. Both run from the `Catalog` scheme.
- **Concurrency.** Every target is nonisolated by default, with Approachable Concurrency on
  (CatalogKit enables `NonisolatedNonsendingByDefault` and `InferIsolatedConformances` to match).
  `@MainActor` is written on the view models, `ImageLoader` and the view-model test suites. Only
  `APIClient`'s private `send` and `ImageLoader`'s fetch-and-decode are `@concurrent`; with
  URLSession's own I/O, that is all that runs off the main actor. A plain `nonisolated async`
  function runs on its caller's actor.
- **Product.**
  - List row: thumbnail, title, price, stock status with count, category. No rating.
  - Detail: the first image (no gallery in v1), price with "x% off", stock status and count,
    minimum order quantity, SKU, barcode, category, brand when present, description, shipping,
    warranty, return policy, then rating and reviews. No weight or dimensions: they have no units
    and look random.
  - Stock status is shown as the API sends it, as text plus an icon, never derived from the count.
    A status we don't know decodes as `.other` and shows as sent, instead of failing the page.
  - `price` is before the discount. No computed sale price in v1, to keep money math out of
    `Double`.
  - Currency is a fixed USD constant, formatted in the user's locale, never
    `Locale.current.currency`.
  - iPhone only. No cart, checkout, auth, persistence or editing.
- **Debug switches.** DEBUG builds read `CATALOG_DELAY_MS`, `CATALOG_FAIL_STATUS` and
  `CATALOG_FAIL_AFTER` (the first N requests succeed) and give `APIClient` an optional request
  adapter that adds `delay` or swaps the path for `/http/<code>`. They're listed unticked in the
  shared scheme, and CatalogKit has no debug code. To test offline, switch off the Mac's network.

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
- `availabilityStatus` doesn't follow from `stock`: stock 7 appears as both "In Stock" and
  "Low Stock".
- The API never states a currency. A product doesn't say whether `price` is before or after
  `discountPercentage`, but cart lines compute `discountedTotal = total × (1 − discountPercentage/100)`,
  so `price` is before the discount.
- `weight` is a whole number from 1 to 10 for every product and `dimensions` look random; neither
  has units.
- Images on `cdn.dummyjson.com` are WebP (300×300 thumbnails, 1000×1000 photos). Images and API
  responses both come with `Cache-Control: no-store`.
- `?delay=3000` slows any response, up to 5000 ms (more returns 400), and `/http/<code>` returns
  that status (checked with 404, 500 and 503). Use them to check the slow and failed states by hand.
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
