mock "tfplan/v2" {
  module {
    source = "testdata/mock-tfplan-test-name-tag-only-passes.sentinel"
  }
}

mock "tfrun" {
  module {
    source = "testdata/mock-tfrun-test.sentinel"
  }
}

test {
  rules = {
    main                    = true
    mandatory_instance_tags = true
    instance_type_allowed   = true
  }
}
