type 'a kind =
  | N4   : n4 kind
  | N16  : n16 kind
  | N48  : n48 kind
  | N256 : n256 kind
  | NULL : unit kind

and n4   = bytes
and n16  = bytes
and n48  = bytes
and n256 = N256_Key

type 'a record =
  { prefix : bytes
  ; mutable prefix_length : int
  ; mutable count : int
  ; kind : 'a kind
  ; keys : 'a }

type 'a node = { header : header; children : 'a elt array }
and  'a leaf = { value : 'a; key : string }
and  'a elt =
  | Leaf of 'a leaf
  | Node of 'a node
and header = Header : 'a record -> header [@@unboxed]
