# Create Contact Form

Guide for adding a contact form to a website using the message-router infrastructure.

## Overview

The message-router is a centralized multi-tenant form submission service that handles contact forms for all websites in the cluster. It provides:

- **Single API endpoint** for all contact forms (`https://notifications.jakob-lingel.dev/v1/submit`)
- **API key authentication** for security
- **Honeypot spam protection** via hidden `_website` field
- **Rate limiting** (5 submissions/hour per IP)
- **CORS origin validation** per site
- **Email delivery** via Resend

## Prerequisites

Before adding a contact form to a new website, ensure:

1. **message-router is deployed** in the Kubernetes cluster (namespace: `message-router`)
2. **External Secrets Operator** is running and configured
3. **AWS Parameter Store** access is configured
4. **Resend API key** is set up in the message-router secrets
5. **DNS records** point `notifications.jakob-lingel.dev` to the cluster

Verify the infrastructure:

```bash
# Check message-router is running
kubectl get pods -n message-router

# Check External Secrets Operator
kubectl get pods -n external-secrets

# Check the external secret exists
kubectl get externalsecret -n message-router
```

## Phase 1: Infrastructure Setup (Terraform)

### Step 1.1: Add App to app_patterns

Edit `~/documents/code/infra/terraform/locals.tf` and add your site to the `app_patterns` map:

```hcl
app_patterns = {
  # ... existing apps ...
  your_site_name = "your-site-name"
}
```

**Naming convention:** Use lowercase with underscores in Terraform (`your_site_name`), the actual SSM paths use hyphens (`your-site-name`).

### Step 1.2: Create SSM Parameter for Recipient Email

Add a new AWS SSM parameter in `~/documents/code/infra/terraform/projects/ssm.tf`:

```hcl
#################
# your-site-name #
#################
resource "aws_ssm_parameter" "your_site_name_notifications_recipient_email_address" {
  name        = "/your-site-name/notifications/recipient_email_address"
  description = "Notification recipient email address for your-site-name"
  type        = "SecureString"
  value       = "dummy"
  lifecycle {
    ignore_changes = [value]
  }
}
```

**Parameter naming convention:** `/{site-id}/notifications/recipient_email_address`

### Step 1.3: Commit and Apply Terraform

```bash
cd ~/documents/code/infra
git add terraform/locals.tf terraform/projects/ssm.tf
git commit -m "feat: Add your-site-name contact form infrastructure

- Add app pattern to locals.tf
- Create SSM parameter for recipient email

Refs: bd-<task-id>"
git push
```

**⚠️ Human supervision required:** A human must run `terraform apply` to update IAM permissions:

```bash
cd ~/documents/code/infra/terraform
terraform apply -target=aws_iam_role_policy.ci-policy
```

### Step 1.4: Set Real Email Value in AWS Console

After terraform apply completes:

1. Open AWS Systems Manager Console
2. Navigate to Parameter Store
3. Find `/your-site-name/notifications/recipient_email_address`
4. Edit and set the real recipient email address

## Phase 2: Kubernetes Configuration (External Secrets)

### Step 2.1: Update message-router-sites-external-secret.yaml

Edit `~/documents/code/app-of-apps/external-secrets/message-router-sites-external-secret.yaml`:

Add your site to the `sites.json` template in the data section:

```yaml
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: message-router-sites-external-secret
  namespace: message-router
spec:
  refreshInterval: 6h
  secretStoreRef:
    name: aws-parameter-store
    kind: ClusterSecretStore
  target:
    name: message-router-sites-secret
    creationPolicy: Owner
    deletionPolicy: Delete
    template:
      type: Opaque
      data:
        sites.json: |
          {
            # ... existing sites ...
            "your-site-name": {
              "recipient": "{{ .your_site_recipient_email }}",
              "subject": "New Contact Form Submission - Your Site Name",
              "allowed_origins": ["https://your-domain.com", "https://www.your-domain.com", "http://localhost:3000", "http://localhost:4321"]
            }
          }
  data:
    # ... existing data entries ...
    - secretKey: your_site_recipient_email
      remoteRef:
        key: /your-site-name/notifications/recipient_email_address
```

**Important:**

- The `site_id` in the JSON (e.g., `your-site-name`) must match the key you use in the frontend form
- Template syntax for referencing secrets: `{{ .secret_key_name }}`
- `allowed_origins` must include all domains where the form will be hosted (including localhost for development)

### Step 2.2: Commit and Push

