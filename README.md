# qvm-create-windows-qube

qvm-create-windows-qube is a tool for quickly and conveniently installing fresh new Windows [qubes](https://www.qubes-os.org) with [Xen PV drivers](https://xenproject.org/windows-pv-drivers/) and [Qubes Windows Tools (QWT)](https://xenproject.org/windows-pv-drivers/) automatically. It supports Windows 7/8.1/10 and Windows Server 2008R2/2012R2/2016/2019.

The project emphasizes correctness, security and treating Windows as an untrusted guest operating system throughout the entire process. It also features other goodies such as automatic installation of packages such as Firefox, Office 365, Notepad++ and Visual Studio using [Chocolatey](https://chocolatey.org/).

## Installation

1. Download the [installation script](https://raw.githubusercontent.com/elliotkillick/qvm-create-windows-qube/master/install.sh) by opening the link, right-clicking and then selecting "Save as..."
2. Copy `install.sh` into Dom0 by running the following command in Dom0: `qvm-run -p --filter-escape-chars --no-color-output <qube_script_is_located_on> "cat '/home/user/Downloads/install.sh'" > install.sh`
3. Review the code of `install.sh` to ensure its integrity (Safer with escape character filtering enabled above; qvm-run disables it by default when output is a file)
4. Run `chmod +x install.sh && ./install.sh`
5. Review the code of the resulting `qvm-create-windows-qube.sh`

## Usage

```
Usage: ./qvm-create-windows-qube.sh [options] <name>
  -h, --help
  -c, --count <number> Number of Windows qubes with given basename desired
  -t, --template Make this qube a TemplateVM instead of a StandaloneVM
  -n, --netvm <qube> NetVM for Windows to use
  -s, --seamless Enable seamless mode persistently across reboots
  -o, --optimize Optimize Windows by disabling unnecessary functionality for a qube
  -y, --anti-spy Disable Windows telemetry
  -w, --whonix Apply Whonix recommended settings for a Windows-Whonix-Workstation
  -p, --packages <packages> Comma-separated list of packages to pre-install (see available packages at: https://chocolatey.org/packages)
  -i, --iso <file> Windows media to automatically install and setup (default: win7x64-ultimate.iso)
  -a, --answer-file <xml file> Settings for Windows installation (default: win7x64-ultimate.xml)
```

### Examples

Windows 7:

`./qvm-create-windows-qube.sh -n sys-firewall -soyp firefox,notepadplusplus,office365proplus work-win7`

Windows 10 (After downloading with `download-windows.sh`):

`./qvm-create-windows-qube.sh -oyp steam -i win10x64.iso -a win10x64-pro.xml game-console`

Windows 10 LTSC:

`./qvm-create-windows-qube.sh -n sys-whonix -oyw -i win10x64-ltsc-eval.iso -a win10x64-ltsc-eval.xml anon-win10`

Windows Server 2019:

`./qvm-create-windows-qube.sh -n sys-firewall -oy -i win2019-eval.iso -a win2019-datacenter-eval.xml dc-win2019`

## Security

qvm-create-windows-qube is "reasonably secure," as Qubes would have it.

- `windows-mgmt` is air gapped
- The entirety of the Windows qube setup process happens is done air gapped
    - There is an exception for installing packages at the very end of the Windows qube installation
- Entire class of command injection vulnerabilities eliminated in the Dom0 shell script by not letting it parse any output from the untrusted `windows-mgmt` qube
    - Only exit codes are passed by `qvm-run`; no variables
    - This also mitigates the fallout of another [Shellshock](https://en.wikipedia.org/wiki/Shellshock_(software_bug)) Bash vulnerability
- Downloading of the Windows ISOs is made secure by enforcing:
    - ISOs are downloaded straight from Microsoft controlled subdomains of `microsoft.com`
    - HTTPS TLS 1.2/1.3
    - HTTP public key pinning (HPKP) to whitelist the website's certificate instead of relying on certificate authorities (CAs)
    - SHA-256 verification of the files after download
- Packages such as Firefox are offered out of the box so the infamously insecure Internet Explorer never has to be used
- Windows is treated as an untrusted guest operating system the entire way through
- The impact of any theoretical vulnerabilities in handling of the Windows ISO is limited to `windows-mgmt`

Windows 7 and Windows Server 2008 R2 reached [End Of Life (EOL) on January 14, 2020](https://support.microsoft.com/en-us/help/4057281/windows-7-support-will-end-on-january-14-2020). Updates for these OSs are still available with Extended Security Updates (ESUs) if paid for. Office 365 for these OSs will continue getting security updates until [January 2023](https://support.office.com/en-us/article/windows-7-end-of-support-and-office-78f20fab-b57b-44d7-8368-06a8493f3cb9).

If RDP is to be enabled on a Windows 7 qube (not default) then make sure it is fully up-to-date because the latest Windows 7 ISO Microsoft offers is unfortunately still vulnerable to [BlueKeep](https://en.wikipedia.org/wiki/BlueKeep) and related DejaBlue vulnerabilities.

A critical vulnerability in Windows 10 and Windows Server 2016/2019 cryptography was [recently disclosed](https://media.defense.gov/2020/Jan/14/2002234275/-1/-1/0/CSA-WINDOWS-10-CRYPT-LIB-20190114.PDF). This allows any and all cryptography in these OSs (including HTTPS; the little padlock in your browser) to be easily intercepted. When Microsoft releases an updated ISO, the direct links in `download-windows.sh` will be updated but until then please update your qubes if they run the aforementioned OSs.

## Privacy

qvm-create-windows-qube aims to be the most private way to use Windows. Many Qubes users switched from Windows (or another proprietary OS) in part to get away from Microsoft (or Big Tech in general) and so being able to use Windows from a safe distance is of utmost importance to this project. Or at least, as safe a distance as possible for what is a huge, proprietary binary blob.

### Microsoft Telemetry

- Opt-out of Customer Experience Improvement Program (CEIP)
- Disable Windows Error Reporting (WER)
- Disable DiagTrack service
- Disable all telemetry in Windows 10 Settings application
- Enable "Security" level of telemetry on compatible editions of Windows 10
- See `anti-spy.bat` for more info

### Whonix Recommendations for Windows-Whonix-Workstation

Everything mentioned [here](https://www.whonix.org/wiki/Other_Operating_Systems) up to "Even more security" is implemented. "Most security" is to use an official Whonix-Workstation built yourself from source. This feature is not official or endorsed by Whonix.

### Easy to Reset Fingerprint

There are countless unique identifiers present in every Windows installation such as the MachineGUID, NTFS drive Volume Serial Numbers (VSNs), NTFS filesystem timestamps and more. With qvm-create-windows-qube, these unique identifiers can easily be reset by automatically reinstalling Windows.

### Limitations

Fingerprinting is possible through the hypervisor in the event of VM compromise, here are some practical examples (not specific to Windows):

- [Xen clocksource](https://phabricator.whonix.org/T389)
    - Can partially be mitigated by configuring UTC time in the BIOS/UEFI, local timezone can still be configured for XFCE Dom0 clock
- [lscpu](https://github.com/QubesOS/qubes-issues/issues/1142)
- Generally some of the VM interfaces documented [here](https://www.qubes-os.org/doc/vm-interface) (e.g. screen dimensions)

## Contributing

You can start by giving this project a star! PRs are also welcome! Take a look at the todo list below if you're looking for things that need improvement. Other improvements such as more elegant ways of completing a task, code cleanup and other fixes are also welcome. :)

Lots of Windows-related [GSoCs](https://www.qubes-os.org/gsoc) for those interested.

This project is the product of an independent effort that is not officially endorsed by Qubes OS.

## QWT Known Issues

I may get around to patching some of these upstream issues later if nobody else does. Fixing these issues requires building QWT for which I would have to become the maintainer for, but, as of right now, I simply lack the time.

All OSs:
- If Qubes GUI driver is not installed you must run `qvm-features <windows_qube> gui 1` to make display show up after setup is complete (Any OS other than by default Windows 7/Windows Server 2008 R2 does not support Qubes GUI driver)
- Windows may crash on first boot after QWT is installed
    - On Windows 7, the desktop may boot back up to having no wallpaper and missing libraries. Just delete that qube and start over
    - Or it may crash during app menu creation shortly after first boot after desktop wallpaper/libraries is setup (qvm-sync-appmenus <qube_name> will fix)
    - Or it might just hang on trying to copy the post scripts over to the crashed qube
    - Fix: Just delete the qube and start over

All OSs except Windows 7/Windows Server 2008 R2:
- [Prompt to install earlier version of .NET](https://github.com/QubesOS/qubes-issues/issues/5091) (However, qrexec services still seem to work. Has been merged but QWT needs to be rebuilt to include it and there's currently no maintainer)
- No GUI driver yet
    - The resolution can still be increased to 1920x1080 or higher by increasing the display resolution in Windows

Windows 7/Windows Server 2008R2:
- These are the only platforms Qubes GUI driver is supported on. However, if the Qubes GUI driver is unwanted, either due to stability or performance issues, then that can be disabled by going into the answer file and removing everything under the `RunSynchronous` tag for enabling test signing. Make sure you also cause a new ISO to be generated by deleting the old one in the `out` folder. If you just want this done once then you can quickly "X" out of the "Enable Test Signing" box at the start of Windows setup. This works because the Qubes GUI driver is the only unsigned driver in QWT and the QWT installer will automatically not install the GUI driver if it detects test signing is disabled.
- When Qubes GUI driver is in use, you may receive a message saying Windows "attempted to perform an invalid or suspicious GUI request" GUI causing installation to pause
    - Fix by clicking "Ignore" on prompt

Windows 10/Windows Server 2019:
- [Private disk creation fails](https://github.com/QubesOS/qubes-issues/issues/5090) (Has been merged but QWT needs to be rebuilt to include it and there's currently no maintainer)
    - Temp fix: Close prepare-volume.exe window causing there to be no private disk (can't make a `TemplateVM`) but besides that it will continue as normal

See here:

- https://groups.google.com/forum/#!topic/qubes-users/AdQcjg7XOFo
- https://groups.google.com/forum/#!topic/qubes-devel/aCCGpYysZTQ
- https://github.com/QubesOS/qubes-issues/labels/C%3A%20windows-tools
- https://github.com/QubesOS/qubes-issues/labels/C%3A%20windows-vm

## Todo

- [x] Gain the ability to reliably unpack/insert answer file/repack for any given ISO 9660 (Windows ISO format)
    - Blocking issue for supporting other versions of Windows
- [x] auto-qwt takes D:\\ making QWT put the user profile on E:\\; it would be nicer to have it on D:\\ so there is no awkward gap in the middle
- [x] Make Windows answer file automatically use trial key for Windows installation without hard-coding any product keys anywhere (Windows is finicky on this one)
- [x] Support Windows 8.1-10 (Note: QWT doesn't fully officially any OS other than Windows 7 yet, however, everything is functional except the GUI driver)
- [x] Support Windows Server 2008 R2 to Windows Server 2019
- [x] Support Windows 10 Enterprise LTSC (Long Term Support Channel, provides security updates for 10 years, very stable and less bloat than stock Windows 10)
- [x] Provision Chocolatey
- [x] Add an option to slim down Windows as documented for Qubes [here](https://www.qubes-os.org/doc/windows-template-customization/)
- [x] Make `windows-mgmt` air gapped
- [ ] Possibly switch from udisksctl for reading/mounting ISOs because it is written in its man page that it is not intended for scripts
    - guestfs
    - losetup/mount (requires sudo, but it's what's used by the Qubes Core Team in their scripts)
    - Consider other alternatives
- [ ] I recently discovered this is a Qubes [Google Summer of Code](https://www.qubes-os.org/gsoc) project; which is cool
    - [x] Add automated tests
        - Using Travis CI for automated ShellCheck
    - [ ] ACPI tables for fetching Windows the license embedded there
        - It mentions use of C, however, it seems like it may be possible to [just use shell](https://osxdaily.com/2018/09/09/how-find-windows-product-key)
    - [ ] Port to Python
        - This seems like it would only add unnecessary LOC to scripts like create-media.sh where the Python script would essentially just be calling udisksctl and genisoimage
        - This would certainly be suitable for `qvm-create-windows-qube.sh` though
            - This would allow us to interchange data between Dom0 and the VM without worrying about another Shellshock
- [ ] Automatically select which answer file to use based on Windows ISO characteristics gathered from the wiminfo command (Currently a WIP; see branch)
    - Works just like DISM on Windows
- [x] Follow [this](https://www.whonix.org/wiki/Other_Operating_Systems) Whonix documentation to make Windows-Whonix-Workstation
- [ ] Add functionality for `create-media.sh` to add MSUs (Microsoft Update standalone packages) to be installed during Windows PE pass ("Installing updates...") of Windows Setup for patching critical issues
    - We could fix currently not working QWT installation for old Windows 7 SP1 and Windows Server 2008 R2 ISOs using [KB4474419](https://github.com/QubesOS/qubes-issues/issues/3585#issuecomment-521280301) to add SHA-256 support
    - Allows us to get rid of `allow-drivers.vbs` hack by fixing SHA-256 automatic driver installation bug
    - Patch BlueKeep for Windows 7 out-of-the-box
    - Windows Server 2008 R2 base ISO is also vulnerable to ETERNALBLUE and BlueKeep out-of-the-box
- [ ] Headless mode

## End Goal

Have feature similar (or superior) to [VMWare's Windows "Easy Install"](https://www.youtube.com/watch?v=1OpDXlttmE0) feature on Qubes.

VirtualBox also has [something similar](https://blogs.oracle.com/scoter/oracle-vm-virtualbox-52:-unattended-guest-os-install).
