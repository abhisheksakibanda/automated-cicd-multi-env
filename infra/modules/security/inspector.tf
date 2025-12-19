resource "aws_inspector2_enabler" "this" {
  account_ids   = ["self"]
  resource_types = ["EC2"]
}
