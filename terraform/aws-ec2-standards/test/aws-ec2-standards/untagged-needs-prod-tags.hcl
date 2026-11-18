mock "tfplan/v2" {
  module {
    source = "testdata/mock-tfplan-untagged-needs-prod-tags.sentinel"
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
    mandatory_instance_tags = false
  }
}
