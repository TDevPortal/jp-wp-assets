# jp-wp-assets

Public CDN mirror of static assets for the **jobpage.lk** WordPress site,
served through [jsDelivr](https://www.jsdelivr.com/). This repo contains **no
PHP and no secrets** — only files the browser fetches:

```
wp-content/
  themes/jobpage-lk/style.css
  themes/jobpage-lk/assets/**   (fonts, logo, category SVGs)
  uploads/**                    (media library images)
```

The live theme rewrites its asset/image URLs to:

```
https://cdn.jsdelivr.net/gh/TDevPortal/jp-wp-assets@main/<path>
```

## Updating

Whenever images are added/changed in WordPress, or `style.css` is edited, run:

```powershell
powershell -ExecutionPolicy Bypass -File .\sync-cdn.ps1
```

It copies the latest files from the WP install and pushes them here.

> jsDelivr caches a branch ref (`@main`) for ~12h. For instant, long-lived
> caching, tag a release (`git tag v1 && git push --tags`) and point the theme's
> `JOBPAGE_CDN_REF` at the tag — or purge a file via
> `https://purge.jsdelivr.net/gh/TDevPortal/jp-wp-assets@main/<path>`.
