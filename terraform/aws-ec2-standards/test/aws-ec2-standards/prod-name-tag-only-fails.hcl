mock "tfplan/v2" {
  module {
    source = "testdata/mock-tfplan-prod-name-tag-only-fails.sentinel"
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
    mandatory_instance_tags = false
  }
}
