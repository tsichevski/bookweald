open Alcotest
open Bookweald.Xml_declaration
open Bookweald.Utils

let test src exp_encoding exp_rest =
  let enc = extract_encoding 
    {|<?xml version="1.0" encoding="windows-1251"?>|}
  in
  check string "detects cp1251" "windows-1251" enc

let test_extract_encoding () =
  let enc = extract_encoding 
    {|<?xml version="1.0" encoding="windows-1251"?>|}
  in
  check string "detects cp1251" "windows-1251" enc

let test_extract_encoding_default () =
  let enc = extract_encoding {|<?xml version="1.0"?>|}
  in
  check string "defaults to utf-8" "utf-8" enc

let test_extract_encoding_malformed () =
  let enc = extract_encoding {|garbage|}
  in
  check string "malformed returns utf-8" "utf-8" enc

let tests = [
  test_case "extract encoding (cp1251)" `Quick test_extract_encoding;
  test_case "extract encoding (no encoding attr)" `Quick test_extract_encoding_default;
  test_case "extract encoding (malformed)" `Quick test_extract_encoding_malformed;
]