```bash
cd ~/documents/code/app-of-apps
git add external-secrets/message-router-sites-external-secret.yaml
git commit -m "feat: Add your-site-name to message-router

- Add site configuration to sites.json
- Add SSM parameter reference for recipient email

Refs: bd-<task-id>"
git push
```

ArgoCD will automatically sync the changes within ~3 minutes.

### Step 2.3: Verify ExternalSecret Sync

**Option A: Using kubectl (if available):**

```bash
# Check the secret was created
kubectl get secret message-router-sites-secret -n message-router

# Verify the sites.json content
kubectl get secret message-router-sites-secret -n message-router -o jsonpath='{.data.sites\.json}' | base64 -d
```

**Option B: Using ArgoCD UI (preferred):**

1. Navigate to the `message-router` application in ArgoCD
2. Find the `message-router-sites-secret` in the resource tree
3. Click on it to view the decoded `sites.json` content
4. Verify your site's `recipient` field shows the actual email, not "dummy"

### Step 2.4: Restart message-router (IMPORTANT)

**⚠️ Critical:** After updating the ExternalSecret with a new email value, you **MUST restart the message-router pod** to pick up the changes.

**Why?** The message-router watches the config file for changes, but Kubernetes secret updates don't always trigger filesystem events reliably. The safest approach is a restart.

**Using ArgoCD:**

1. Go to the `message-router` application
2. Find the `message-router` Deployment
3. Click "Restart" on the deployment, OR delete the pod (it will be recreated)

**Using kubectl (if available):**

```bash
# Restart the deployment
kubectl rollout restart deployment/message-router -n message-router

# Or delete the pod (it will be recreated)
kubectl delete pods -n message-router -l app=message-router
```

**Verification:** After restart, check the message-router logs to confirm it loaded the new configuration:

```bash
kubectl logs -n message-router -l app=message-router --tail=20
```

You should see: `Loaded configuration for X sites`

## Phase 3: Frontend Implementation

### Step 3.1: Create Contact Form Component

Create a contact form component based on the pattern from `business-website`. Here's a minimal example:

**For Astro projects (Contact.astro):**

```astro
---
// Contact.astro
interface Props {
  siteId?: string;
  locale?: string;
}

const { siteId = 'your-site-name', locale = 'de' } = Astro.props;
---

<section id="contact">
  <form name="contact" id="contact-form">
    <!-- Hidden site_id field (must match sites.json key) -->
    <input type="hidden" name="site_id" value={siteId} />

    <!-- Honeypot field (hidden from humans, traps bots) -->
    <p class="hidden">
      <label>Don't fill this out if you're human:
        <input name="_website" tabindex="-1" autocomplete="off" />
      </label>
    </p>

    <!-- Name Field -->
    <div>
      <label for="name">Name *</label>
      <input type="text" id="name" name="name" required />
    </div>

    <!-- Email Field -->
    <div>
      <label for="email">Email *</label>
      <input type="email" id="email" name="email" required />
    </div>

    <!-- Message Field -->
    <div>
      <label for="message">Message *</label>
      <textarea id="message" name="message" rows="5" required></textarea>
    </div>

    <!-- Success/Error Messages -->
    <div id="form-success" class="hidden">
      <p>Thank you! Your message has been sent.</p>
    </div>
    <div id="form-error" class="hidden">
      <p id="error-message">An error occurred. Please try again.</p>
    </div>

    <!-- Submit Button -->
    <button type="submit" id="submit-btn">
      <span id="btn-text">Send Message</span>
      <span id="btn-loading" class="hidden">Sending...</span>
    </button>
  </form>
</section>

<script>
  const form = document.getElementById('contact-form');
  const submitBtn = document.getElementById('submit-btn');
  const btnText = document.getElementById('btn-text');
  const btnLoading = document.getElementById('btn-loading');
  const successMsg = document.getElementById('form-success');
  const errorMsg = document.getElementById('form-error');
  const errorText = document.getElementById('error-message');

  // Environment variables (set in .env file)
  const API_URL = import.meta.env.PUBLIC_MESSAGE_ROUTER_URL || 'https://notifications.jakob-lingel.dev/v1/submit';
  const API_KEY = import.meta.env.PUBLIC_MESSAGE_ROUTER_API_KEY || '';

  form?.addEventListener('submit', async (e) => {
    e.preventDefault();

    // Reset messages
    successMsg?.classList.add('hidden');
    errorMsg?.classList.add('hidden');

    // Show loading state
    if (submitBtn) submitBtn.disabled = true;
    btnText?.classList.add('hidden');
    btnLoading?.classList.remove('hidden');

    try {
      const formData = new FormData(form as HTMLFormElement);
      const data = Object.fromEntries(formData);

      // Check honeypot - if filled, silently succeed (bot trap)
      if (data._website) {
        console.log('Honeypot triggered');
        successMsg?.classList.remove('hidden');
        (form as HTMLFormElement).reset();
        return;
      }

      const response = await fetch(API_URL, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': API_KEY,  // Required API key header
        },
        body: JSON.stringify({
          site_id: data.site_id,
          name: data.name,
          email: data.email,
          message: data.message,
        }),
      });

      if (!response.ok) {
        const errorData = await response.json().catch(() => ({}));
        throw new Error(errorData.message || `HTTP ${response.status}`);
      }

      const result = await response.json();

      if (result.success) {
        successMsg?.classList.remove('hidden');
        (form as HTMLFormElement).reset();
      } else {
        throw new Error(result.message || 'Unknown error');
      }
    } catch (error) {
      console.error('Form submission error:', error);
      if (errorText) {
        errorText.textContent = (error as Error).message || 'An error occurred. Please try again later.';
      }
      errorMsg?.classList.remove('hidden');
    } finally {
      // Hide loading state
      if (submitBtn) submitBtn.disabled = false;
      btnText?.classList.remove('hidden');
      btnLoading?.classList.add('hidden');
    }
  });
</script>
```

