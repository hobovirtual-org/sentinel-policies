mock "tfplan/v2" {
  module {
    source = "testdata/mock-tfplan-prod-type-outside-list-fails.sentinel"
  }
}

mock "tfrun" {
  module {
    source = "testdata/mock-tfrun-prod.sentinel"
  }
}

test {
  rules = {
    main                    = false
    mandatory_instance_tags = true
    instance_type_allowed   = false
  }
}
