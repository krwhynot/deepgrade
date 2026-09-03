# Wave 0 Snapshot — 22 pre-reconciliation sources

**Ticket:** PHV5-001 (acceptance-matrix row A4) · **Captured:** 2026-07-29 · **Repo HEAD at capture:** `8b870c9`
**Purpose:** freeze every input to the Wave 6 reconciliation *before* anything touches it (R11 — the sibling was
unversioned and had already drifted). Wave 6 reconciles **from these hashes**, not from live files.

> **Immutability.** These files are a historical record. They are never edited, reformatted, or "fixed" — a
> correction to canonical content belongs in `docs/troubleshooting-techniques/`, never here. `.gitattributes`
> pins this directory to `-text` so no clone can normalize line endings and invalidate the hashes below.

## Arithmetic (approach.md §3.3)

| Count | Meaning |
|------:|---------|
| 9 | shared technique files, **plugin side** |
| 13 | sibling bundle = 9 techniques + 4 sibling-only (`SKILL.md`, `README.md`, `resources/methodology.md`, `resources/kb-schema.md`) |
| **22** | **total pre-reconciliation sources preserved here** (18 = both sides of the 9 shared, + 4 sibling-only) |
| 13 | *(different figure, by design)* the reconciled **output** bundle count — see §3.3 bundle input manifest |

## Authoritative drift count

Pinned command, run over the 9 shared pairs at capture time:

```
git diff --no-index --numstat docs/troubleshooting-techniques/<f>.md \
                              <sibling>/resources/techniques/<f>.md
```

| File | + | − |
|------|--:|--:|
| 01-severity-classification-and-triage | 0 | 20 |
| 02-containment-before-root-cause | 5 | 23 |
| 03-blast-radius-assessment | 0 | 20 |
| 04-observability-first-diagnosis | 3 | 20 |
| 05-guardrail-evaluation | 16 | 28 |
| 06-structured-postmortem | 8 | 26 |
| 07-communication-protocol | 8 | 23 |
| 08-smart-correlation-engine | 30 | 45 |
| 09-incident-timeline-reconstruction | 8 | 17 |
| **TOTAL** | **78** | **222** |

**Authoritative total: 300 changed lines** (78 + 222) — reproduced exactly at capture, matching the plan's
re-measurement and round 4's independent count. **The 296 figure from `research/` is superseded and is not
authoritative anywhere.**

## Source provenance

| Side | Captured from | Tracked before this commit? |
|------|---------------|-----------------------------|
| `plugin-side/` | `toque-plugin/docs/troubleshooting-techniques/` | Yes (tracked in this repo) |
| `skill-side/` | `Projects/plugin/troubleshooting-skill/` — **outside this repo, unversioned** | **No — this is the R11 exposure these snapshots close** |

Both copies verified **byte-identical** to their sources at capture (`diff -r`, clean on both sides).

## Content hashes (SHA-256)

### plugin-side/ — 9 files

| SHA-256 | File |
|---------|------|
| `d5d06129add3cc0e12e33b2d1cac1d421ac98068dfb5fb3e1c2ef9346498b54c` | 01-severity-classification-and-triage.md |
| `79989c9add03e9f78db077d255d53e58141f40dfb9c18be5af54356a6874f688` | 02-containment-before-root-cause.md |
| `703bb7440a080c8cc3648774fce7efa833092a9c1ca0240bfa062f83de251416` | 03-blast-radius-assessment.md |
| `397c830cc7329350380fa8113fe30b32de59cb2095a8372a976426eb0dcb6f0e` | 04-observability-first-diagnosis.md |
| `2d9d08181d874c36095552bcfbfffce674e5640ad22f758c1241941ddca55f63` | 05-guardrail-evaluation.md |
| `ff32a1cf43b1ef4a3b0ee62bbfe572d31020b25a4b0e697fe750a90fd9caa697` | 06-structured-postmortem.md |
| `3ae29693c351ed24370ff137109c9d1ab23302c8ebcfd3c2f225357791179c61` | 07-communication-protocol.md |
| `424bf942123d7ab8018111920c6bc8044825e690c8a0dc7f0fa71633259f6f26` | 08-smart-correlation-engine.md |
| `612800ac927c74449b615b64b49447caa62f7afe9d0b09aa21340c5c7be2264a` | 09-incident-timeline-reconstruction.md |

### skill-side/ — 13 files

| SHA-256 | File |
|---------|------|
| `c85c61819ddbf0c6204ed94f476a848fd729700b6429453fa84442ee95203683` | SKILL.md ★ |
| `ff4f495e4a7e21033493f6b0ef742956bb812a79ace84e829715735d7e09232d` | README.md ★ |
| `d3e91ec842c87e5fe4a55e288ab5974e96a03fc65cfed2ae9e76ad4031243fbd` | resources/methodology.md ★ |
| `adc7b7613eee3734d3107ac44835b711455a43ae81a5a0b9816a5d34055bf771` | resources/kb-schema.md ★ |
| `f8331a38c48205c92d90fc895167ad00be873ef845c9eef3d3ebfba155667650` | resources/techniques/01-severity-classification-and-triage.md |
| `03e9c690446f1c22e2da57c9a93653abc87918321b41e79abe321be29d549833` | resources/techniques/02-containment-before-root-cause.md |
| `3869cfa25cd13e62a92e2527947982aa70928e449d4944fa23a76e84999afdd5` | resources/techniques/03-blast-radius-assessment.md |
| `a03d4d6c7d49da5f05a9e9d0021e49190a768b07453cd20816bf1b5892dba3e8` | resources/techniques/04-observability-first-diagnosis.md |
| `0e99faf9ee3b2bd51dd310e51f68c7194b7049197294074ccb00cd86add433d1` | resources/techniques/05-guardrail-evaluation.md |
| `da701e497fa3abe2d61ff113a9ccce428772c01e385c3b3fbc96942d47dd50fe` | resources/techniques/06-structured-postmortem.md |
| `a8e8972a8b486665baf847b556c2e8f112e4c57b40449a329edf638d1a348dfd` | resources/techniques/07-communication-protocol.md |
| `29684bfcc471f6265b99888a93b33f5f014625e90eed726711e09d826d6eaa24` | resources/techniques/08-smart-correlation-engine.md |
| `075a5506e6b21f9b39a44345c72adb161a4fb27b3d0b11c556fbf082ae184d2f` | resources/techniques/09-incident-timeline-reconstruction.md |

★ = sibling-only (no plugin-side counterpart; these are the 4 that existed **only** in the untracked sibling).

## Re-verification

```bash
cd docs/plans/2026-07-20-plugin-hardening-v5/snapshots
(cd plugin-side && sha256sum -c ../HASHES-plugin-side.txt)
(cd skill-side  && sha256sum -c ../HASHES-skill-side.txt)
```

Any mismatch means a snapshot was modified after capture — a defect, not a legitimate update.

## Acceptance (A4)

- [x] All 22 sources present at named tracked paths
- [x] Content hashes recorded
- [x] Authoritative diff count recorded with the exact pinned command (300 = 78 + 222)
- [x] Superseded 296 figure appears nowhere as authoritative
- [x] Byte-identity to sources verified at capture
- [x] Clean clone will contain all 22 (verified after commit)
