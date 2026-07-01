---
name: view-x-post
description: Read X/Twitter status posts and X Articles. Use `npx curl.md` for public status URLs, and use chrome-devtools-mcp with the logged-in headed `x-for-ai` Chrome profile for x.com article URLs that require authentication. Trigger when the user asks to view, inspect, summarize, quote, verify, or extract content from x.com/twitter.com status or article URLs.
---

# View X Post

## Status Post Workflow

1. Fetch the post as Markdown:

```bash
npx curl.md "https://x.com/<handle>/status/<id>"
```

Use the URL the user provided. Do not install `curl.md` globally.

2. Verify the response is a real post page:

- Prefer the `## Post` section as the canonical source.
- Cross-check `title`, `description`, author name, handle, and status URL.
- Treat login/signup links, "Don't miss what's happening", and other X chrome as noise.
- If the Markdown contains only login/signup/chrome and no post body, report that the post was not readable through `curl.md`.

3. Extract only what is supported by the Markdown:

- Author display name and handle
- Post body text
- Timestamp
- View/reply/repost/like/bookmark counts when present
- Attached media links such as `/photo/1`, `/photo/2`, etc.

Do not infer image contents from `/photo/N` links. Say only that media is attached unless another tool has actually inspected the media.

4. When answering, keep source uncertainty explicit:

- Say that the content was read via `npx curl.md`.
- If `title`/`description` and `## Post` disagree, prefer `## Post` and mention the mismatch.
- If metrics are shown as bare numbers without labels, avoid over-labeling them unless the surrounding order is clear.

## X Article Workflow

Use chrome-devtools-mcp for `https://x.com/<handle>/article/<id>` URLs. `npx curl.md` usually returns only `url` and `site` for X Articles.

Use the headed Google Chrome profile named `x-for-ai`. Do not use headless mode for X Articles; measured attempts with headless did not preserve the logged-in X session reliably.

1. Open the article URL with chrome-devtools-mcp in the existing headed browser.

2. Verify the MCP browser is using the dedicated X profile:

- Open `chrome://version`.
- Confirm `Profile Path` is `/Users/lilpacy/Library/Application Support/Google/Chrome/Profile 16`.
- This is the Chrome profile named `x-for-ai`.
- If a different profile is attached, stop and ask the user to open or switch to the headed `x-for-ai` Chrome profile.

3. If X redirects to login:

- Bring the login tab to the front.
- Ask the user to log in in the browser window.
- Never ask for X credentials in chat and never type credentials yourself.
- Retry the article URL after the user confirms login.

4. Extract the article from the loaded page:

- Prefer `take_snapshot` first; X Articles expose title, author, headings, body text, metrics, and media links in the accessibility tree.
- If the snapshot is noisy, run `evaluate_script` and read `document.querySelector('main').innerText`.
- Keep media handling conservative: report image/video links or alt text shown by the page, but do not infer visual content without inspecting the media.

Example `evaluate_script` body:

```js
() => {
  const main = document.querySelector("main");
  const text = main ? main.innerText : document.body.innerText;
  return {
    title: document.title,
    url: location.href,
    text,
    headings: Array.from(document.querySelectorAll("h1,h2"))
      .map((heading) => heading.innerText)
      .filter(Boolean),
  };
}
```

5. If the MCP browser is not using `Profile 16`, stop and report that the headed `x-for-ai` profile is not attached. Do not continue with another profile for authenticated X content.

## Useful Commands

Fetch and save a temporary copy for inspection:

```bash
npx curl.md "https://x.com/<handle>/status/<id>" > /tmp/x-post.md
```

Search the fetched Markdown for the post area:

```bash
rg -n "^(title:|description:|## Post|@|[0-9:]+ [AP]M|[0-9]+\\.?[0-9]*[KM]?Views)" /tmp/x-post.md
```
