mock "tfplan/v2" {
  module {
    source = "testdata/mock-tfplan-prod-noops-and-reads-not-counted.sentinel"
  }
}

mock "tfrun" {
  module {
    source = "testdata/mock-tfrun-prod-noops-and-reads-not-counted.sentinel"
  }
}

test {
  rules = {
    main = true
  }
}
