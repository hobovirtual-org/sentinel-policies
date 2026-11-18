mock "tfplan/v2" {
  module {
    source = "testdata/mock-tfplan-noncompliant-update-fails.sentinel"
  }
}

mock "tfrun" {
  module {
    source = "testdata/mock-tfrun-dev.sentinel"
  }
}

test {
  rules = {
    main                    = false
    mandatory_instance_tags = false
  }
}
