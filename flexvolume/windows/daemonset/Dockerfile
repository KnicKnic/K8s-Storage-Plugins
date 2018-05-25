# escape=`

from microsoft/powershell:nanoserver as downloaded_files

copy ./download_files.ps1 c:/work/download_files.ps1
WORKDIR c:/work

RUN C:\"Program Files"\PowerShell\pwsh.exe -file c:\work\download_files.ps1


from microsoft/powershell:nanoserver
copy ./copy_files.ps1 c:/work/
copy --from=downloaded_files /download/ /src/

ENTRYPOINT ["\"c:\\Program Files\\PowerShell\\pwsh.exe\""]
CMD ["-file","c:\\work\\copy_files.ps1"]

WORKDIR c:/work