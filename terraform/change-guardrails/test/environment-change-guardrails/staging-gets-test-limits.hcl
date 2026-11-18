mock "tfplan/v2" {
  module {
    source = "testdata/mock-tfplan-staging-gets-test-limits.sentinel"
  }
}

mock "tfrun" {
  module {
    source = "testdata/mock-tfrun-staging-gets-test-limits.sentinel"
  }
}

test {
  rules = {
    main = true
  }
}
