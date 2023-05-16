# Fleet gitops - push pattern
## Repo structure
### cli
The `rcncli` source code.
Requires `gum` by [charm.sh](charm.sh)
A few environment variables are also required.
Basically, as long as you can access this directory and the controller through `kubectl` you're good to go.
### fleet-clusters
#### nginx-web
Helm chart for `nginx` with volume mount points for the configmaps
#### nginx-conf
Helm chart for the configmaps required for `nginx`
### fleet-controller
#### controller
yaml files to setup the controller and a template to set up the agents on the managed clusters.
#### gitops
yaml files to setup gitops on the managed clusters
## Installation
WIP
Follow the guides at [the fleet web site](https://fleet.rancher.io/).
## Drawbacks
### Based off controller cache
No reconcilliation occurs when the state deployed is the state that was last seen on the machine