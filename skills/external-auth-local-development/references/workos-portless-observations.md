# WorkOS and Portless observations

These observations came from a local multi-worktree authentication investigation. Re-check the installed WorkOS tools and current official documentation before changing provider configuration.

## Verified observations

- The application's public origin and login callback URI were separate environment inputs. Both had to preserve the Portless scheme, hostname, and explicit port.
- The repository setup script already consumed the callback environment value to register a WorkOS redirect URI. Changing the environment value alone would not have registered it without that script.
- Inspection of WorkOS CLI `0.20.2` showed distinct operations for redirect URI registration and application homepage updates. This demonstrated that those provider resources are separate; it does not establish that every sign-out setting has the same automation surface.
- A missing local cookie-encryption secret caused AuthKit to fail before it generated an authorization URL. Presence/length-only diagnostics isolated this without printing the secret.
- Missing development-only secrets could be generated idempotently, persisted in an ignored local environment file, and covered by setup-script tests.
- Synchronizing one worktree's application homepage produced a successful login/logout round trip for that worktree.
- Independent review then identified a concurrency defect: the application homepage was a singleton provider setting, so a second worktree could replace the first worktree's fallback destination. The one-worktree success was therefore insufficient evidence for the intended parallel-worktree contract.

## Diagnostic consequence

For this provider combination, always distinguish:

1. callback redirect registration;
2. the application's explicit logout return value;
3. the provider's sign-out allowlist;
4. the provider's application homepage fallback;
5. CORS origin registration.

Capture the final SDK/HTTP values and provider-side registrations separately. Verify two concurrent local origins before declaring the setup complete.

## Deliberately not recorded as a solution

The session ended before the revised parallel-worktree sign-out configuration completed its final provider Dashboard and browser verification. Do not treat any unverified wildcard or undocumented management endpoint from that investigation as a recommended procedure.
