# Registry Diff Preview

This is a dry-run preview. No registry file was modified.

## Proposed additions after future approval

```diff
+ registry.project veri_d55ae65706
+   display_name: veri
+   repo_root: /srv/veri
+   registry_state: registered_pending_selection_review
+   selection_state: not_selected
+   project_switching_allowed: false
+   runtime_execution_allowed: false
+ registry.audit registration_dry_run_prepared veri_d55ae65706
+ selector.entry veri_d55ae65706 not_selectable_until_post_registration_review
```

## Still blocked

- Registry write.
- Candidate registration.
- Project switching.
- Runtime execution.
- Provider auth.
- Remote mutation.
