context("test-vroom.R")

test_that("vroom can read a tsv", {
  test_vroom("a\tb\tc\n1\t2\t3\n",
    equals = tibble::tibble(a = 1, b = 2, c = 3)
  )
})

test_that("vroom can read a csv", {
  test_vroom("a,b,c\n1,2,3\n", delim = ",",
    equals = tibble::tibble(a = 1, b = 2, c = 3)
  )
})

test_that("vroom guesses columns with NAs", {
  test_vroom("a,b,c\nNA,2,3\n4,5,6\n", delim = ",",
    equals = tibble::tibble(a = c(NA, 4), b = c(2, 5), c = c(3, 6))
  )

  test_vroom("a,b,c\nfoo,2,3\n4,5,6\n", delim = ",", na = "foo",
    equals = tibble::tibble(a = c(NA, 4), b = c(2, 5), c = c(3, 6))
  )

  test_vroom("a,b,c\nfoo,2,3\n4.0,5,6\n", delim = ",", na = "foo",
    equals = tibble::tibble(a = c(NA, 4), b = c(2, 5), c = c(3, 6))
  )

  test_vroom("a,b,c\nfoo,2,3\nbar,5,6\n", delim = ",", na = "foo",
    equals = tibble::tibble(a = c(NA, "bar"), b = c(2, 5), c = c(3, 6))
  )
})

test_that("vroom can trim whitespace", {
  test_vroom('a,b,c\n foo ,  bar  ,baz\n', delim = ",",
    equals = tibble::tibble(a = "foo", b = "bar", c = "baz")
  )

  test_vroom('a,b,c\n\tfoo\t,\t\tbar\t\t,baz\n', delim = ",",
    equals = tibble::tibble(a = "foo", b = "bar", c = "baz")
  )

  # whitespace trimmed before quotes
  test_vroom('a,b,c\n "foo" ,  "bar"  ,"baz"\n', delim = ",",
    equals = tibble::tibble(a = "foo", b = "bar", c = "baz")
  )

  # whitespace kept inside quotes
  test_vroom('a,b,c\n "foo" ,  " bar"  ,"\tbaz"\n', delim = ",",
    equals = tibble::tibble(a = "foo", b = " bar", c = "\tbaz")
  )
})

test_that("vroom can read files with quotes", {
  test_vroom('"a","b","c"\n"foo","bar","baz"\n', delim = ",",
    equals = tibble::tibble(a = "foo", b = "bar", c = "baz")
  )

  test_vroom('"a","b","c"\n",foo","bar","baz"\n', delim = ",",
    equals = tibble::tibble(a = ",foo", b = "bar", c = "baz")
  )

  test_vroom("'a','b','c'\n',foo','bar','baz'\n", delim = ",", quote = "'",
    equals = tibble::tibble(a = ",foo", b = "bar", c = "baz")
  )
})

test_that("vroom escapes double quotes", {
  test_vroom('"a","b","c"\n"""fo""o","b""""ar","baz"""\n', delim = ",",
    equals = tibble::tibble(a = "\"fo\"o", b = "b\"\"ar", c = "baz\"")
  )
})

test_that("vroom escapes backslashes", {
  test_vroom('a,b,c\n\\,foo,\\"ba\\"r,baz\\"\n', delim = ",", escape_backslash = TRUE,
    equals = tibble::tibble(a = ",foo", b = "\"ba\"r", c = "baz\"")
  )
})

test_that("vroom ignores leading whitespace", {
  test_vroom('\n\n   \t \t\n  \n\na,b,c\n1,2,3\n', delim = ",",
    equals = tibble::tibble(a = 1, b = 2, c = 3)
  )
})

test_that("vroom ignores comments", {
  test_vroom('\n\n \t #a,b,c\na,b,c\n1,2,3\n', delim = ",", comment = "#",
    equals = tibble::tibble(a = 1, b = 2, c = 3)
  )
})

test_that("vroom respects skip", {
  test_vroom('#a,b,c\na,b,c\n1,2,3\n', delim = ",", skip = 1,
    equals = tibble::tibble(a = 1, b = 2, c = 3)
  )

  test_vroom('#a,b,c\na,b,c\n1,2,3\n', delim = ",", skip = 1, comment = "#",
    equals = tibble::tibble(a = 1, b = 2, c = 3)
  )

  test_vroom('#a,b,c\nasdfasdf\na,b,c\n1,2,3\n', delim = ",", skip = 2, comment = "#",
    equals = tibble::tibble(a = 1, b = 2, c = 3)
  )

  test_vroom('\n\n#a,b,c\nasdfasdf\na,b,c\n1,2,3\n', delim = ",", skip = 4, comment = "#",
    equals = tibble::tibble(a = 1, b = 2, c = 3)
  )
})

