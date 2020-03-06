Invoke-WebRequest "https://aka.ms/vs/16/release/vc_redist.x64.exe" -OutFile "C:\Users\Administrator\Downloads\vc_redist.x64.exe"
Start-Process -FilePath "C:\Users\Administrator\Downloads\vc_redist.x64" -ArgumentList '/install /passive /norestart'
Invoke-WebRequest "http://go.microsoft.com/fwlink/?LinkId=863262" -Outfile "C:\Users\Administrator\Downloads\NDP472-KB4054531-Web.exe"
New-Item -Path "C:\" -Name "sources\sxs" -ItemType "directory"
Install-WindowsFeature -Name Net-Framework-Core -Source C:\source\sxs
Invoke-WebRequest "https://download.microsoft.com/download/E/6/B/E6BFDC7A-5BCD-4C51-9912-635646DA801E/en-US/msodbcsql_17.4.2.1_x64.msi" -OutFile "C:\Users\Administrator\Downloads\msodbcsql_17.4.2.1_x64.msi"
Start-Process "msiexec.exe" -Wait -ArgumentList '/quiet /passive /qn /i C:\Users\Administrator\Downloads\msodbcsql_17.4.2.1_x64.msi IACCEPTMSODBCSQLLICENSETERMS=YES ADDLOCAL=ALL' 
Invoke-WebRequest "https://go.microsoft.com/fwlink/?linkid=2082790" -OutFile "C:\Users\Administrator\Downloads\MsSqlCmdLnUtils.msi"
Start-Process "msiexec.exe" -Wait -ArgumentList '/quiet /passive /qn /i C:\Users\Administrator\Downloads\MsSqlCmdLnUtils.msi IACCEPTMSSQLCMDLNUTILSLICENSETERMS=YES' 
Invoke-WebRequest "https://download.microsoft.com/download/C/9/E/C9E8180D-4E51-40A6-A9BF-776990D8BCA9/rewrite_amd64.msi" -Outfile "C:\Users\Administrator\Downloads\rewrite_amd64.msi"
Write-Host "Downloading TPP 19.4.0 with user account:" $Env:VenafiUser
[system.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12; Invoke-WebRequest -Uri 'https://download.venafi.com/Trust Protection Platform/Current/19.4.0/Venafi Trust Protection Platform 19.4.0.zip' -Headers @{ Authorization = "Basic $([System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes("$Env:VenafiUser/:$Env:VenafiPassword")))" } -Outfile 'C:\Users\Administrator\Downloads\Venafi Trust Protection Platform 19.4.0.zip'
Write-Host "Download complete. Unzipping file to Downloads folder now..."
Expand-Archive -LiteralPath "C:\Users\Administrator\Downloads\Venafi Trust Protection Platform 19.4.0.zip" -DestinationPath "C:\Users\Administrator\Downloads\Venafi Trust Protection Platform 19.4.0"
Write-Host "Installing .NET 4.7.2..."
Start-Process -Wait -FilePath "C:\Users\Administrator\Downloads\NDP472-KB4054531-Web.exe" -ArgumentList '/install /q /forcerestart'