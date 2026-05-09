# ARTEMIS AGENT RUNTIME APPROVAL CHECKLIST

Before changing `decision_record.decision` from `pending`:

- Review `decision_record.decision`.
- Review `decision_record.decided_by`.
- Review `decision_record.decided_at`.
- Review `decision_record.reason`.
- Review `decision_record.approved_profile_id`.
- Review `decision_record.approved_runtime`.
- Review `decision_record.approved_command_surface`.
- Review `decision_record.approved_model_policy`.
- Review `decision_record.approved_budget`.
- Review `decision_record.approved_auth`.
- Review `decision_record.approved_workspace`.
- Review `decision_record.approved_rollback`.
- Review `decision_record.approved_validation`.
- Review `decision_record.approved_commands`.
- Confirm exact command(s), budget, auth, workspace, rollback and validation evidence.
- Confirm no remote write, secret, deploy or production action is bundled accidentally.
- Run the validation gate after editing the decision.
