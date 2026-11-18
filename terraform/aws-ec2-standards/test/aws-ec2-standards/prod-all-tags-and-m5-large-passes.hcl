mock "tfplan/v2" {
  module {
    source = "testdata/mock-tfplan-prod-all-tags-and-m5-large-passes.sentinel"
  }
}

mock "tfrun" {
  module {
    source = "testdata/mock-tfrun-prod.sentinel"
  }
}

test {
  rules = {
    main                    = true
    mandatory_instance_tags = true
    instance_type_allowed   = true
  }
}
