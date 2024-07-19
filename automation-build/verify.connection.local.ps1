# Set-Item WSMan:localhost\client\trustedhosts -value 172.22.217.255

Test-WSMan -ComputerName 172.22.217.255 -Credential deploy -Authentication default