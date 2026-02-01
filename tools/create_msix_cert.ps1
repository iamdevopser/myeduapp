param(
  [string]$CertName = "MyEduApp",
  [string]$OutDir = "build\\msix",
  [string]$Password = "MyEduApp123!"
)

$cert = New-SelfSignedCertificate `
  -Type Custom `
  -Subject "CN=$CertName" `
  -KeyUsage DigitalSignature `
  -CertStoreLocation "Cert:\CurrentUser\My" `
  -KeyExportPolicy Exportable `
  -NotAfter (Get-Date).AddYears(5)

$pwd = ConvertTo-SecureString -String $Password -Force -AsPlainText

New-Item -ItemType Directory -Force -Path $OutDir | Out-Null

$cerPath = Join-Path $OutDir "$CertName.cer"
$pfxPath = Join-Path $OutDir "$CertName.pfx"

Export-Certificate -Cert $cert -FilePath $cerPath | Out-Null
Export-PfxCertificate -Cert $cert -FilePath $pfxPath -Password $pwd | Out-Null

Write-Host "Created certificate files:"
Write-Host "  $cerPath"
Write-Host "  $pfxPath"

