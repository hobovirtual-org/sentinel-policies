mock "tfplan/v2" {
  module {
    source = "testdata/mock-tfplan-unknown-environment-gets-prod-limits.sentinel"
  }
}

mock "tfrun" {
  module {
    source = "testdata/mock-tfrun-unknown-environment-gets-prod-limits.sentinel"
  }
}

test {
  rules = {
    main = false
  }
}
