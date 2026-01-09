# gitraf-pages

Server-side scripts and configuration for gitraf pages static site hosting.

## Overview

This repo contains the server infrastructure for hosting static sites from git repositories at `{repo}.rafayel.dev`.

## Architecture

```
Git Push → post-receive hook → Build (optional) → Deploy to /opt/ogit/pages/{repo}/site
                                                            ↓
Browser request to {repo}.rafayel.dev → nginx → Serve files
```

## Server Components

### Directory Structure

```
/opt/ogit/
├── data/repos/           # Git repositories
│   └── {repo}.git/
│       ├── git-pages.json    # Pages config
│       └── hooks/post-receive → /opt/ogit/hooks/post-receive-pages
├── hooks/
│   └── post-receive-pages    # Shared deployment hook
├── pages/
│   └── {repo}/
│       ├── build/            # Checkout for build
│       └── site/             # Served by nginx
└── check-cert-expiry.sh      # Certificate renewal reminder
```

### Configuration File (git-pages.json)

Each pages-enabled repo has a config file:

```json
{
  "enabled": true,
  "branch": "main",
  "build_command": "npm run build",
  "output_dir": "dist"
}
```

### Post-Receive Hook

Located at `/opt/ogit/hooks/post-receive-pages`. When a push is received:

1. Check if git-pages.json exists
2. Parse config (branch, build command, output dir)
3. Only deploy if pushed branch matches configured branch
4. Checkout repo to pages/{repo}/build/
5. Run build command if specified (npm install + build)
6. rsync output directory to pages/{repo}/site/

### nginx Configuration

Wildcard server block in `/etc/nginx/nginx.conf`:

```nginx
server {
    listen 443 ssl;
    server_name ~^(?<subdomain>.+)\.rafayel\.dev$;

    ssl_certificate     /etc/letsencrypt/live/rafayel.dev-0001/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/rafayel.dev-0001/privkey.pem;

    root /opt/ogit/pages/$subdomain/site;
    index index.html index.htm;

    location / {
        try_files $uri $uri/ $uri.html =404;
    }
}
```

## SSL Certificate

Wildcard certificate for `*.rafayel.dev` obtained via certbot DNS challenge.

**Location:** `/etc/letsencrypt/live/rafayel.dev-0001/`

**Renewal:** Manual DNS challenge required. Check `/var/log/syslog` for renewal reminders from the daily cron job.

To renew:
```bash
sudo certbot certonly --manual --preferred-challenges dns -d "*.rafayel.dev"
```

## Client Commands

See the main gitraf README for CLI usage:

```bash
gitraf pages enable <repo>   # Enable pages
gitraf pages disable <repo>  # Disable pages
gitraf pages list            # List pages repos
gitraf pages status [repo]   # Show status
gitraf pages deploy <repo>   # Force deploy
```

## Maintenance

### View deployment logs
```bash
# Check systemd journal
journalctl -t cert-check

# View site contents
ls -la /opt/ogit/pages/{repo}/site/
```

### Remove a deployed site
```bash
sudo rm -rf /opt/ogit/pages/{repo}
```

### Debug hook execution
```bash
# Run hook manually
cd /opt/ogit/data/repos/{repo}.git
echo "0000000 HEAD refs/heads/main" | sudo -u git /opt/ogit/hooks/post-receive-pages
```
