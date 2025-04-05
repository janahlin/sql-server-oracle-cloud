config {
  plugin_dir = "~/.tflint.d/plugins"
}

plugin "terraform" {
  enabled = true
  preset  = "recommended"
}

# Rules that can be reasonably skipped
rule "terraform_comment_syntax" {
  enabled = false
}

rule "terraform_naming_convention" {
  enabled = false
}

rule "terraform_documented_variables" {
  enabled = true
}

rule "terraform_documented_outputs" {
  enabled = true
}

rule "terraform_module_pinned_source" {
  enabled = false
}

rule "terraform_workspace_remote" {
  enabled = false
}
