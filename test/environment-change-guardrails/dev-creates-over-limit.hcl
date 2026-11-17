mock "tfplan/v2" {
  module {
    source = "testdata/mock-tfplan-dev-creates-over-limit.sentinel"
  }
}

mock "tfrun" {
  module {
    source = "testdata/mock-tfrun-dev-creates-over-limit.sentinel"
  }
}

test {
  rules = {
    main = false
  }
}
