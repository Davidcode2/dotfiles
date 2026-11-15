# Databases and persistence

Read for any stateful component, including SQLite, uploads, queues or embedded databases. Full support means reasoning about initialization, access, updates, backup/restore and deletion—not just attaching a PVC.

## Choose the state architecture

Establish database type/version, existing versus new instance, required extensions, app compatibility, storage size, acceptable downtime, backup expectations and retention. Prefer a documented existing managed database/operator where appropriate, but don't install a cluster-wide operator without scope. A simple dedicated single-instance database can fit a test/project; describe that it is not database HA even on a three-node control plane.

Choose:
- Deployment for stateless app instances or an intentionally simple single-instance database with a standalone PVC and explicit `Recreate`.
- StatefulSet when stable identity, ordered replacement or per-instance claim ownership is useful. Include a matching governing/headless Service when required. Multiple database StatefulSet replicas do not configure replication or failover automatically.
- An established database operator when operational requirements justify it and it is available; consult its current docs/API instead of inventing resources.

Single-writer apps (SQLite, embedded stores, some upload layouts) need one instance and no overlapping writers during rollout. A one-replica Deployment still surges by default. Choose `Recreate` or another reasoned no-overlap strategy; intentional downtime is better than corruption. StatefulSet identity is not fencing during forced deletion/node partitions. Don't recommend force-deleting a stateful Pod to bypass attachment safeguards.

## Storage contract

Inspect actual StorageClasses: provisioner, default flag, `volumeBindingMode`, topology, expansion, reclaim policy and CSI capabilities. Existing PVCs without `storageClassName` use default provisioning; this does not prove which class is installed. Don't invent a distributed storage class.

- `ReadWriteOnce` means writable from one **node**, not one Pod; it does not enforce application-level single-writer safety.
- `ReadWriteOncePod` can restrict to one Pod with supported CSI/version. Verify support before selecting it.
- `ReadWriteMany` requires suitable storage; it does not make SQLite/multiwriter behavior safe.
- K3s local-path volumes are node-local: a Pod can be rescheduled, but its data does not magically move. Node failure can make state unavailable or lose it. Topology/affinity may constrain placement.
- Network/block volumes can move subject to attachment/detachment and topology; RWO rollouts may hit Multi-Attach. Replicas alone don't solve this.
- `WaitForFirstConsumer` PVCs may remain Pending until a consuming Pod is scheduled. Putting the PVC in a wave that must become Bound before creating its consumer can deadlock; co-schedule or adjust ordering/health deliberately.
- Mount only documented data directories. Consider `PGDATA` subdirectories, ownership, `fsGroup`, initialization and filesystem artifacts at a volume root.
- Capacity requests need headroom for WAL, indexes, temp files and uploads. Expansion requires driver support and sometimes filesystem steps; shrinking is generally unsupported.

## Credentials and initialization

Keep databases internal behind ClusterIP; use service DNS, not a Pod IP. Separate app roles/databases from superuser access when supported. Match Secret keys to both database initialization env and app connection settings. URI credentials need correct escaping; don't concatenate arbitrary passwords into a connection URL unsafely.

Official database env/init scripts commonly apply only to an **empty data directory**. Changing a Secret does not update an existing database user's password. Plan SQL-level rotation and app rollout together. Reusing an existing PVC can carry old credentials/schema even if all manifests are new.

## Migrations and ArgoCD ordering

Use the image's documented command, correct credentials, concurrency protection and a bounded Job with appropriate `backoffLimit`, `activeDeadlineSeconds`, resources and image pull credentials.

A first-install-safe sequence inside a single Application is:
1. Namespace/ExternalSecrets (wait for materialized Secret), config, PVC and database Service/workload.
2. Database ready for the actual migration connection.
3. **Sync-phase** migration Job/hook in a later wave; wait for successful completion.
4. Application rollout in a subsequent wave.

Use `argocd.argoproj.io/hook: Sync` with a later sync wave when appropriate, and `BeforeHookCreation` for a deliberately rerunnable hook. Explain whether it runs every sync, per image version, or only on first install. Hooks don't run during selective sync; don't use selective sync to bypass required migrations. Keep useful failure logs and avoid infinite retries. An immutable normal Job needs a versioned name or deliberate replacement policy.

`PreSync` runs before normal Sync resources: it cannot bootstrap against a Secret/database/PVC created only in that Sync. Parent app waves also don't automatically await child app health; check ArgoCD health customization or stage prerequisite changes separately. Don't place app migrations after app readiness if the app cannot become ready until migrations finish.

For updates consider old/new app schema compatibility, migration locks and downgrade compatibility. A Git revert restores manifests, not database contents; irreversible migrations can make image rollback unsafe.

## Backup and restore

For valuable data, define RPO/RTO and a concrete mechanism: engine-aware logical/physical backups or an existing operator's mechanism, plus upload/file backups. Include destination, schedule, retention, credentials and a restore procedure. A CronJob should have concurrency behavior, timeouts and failure visibility; don't leave backups only on the same PVC/node. Snapshots require installed snapshot support and consistency coordination; a raw live-volume copy may not be a valid database backup.

For a disposable demo, explicitly describe data as disposable rather than inventing backup infrastructure. For a real tool with unspecified backup destination, ask or leave a precise blocker; don't claim durable operations from a PVC alone. Validate restoration to separate storage before relying on backups. Don't run destructive restore tests on the user's live data.

## Retention and teardown

Resolve whether uninstall retains or deletes state before enabling automated pruning/cascading finalizers.

- ArgoCD pruning a standalone PVC can delete it. PV reclaim policy `Delete` can then delete backend storage; `Retain` leaves data needing manual lifecycle management.
- PVC annotations such as `argocd.argoproj.io/sync-options: Prune=false,Delete=false` can protect against Argo resource prune/application deletion when supported. They do **not** protect against Kubernetes Namespace deletion, explicit PVC deletion or underlying storage loss.
- A managed Namespace plus a cascading Application finalizer can destroy namespaced retained data despite PVC-level settings. Keep the namespace deliberately outside the deleted app's cascade or retain/transfer its ownership before removal.
- StatefulSet `persistentVolumeClaimRetentionPolicy` is separate from Argo ownership, namespace deletion and PV reclaim policy. Inspect actual settings and Kubernetes version; do not assume retention covers every deletion route.
- Removing an Application without a finalizer may leave all workloads running. Retain data intentionally while removing compute and exposure through a staged Git change, not accidental orphaning.

For “remove app, keep data”: inventory owners/claims/volume policies, establish retained namespace/PVC ownership, remove app workloads/Ingress/Service through Git, verify retained state and stopped compute, then remove the child Application if appropriate. Preserve shared certificate/DNS/secrets unless actually owned exclusively by this app. Don't delete the source application repository.

Sources:
- https://kubernetes.io/docs/concepts/storage/persistent-volumes/
- https://kubernetes.io/docs/concepts/storage/storage-classes/
- https://kubernetes.io/docs/concepts/workloads/controllers/statefulset/
- https://argo-cd.readthedocs.io/en/stable/user-guide/sync-waves/
- https://argo-cd.readthedocs.io/en/stable/user-guide/resource_hooks/
- https://argo-cd.readthedocs.io/en/stable/user-guide/sync-options/
