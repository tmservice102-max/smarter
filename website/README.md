# smartersapp.org public pages

Static pages served from Hostinger `public_html`:

- `site/` -> home page (served at `/` by a rewrite rule in `public_html/.htaccess`), plus shared `style.css` and images
- `contact/` -> `/contact/`

Each folder needs its own `.htaccess` with `RewriteEngine Off` and `DirectoryIndex index.html` (same as `/privacy-policy/` and `/terms/`), so the CodeIgniter admin panel's rewrites don't touch them.

Root `.htaccess` has this line right after `RewriteEngine On`:

    RewriteRule ^$ site/index.html [L]

When the iPhone app goes live, change the "Coming soon" App Store button in `site/index.html` to a link to https://apps.apple.com/app/id6839402580.
