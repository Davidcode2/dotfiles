---
name: github-actions-migration
description: Migrate application delivery pipelines from Jenkins to GitHub Actions in the Karcher app/platform/infrastructure model. Use this skill whenever the user wants to replace Jenkins, add GitHub Actions CI/CD, switch deployment branches, wire AWS OIDC roles for GitHub Actions, update namespace ECR access, or document a new trunk-based release flow, especially for Shopify and e-commerce applications that deploy through platform and infrastructure repos.
---

# GitHub Actions Migration

Use this skill to migrate an application from Jenkins to GitHub Actions without breaking the surrounding delivery model.

This skill is optimized for the Karcher multi-repo setup where one application usually spans:

- an app repo with source code and CI/CD workflow definitions
- a platform repo that stores per-environment Helm values consumed by ArgoCD
- an infrastructure repo that creates AWS IAM, ECR, SSM, DynamoDB, or related resources
- sometimes a cluster-config repo that maps namespace ECR pull permissions to the deployment role

## When to use

Use this skill whenever the user asks to:

- replace a Jenkins pipeline with GitHub Actions
- copy an existing GitHub Actions setup from a sibling application
- move from branch-per-environment Jenkins deploys to GitHub Actions deployments
- introduce trunk-based development with promotion branches like `stage` and `prod`
- create or wire AWS GitHub Actions OIDC roles
- replace legacy `ci-shopify` or similar shared CI roles with app-specific GitHub Actions roles
- update README or operational docs to describe the new branching and deployment workflow

Default to this skill when the app uses the app/platform/infra repo pattern, even if the user only mentions one repo at first.

## Operating model

Always examine the whole delivery chain before editing anything.

For a migration, inspect these areas first:

1. App repo: current Jenkinsfile, existing GitHub workflows, package/test/build scripts, branch layout.
2. Platform repo: environment branches, `envs/*/values.yaml`, image tag fields, environment naming.
3. Infrastructure repo: existing GitHub Actions IAM roles, OIDC trust, branch strategy, AWS account mapping.
4. Cluster-config repo if present: namespace `ecr_repo_role` or similar image pull access.
5. GitHub repo settings if accessible: secrets, org secrets, variables, rulesets, required checks.

Do not assume the migration is only an app-repo change.

## Core migration sequence

Follow this order unless the user explicitly wants something different:

1. Identify the current Jenkins branch-to-environment mapping.
2. Find a sibling repo that already uses the desired GitHub Actions pattern.
3. Decide the target branch model before writing workflows.
4. Add or confirm AWS GitHub Actions roles in infrastructure.
5. Update namespace ECR access if the cluster uses explicit `ecr_repo_role` wiring.
6. Add app repo CI workflow for pull requests.
7. Add app repo deploy workflow for deployment branches.
8. Choose the cross-repo authentication model deliberately, usually a fine-grained PAT for smaller apps.
9. Create deployment branches and align rulesets/required checks.
10. Document the new workflow in `README.md` or the appropriate operational doc.
11. Disable Jenkins only after GitHub Actions is proven.

## Branching strategy playbook

For trunk-based delivery, prefer this shape:

- `main`: integration branch, always production-ready, no direct deploy unless explicitly desired
- `stage`: deploy branch for the non-prod live environment
- `prod`: deploy branch for production
- `dev`: only if a real dev environment exists, or as a future placeholder

Default to `stage` rather than `test` for the non-prod deployment branch unless the user explicitly says the organization uses `test`.

This is usually the safest first step because it avoids a wide rename across:

- platform repo branch names
- `envs/stage` directories
- SSM parameter paths
- namespace names
- Terraform locals and state layout

## GitHub Actions workflow patterns

### CI workflow

Create a dedicated PR workflow that validates what must be true before promotion.

For Node/Shopify apps, the default checks are:

- `npm ci`
- `npm test`
- `npm run build`

Add `lint` only if the repo's lint command already works in CI. Do not force a large ESLint migration into a pipeline migration unless the user asks for it.

Include PR targets that match the repo's active promotion branches. If promotion PRs target `stage` or `prod`, CI should run there too so failures happen before merge, not after deployment starts.

