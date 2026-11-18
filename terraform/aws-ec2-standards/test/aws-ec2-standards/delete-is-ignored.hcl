mock "tfplan/v2" {
  module {
    source = "testdata/mock-tfplan-delete-is-ignored.sentinel"
  }
}

mock "tfrun" {
  module {
    source = "testdata/mock-tfrun-dev.sentinel"
  }
}

test {
  rules = {
    main                    = true
    mandatory_instance_tags = true
    instance_type_allowed   = true
  }
}
