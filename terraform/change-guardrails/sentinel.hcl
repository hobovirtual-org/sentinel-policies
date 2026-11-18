# Advisory while the counts are compared with real plans. Raise to soft-mandatory, then
# hard-mandatory, per the rollout table in README.md.
policy "environment-change-guardrails" {
  source            = "./environment-change-guardrails.sentinel"
  enforcement_level = "advisory"
}
