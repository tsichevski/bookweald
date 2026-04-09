type person = {
  id : string;
  first_name : string option;
  middle_name : string option;
  last_name : string option;
}

let normalize last_name first_name middle_name : string option =
  Utils.filter_map_concat_list (List.filter_map Fun.id [last_name; first_name; middle_name]) ' ' Normalize.normalize_name

let person_create_exn last_name first_name middle_name : person =
  match normalize last_name first_name middle_name with
  | None -> failwith "Attempt to create person with empty normalized name"
  | Some id -> 
  { id;
    first_name;
    middle_name;
    last_name }
    