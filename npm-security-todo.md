# npm Security — Minimal To-Do

More information: \
https://github.com/lirantal/npm-security-best-practices#2-block-git-based-dependencies \
https://cheatsheetseries.owasp.org/cheatsheets/NPM_Security_Cheat_Sheet.html

## Set once (global config)

```bash
npm config set ignore-scripts true    # block post-install script execution
npm config set allow-git none         # registry-only, no git URLs (npm 11.10+)
npm config set min-release-age 30      # cooldown: skip versions under 30 days old
```

Or drop it straight into `~/.npmrc`:

```
ignore-scripts=true
allow-git=none
min-release-age=30
```

## Every install

- [ ] Use `npm ci`, not `npm install` — installs exact lockfile versions and fails on drift. Commit the lockfile.

## Before adding a new package

Run these checks before a name ever reaches your `package.json`. Most of it takes under a minute.

**Confirm the name is the one you mean.** Typosquatting relies on a slipped character or a near-identical name. Check it against the real project's homepage or GitHub repo, not just a search result.

**Run it through npq.** This is the single highest-leverage check — it audits CVEs, package age, typosquats, signatures, provenance, install scripts, deprecations, and expired maintainer domains in one go:

```bash
npm install -g npq        # once
npq install <package>     # instead of npm install
```

Or block flagged packages outright with Socket Firewall:

```bash
sfw npm install <package>
```

**Check package health on Snyk.** Look past the CVE count to maintenance, popularity, and community activity — a neglected package is a likelier future compromise:

```
https://security.snyk.io/package/npm/<package>
```

**Inspect the actual tarball, not the npmjs.org page.** The website omits git/HTTPS dependencies and can drift from what actually installs:

```bash
npm pack <package> --dry-run         # see what files ship
npm pack <package>
tar -tzf <package>-<version>.tgz     # list contents of the real artefact
```

### Check before you commit:

- [ ] Name matches the real project (no typosquat)
- [ ] Passes npq / sfw without serious flags
- [ ] Has a README, LICENSE, and linked repository
- [ ] Maintained recently and reasonably adopted (Snyk health)
- [ ] No surprise install scripts or bundled binaries
- [ ] Version isn't brand new
- [ ] Dependency tree isn't wildly larger than the job needs

If a package fails several of these, look for an alternative or vendor the small bit you actually need.

---

Everything beyond this floor — lockfile-lint, pnpm `blockExoticSubdeps`, dev containers, dependency-confusion scopes — is hardening on top.

*Based on "Awesome npm Security Best Practices" © Liran Tal, Apache 2.0 License.*
