mock "tfplan/v2" {
  module {
    source = "testdata/mock-tfplan-untagged-prod-tags-and-dev-type-pass.sentinel"
  }
}

mock "tfrun" {
  module {
    source = "testdata/mock-tfrun-untagged.sentinel"
  }
}

test {
  rules = {
    main                    = true
    mandatory_instance_tags = true
    instance_type_allowed   = true
  }
}
