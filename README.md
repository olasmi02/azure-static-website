# Hosting a Static Website on Azure Blob Storage

My submission for the Azure Blob Storage Static Web Hosting learning program. I built a small personal portfolio site and deployed it straight out of a storage account, no web server involved.

**Live URL:** https://olamileyestaticsite.z6.web.core.windows.net/

Try a broken link too, like [/this-page-does-not-exist](https://olamileyestaticsite.z6.web.core.windows.net/this-page-does-not-exist), to see the custom 404 page.

## What's in this repo

- `index.html` - the portfolio homepage
- `404.html` - custom error page
- `styles.css` - all styling
- `main.js` - footer year + smooth scrolling
- `screenshots/` - Azure portal screenshots (storage account config, static website settings, and the `$web` container contents)

## How I deployed it

I created a storage account called `olamileyestaticsite` in the Azure portal, inside a new resource group named `rg-static-website`, region West Europe. Once it deployed, I went to Data management > Static website and flipped the toggle to Enabled. Azure created the `$web` container for me and handed back a public endpoint ending in `.z6.web.core.windows.net`.

I set `index.html` as the index document and `404.html` as the error document path, saved, then uploaded my four site files into `$web`. That was it. Opened the endpoint in a browser and the site rendered with all assets loading correctly.

One thing I learned the hard way: keep the file structure flat if you can. I originally had `css/` and `js/` subfolders, but uploading a flat set of files through the portal is much less fiddly, so I moved everything to the root and fixed the references.

## Why Standard performance and LRS redundancy

**Performance tier: Standard.** Premium is built for workloads that need consistently low latency, like databases or high-traffic APIs, and it costs several times more. A portfolio site serving a few KB of HTML and CSS doesn't come close to needing that. Standard general-purpose v2 also supports access tiers (mine sits in Hot), which Premium block blob accounts handle differently.

**Redundancy: LRS (locally redundant storage).** LRS keeps three copies of the data within a single datacenter. It's the cheapest redundancy option Azure offers; GRS roughly doubles the storage cost because it replicates everything to a paired region hundreds of miles away.

Here's how I thought about the trade-off. The durability of LRS is already eleven nines (99.999999999%) over a year. The realistic failure scenario it doesn't cover is an entire datacenter or region going down. If that happened, my site would be unavailable until Azure recovered, but the source files live in this repo anyway, so I could redeploy to another region in about ten minutes. For a learning project where the monthly bill should stay in pennies, paying double for geo-replication buys nothing I actually need. A business site where downtime costs money would justify ZRS or GRS; this doesn't.

Cost impact in practice: the whole site is under 8 KB. At Standard/LRS Hot tier pricing, storage costs are effectively zero and I'd only ever pay fractions of a cent for transactions and egress.

## Security and scalability review

The `$web` container is the one place where anonymous public read access is the whole point, and Azure scopes it sensibly: visitors can fetch files through the web endpoint but can't list the container or touch anything else in the account. Writes still require authentication. Secure transfer (HTTPS) is enforced on the account, minimum TLS 1.2.

Things I'd change before calling this production-ready:

- Put **Azure CDN or Front Door** in front of the endpoint. Right now every request hits West Europe; a CDN would cache files at edge locations so a visitor in Lagos or Sydney gets similar load times to one in Amsterdam. It's also the only way to get HTTPS on a custom domain with this setup, since the blob endpoint's certificate only covers the default hostname.
- Add a custom domain instead of the long `web.core.windows.net` address.
- Set cache-control headers on the blobs so browsers don't re-download unchanged CSS.

Scaling isn't really my problem to solve here, which is the appeal of this whole approach. Blob Storage absorbs traffic spikes without me provisioning anything; there's no VM to resize and no Nginx config to tune. For frontend-only projects like portfolios, docs sites, and landing pages, that trade is hard to argue with.
