# qvm-create-windows-qube

qvm-create-windows-qube is a tool for quickly and conveniently installing fresh new Windows qubes with Qubes Windows Tools as well as other packages such as Firefox pre-installed modularly and automatically. It also benefits privacy and anominity by reseting unique identifiers present in every Windows installation such as the MachineGUID, NTFS drive Volume Serial Numbers and more.

## Installation

1. Download the [installation script](https://raw.githubusercontent.com/crazyqube/qvm-create-windows-qube/master/install-qvm-create-windows-qube.sh) by right-clicking then selecting "Save as..."
2. Copy "install-qvm-create-windows-qube.sh" into Dom0 by running the following command in Dom0: `qvm-run -p QUBE_SCRIPT_IS_LOCATED_ON 'cat $HOME/Downloads/install-qvm-create-windows-qube.sh' > install-qvm-create-windows-qube.sh`
3. Review the code of the script to ensure its integrity
4. Run it

Pro Tip: Use `cat -v` during code review so [terminal escape sequences aren't interpreted](https://ma.ttias.be/terminal-escape-sequences-the-new-xss-for-linux-sysadmins/)

## Usage

```
Usage: ./qvm-create-windows-qube.sh [options] <name>
  -h, --help
  -c, --count <number> Number of Windows qubes with given basename desired
  -n, --netvm <netvm> NetVM for Windows to use (default: sys-firewall)
  -b, --background Installation process will happen in a minimized window
  -m, --module <modules> Comma-separated list of modules to pre-install
  -i, --iso <file> Windows ISO to automatically install and setup (default: Win7_Pro_SP1_English_x64.iso)
  -a, --answer-file <xml file> Settings for Windows installation (default: windows-7.xml)
```

Example: `./qvm-create-windows-qube.sh -bm firefox windows-7`

## Security

To mitigate the fallout of another shellshock-like Bash vulnerability, the dom0 script communicates to the windows-mgmt qube in a one-way fashion. Downloading of the Windows ISOs and update packages are made as secure as possible by encforcing HTTPS with public key pinning whenever possible as well as verifying the SHA256 of the files after download. Firefox is offered as a module so the infamously insecure Internet Explorer never has to be used.

## Contributing

PRs are welcome! The codebase of this project was built to be as modular as possible to allow for frictionless extensibility. Take a look at the todo list below if you're looking for things that need improvement.

## Todo

- [ ] Find out how to use `7601.24214.180801-1700.win7sp1_ldr_escrow_CLIENT_ULTIMATE_x64FRE_en-us.iso` as ISO because it packages a lot of updates with it making it so we don't have to install those MSU files at the start as well as have less updates to install afterwards
    1. It seems like the pre-installed updates appear to be packaged in a weird way that gets loss upon extracting the ISO and repacking it. (Quite telling due to how the outputted ISO loses around 2GB) The result is a broken ISO that installs but has a lot of weird error messages on the way and no updates
    2.  This could be done by a tool that allows you to insert a file directly into an ISO without having to repack it (This is also faster than having to undergo the process of extracting and repacking)
    3.  This seems perfect: https://rwmj.wordpress.com/2010/11/04/customizing-a-windows-7-install-iso/ (guestfish, dnf info libguestfs-tools or apt show libguestfs-tools)
- [ ] Auto Tools takes D:\\ making QWT put the user profile on E:\\; it would be nicer to have it on D:\\ so there is no awkward gap in the middle
- [ ] Support Windows 10 (Note: QWT doesn't fully support Windows 10 yet)
- [ ] Add more modules
- [ ] Add an option to slim down Windows as documented in: https://www.qubes-os.org/doc/windows-template-customization/
- [ ] Improve background option (What happened to the --no-guid/--no-start-guid option in qvm-start? Before R4 it seemed to be present)
- [ ] Make windows-mgmt air-gapped. This is easy to for the inital ISO and update download, however the Firefox module is also frequently updated
    1. We could switch from the offline Firefox installer to the online installer so then we can just have a DispVM download it one time (assuming no updates for the Firefox online installer). However, this means that the Windows qube could not be air-gapped (because it needs to download from the internet). Also, we may have wait for it to download for every install. This also is potentially limiting for future modules.
    2. Download the latest Firefox offline installer in a DispVM then copy it over to windows-mgmt and verify it's from Mozilla by looking at the PE verified signer using the tool osslsigncode. Problem: This would still make it possible for [data smugling](https://www.blackhat.com/docs/us-16/materials/us-16-Nipravsky-Certificate-Bypass-Hiding-And-Executing-Malware-From-A-Digitally-Signed-Executable-wp.pdf) between VMs to take place
    3. On second thought, Mozilla has a [GPG key](https://blog.mozilla.org/security/2019/06/13/updated-firefox-gpg-key/) so should obviously we should just that to verify the files haven't been tampered with (Also note that this is on top of HPKP HTTPS (meaning we don't even need to trust the whole certificate chain) so perhaps this a bit paranoid assuming the Mozilla website itself isn't comprimised)
- [ ] Put this todo list into GitHub issues
