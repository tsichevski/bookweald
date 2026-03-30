open Alcotest
open Bookweald.Normalize

let string_option = option string

let test_normalize () =
  check string_option "Simple" (normalize_name "1щёпкина ") (Some "Щепкина");
  check string_option "Compound" (normalize_name "Щепкина-Куперник") (Some "Щепкина-Куперник");
  check string_option "Normalized to None" (normalize_name " !4-###") None

let tests = [
  test_case "name normalization" `Quick test_normalize;
]