### Deploy workflow

Deployment workflows usually:

1. run validation again on the deployment branch push
2. assume an AWS role through OIDC
3. log into ECR
4. build and push the Docker image
5. check out the platform repo
6. update the image tag in `values.yaml`
7. commit and push the platform repo change

Use deterministic image tags following the existing convention if one exists. In this environment the common format is:

`{env}_{7-char-git-sha}`

## AWS and infrastructure pattern

If the app does not yet have a dedicated GitHub Actions deployment role, add it in the infrastructure repo.

In the ecommerce pattern, these roles often live in files like:

- `envs/test/github-action-roles.tf`
- `envs/prod/github-action-roles.tf`

Do not assume the infrastructure repo uses the same branch names as the app repo. Some infra repos still promote via `test` and `prod` even when the app repo uses `stage` and `prod`.

Mirror the sibling app pattern:

- `application_name`
- `app_id`
- `app_prefix`
- application repo subjects
- infrastructure repo read/write subjects
- environment-specific branch restrictions for infra writes

The role name usually becomes something like:

`GitHubActionsApplication<AppName>`

Check whether the cluster-config repo also needs updates to namespace image pull permissions, for example:

- `ecr_repo_role = "arn:aws:iam::<account>:role/GitHubActionsApplication..."`

If the namespace still points at a legacy shared CI role, update it.

## Token and secret handling

For smaller apps, prefer a fine-grained PAT for cross-repo checkout and push operations.

In this organization, GitHub Apps are limited to a small number of installations and should be used selectively. Do not assume GitHub Apps are the default just because org-level app credentials exist.

Default guidance:

- smaller apps and simple app-to-platform update flows: use a fine-grained PAT stored in Actions secrets
- larger or more strategic shared automations: evaluate GitHub App usage deliberately

### Fine-grained PAT creation flow

If the user has not created a PAT yet, direct them to create a fine-grained personal access token in the GitHub web UI:

1. Open `Settings`.
2. Go to `Developer settings`.
3. Open `Personal access tokens`.
4. Open `Fine-grained tokens`.
5. Generate a new token.

Guide the user carefully through the important choices:

- choose the `karcher-digital` organization as the resource owner, not the user's personal GitHub account
- grant access only to the repository that needs cross-repo access, usually the platform repo paired with the app repo being migrated
- set repository permissions to `Contents: Read and write`
- expect manual approval by a GitHub admin before the token becomes usable

After approval, store the token in the appropriate GitHub Actions secret and use it only for the repo checkout and push steps that need cross-repo access.

When using a PAT:

- keep the scope as narrow as possible
- grant access only to the necessary repositories
- grant only the permissions needed for checkout and push
- follow enterprise PAT approval and expiration policies

If the repo has access to org-level GitHub App credentials such as:

- `vars.INTERNAL_REPOSITORY_ACCESS_APP_ID`
- `secrets.INTERNAL_REPOSITORY_ACCESS_PRIVATE_KEY`

do not switch to `actions/create-github-app-token` automatically. First confirm that the GitHub App is the intended pattern for that app and that it is installed on every target repository.

If a GitHub App token step fails with a 404 on an endpoint like:

- `GET /repos/<owner>/<repo>/installation`

the most likely reason is that the GitHub App is not installed on the target repository, or its installation scope does not include that repository.

## Action pinning and supply-chain hardening

Pin actions to immutable SHAs whenever possible.

At minimum, pin:

- `actions/checkout`
- `actions/setup-node`
- `aws-actions/configure-aws-credentials`
- `aws-actions/amazon-ecr-login`
- `docker/build-push-action`
- `docker/setup-buildx-action`
- `actions/create-github-app-token`
- helper actions like `mikefarah/yq`

Do not download executables with `curl` and run them with `sudo` in deployment jobs when a maintained GitHub Action already exists.

However, always check the repository's Actions policy before replacing a third-party action reference with a SHA-pinned one. A repo using `allowed_actions: selected` may allow only a tag-based pattern such as `mikefarah/yq@v4`. In that case, changing to a SHA can produce a workflow `startup_failure` before any jobs start.

When selected-actions policy is enabled:

