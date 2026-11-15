# Exposure, DNS and TLS

## Model and route selection

`DNS → ingress address → host/path match → Service → ready Pod`; TLS validates the client-facing hostname. DNS does not route URL paths. A CNAME aliases a hostname, not a browser redirect; the original Host/SNI still needs routing and a certificate.

Prefer ClusterIP for HTTP backends. An Ingress normally targets a Service in its own namespace. `containerPort` documents a port; it does not open one, start a listener or publish it. Match Service `targetPort` to the process listener, and require binding beyond loopback (usually `0.0.0.0`).

| Request | Resolve |
|---|---|
| Demo at `/demo/xyz` | Check existing host/path owners, base-path support and shared-host TLS |
| New tool hostname | Choose domain/subdomain with user; DNS, Ingress, certificate |
| Replace an existing route | Identify owner and make a deliberate replacement, not duplicate rules |
| Internal service/worker | No public Ingress/DNS; explain in-cluster DNS or port-forward access |
| WebSocket/SSE/gRPC | Check controller-specific protocol/timeouts, buffering, backend protocol |
| Raw TCP/UDP | HTTP Ingress is insufficient; inspect supported Service/controller mechanisms and firewall scope |

Do not publicly expose databases by default. For a sensitive tool, discuss existing oauth2-proxy integration or application auth as relevant to its intended access. Namespace separation alone is not network isolation; NetworkPolicies need an enforcing CNI and explicit DNS/database/ingress flows.

## Demo paths on the existing apex

Inspect `business-website` (root `/`), `hello-demo` (`/demo/gkv`) and any overlapping routes. ingress-nginx can combine compatible rules from multiple Ingresses with the same host; duplicate host/path owners are not a reliable override. Kubernetes Prefix routing uses path elements, with longest matches preferred; Exact wins equal-length matches. Controller-specific regex changes can affect other paths on that hostname.

Select one approach from application documentation:

1. **Prefix-aware application**: configure its documented base/public URL and pass the prefix unchanged.
2. **Backend needs `/` and is genuinely prefix-compatible**: strip prefix with a narrowly scoped controller rewrite.
3. **Hardcoded root URLs/assets/redirects/cookies/OAuth callbacks**: explain why stripping the request prefix is insufficient; resolve a dedicated subdomain instead of promising a broken demo route.

For nginx regex stripping, a common pattern is path `/demo/xyz(/|$)(.*)`, `pathType: ImplementationSpecific`, `use-regex: "true"` and `rewrite-target: /$2`. Only use if supported by the installed controller/admission settings. Escape any regex metacharacters in the chosen prefix. Evaluate host-wide regex effects before adding this pattern. Prefer native base-path support when possible. Don't add a fake ACME challenge backend to the app; cert-manager manages HTTP-01 solver routes.

Verify trailing slash behavior, deep links, redirects, asset requests, cookies and callback URLs. The public base URL and internal readiness path may differ.

## Certificate ownership on a shared hostname

The current `hello-demo` has an issuer annotation but no `spec.tls`; it declares no independent ingress-shim certificate. `business-website` owns apex TLS in its namespace. Verify the existing certificate/controller behavior rather than blindly copying this arrangement.

For another apex demo route, preserve the existing hostname certificate owner; do not reference `business-website-tls` from another namespace or request duplicate certificates unnecessarily. If owner/controller behavior cannot be established, mark TLS verification unresolved. Don't add an issuer annotation as a substitute for actual TLS ownership.

For a new hostname, declare its `spec.tls.hosts` and a TLS Secret name in the Ingress namespace, using the discovered issuer. Request only actual hostnames; no automatic `www`, especially `www.some-subdomain`.

The existing issuer uses HTTP-01: public DNS, port 80 and the correct ingress class must reach the solver. Wildcard certificates need DNS-01; wildcard DNS is independent and does not require wildcard TLS. Don't change the issuer/controller just to deploy one app.

## DNS and scoped infra edits

Read `infra/AGENTS.md` and nested instructions. Inspect existing DNS resources and CI workflows. Agents currently cannot run Terraform commands. Edit the minimal record/resource and use CI; if IAM or another prerequisite needs human execution, give exact resource-scoped instructions based on actual files.

For a subdomain, reuse the repo's DigitalOcean CNAME convention when appropriate:

```hcl
resource "digitalocean_record" "jakob_lingel_dev_APP_NAME" {
  domain = digitalocean_domain.jakob-lingel-dev.name
  type   = "CNAME"
  name   = "APP_NAME"
  value  = "${digitalocean_domain.jakob-lingel-dev.name}."
  ttl    = 1800
}
```

First verify the target resolves to the intended ingress; an existing hostname can point to a legacy server or unrelated endpoint. Reuse current HCL style and valid Terraform identifiers. Never copy a hardcoded IP without checking it. An A/AAAA record is also valid. A standard CNAME cannot coexist with other record data at the same name, and is not appropriate at the zone apex; use A/AAAA or a provider's explicit supported alias facility.

New domain: establish registration, authoritative DNS/delegation, existing zone management and current records. Preserve mail and validation records. Do not assume the user owns it or that creating a zone changes registrar delegation. Check A **and AAAA**, CAA restrictions, TTL/propagation and any DNS proxy behavior when issuance/routing fails.

Sources:
- https://kubernetes.io/docs/concepts/services-networking/ingress/
- https://cert-manager.io/docs/usage/ingress/
- https://cert-manager.io/docs/configuration/acme/http01/
