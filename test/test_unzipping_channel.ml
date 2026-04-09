module Fs = Bookweald.Fs
module Utils = Bookweald.Utils
module Unzip = Bookweald.Unzip

let () =
  In_channel.with_open_bin "test/fixtures/zipped.fb2.zip"
    (fun ic ->
      let zip_seq = Utils.ic_to_seq ic in
      let unzip_seq = Unzip.unzip_fb2_file zip_seq in
      Printf.printf "Result: %s\n" (String.of_seq unzip_seq))