**For React projects (ContactForm.tsx):**

```tsx
import { useState } from "react";

const API_URL =
  import.meta.env.PUBLIC_MESSAGE_ROUTER_URL ||
  "https://notifications.jakob-lingel.dev/v1/submit";
const API_KEY = import.meta.env.PUBLIC_MESSAGE_ROUTER_API_KEY || "";

interface ContactFormProps {
  siteId?: string;
}

export function ContactForm({ siteId = "your-site-name" }: ContactFormProps) {
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [status, setStatus] = useState<"idle" | "success" | "error">("idle");
  const [errorMessage, setErrorMessage] = useState("");

  const handleSubmit = async (e: React.FormEvent<HTMLFormElement>) => {
    e.preventDefault();
    setIsSubmitting(true);
    setStatus("idle");

    const formData = new FormData(e.currentTarget);
    const data = Object.fromEntries(formData);

    // Honeypot check
    if (data._website) {
      setStatus("success");
      e.currentTarget.reset();
      setIsSubmitting(false);
      return;
    }

    try {
      const response = await fetch(API_URL, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "x-api-key": API_KEY,
        },
        body: JSON.stringify({
          site_id: data.site_id,
          name: data.name,
          email: data.email,
          message: data.message,
        }),
      });

      if (!response.ok) {
        const errorData = await response.json().catch(() => ({}));
        throw new Error(errorData.message || `HTTP ${response.status}`);
      }

      const result = await response.json();

      if (result.success) {
        setStatus("success");
        e.currentTarget.reset();
      } else {
        throw new Error(result.message || "Unknown error");
      }
    } catch (error) {
      setStatus("error");
      setErrorMessage(
        (error as Error).message || "An error occurred. Please try again.",
      );
    } finally {
      setIsSubmitting(false);
    }
  };

  return (
    <form onSubmit={handleSubmit}>
      <input type="hidden" name="site_id" value={siteId} />

      {/* Honeypot */}
      <div style={{ display: "none" }}>
        <label>
          Don't fill this out:{" "}
          <input name="_website" tabIndex={-1} autoComplete="off" />
        </label>
      </div>

      <div>
        <label htmlFor="name">Name *</label>
        <input type="text" id="name" name="name" required />
      </div>

      <div>
        <label htmlFor="email">Email *</label>
        <input type="email" id="email" name="email" required />
      </div>

      <div>
        <label htmlFor="message">Message *</label>
        <textarea id="message" name="message" rows={5} required />
      </div>

      {status === "success" && <p>Thank you! Your message has been sent.</p>}
      {status === "error" && <p>Error: {errorMessage}</p>}

      <button type="submit" disabled={isSubmitting}>
        {isSubmitting ? "Sending..." : "Send Message"}
      </button>
    </form>
  );
}
```

### Step 3.2: Required Form Fields

The message-router requires these fields:

