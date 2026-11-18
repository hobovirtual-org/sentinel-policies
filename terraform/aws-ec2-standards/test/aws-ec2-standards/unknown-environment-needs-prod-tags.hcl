mock "tfplan/v2" {
  module {
    source = "testdata/mock-tfplan-unknown-environment-needs-prod-tags.sentinel"
  }
}

mock "tfrun" {
  module {
    source = "testdata/mock-tfrun-unknown.sentinel"
  }
}

test {
  rules = {
    main                    = false
    mandatory_instance_tags = false
  }
}