- inspect the allowlist first
- match the allowed action reference form exactly for third-party actions
- keep SHA pinning where policy allows it, especially for GitHub-owned actions
- record the reason if a third-party action must remain tag-based to satisfy the allowlist

## Rulesets and required checks

After the workflows exist and branch names are settled, inspect the repo rulesets.

Typical adjustments:

- main branch checks should require the new GitHub Actions CI contexts rather than Jenkins
- promotion branches should require PR approval
- deployment branches should block deletion and force-pushes
- ruleset names should describe their real function

Use the actual check names reported by GitHub, not just workflow names. For example, a workflow named `CI` may publish a check context named `test` if that is the job name.

If deployment branch names change during migration, update the rulesets before deleting obsolete branches. Otherwise branch cleanup can be blocked by the old protection rules.

## What not to over-constrain

GitHub rulesets can protect target branches, but they do not cleanly express "only allow PRs from `main` into `stage` or `prod`".

For trunk-based development, recommend this order of strictness:

1. Start with process and documentation: feature branches merge to `main`, promotions go from `main` to `stage` and `prod`.
2. Protect `stage` and `prod` with PR-only merges plus approval.
3. Add a custom PR validation workflow later if the team really wants to enforce `head_ref == 'main'` for promotion PRs.

Avoid making the promotion path so rigid that emergency fixes become painful unless the user explicitly wants that tradeoff.

## Documentation update checklist

When the migration changes developer workflow, update the app README or equivalent doc.

Document at least:

- the new trunk-based model
- which branches are deploy branches
- which branch is the non-prod deployment branch, usually `stage`
- the expected promotion flow from feature branch to `main` and from `main` to deployment branches
- whether a `dev` environment exists yet

## Commit and PR workflow

When asked to commit:

- inspect recent commit messages first
- respect repo hooks unless the user explicitly asks to bypass them
- if a repo enforces ticket-prefixed commit messages and the user has not provided a ticket, ask for it unless they explicitly instruct `--no-verify`

When asked to create PRs:

- choose the correct base branch for each repo
- app repo migration PRs usually target `main`
- infra repos may still target `test` and `prod` depending on their own promotion model
- cluster-config or platform repos often target `main`

Do not assume the same base branch conventions apply to every related repo.

## Verification checklist

Before finishing, verify as many of these as possible:

- local tests pass
- local build passes
- workflow files read cleanly after edits
- app repo branch exists remotely
- deployment branches exist remotely
- rulesets were updated if requested and permitted
- PR checks started or passed
- infra and cluster-config changes are committed or clearly reported as pending

## Response format

When using this skill, respond in a compact migration-focused structure:

1. `Current state`: what the repo does today
2. `Required changes`: app, platform, infra, cluster-config, GitHub settings
3. `Implemented`: exact files/branches/PRs changed
4. `Verification`: tests, builds, runs, rulesets
5. `Open items`: secrets, AWS roles, branch protections, pending repo-specific blockers

## Practical cautions

- Do not rename `stage` to `test` across every repo as a first move unless the user explicitly wants a full environment rename.
- Do not assume repo-level secrets exist; check repo-visible org secrets and variables too.
- Do not change branch protections blindly before confirming the new check contexts.
- Do not disable Jenkins until GitHub Actions has run successfully on the intended branch flow.
- Do not introduce lint gates into CI if the repo's lint setup is already broken and unrelated to the migration request.
- Do not assume GitHub App auth is the preferred default for small apps.
- Do not assume GitHub App token generation will work just because the app ID and private key are visible; the app must be installed on the target repository.
- Do not assume SHA-pinned third-party actions will run in repos with selected-actions policy; the allowlist may require a tag-based reference.

## Example migration outcomes this skill supports well

- migrate a Shopify app from Jenkins to GitHub Actions using a sibling app as template
- add AWS OIDC deployment roles in shared infra
- update cluster namespace ECR role binding to the new GitHub Actions role
- create `stage` and `prod` deploy branches while keeping `main` as the trunk branch
- use fine-grained PAT-based cross-repo pushes for smaller apps
- use GitHub App token generation only when installation and organizational priority both justify it
- update README and rulesets to reflect the new release model
