mock "tfplan/v2" {
  module {
    source = "testdata/mock-tfplan-untagged-gets-prod-limits.sentinel"
  }
}

mock "tfrun" {
  module {
    source = "testdata/mock-tfrun-untagged-gets-prod-limits.sentinel"
  }
}

test {
  rules = {
    main = false
  }
}
