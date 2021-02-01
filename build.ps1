[cmdletbinding()]
Param (
    [Parameter(Mandatory = $false)]
    [string]$ImportName = "cblmariner",
    [Parameter(Mandatory = $true)]
    [string]$ImportPath,
    [Parameter(Mandatory = $false)]
    [string]$ImportVersion = '2'
)
$build_instance = New-UbuntuWSLInstance -Release bionic -Version 2 -AdditionalPPA "longsleep/golang-backports," -AdditionalPkg "make,tar,wget,curl,rpm,qemu-utils,golang-1.15-go,genisoimage,python-minimal,bison,gawk" -NonInteractive
wsl.exe -d ubuntu-$build_instance echo -e `"`[automount`]\noptions `= `"metadata`"`" `>`> /etc/wsl.conf
wsl.exe -t ubuntu-$build_instance
function Invoke-WithInstance { wsl.exe -d ubuntu-$build_instance -u $env:USERNAME $args }

Invoke-WithInstance sudo ln -vsf /usr/lib/go-1.15/bin/go /usr/bin/go
Invoke-WithInstance curl -fsSL https://get.docker.com -o get-docker.sh
Invoke-WithInstance sudo sh get-docker.sh
Invoke-WithInstance sudo usermod -aG docker $env:USERNAME
wsl.exe -t ubuntu-$build_instance

Invoke-WithInstance git clone https://github.com/microsoft/CBL-Mariner.git ~/cblm
Invoke-WithInstance git --work-tree=/home/$env:USERNAME/cblm checkout 1.0-stable

Invoke-WithInstance bash -c `"sudo make `-C ~/cblm/toolkit/ image REBUILD_TOOLS=y REBUILD_PACKAGES=n CONFIG_FILE=~/cblm/toolkit/imageconfigs/core-container.json`"
# for some unknown reason, first run will not always run successfully
while (-not $?) {
    Invoke-WithInstance bash -c `"sudo make `-C ~/cblm/toolkit/ image REBUILD_TOOLS=y REBUILD_PACKAGES=n CONFIG_FILE=~/cblm/toolkit/imageconfigs/core-container.json`"
}
#Invoke-WithInstance sudo make `-C ~/cblm/toolkit/ toolchain REBUILD_TOOLS=y REBUILD_TOOLCHAIN=y DOWNLOAD_SRPMS=y 
#Invoke-WithInstance sudo make `-C ~/cblm/toolkit/ build`-packages `-j`$`(nproc`) CONFIG_FILE= REBUILD_TOOLS=y REBUILD_PACKAGES=n PACKAGE_IGNORE_LIST='openjdk8 openjdk8_aarch64 shim-unsigned-aarch64'
#Invoke-WithInstance sudo make `-C ~/cblm/toolkit/ image CONFIG_FILE=./imageconfigs/core-container.json REBUILD_TOOLS=y DOWNLOAD_SRPMS=y

Invoke-WithInstance cp `-r ~/cblm/out/images/core-container/*.tar.gz .
Move-Item *.tar.gz install.tar.gz
wsl.exe --import $ImportName $ImportPath ./install.tar.gz --version $ImportVersion
Remove-Item get-docker.sh
Remove-Item install.tar.gz
Remove-UbuntuWSLInstance -Id $build_instance