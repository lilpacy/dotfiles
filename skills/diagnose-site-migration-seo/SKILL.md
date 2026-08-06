---
name: diagnose-site-migration-seo
description: Diagnose why a site is missing or underperforming in branded search after a domain or hostname migration. Use when checking old-to-new redirects, HTTP/HTTPS canonicalization, robots directives, sitemaps, on-page brand signals, structured data, Search Console migration steps, and the distinction between indexing and ranking.
---

# Diagnose Site Migration SEO

Use read-only measurements. Do not infer Google-specific index status from a generic web search; confirm it in Google Search Console when access is available.

## Establish the symptom

Separate these cases:

- The new URL is not indexed.
- The new URL is indexed but does not rank for the branded query.
- A secondary page ranks instead of the homepage.
- The old URL still appears.

Record the exact query, search engine, locale, device, and observed result. Treat `site:` searches as diagnostics, not normal ranking tests.

## Measure the migration

1. Resolve DNS for the old and new apex, `www`, and intended subdomain variants.
2. Inspect `http` and `https` responses with `curl -sSIL --max-redirs 10`.
3. Test representative deep paths, not only the homepage. Require direct, page-to-page permanent redirects where equivalent pages exist.
4. Check a deliberately nonexistent path. It must end in `404` or `410`, not a homepage redirect or `200`.
5. Keep loop variables task-specific in zsh; never use `path`, because zsh ties `$path` to `$PATH`.

Classify redirect chains separately from broken redirects. A working two-hop chain is weaker operationally than a direct redirect but is not equivalent to a missing migration.

## Inspect indexability and canonical signals

For representative new URLs, verify:

- `200` status on the preferred HTTPS URL.
- HTTP redirects to HTTPS instead of serving a duplicate `200` page.
- No `X-Robots-Tag: noindex` or `<meta name="robots" content="noindex">`.
- A self-referential HTTPS canonical on the preferred page.
- `robots.txt` permits public content and names the current sitemap.
- The sitemap contains only preferred new URLs.
- `hreflang` pairs point to equivalent language pages and are reciprocal.
- Deleted or unmapped old URLs resolve to `404` or `410` on the new site.

Use `npx curl.md URL` to read page content. If exact metadata must be extracted, pipe the response into an HTML parser and output only the required fields; do not inspect raw HTML dumps.

## Inspect branded relevance

Compare the branded query with the homepage:

- Descriptive `<title>` containing the public or legal brand name where appropriate.
- One clear visible main heading.
- The exact organization name in visible homepage text.
- Useful meta description.
- `Organization` JSON-LD on the homepage or organization page with `name`, `alternateName`, canonical `url`, `logo`, `address`, and verified `sameAs` profiles where applicable.
- Consistent organization name and website URL on authoritative third-party profiles.

Do not promise rankings from metadata or structured data. Describe them as relevance and entity-disambiguation signals.

## Check Search Console

When available, verify both old and new properties and inspect:

- URL Inspection for the new homepage: indexed state, user-declared canonical, Google-selected canonical, last crawl, and rendered page.
- Sitemaps report for the new sitemap.
- Page indexing and manual actions.
- Performance queries for the exact brand name.
- Change of Address status for every relevant old hostname when the move crosses domains or hostnames.

If Search Console is unavailable, state that Change of Address submission and Google-selected canonical cannot be verified externally.

## Report findings

Use a compact evidence table with columns: check, observed value, impact, confidence, action. Lead with the distinction between indexing failure and ranking/relevance weakness. Prioritize:

1. Index-blocking or redirect failures.
2. Missing Change of Address or sitemap submission.
3. Duplicate HTTP/HTTPS or conflicting canonical signals.
4. Weak homepage brand signals and missing organization structured data.
5. Minor redirect chains and `hreflang` defects.

Link current primary search-engine documentation for recommendations that can change over time.