test_that("vroom respects col_types", {
  test_vroom('a,b,c\n1,2,3\n', delim = ",", col_types = "idc",
    equals = tibble::tibble(a = 1L, b = 2, c = "3")
  )

  test_vroom('a,b,c,d\nT,2,3,4\n', delim = ",", col_types = "lfc_",
    equals = tibble::tibble(a = TRUE, b = factor(2), c = "3")
  )
})

test_that("vroom handles UTF byte order marks", {
  # UTF-8
  expect_equal(
    vroom(as.raw(c(0xef, 0xbb, 0xbf, # BOM
                0x41, # A
                0x0A # newline
             )), col_names = FALSE
    )[[1]],
    "A")

  # UTF-16 Big Endian
  expect_equal(
    vroom(as.raw(c(0xfe, 0xff, # BOM
                0x41, # A
                0x0A # newline
             )), col_names = FALSE
    )[[1]],
    "A")

  # UTF-16 Little Endian
  expect_equal(
    vroom(as.raw(c(0xff, 0xfe, # BOM
                0x41, # A
                0x0A # newline
             )), col_names = FALSE
    )[[1]],
    "A")

  # UTF-32 Big Endian
  expect_equal(
    vroom(as.raw(c(0x00, 0x00, 0xfe, 0xff, # BOM
                0x41, # A
                0x0A # newline
             )), col_names = FALSE
    )[[1]],
    "A")

  # UTF-32 Little Endian
  expect_equal(
    vroom(as.raw(c(0xff, 0xfe, 0x00, 0x00, # BOM
                0x41, # A
                0x0A # newline
             )), col_names = FALSE
    )[[1]],
    "A")
})

test_that("vroom handles vectors shorter than the UTF byte order marks", {

  expect_equal(
    charToRaw(vroom(as.raw(c(0xef, 0xbb, 0x0A)), col_names = FALSE)[[1]]),
    as.raw(c(0xef, 0xbb))
  )

  expect_equal(
    charToRaw(vroom(as.raw(c(0xfe, 0x0A)), col_names = FALSE)[[1]]),
    as.raw(c(0xfe))
  )

  expect_equal(
    charToRaw(vroom(as.raw(c(0xff, 0x0A)), col_names = FALSE)[[1]]),
    as.raw(c(0xff))
  )
})

test_that("vroom handles windows newlines", {

  expect_equal(
    vroom("a\tb\r\n1\t2\r\n", trim_ws = FALSE)[[1]],
    1
  )
})

test_that("vroom can read a file with only headers", {
  test_vroom("a\n",
    equals = tibble::tibble(a = character())
  )

  test_vroom("a,b,c\n",
    equals = tibble::tibble(a = character(), b = character(), c = character())
  )
})

test_that("vroom can read an empty file", {
  test_vroom("\n",
    equals = tibble::tibble()
  )

  f <- tempfile()
  file.create(f)
  on.exit(unlink(f))

  capture.output(type = "message",
    expect_equal(vroom(f), tibble::tibble())
  )

  capture.output(type = "message",
    expect_equal(vroom(f, col_names = FALSE), tibble::tibble())
  )

  expect_equal(vroom(character()), tibble::tibble())
})

test_that("vroom_examples() returns the example files", {
  expect_equal(vroom_examples(), list.files(system.file("extdata", package = "vroom")))
})

test_that("vroom_example() returns a single example files", {
  expect_equal(vroom_example("mtcars.csv"), system.file("extdata", "mtcars.csv", package = "vroom"))
})

test_that("subsets work", {
  res <- vroom("1\n2\n3\n4\n5\n6\n7\n8\n9\n10\n11\n12\n13\n14", col_names = FALSE)
  expect_equal(head(res[[1]]), c(1:6))
  expect_equal(tail(res[[1]]), c(9:14))

  expect_equal(tail(res[[1]][3:8]), c(3:8))
})

test_that("n_max works with normal files", {
    expect_equal(
      NROW(vroom(vroom_example("mtcars.csv"), n_max = 2)),
      2
    )

    # headers don't count
    expect_equal(
      NROW(vroom(vroom_example("mtcars.csv"), n_max = 2, col_names = FALSE)),
      2
    )

    # Zero rows with headers should just have the headers
    expect_equal(
      dim(vroom(vroom_example("mtcars.csv"), n_max = 0)),
      c(0, 12)
    )

    # If you don't read the header or any rows it must be empty
    expect_equal(
      dim(vroom(vroom_example("mtcars.csv"), n_max = 0, col_names = FALSE)),
      c(0, 0)
    )
})

