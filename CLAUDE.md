# CLAUDE.md

OpenTerminal: a Bloomberg-style market workspace built only on free public data.
npm workspaces: `server/` (Express + TypeScript API, SQLite) and `web/` (Next.js 15 + React 19).

## Commands

```bash
npm install                      # Node 22+ (better-sqlite3 13 ships prebuilt binaries)
npm run dev                      # API :4000 + web :3000 (API_PORT / PORT to move them)
npm test                         # Vitest, server only, no network calls
npx -w server vitest run src/cache.test.ts          # one test file
npx tsc --noEmit -p server/tsconfig.json            # type check the API
npx tsc --noEmit --incremental false -p web/tsconfig.json   # type check the web app
npm run build                    # server tsc + next build (what CI runs, see .github/workflows/ci.yml)
```

There is no ESLint setup: `npm run lint` (`next lint`) would ask to install it. Use the type checks above.
Pass `--incremental false` to the web type check: `web/tsconfig.tsbuildinfo` is tracked, and an
incremental run rewrites it.

## Layout

- `server/src/providers/` — one isolated module per upstream source (nasdaq, yahoo, stooq, tradingview,
  fred, ecb, econcalendar, coingecko, binance, news, secedgar, finra). Routes wrap them in `cached`
  (stale-while-revalidate) and, where several sources exist, `withFallback`; a provider failure must
  degrade, never crash.
- `server/src/routes/market.ts` — keyless market routes (rate limited, 240 req/min per IP).
- `server/src/routes/portfolio.ts`, `routes/ai.ts` — require the shared key (`X-Api-Key`, see `auth.ts`).
- `web/app/api/[...path]/route.ts` — server-side proxy that attaches the shared key; the key never
  reaches the browser.
- `web/components/widgets/` — one file per widget; `WidgetErrorBoundary` contains render crashes.

## Constraints

- Keep the security defaults: API bound to `127.0.0.1`, CORS limited to `WEB_ORIGIN`, shared key on
  portfolio and AI routes, `TRUST_PROXY` off unless a trusted reverse proxy sets `X-Forwarded-For`.
- Tests stay offline: mock `fetch`, never call a real provider.
- Downstream consumer: this fork is vendored into `Tahititrader/LegacyFX-Ultra-` under `openterminal/`.
  Its scan agent and its MCP server `openterminal` (`backend/openterminal_bridge/`) read
  `/api/econ-calendar` (`title`, `country`, `date`, `impact`, `forecast`, `previous`, `actual`) and
  `/api/macro` (`yields[{tenor, value}]` with tenors `3M`/`10Y`, `vix`, `indexes`, `policyRate`,
  `inflation`). Changing those shapes breaks LegacyFX: update its bridge in the same change.

## Claude Code cloud sessions

`.claude/hooks/session-start.sh` runs `npm install --no-save` when a cloud session starts, so tests and
builds work right away (`--no-save` keeps the lockfile written by a newer npm untouched).
Live data needs these hosts in the environment's network allowlist, otherwise every widget answers
"All data providers are temporarily unavailable": `api.nasdaq.com`, `query1.finance.yahoo.com`,
`query2.finance.yahoo.com`, `fc.yahoo.com`, `feeds.finance.yahoo.com`, `stooq.com`,
`scanner.tradingview.com`, `symbol-search.tradingview.com`, `api.coingecko.com`, `api.binance.com`,
`fred.stlouisfed.org`, `data-api.ecb.europa.eu`, `nfs.faireconomy.media`, `news.google.com`,
`www.sec.gov`, `data.sec.gov`, `cdn.finra.org`.
