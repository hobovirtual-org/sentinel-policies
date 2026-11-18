mock "tfplan/v2" {
  module {
    source = "testdata/mock-tfplan-prod-replaces-over-limit.sentinel"
  }
}

mock "tfrun" {
  module {
    source = "testdata/mock-tfrun-prod-replaces-over-limit.sentinel"
  }
}

test {
  rules = {
    main = false
  }
}
