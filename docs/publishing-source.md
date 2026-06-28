# Making this repository public

Checklist before flipping visibility on GitHub.

## Already handled in-repo

- [x] **License:** [LICENSE](../LICENSE) — MIT (fork-friendly, public service).
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

2. **Optional:** Add repo topics — `ios`, `swift`, `swiftui`, `privacy`, `sms`, `filter`, `mit`.

3. **Keep Issues enabled** — users can file bugs here or email luke@lukefwalton.com.

## After going public

- Do not commit `project.local.yml` or signing assets (`.p12`, `.mobileprovision`).
- App Store: `https://apps.apple.com/us/app/stop-political-spam-texts/id6782703267`
- App Store privacy URL: `https://github.com/lukefwalton/stop-political-texts/blob/main/PRIVACY.md`
- Support URL: `https://github.com/lukefwalton/stop-political-texts/issues`
