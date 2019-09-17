# qvm-create-windows-qube

qvm-create-windows-qube is a tool for quickly and conveniently installing fresh new Windows qubes with Qubes Windows Tools as well as other packages such as Firefox, Office 365, Notepad++ and Visual Studio pre-installed modularly and automatically. It also benefits privacy and anominity by disabling unwanted Microsoft telemetry such as Windows Error Reporting (WER) by default as well as by reseting unique identifiers present in every Windows installation such as the MachineGUID, NTFS drive Volume Serial Numbers (VSNs) and more.

## Installation

1. Download the [installation script](https://raw.githubusercontent.com/crazyqube/qvm-create-windows-qube/master/install-qvm-create-windows-qube.sh) by right-clicking then selecting "Save as..."
2. Copy "install-qvm-create-windows-qube.sh" into Dom0 by running the following command in Dom0: `qvm-run -p QUBE_SCRIPT_IS_LOCATED_ON 'cat $HOME/Downloads/install-qvm-create-windows-qube.sh' > install-qvm-create-windows-qube.sh`
3. Review the code of `install-qvm-create-windows-qube.sh` to ensure its integrity
4. Run `chmod +x install-qvm-create-windows-qube.sh && ./install-qvm-create-windows-qube.sh` in Dom0
5. Review the code of the resulting `qvm-create-windows-qube.sh`

Pro Tip: Use `cat -v` during code review so [terminal escape sequences aren't interpreted](https://ma.ttias.be/terminal-escape-sequences-the-new-xss-for-linux-sysadmins/)

## Usage

```
Usage: ./qvm-create-windows-qube.sh [options] <name>
  -h, --help
  -c, --count <number> Number of Windows qubes with given basename desired
  -n, --netvm <netvm> NetVM for Windows to use (default: sys-firewall)
  -b, --background Installation process will happen in a minimized window
  -p, --packages <packages> Comma-separated list of packages to pre-install (see available packages at: https://chocolatey.org/packages)
  -d, --disable-updates Disables installing of future updates (automatic reboots are disabled either way)
  -i, --iso <file> Windows ISO to automatically install and setup (default: Win7_Pro_SP1_English_x64.iso)
  -a, --answer-file <xml file> Settings for Windows installation (default: windows-7.xml)
```

Example: `./qvm-create-windows-qube.sh -n sys-firewall -p firefox,notepadplusplus,office365business windows-7`

## Security

To mitigate the fallout of another shellshock-like Bash vulnerability, the Dom0 script communicates to the windows-mgmt qube in a one-way fashion. Downloading of the Windows ISOs and update packages are made as secure as possible by encforcing HTTPS with public key pinning whenever possible as well as verifying the SHA256 of the files after download. Packages such as Firefox are offered out of the box so the infamously insecure Internet Explorer never has to be used.

## Contributing

PRs are welcome! The codebase of this project was built to be as modular as possible to allow for frictionless extensibility. Take a look at the todo list below if you're looking for things that need improvement.

## Todo

- [ ] Find out how to use `7601.24214.180801-1700.win7sp1_ldr_escrow_CLIENT_ULTIMATE_x64FRE_en-us.iso` as ISO because it packages a lot of updates with it making it so we don't have to install those MSU files at the start as well as have less updates to install afterwards
    1. It seems like the pre-installed updates appear to be packaged in a weird way that gets loss upon extracting the ISO and repacking it. (Quite telling due to how the outputted ISO loses around 2GB) The result is a broken ISO that installs but has a lot of weird error messages on the way and no updates
    2. This could be done by a tool that allows you to insert a file directly into an ISO without having to repack it (This is also faster than having to undergo the process of extracting and repacking)
    3. This seems perfect: https://rwmj.wordpress.com/2010/11/04/customizing-a-windows-7-install-iso/ (guestfish, dnf info libguestfs-tools or apt show libguestfs-tools)
    4. New development! We should instead use packer (apt show packer) to further automate deployment (faster too!): https://www.hurryupandwait.io/blog/creating-windows-base-images-for-virtualbox-and-hyper-v-using-packer-boxstarter-and-vagrant (Possibly also Boxstarter)
    5. Issues with packer: There doesn't seem to be a dnf package and lots of dependencies to install on every boot of windows-mgmt if it is to remain an AppVM
    6. In my experience QWT also seems to be the most stable on the lastest version of Windows 7
- [ ] Auto Tools takes D:\\ making QWT put the user profile on E:\\; it would be nicer to have it on D:\\ so there is no awkward gap in the middle
- [ ] Support Windows 10 (Note: QWT doesn't fully support Windows 10 yet)
- [x] Provision Chocolatey (#2)
- [ ] Add an option to slim down Windows as documented in: https://www.qubes-os.org/doc/windows-template-customization/
- [ ] Improve background option (What happened to the --no-guid/--no-start-guid option in qvm-start? Before R4 it seemed to be present)
- [ ] Make windows-mgmt air gapped
- [ ] Put this todo list into GitHub issues
