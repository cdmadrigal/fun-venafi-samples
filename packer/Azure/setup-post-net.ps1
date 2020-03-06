Install-WindowsFeature -name Web-Server -IncludeManagementTools
Start-Process "msiexec.exe" -Wait -ArgumentList '/i C:\Users\Public\Downloads\rewrite_amd64.msi /q'
Enable-WindowsOptionalFeature -Online -FeatureName IIS-ApplicationDevelopment
Enable-WindowsOptionalFeature -Online -FeatureName IIS-ApplicationInit
Enable-WindowsOptionalFeature -Online -FeatureName IIS-ISAPIExtensions
Enable-WindowsOptionalFeature -Online -FeatureName IIS-ASP
Enable-WindowsOptionalFeature -Online -FeatureName IIS-ISAPIFilter
Enable-WindowsOptionalFeature -Online -FeatureName IIS-WebSockets
Enable-WindowsOptionalFeature -Online -FeatureName IIS-ServerSideIncludes
Enable-WindowsOptionalFeature -Online -FeatureName IIS-ASPNET45 -All
Write-Host "Unpacking TPP installer..."
Start-Process "C:\Users\Public\Downloads\Venafi Trust Protection Platform 19.4.0\VenafiTPPInstallx64.msi" -Wait -ArgumentList '/q /n' 
Write-Host "Cleaning up winrm connection. Will be removed and disabled at shutdown..."
Invoke-Expression (invoke-webrequest -uri 'https://raw.githubusercontent.com/DarwinJS/Undo-WinRMConfig/master/Undo-WinRMConfig.ps1' -UseBasicParsing)