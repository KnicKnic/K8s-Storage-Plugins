# escape=`
from mcr.microsoft.com/powershell:nanoserver-1809
copy ./copy_files.ps1 c:/work/
copy ./microsoft-windows-plugin-version.txt c:/work/
copy ./plugins /src/plugins/

ENTRYPOINT ["\"c:\\Program Files\\PowerShell\\pwsh.exe\""]
CMD ["-file","c:\\work\\copy_files.ps1"]

WORKDIR c:/work