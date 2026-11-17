mock "tfplan/v2" {
  module {
    source = "testdata/mock-tfplan-dev-within-limits.sentinel"
  }
}

mock "tfrun" {
  module {
    source = "testdata/mock-tfrun-dev-within-limits.sentinel"
  }
}

test {
  rules = {
    main = true
  }
}
