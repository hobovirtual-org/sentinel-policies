mock "tfplan/v2" {
  module {
    source = "testdata/mock-tfplan-dev-at-creates-limit.sentinel"
  }
}

mock "tfrun" {
  module {
    source = "testdata/mock-tfrun-dev-at-creates-limit.sentinel"
  }
}

test {
  rules = {
    main = true
  }
}
