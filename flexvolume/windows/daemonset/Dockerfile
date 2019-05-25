# escape=`

from mcr.microsoft.com/powershell:nanoserver-1809 as downloaded_files

copy ./download_files.ps1 c:/work/download_files.ps1
WORKDIR c:/work

RUN C:\"Program Files"\PowerShell\pwsh.exe -file c:\work\download_files.ps1


from mcr.microsoft.com/powershell:nanoserver-1809
copy ./copy_files.ps1 c:/work/
copy --from=downloaded_files /download/ /src/

ENTRYPOINT ["\"c:\\Program Files\\PowerShell\\pwsh.exe\""]
CMD ["-file","c:\\work\\copy_files.ps1"]

WORKDIR c:/work