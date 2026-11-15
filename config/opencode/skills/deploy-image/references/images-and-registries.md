# Images and registries

## Establish the runtime contract

Obtain the complete registry/repository:tag or @sha256 digest. Check image OS/architecture against eligible nodes, entrypoint/CMD, configured user, documentation, exposed ports, required env, persistent directories and health behavior. An ARM-only laptop build will not run natively on amd64 nodes. Do not silently build or modify the application to fix this.

Possible metadata tools, if already available: `docker manifest inspect`, `docker image inspect` for a local image, `skopeo inspect`, `crane manifest`. Avoid commands that print Docker auth configuration or application secrets. Use upstream image documentation to resolve settings not present in metadata.

Prefer a supplied digest, or resolve a published tag to a digest if authorized and possible. Do not silently change the requested release. Tags can move; the Deployment controller does not roll Pods just because a registry tag changed. `Always` resolves on container start, not continuously. `IfNotPresent` can reuse a cached tag. The API's default pull policy is set when an object is created and does not automatically change with later tag edits; set it deliberately.

## Public Docker Hub / public GHCR / other public registry

Anonymous pulling is normally enough. Public GitHub repository visibility does not prove GHCR package visibility. Check the package/image, not just the source repo. Consider anonymous rate limits and network reachability only when relevant; do not create credentials for every public image.

## Private GHCR

Git access, build/push access, and cluster image-pull access are separate credentials. A laptop `docker login`, `gh auth`, or a GitHub Actions `GITHUB_TOKEN` does not automatically authenticate a remote node.

Use the cluster's established mechanism if documented. Normally reference a Secret of type `kubernetes.io/dockerconfigjson` in the **same namespace as every consuming Pod**:

```yaml
# Pod spec, including Jobs/init containers through their parent Pod:
imagePullSecrets:
  - name: ghcr-pull
```

An existing Secret in `argocd` or `external-secrets` cannot be referenced across namespaces. ServiceAccount imagePullSecrets are another option; inspect rather than mutating a shared default ServiceAccount globally. Node-level registry credentials are possible but require infrastructure-managed configuration, not hidden SSH edits.

For GHCR, commonly use a dedicated read-only classic PAT with `read:packages`, access to the package, and SSO authorization if required by the organization. Consult current GitHub documentation for supported credential types; do not assume a GitHub App installation token or short-lived Actions token is suitable as a long-lived pull credential. Document expiration and rotation.

Prefer an ExternalSecret reading a preexisting SSM docker-config JSON. Example uses `v1beta1` only if the installed CRD serves it:

```yaml
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: ghcr-pull
  namespace: APP_NAME
spec:
  refreshInterval: 1h
  secretStoreRef:
    name: aws-parameter-store
    kind: ClusterSecretStore
  target:
    name: ghcr-pull
    creationPolicy: Owner
    template:
      engineVersion: v2
      type: kubernetes.io/dockerconfigjson
      data:
        .dockerconfigjson: '{{ .dockerconfig }}'
  data:
    - secretKey: dockerconfig
      remoteRef:
        key: /EXISTING_OR_PROVISIONED_PATH/ghcr/dockerconfigjson
```

The SSM value is valid Docker config JSON containing `auths.ghcr.io`, not a literal PAT placed under `.dockerconfigjson`. Store the value using a secure existing secret-management procedure, not in Git, output artifacts or command-line arguments. Verify generated Secret type and key names without displaying values. Missing parameter, package permissions or IAM access remain explicit blockers.

## Image only exists locally

Yes, registry-free deployment is possible, but a remote cluster cannot read a laptop's Docker image store.

Preferred for remote multi-node K3s: publish the already-built image to a reachable registry (private GHCR if desired), then deploy its immutable reference. This is distribution, not application creation. Ask before publishing if destination/visibility is unspecified.

Alternative for an explicit registry-free experiment:

1. Export the named image to an archive, preserving a unique reference and matching platform.
2. Distribute and import into **K3s's containerd/k8s.io image namespace**, on every schedulable node, or deliberately constrain scheduling to prepared nodes.
3. Verify the exact reference on each target node. Set `imagePullPolicy: Never` or `IfNotPresent`; `Always` still needs the registry to resolve the image.
4. Record how images are restored after node replacement and explain that Git alone cannot distribute the archive.

K3s supports image archives under `/var/lib/rancher/k3s/agent/images/`; live-import behavior varies by K3s release. Manual `k3s ctr -n k8s.io images import IMAGE.tar` is another node-side mechanism. Verify current K3s docs/version first. These are infrastructure/node mutations: do not execute SSH/import as a normal app-of-apps deployment. Supply the exact explicit opt-in procedure or an infra-managed path. Laptop Docker import and `kind load docker-image` do not load a remote K3s cluster.

Primary references:
- https://kubernetes.io/docs/concepts/containers/images/
- https://docs.github.com/en/packages/working-with-a-github-packages-registry/working-with-the-container-registry
- https://docs.k3s.io/import-images
- https://external-secrets.io/latest/guides/common-k8s-secret-types/