| Field         | Required | Description                                               |
| ------------- | -------- | --------------------------------------------------------- |
| `site_id`     | Yes      | Must match the key in sites.json (e.g., `your-site-name`) |
| `name`        | Yes      | Sender's name                                             |
| `email`       | Yes      | Sender's email address                                    |
| `message`     | Yes      | The message content                                       |
| `_website`    | No       | Honeypot field - if filled, request is silently dropped   |
| `subject`     | No       | Override default subject line                             |
| `success_url` | No       | URL to redirect to on success (for non-AJAX forms)        |
| `error_url`   | No       | URL to redirect to on error (for non-AJAX forms)          |

### Step 3.3: Environment Variables

Create or update `.env` file in your project root for local development:

```env
# Message Router Configuration
PUBLIC_MESSAGE_ROUTER_URL=https://notifications.jakob-lingel.dev/v1/submit
PUBLIC_MESSAGE_ROUTER_API_KEY=hKIyrwchSilSPF0Ifdrd3fTr2N9zCwMS
```

**For Production Deployment:**

Pass the values directly as build arguments in your GitHub Actions workflow:

**Update your `.github/workflows/main.yml`:**

```yaml
build-and-push:
  uses: ./.github/workflows/build-and-push.yml
  needs: bump-version
  with:
    image_name: ghcr.io/${{ github.repository }}
    dockerfile: dockerfile
    ref: ${{ needs.bump-version.outputs.sha }}
    build_args: |
      PUBLIC_MESSAGE_ROUTER_URL=https://notifications.jakob-lingel.dev/v1/submit
      PUBLIC_MESSAGE_ROUTER_API_KEY=hKIyrwchSilSPF0Ifdrd3fTr2N9zCwMS
  secrets: inherit
```

**Why hardcode values?** The API key and URL are not sensitive enough to warrant GitHub Secrets for this use case, and this approach is simpler to maintain.

## Phase 4: Configuration Details

### sites.json Fields Explained

Each site entry in the sites.json template has three fields:

```json
{
  "your-site-name": {
    "recipient": "{{ .your_site_recipient_email }}",
    "subject": "New Contact Form Submission",
    "allowed_origins": ["https://your-domain.com", "http://localhost:3000"]
  }
}
```

**Field descriptions:**

| Field             | Description                               | Example                                         |
| ----------------- | ----------------------------------------- | ----------------------------------------------- |
| `recipient`       | Email address to receive form submissions | `contact@your-domain.com`                       |
| `subject`         | Default subject line for emails           | `"New Contact Form Submission"`                 |
| `allowed_origins` | Array of allowed CORS origins             | `["https://site.com", "http://localhost:3000"]` |

**CORS Origin Rules:**

- Must include exact protocol (`https://` or `http://`)
- Must include exact domain (no wildcards)
- Must include `www.` subdomain separately if used
- Should include localhost ports for development

### Template Syntax

In the ExternalSecret template, use Go template syntax to reference SSM parameters:

```yaml
data:
  sites.json: |
    {
      "your-site-name": {
        "recipient": "{{ .your_site_recipient_email }}",
        ...
      }
    }
```

The `secretKey` in the `data` section maps SSM parameters to template variables:

```yaml
data:
  - secretKey: your_site_recipient_email # Template variable name
    remoteRef:
      key: /your-site-name/notifications/recipient_email_address # SSM parameter path
```

## Phase 5: Testing & Verification

### Step 5.1: Verify SSM Parameter

```bash
# Check parameter exists
aws ssm get-parameter --name "/your-site-name/notifications/recipient_email_address" --with-decryption

# Should return the parameter with the real email value
```

### Step 5.2: Verify ExternalSecret Sync

```bash
# Check the ExternalSecret status
kubectl describe externalsecret message-router-sites-external-secret -n message-router

# Check the secret was created/updated
kubectl get secret message-router-sites-secret -n message-router -o yaml

# View the sites.json content
kubectl get secret message-router-sites-secret -n message-router -o jsonpath='{.data.sites\.json}' | base64 -d | jq .
```

### Step 5.3: Test Form Locally

1. Set environment variables in `.env`:

   ```env
   PUBLIC_MESSAGE_ROUTER_URL=https://notifications.jakob-lingel.dev/v1/submit
   PUBLIC_MESSAGE_ROUTER_API_KEY=your-api-key
   ```

2. Start development server:

   ```bash
   npm run dev
   ```

3. Open the contact form and submit a test message

4. Check browser DevTools Network tab:
   - Request URL should be `https://notifications.jakob-lingel.dev/v1/submit`
   - Status should be `200 OK`
   - Response should show `{"success": true}`

### Step 5.4: Test in Production

