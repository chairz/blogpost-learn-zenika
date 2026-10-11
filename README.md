# Learning Notes

A minimal Hugo blog hosted on GitHub Pages. No external theme, JavaScript framework, or .NET runtime is required. C# examples are highlighted by Hugo.

## Local development

Requires Bash, curl, tar, and sha256sum (or shasum). The installer supports Linux amd64/arm64 and macOS.

From the repository root:

```bash
bash scripts/install-hugo.sh
.tools/bin/hugo server -D
```

The installer downloads Hugo Extended 0.147.9 from its official GitHub release and verifies its published SHA-256 checksum. It installs into ignored `.tools/bin/`. Repeating the command reuses the installed version.

## Add a post

```bash
.tools/bin/hugo new content posts/my-first-post.md
```

Edit `content/posts/my-first-post.md`. Posts begin as drafts; set `draft = false` when ready to publish. Use fenced `csharp` code blocks for C# highlighting. `hugo server -D` includes drafts; the production build excludes them.

Build before committing:

```bash
.tools/bin/hugo --minify --panicOnWarning
```

Generated `public/` files are ignored. Commit source files only.

## GitHub Pages

In this repository's **Settings → Pages → Build and deployment**, set **Source** to **GitHub Actions**. GitHub Pages availability for private repositories depends on the account's plan. A published Pages site may be publicly accessible even when its source repository is private.

Pushes to `main` build and deploy the site. Pull requests build without deploying. After enabling Pages, use **Actions → Deploy Hugo to GitHub Pages → Run workflow** if the initial deployment failed before Pages was enabled.

Expected site address: https://chairz.github.io/blogpost-learn-zenika/

If the repository or hosting URL changes, update `baseURL` in `hugo.toml`.

## Content boundary

Publish independent technical explanations and fictional examples only. Do not commit project architecture photos, internal diagrams, company or customer details, infrastructure addresses, credentials, or copied private source code. This starter contains no project material or blog post.
