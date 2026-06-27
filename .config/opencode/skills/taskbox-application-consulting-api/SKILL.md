---
name: taskbox-application-consulting-api
description: Create, prepare, and submit TaskBox Application Consulting requests through the authenticated request endpoint instead of driving the full UI. Use this whenever the user wants a new Application Consulting ticket in TaskBox, especially for GitHub repository creation, cloud app setup, or other DevSecOps-style requests, and prefer this skill over a fully UI-driven approach after the user has authenticated in a headed Playwright session.
---

# TaskBox Application Consulting API

Use this skill for TaskBox `Application Consulting` requests that live behind portal `97` and request type `4030`.

The main idea is simple:

- use headed Playwright only for user authentication and live form discovery
- extract the current form metadata from the embedded request iframe
- submit the request through the same authenticated `POST` the UI sends
- fall back to UI clicking only if the request format has changed or the direct submit fails

## When To Prefer This Skill

Prefer this skill over a full UI workflow when:

- the user wants to create an `Application Consulting` ticket
- the user is already logged into TaskBox in a Playwright browser
- the request can be represented as a normal form submission
- the goal is repeatable automation rather than one-off clicking

Typical examples:

- create a GitHub repo request through `Github Enterprise Cloud`
- create a cloud setup request through the same request type
- draft a request, preview values, and submit only after confirmation
- capture or refresh the live payload shape for later reuse

## Safety Rules

- Never ask the user to paste credentials into chat.
- Use headed Playwright so the user can authenticate directly in the browser.
- Do not submit until the user explicitly says to submit.
- Do not hardcode stale `atl_token` values.
- Do not assume Insight object IDs are permanent.
- If the direct `POST` fails, inspect the live form again before retrying.

## Known Request Metadata

Captured from a successful live submission on `2026-05-07`:

Reference artifact:

- `references/request-capture.md` contains the raw captured body from a successful repo-creation request.

- portal id: `97`
- request type id: `4030`
- form name: `Application Consulting`
- submit endpoint: `POST https://taskbox.karcher.com/servicedesk/customer/portal/97/create/4030`
- content type: `application/x-www-form-urlencoded`
- required business fields:
  - `summary`
  - `customfield_29904` (`Application Consulting`)
  - `description`
  - `customfield_20063` (`Organization`)
  - `customfield_20827` (`Cost Center`)

Observed default/supporting fields in the same request:

- `projectId=17103`
- `pid=17103`
- `customfield_19601` (`Request on behalf of`)
- `customfield_33300` (`TaskBox Project`)
- `customfield_14402` (`Share this request with`)
- `customfield_18201` (`Resolver Group`)
- duplicated `atl_token`
- `sd-kb-article-viewed=false`

## Live Discovery Workflow

### 1. Open an authenticated browser

Use `playwright-cli`.

Recommended flow:

- `playwright-cli -s=taskbox open "https://taskbox.karcher.com" --browser=chrome --persistent`
- `playwright-cli -s=taskbox show`
- wait for the user to finish login
- `playwright-cli -s=taskbox goto "https://taskbox.karcher.com/plugins/servlet/desk/portal/97/create/4030"`

The actual form lives in an iframe after the page loads.

### 2. Read the embedded request metadata

The inner iframe usually contains a `#jsonPayload` element with the live form definition.

Use Playwright code like this:

```js
async page => {
  const frame = page.frames().find(f => (f.url() || '').includes('/servicedesk/customer/portal/97/create/4030'))
  if (!frame) throw new Error('request form iframe not found')

  const payload = await frame.evaluate(() => JSON.parse(document.querySelector('#jsonPayload')?.textContent || '{}'))

  return {
    portalId: payload.portal?.id,
    projectId: payload.portal?.projectId,
    requestTypeId: payload.reqCreate?.id,
    formName: payload.reqCreate?.form?.name,
    fields: payload.reqCreate?.fields?.filter(f => f.displayed).map(f => ({
      label: f.label,
      fieldId: f.fieldId,
      fieldType: f.fieldType,
      required: f.required,
    })),
  }
}
```

Use that output as the source of truth if the request type changes.

### 3. Discover fresh object IDs

Do not rely on previously captured `ITSMRD-*` or `SH-*` IDs without checking the live form.

Use the live controls to select the needed objects and then read the hidden values.

Captured example mappings from one successful request:

- `customfield_29904=SH-629103` -> `Github Enterprise Cloud`
- `customfield_20063=ITSMRD-465157` -> `DE10 - AKW - Alfred Kärcher SE & Co. KG - Germany`
- `customfield_20827=ITSMRD-585439` -> `DE10 006240 WIN Digital Channel Products`
- `customfield_18201=ITSMRD-624682` -> default resolver group value, rendered later as `DevSecOps`

These are good examples, not permanent constants.

### 4. Read a fresh token and hidden defaults

Read the current form values directly from the iframe before submitting.

Useful selectors observed on the live form:

- `#summary`
- `#description`
- `#customfield_29904` and visible input `#react-select-3-input`
- `#customfield_20063` and visible input `#react-select-5-input`
- `#customfield_20827` and visible input `#react-select-4-input`
- `input[name="atl_token"]`

## Submit Strategy

### Preferred approach

