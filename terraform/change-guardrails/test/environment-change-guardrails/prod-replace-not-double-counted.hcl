mock "tfplan/v2" {
  module {
    source = "testdata/mock-tfplan-prod-replace-not-double-counted.sentinel"
  }
}

mock "tfrun" {
  module {
    source = "testdata/mock-tfrun-prod-replace-not-double-counted.sentinel"
  }
}

test {
  rules = {
    main = true
  }
}
