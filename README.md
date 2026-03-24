# kubeWAF Website (hack/website)

Very basic static website for the kubeWAF project.

## How to view

Open `index.html` in your browser.

Or run a local server:

```bash
python3 -m http.server 8080
# then visit http://localhost:8080
```

## Tech
- Tailwind CSS via CDN (no build step)
- Single HTML file
- Uses provided logos in `assets/` (`logo.png`, `logo_with_name.png`, `logo_with_name.svg`)

Target audience: Kubernetes + WAF technical users.

Company: Buzz-IT GmbH, Bern, Switzerland.
Status: BETA (breaking changes expected).

## Deployment

This website is automatically deployed to GitHub Pages using a GitHub Action whenever you push to the `main` branch.

The site will be available at: `https://<username>.github.io/<repo-name>` (or your custom domain if configured).