test_that("n_max works with connections files", {
    expect_equal(
      NROW(vroom(vroom_example("mtcars.csv.gz"), n_max = 2)),
      2
    )

    # headers don't count
    expect_equal(
      NROW(vroom(vroom_example("mtcars.csv.gz"), n_max = 2, col_names = FALSE)),
      2
    )

    # Zero rows with headers should just have the headers
    expect_equal(
      dim(vroom(vroom_example("mtcars.csv.gz"), n_max = 0)),
      c(0, 12)
    )

    # If you don't read the header or any rows it must be empty
    expect_equal(
      dim(vroom(vroom_example("mtcars.csv.gz"), n_max = 0, col_names = FALSE)),
      c(0, 0)
    )
})

test_that("vroom truncates col_names if it is too long", {
  test_vroom("1\n2\n", col_names = c("a", "b"),
    equals = tibble::tibble(a = c(1, 2))
  )
})

test_that("vroom makes additional col_names if it is too short", {
  test_vroom("1,2,3\n4,5,6\n", col_names = c("a", "b"),
    equals = tibble::tibble(a = c(1, 4), b = c(2, 5), X3 = c(3, 6))
  )
})

test_that("vroom reads newlines in data", {
  test_vroom('a\n"1\n2"\n',
  equals = tibble::tibble(a = "1\n2"))
})

test_that("vroom reads headers with embedded newlines", {
  test_vroom("\"Header\nLine Two\"\nValue\n", delim = ",",
    equals = tibble::tibble("Header\nLine Two" = "Value")
  )

  test_vroom("\"Header\",\"Second header\nLine Two\"\nValue,Value2\n", delim = ",",
    equals = tibble::tibble("Header" = "Value", "Second header\nLine Two" = "Value2")
  )
})

test_that("vroom reads headers with embedded newlines 2", {
  test_vroom("\"Header\nLine Two\"\n\"Another line\nto\nskip\"\nValue,Value2\n", skip = 2, col_names = FALSE, delim = ",",
    equals = tibble::tibble("X1" = "Value", "X2" = "Value2")
  )
})

test_that("vroom uses the number of rows when guess_max = Inf", {
  tf <- tempfile()
  df <- tibble::tibble(x = c(1:1000, "foo"))
  vroom_write(df, tf, delim = "\t")

  # The type should be guessed wrong, because the character comes at the end
  res <- vroom(tf)
  expect_is(res[["x"]], "numeric")
  expect_true(is.na(res[["x"]][[NROW(res)]]))

  # The value should exist with guess_max = Inf
  res <- vroom(tf, guess_max = Inf)
  expect_is(res[["x"]], "character")
  expect_equal(res[["x"]][[NROW(res)]], "foo")
})

test_that("vroom adds columns if a row is too short", {
  test_vroom("a,b,c,d\n1,2\n3,4,5,6\n", delim = ",",
    equals = tibble::tibble("a" = c(1,3), "b" = c(2,4), "c" = c(NA, 5), "d" = c(NA, 6))
  )
})

test_that("vroom adds removes columns if a row is too long", {
  test_vroom("a,b,c,d\n1,2,3,4,5,6,7\n8,9,10,11\n", delim = ",", col_types = c(d = "c"),
    equals = tibble::tibble("a" = c(1,8), "b" = c(2,9), "c" = c(3, 10), "d" = c("4,5,6,7", "11"))
  )
})

# Figure out a better way to test progress bars...
#test_that("progress bars work", {
  #withr::with_options(c("vroom.show_after" = 0), {
    #expect_output_file(vroom(vroom_example("mtcars.csv"), progress = TRUE), "mtcars-progress")
  #})
#})

test_that("guess_type works with long strings (#74)", {
  expect_is(
    guess_type("https://www.bing.com/search?q=mr+popper%27s+penguins+worksheets+free&FORM=QSRE1"),
    "collector_character"
  )
})

test_that("vroom errors if unnamed column types do not match the number of columns", {
  expect_error(vroom("a,b\n1,2\n", col_types = "i"), "must have the same length", class = "Rcpp::eval_error")
})

test_that("column names are properly encoded", {
  nms <- vroom::vroom("f\U00F6\U00F6\nbar\n")
  expect_equal(Encoding(colnames(nms)), "UTF-8")
})

test_that("Files with windows newlines and missing fields work", {
  test_vroom("a,b,c,d\r\nm,\r\n\r\n", delim = ",",
    equals = tibble::tibble(a = c("m", NA), b = c(NA, NA), c = c(NA, NA), d = c(NA, NA))
  )
})
