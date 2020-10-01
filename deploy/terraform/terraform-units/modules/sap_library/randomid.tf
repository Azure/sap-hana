# Generates random text for boot diagnostics storage account name
resource "random_id" lib_random_id {
  byte_length = 4
}
