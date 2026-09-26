/// The fields of the edit-profile form, declared in the order the form asks
/// for a missing one: the name first, then the details the profile bonus
/// needs (date of birth, gender, household size), the optional email last.
enum ProfileField { name, dateOfBirth, gender, householdSize, email }
