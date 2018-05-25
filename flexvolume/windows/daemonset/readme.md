# Daemonset deployment of flexvolume plugins

This will create a daemonset that will download the kubernetes windows flexvoluem plugins at startup into the specified folder on the windows host machine. 

The default folder is `C:\usr\libexec\kubernetes\kubelet-plugins\volume\exec`

To Deploy on 1803
1. run `kubectl create -f https://github.com/KnicKnic/K8s-Storage-Plugins/tree/flexvolume-plugin-demonset/flexvolume/windows/daemonset`

To Deploy manually
1. build the docker file as `knicknic/flexvolume-plugins-copy:v0.0.2`
    1. `docker build . -t knicknic/flexvolume-plugins-copy:v0.0.2`
1. run `kubectl create -f deploy-microsoft-windows-flexvolume.yaml`

