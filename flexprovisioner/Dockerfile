FROM microsoft/windowsservercore
copy ./src/* /provisioner/
copy ./build/flex-provisioner.exe /provisioner/

RUN winrm s winrm/config/client "@{TrustedHosts=\"*\"}"
ENTRYPOINT ["c:\\provisioner\\flex-provisioner.exe", "-logtostderr", "-provisioner", "microsoft.com/windows-server-storage-provisioner", "-execCommand", "c:\\provisioner\\flex.cmd"]
