mock "tfplan/v2" {
  module {
    source = "testdata/mock-tfplan-null-tags-fails.sentinel"
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
