$AVS_ACCESS_REQUEST = <<XML
<?xml version="1.0"?>
<AccessRequest>
  <AccessLicenseNumber></AccessLicenseNumber>
  <UserId>selecthw101</UserId>
  <Password>efg$K8109</Password>
</AccessRequest>
<?xml version="1.0"?>
XML
# Don't delete the extra xml declaration because UPS actually processes
# two XML docs in one request.

$AVS_URL = URI.parse('https://wwwcie.ups.com/ups.app/xml/AV')

$AVS_FAILURE_RESPONSE = <<XML
<?xml version="1.0"?>
<Response>
  <ResponseStatusCode>-1</ResponseStatusCode>
</Response>
XML
