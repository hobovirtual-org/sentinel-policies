mock "tfplan/v2" {
  module {
    source = "testdata/mock-tfplan-prod-total-over-limit.sentinel"
  }
}

mock "tfrun" {
  module {
    source = "testdata/mock-tfrun-prod-total-over-limit.sentinel"
  }
}

test {
  rules = {
    main = false
  }
}
