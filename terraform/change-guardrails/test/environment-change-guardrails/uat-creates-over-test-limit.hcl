mock "tfplan/v2" {
  module {
    source = "testdata/mock-tfplan-uat-creates-over-test-limit.sentinel"
  }
}

mock "tfrun" {
  module {
    source = "testdata/mock-tfrun-uat-creates-over-test-limit.sentinel"
  }
}

test {
  rules = {
    main = false
  }
}
