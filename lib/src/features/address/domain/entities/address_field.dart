/// The free-text fields of the address form, named after the API fields.
enum AddressField {
  city,
  block,
  street,
  building,
  floor,
  apartment,
  phone,
  notes,
}

/// Why a field value cannot be saved.
enum AddressFieldError { required, tooLong, invalidPhone }
