# Making this repository public

Checklist before flipping visibility on GitHub.

## Already handled in-repo

- [x] **Copyright:** [LICENSE](../LICENSE) — Luke F. Walton, all rights reserved (not MIT/open source).
- [x] **Secrets gitignored:** `project.local.yml`, signing assets, `build/`,
  `*.xcodeproj/`, local export plists — see [.gitignore](../.gitignore).
- [x] **Example config only:** [project.local.yml.example](../project.local.yml.example) uses placeholder team ID.
- [x] **Privacy policy:** [PRIVACY.md](../PRIVACY.md).
- [x] **Attributions:** [NOTICE](../NOTICE) for third-party references.

## Before you click "Public" on GitHub

1. **Confirm no secrets in history**
   ```bash
   git log --all -- project.local.yml   # should be empty
   git grep -i 'YOUR_TEAM_ID_HERE' $(git rev-list --all)  # should find nothing (except project.local.yml.example)
   ```

2. **Optional:** Add repo topics — `ios`, `swift`, `swiftui`, `privacy`, `sms`, `filter`.

3. **Optional:** Set GitHub **About** link to the repo itself or a future product page.

4. **Keep Issues enabled** — users can file bugs here or email luke@lukefwalton.com.

## After going public

- Do not commit `project.local.yml` or signing assets (`.p12`, `.mobileprovision`).
- App Store releases stay tied to your signing identity and Apple Developer account.
- Update [docs/app-store-listing.md](app-store-listing.md) Support URL once the repo is public.