1. Deploy the website with the contact form
2. Submit a test message from the production domain
3. Verify the email is received by the configured recipient
4. Check message-router logs if issues occur:
   ```bash
   kubectl logs -n message-router -l app=message-router --tail=50
   ```

### Step 5.5: Test Honeypot

To verify spam protection:

1. Use browser DevTools to remove `hidden` class from the honeypot field
2. Fill in the `_website` field
3. Submit the form
4. The form should appear to succeed but no email should be sent

## Phase 6: Example Walkthrough

Complete example adding a contact form to `mimis-kreativstudio.de`:

### 1. Terraform - Add to locals.tf

```hcl
# infra/terraform/locals.tf
app_patterns = {
  # ... existing apps ...
  mimis_kreativstudio = "mimis-kreativstudio"
}
```

### 2. Terraform - Create SSM Parameter

```hcl
# infra/terraform/projects/ssm.tf
resource "aws_ssm_parameter" "mimis_kreativstudio_notifications_recipient_email_address" {
  name        = "/mimis-kreativstudio/notifications/recipient_email_address"
  description = "Notification recipient email address for mimis-kreativstudio"
  type        = "SecureString"
  value       = "dummy"
  lifecycle {
    ignore_changes = [value]
  }
}
```

### 3. Terraform - Apply

```bash
cd ~/documents/code/infra
git add .
git commit -m "feat: Add mimis-kreativstudio contact form infrastructure"
git push

# Human runs:
terraform apply -target=aws_iam_role_policy.ci-policy
```

Then set the real email in AWS Console: `mimi@example.com`

### 4. Kubernetes - Update ExternalSecret

```yaml
# app-of-apps/external-secrets/message-router-sites-external-secret.yaml
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: message-router-sites-external-secret
  namespace: message-router
spec:
  # ... spec ...
  target:
    template:
      data:
        sites.json: |
          {
            "mimis-kreativstudio": {
              "recipient": "{{ .mimis_recipient_email }}",
              "subject": "Neue Anfrage für Mimi's Kreativstudio",
              "allowed_origins": ["https://mimis-kreativstudio.de", "https://www.mimis-kreativstudio.de"]
            }
          }
  data:
    - secretKey: mimis_recipient_email
      remoteRef:
        key: /mimis-kreativstudio/notifications/recipient_email_address
```

### 5. Frontend - Create Contact Form

Create `src/components/Contact.astro` with hidden `site_id="mimis-kreativstudio"` field.

### 6. Test

- Verify SSM parameter: `/mimis-kreativstudio/notifications/recipient_email_address`
- Check secret sync: `kubectl get secret message-router-sites-secret -n message-router`
- Test form submission on https://mimis-kreativstudio.de
- Confirm email received at mimi@example.com

## Troubleshooting

### Form submission fails with 403

**Cause:** CORS origin not in allowed_origins

**Fix:** Add the domain to the `allowed_origins` array in the ExternalSecret template

### Form submission fails with 401

**Cause:** Missing or incorrect API key

**Fix:**

1. Verify `PUBLIC_MESSAGE_ROUTER_API_KEY` is set correctly
2. Check the API key in message-router secrets:
   ```bash
   kubectl get secret message-router-secrets -n message-router -o jsonpath='{.data.api_key}' | base64 -d
   ```

### Emails not being received

**Check:**

1. Verify SSM parameter has correct email address (not "dummy")
2. **Restart message-router pod** after updating the secret (see Step 2.4)
3. Check message-router logs: `kubectl logs -n message-router -l app=message-router`
4. Verify Resend API key is valid
5. Check spam folders

### Error: "Invalid `to` field" from Resend

**Cause:** The recipient email address is invalid or still set to "dummy"

**Fix:**

1. Check AWS SSM Parameter Store to confirm the value is a valid email (not "dummy")
2. Verify the ExternalSecret synced the correct value to the Kubernetes secret
3. **Restart message-router pod** (the old config may be cached)
4. Check message-router logs to see what email it's trying to send to

### ExternalSecret not syncing

```bash
# Check status
kubectl describe externalsecret message-router-sites-external-secret -n message-router

# Force refresh
kubectl delete externalsecret message-router-sites-external-secret -n message-router
# ArgoCD will recreate it
```

## Reference

- **message-router repo:** `~/documents/code/message-router/`
- **Example contact form:** `~/documents/code/business-website/src/components/Contact.astro`
- **ExternalSecret definition:** `~/documents/code/app-of-apps/external-secrets/message-router-sites-external-secret.yaml`
- **API endpoint:** `https://notifications.jakob-lingel.dev/v1/submit`
