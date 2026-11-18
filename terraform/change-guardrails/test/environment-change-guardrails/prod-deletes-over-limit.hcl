mock "tfplan/v2" {
  module {
    source = "testdata/mock-tfplan-prod-deletes-over-limit.sentinel"
  }
}

mock "tfrun" {
  module {
    source = "testdata/mock-tfrun-prod-deletes-over-limit.sentinel"
  }
}

test {
  rules = {
    main = false
  }
}
