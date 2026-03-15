# Coding guidelines

Clean code
- descriptive names
- short functions (rarely more than 20 lines)
- short classes (rarely more than 200 lines)
- SRP (Single Responsibility Principle)

# Task Tracking with bd (beads)

Use bd for task/issue tracking in every repository. Tasks are stored in a Dolt database and synced to GitHub.

## Setup (One-time per repo)

```bash
cd <repo>
bd init
bd dolt remote add origin git+ssh://git@github.com/Davidcode2/$(basename $PWD).git
bd dolt push
```

## Daily Workflow

```bash
# Check ready work
bd ready

# Create new task
bd create "Task title" -p 1 -t task --description="Details here"

# Claim and work
bd update <id> --claim

# Complete
bd close <id> --reason "Done"

# Sync to GitHub
bd dolt push
```

## Multi-Machine Sync

```bash
# On new machine after git clone
cd <repo>
bd init
bd dolt pull
bd ready
```

## Key Commands

| Command | Purpose |
|---------|---------|
| `bd ready` | Show tasks with no blockers |
| `bd create "Title" -p 1` | Create P1 task |
| `bd update <id> --claim` | Claim task atomically |
| `bd close <id> --reason "X"` | Complete task |
| `bd dolt push` | Sync to GitHub |
| `bd dolt pull` | Get updates from GitHub |
| `bd show <id>` | View task details |
| `bd dep add <child> <parent>` | Link dependencies |

**Note:** Always run `bd dolt push` after creating/closing/updating tasks to sync with GitHub.

# Global Deployment Architecture

This document describes the high-level deployment structure across all repositories. For detailed implementation, see the specific repository AGENTS.md files.

## 🏗️ Three-Layer Architecture

```
┌─────────────────────────────────────────────────────────────┐
│  LAYER 3: Applications (Individual Repos)                   │
│  - Source code for each app                                 │
│  - GitHub Actions CI/CD workflows                           │
│  - Docker builds → GitHub Container Registry (GHCR)           │
│                                                             │
│  Examples: jakob-lingel, schluesselmomente, immoly, blog    │
└───────────────────────────────┬─────────────────────────────┘
                                │ Push images & update manifests
                                ▼
┌─────────────────────────────────────────────────────────────┐
│  LAYER 2: GitOps (app-of-apps Repo)                         │
│  - ArgoCD Application definitions                           │
│  - Kubernetes manifests (deployments, services, ingress)    │
│  - Helm charts for infrastructure                             │
│  - App-of-apps pattern: one root app creates all others       │
│                                                             │
│  Location: ~/documents/code/app-of-apps/                    │
└───────────────────────────────┬─────────────────────────────┘
                                │ ArgoCD syncs automatically
                                ▼
┌─────────────────────────────────────────────────────────────┐
│  LAYER 1: Infrastructure (infra Repo)                         │
│  - Terraform: Server provisioning (Hetzner Cloud)           │
│  - Ansible: K3s cluster configuration                         │
│  - DNS management                                             │
│                                                             │
│  Location: ~/documents/code/infra/                          │
└─────────────────────────────────────────────────────────────┘
```

## 🔄 Deployment Flow

### 1. Application Deployment (Developer Flow)
```
Code Push → GitHub Actions → Build Image → Update Manifest → ArgoCD Sync → K8s
```

**Key Points:**
- GitHub Actions in app repos (e.g., `jakob-lingel/.github/workflows/main.yml`)
- Reusable workflow: `build-and-push.yml` for Docker builds
- Automatically bumps version in `package.json`
- Updates image tag in app-of-apps repo via GitHub App token
- ArgoCD detects changes and syncs within ~3 minutes

### 2. Infrastructure Deployment (Ops Flow)
```
Terraform Apply → Provision Servers → Ansible Config → K3s Cluster Ready
```

**Key Points:**
- Terraform manages Hetzner Cloud resources
- Ansible configures K3s HA cluster (3 nodes)
- One-time setup, then GitOps takes over

## 🎯 Key Principles

**GitOps:** Git is the single source of truth. All changes flow through Git.

**Automated:** Push code → automatic build → automatic deploy. No manual kubectl.

**Self-Healing:** ArgoCD corrects drift. Deleted manifests = deleted resources.

**Immutable Infrastructure:** New deployments = new image tags. Old versions can be rolled back via Git.

## 📦 Repository Responsibilities

| Repository | Purpose | Location |
|------------|---------|----------|
| **infra** | Infrastructure as Code (Terraform + Ansible) | `~/documents/code/infra/` |
| **app-of-apps** | GitOps manifests (ArgoCD applications) | `~/documents/code/app-of-apps/` |
| **jakob-lingel** | Personal website (Next.js) | `~/documents/code/jakob-lingel/` |
| **schluesselmomente** | Client website | `~/documents/code/schluesselmomente/` |
| **immoly** | Real estate tool | `~/documents/code/immoly/` |
| **blog** | Ghost CMS blog | `~/documents/code/blog/` |

## 🌐 Cluster Setup

- **Provider:** Hetzner Cloud (Nuremberg)
- **Orchestrator:** K3s (lightweight Kubernetes)
- **Nodes:** 3 CX23 instances (4 vCPU, 8GB RAM each)
- **GitOps:** ArgoCD
- **Ingress:** nginx-ingress with cert-manager (Let's Encrypt)
- **Secrets:** External Secrets Operator (AWS Parameter Store)
- **Registry:** GitHub Container Registry (GHCR)

## 🔐 Secrets Management

**Never commit secrets to Git.**

1. **AWS Parameter Store:** Source of truth for application secrets
2. **External Secrets Operator:** Syncs AWS secrets to Kubernetes
3. **GitHub App Tokens:** Used by CI/CD for cross-repo access

## 📚 Further Reading

- **Infrastructure Details:** See `~/documents/code/infra/AGENTS.md`
- **GitOps Details:** See `~/documents/code/app-of-apps/AGENTS.md`
- **CI/CD Examples:** See `.github/workflows/` in any application repo
- **K8s Access:** `export KUBECONFIG=~/documents/code/infra/kubeconfig-<ip>.yaml`

## ⚡ Quick Commands

```bash
# Check ArgoCD apps
kubectl get applications -n argocd

# Force sync an app
argocd app sync <app-name>

# Check cluster nodes
kubectl get nodes

# View pod logs
kubectl logs -n <namespace> -l app=<app-name>
```

---

**Remember:** The flow is always Git → Build → Manifest Update → ArgoCD → Cluster. No direct cluster modifications.
