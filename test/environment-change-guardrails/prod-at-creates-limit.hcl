mock "tfplan/v2" {
  module {
    source = "testdata/mock-tfplan-prod-at-creates-limit.sentinel"
  }
}

mock "tfrun" {
  module {
    source = "testdata/mock-tfrun-prod-at-creates-limit.sentinel"
  }
}

test {
  rules = {
    main = true
  }
}
