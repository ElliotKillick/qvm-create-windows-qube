# qvm-create-windows-qube

qvm-create-windows-qube is a tool for quickly and conveniently installing fresh new Windows qubes with Qubes Windows Tools as well as other packages such as Firefox, Office 365, Notepad++ and Visual Studio pre-installed modularly and automatically. It also benefits privacy and anominity by disabling unwanted Microsoft telemetry such as Windows Error Reporting (WER) by default as well as by reseting unique identifiers present in every Windows installation such as the MachineGUID, NTFS drive Volume Serial Numbers (VSNs) and more.

## Installation

1. Download the [installation script](https://raw.githubusercontent.com/crazyqube/qvm-create-windows-qube/master/install.sh) by right-clicking then selecting "Save as..."
2. Copy "install.sh" into Dom0 by running the following command in Dom0: `qvm-run -p <qube_script_is_located_on> 'cat $HOME/Downloads/install.sh' > install-qvm-create-windows-qube.sh`
3. Review the code of `install-qvm-create-windows-qube.sh` to ensure its integrity
4. Run `chmod +x install-qvm-create-windows-qube.sh && ./install-qvm-create-windows-qube.sh` in Dom0
5. Review the code of the resulting `qvm-create-windows-qube.sh`

Pro Tip: Use `cat -v` for code review so [terminal escape sequences aren't interpreted](https://ma.ttias.be/terminal-escape-sequences-the-new-xss-for-linux-sysadmins/)

## Usage

```
Usage: ./qvm-create-windows-qube.sh [options] <name>
  -h, --help
  -c, --count <number> Number of Windows qubes with given basename desired
  -t, --template Make this qube a TemplateVM instead of a StandaloneVM
  -n, --netvm <qube> NetVM for Windows to use (default: sys-firewall)
  -s, --seamless Enable seamless GUI persistently across restarts
  -p, --packages <packages> Comma-separated list of packages to pre-install (see available packages at: https://chocolatey.org/packages)
  -d, --disable-updates Disables installing of future updates (automatic reboots are disabled either way)
  -i, --iso <file> Windows ISO to automatically install and setup (default: Win7_Pro_SP1_English_x64.iso)
  -a, --answer-file <xml file> Settings for Windows installation (default: windows-7.xml)

Example: `./qvm-create-windows-qube.sh -sn sys-firewall -p firefox,notepadplusplus,office365business windows-7`

## Security

To mitigate the fallout of another shellshock-like Bash vulnerability, the Dom0 script communicates to the windows-mgmt qube in a one-way fashion. Downloading of the Windows ISOs and update packages are made as secure as possible by encforcing HTTPS with public key pinning whenever possible as well as verifying the SHA256 of the files after download. Packages such as Firefox are offered out of the box so the infamously insecure Internet Explorer never has to be used.

## Contributing

PRs are welcome! Take a look at the todo list below if you're looking for things that need improvement. Other improvements such as simpler ways of doing things, code cleanup and other fixes are also welcome.

## Todo

- Use libguestfs for a more efficient way of putting answer files into ISOs: https://rwmj.wordpress.com/2010/11/04/customizing-a-windows-7-install-iso/ (guestfish, dnf info libguestfs-tools or apt show libguestfs-tools)
    - While trying to install this package on Fedora there are many conflicts with older versions of the same packages Qubes tools relies on
    - If --allowerasing option is enabled dnf prompts to remove those Qubes packages
    - Qubes seems to be the third party repository: https://unix.stackexchange.com/questions/442064/package-x-requires-y-but-none-of-the-providers-can-be-installed
    - Installation on Debian works
- [ ] Auto Tools takes D:\\ making QWT put the user profile on E:\\; it would be nicer to have it on D:\\ so there is no awkward gap in the middle
- [ ] Support Windows 10 (Note: QWT doesn't fully support Windows 10 yet)
- [x] Provision Chocolatey (#2)
- [ ] Add an option to slim down Windows as documented in: https://www.qubes-os.org/doc/windows-template-customization/
- [ ] Make windows-mgmt air gapped
- [ ] Put this todo list into GitHub issues
