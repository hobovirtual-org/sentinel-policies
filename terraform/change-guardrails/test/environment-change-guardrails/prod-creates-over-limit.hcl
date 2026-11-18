mock "tfplan/v2" {
  module {
    source = "testdata/mock-tfplan-prod-creates-over-limit.sentinel"
  }
}

mock "tfrun" {
  module {
    source = "testdata/mock-tfrun-prod-creates-over-limit.sentinel"
  }
}

test {
  rules = {
    main = false
  }
}