Submit through the authenticated browser context using the same endpoint and `application/x-www-form-urlencoded` body the form uses.

This avoids brittle clicking while still reusing the browser's session cookies.

### Recommended sequence

1. authenticate in headed Playwright
2. open the live create form
3. discover `atl_token`, `projectId`, request type metadata, and current object IDs
4. build the form body
5. show the user a compact preview
6. submit only after explicit approval
7. return the created ticket URL and key

## Form Body Template

The live request was submitted as `application/x-www-form-urlencoded` with a body shaped like this:

```text
atl_token=<fresh-atl-token>
projectId=17103
customfield_19601=
summary=<urlencoded title>
customfield_29904=<Application Consulting object id>
customfield_33300=
customfield_31302=
customfield_31303=
customfield_10600=
customfield_29905=
customfield_18328=
customfield_11607=
customfield_31602=
customfield_18902=
customfield_22211=
customfield_29911=
customfield_28600=
description=<urlencoded multiline description>
customfield_20063=<organization object id>
customfield_20827=<cost center object id>
pid=17103
atl_token=<fresh-atl-token>
customfield_14402=
customfield_18201=<resolver group object id>
sd-kb-article-viewed=false
```

Keep the body aligned with the live form, even for empty fields.

## Example Playwright Submission

Use `run-code` so the request executes inside the authenticated page context:

```js
async page => {
  const frame = page.frames().find(f => (f.url() || '').includes('/servicedesk/customer/portal/97/create/4030'))
  if (!frame) throw new Error('request form iframe not found')

  const values = await frame.evaluate(() => {
    const read = sel => document.querySelector(sel)?.value || ''
    return {
      atlToken: read('input[name="atl_token"]'),
      projectId: read('input[name="projectId"]') || '17103',
      pid: read('input[name="pid"]') || '17103',
      resolverGroup: read('#customfield_18201'),
    }
  })

  const params = new URLSearchParams()
  params.set('atl_token', values.atlToken)
  params.set('projectId', values.projectId)
  params.set('customfield_19601', '')
  params.set('summary', 'Create GitHub repository for example-repo')
  params.set('customfield_29904', 'SH-629103')
  params.set('customfield_33300', '')
  params.set('customfield_31302', '')
  params.set('customfield_31303', '')
  params.set('customfield_10600', '')
  params.set('customfield_29905', '')
  params.set('customfield_18328', '')
  params.set('customfield_11607', '')
  params.set('customfield_31602', '')
  params.set('customfield_18902', '')
  params.set('customfield_22211', '')
  params.set('customfield_29911', '')
  params.set('customfield_28600', '')
  params.set('description', 'Dear Team,\n\nPlease create ...')
  params.set('customfield_20063', 'ITSMRD-465157')
  params.set('customfield_20827', 'ITSMRD-585439')
  params.set('pid', values.pid)
  params.append('atl_token', values.atlToken)
  params.set('customfield_14402', '')
  params.set('customfield_18201', values.resolverGroup)
  params.set('sd-kb-article-viewed', 'false')

  const response = await page.evaluate(async ({ body }) => {
    const res = await fetch('https://taskbox.karcher.com/servicedesk/customer/portal/97/create/4030', {
      method: 'POST',
      headers: {
        'x-requested-with': 'XMLHttpRequest',
        'content-type': 'application/x-www-form-urlencoded',
      },
      body,
      credentials: 'include',
    })

    return {
      status: res.status,
      url: res.url,
      text: await res.text(),
    }
  }, { body: params.toString() })

  return response
}
```

Replace object IDs with the values discovered from the live form in the current session.

## Success Detection

A successful submit was followed by:

- `POST https://taskbox.karcher.com/servicedesk/customer/portal/97/create/4030 => 200`
- `GET .../search/request?...issueKey=<ticket-key>`
- `GET .../rest/servicedeskapi/request/<ticket-key>?expand=serviceDesk...`

After submit, inspect the current page or returned HTML for the created request key and URL.

## Capturing The Request For Maintenance

If you need to refresh this skill because the form changed:

1. attach request/response listeners to the Playwright page
2. submit a known-good draft once
3. save the captured endpoint, headers, and form body
4. update this skill with any changed field ids or required parameters

This is better than guessing based on stale historical payloads.

## Repo Creation Guidance

For GitHub repo creation requests, the `Application Consulting` object should be `Github Enterprise Cloud`.

Strong title patterns:

- `Create GitHub repository for <repo-name>`
- `Create GitHub repositories for <project-name>`

Strong description pattern:

```text
Dear Team,

Please create a GitHub Enterprise Cloud repository for a new project.

Requested repository:

<repo-name>

Project context:

<short reason>

Please assign me as administrator.

Thank you.
```

## Output Format

When using this skill, return:

1. `Request type`
2. `Preview values`
3. `Submission method` (`api` or `ui fallback`)
4. `Execution result` (`prepared`, `submitted`, or `blocked`)
5. `Ticket URL`
6. `Ticket key`
7. `Notes` about any dynamic values refreshed from the live form

## Fallback Rule

If the direct authenticated `POST` stops working, do not keep retrying blindly.

Instead:

- reopen the form
- inspect `#jsonPayload`
- compare live field ids and defaults against this skill
- if needed, submit once through the form while recording the network call
- update the skill with the new payload shape
