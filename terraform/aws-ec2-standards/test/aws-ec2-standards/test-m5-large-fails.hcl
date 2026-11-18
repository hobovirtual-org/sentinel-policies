mock "tfplan/v2" {
  module {
    source = "testdata/mock-tfplan-test-m5-large-fails.sentinel"
  }
}

mock "tfrun" {
  module {
    source = "testdata/mock-tfrun-test.sentinel"
  }
}

test {
  rules = {
    main                    = false
    mandatory_instance_tags = true
    instance_type_allowed   = false
  }
}
