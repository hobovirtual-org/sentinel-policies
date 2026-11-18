mock "tfplan/v2" {
  module {
    source = "testdata/mock-tfplan-untagged-gets-dev-types.sentinel"
  }
}

mock "tfrun" {
  module {
    source = "testdata/mock-tfrun-untagged.sentinel"
  }
}

test {
  rules = {
    main                    = false
    mandatory_instance_tags = true
    instance_type_allowed   = false
  }
}
