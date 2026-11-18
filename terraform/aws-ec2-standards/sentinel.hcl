# Advisory until the results match real plans. Then raise to soft-mandatory, then
# hard-mandatory.
policy "aws-ec2-standards" {
  source            = "./aws-ec2-standards.sentinel"
  enforcement_level = "advisory"
}
