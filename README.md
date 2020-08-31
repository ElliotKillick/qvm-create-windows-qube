# qvm-create-windows-qube

qvm-create-windows-qube is a tool for quickly and conveniently installing fresh new Windows [qubes](https://www.qubes-os.org) with [Xen PV drivers](https://xenproject.org/windows-pv-drivers/) and [Qubes Windows Tools (QWT)](https://www.qubes-os.org/doc/windows-tools/) automatically. It supports Windows 7, 8.1 and 10 as well as Windows Server 2008 R2, 2012 R2, 2016 and 2019.

The project emphasizes correctness, security and treating Windows as an untrusted guest operating system throughout the entire process. It also features other goodies such as automatic installation of packages including Firefox, Office 365, Notepad++, Visual Studio and more using [Chocolatey](https://chocolatey.org).

## Installation

1. Download the [installation script](https://raw.githubusercontent.com/elliotkillick/qvm-create-windows-qube/master/install.sh) by opening the link, right-clicking and then selecting "Save [Page] as..."
2. Copy `install.sh` into Dom0 by running the following command in Dom0:
    - `qvm-run -p --filter-escape-chars --no-color-output <qube_script_is_located_on> "cat '/home/user/Downloads/install.sh'" > install.sh`
3. Review the code of `install.sh` to ensure its integrity
    - Safer with escape character filtering enabled above; qvm-run disables it by default when output is a file
4. Run `chmod +x install.sh && ./install.sh`
    - Note that this will install packages in the global default `TemplateVM`, which is `fedora-XX` by default
5. Review the code of the resulting `qvm-create-windows-qube.sh`

Coming Soon: Streamlined and secure installation through `qubes-dom0-update` (Issue #11)

## Usage

```
Usage: ./qvm-create-windows-qube.sh [options] <name>
  -h, --help
  -c, --count <number> Number of Windows qubes with given basename desired
  -t, --template Make this qube a TemplateVM instead of a StandaloneVM
  -n, --netvm <qube> NetVM for Windows to use
  -s, --seamless Enable seamless mode persistently across reboots
  -o, --optimize Optimize Windows by disabling unnecessary functionality for a qube
  -y, --spyless Configure Windows telemetry settings to respect privacy
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

`./qvm-create-windows-qube.sh -n sys-firewall -oy -i win2019-eval.iso -a win2019-datacenter-eval.xml fs-win2019`

## Security

qvm-create-windows-qube is "reasonably secure," as [Qubes](https://www.qubes-os.org) would have it.

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
        - Qubes aims to ["distrust the infrastructure"](https://www.qubes-os.org/faq/#what-does-it-mean-to-distrust-the-infrastructure)
    - SHA-256 verification of the files after download
- Packages such as Firefox are offered out of the box so the infamously insecure Internet Explorer never has to be used
- Windows is treated as an untrusted guest operating system the entire way through
- The impact of any theoretical vulnerabilities in handling of the Windows ISO (e.g. vulnerability in filesystem parsing) or answer file is limited to `windows-mgmt`

### Windows

#### Maintenance

Don't forget to apply any applicable updates upon creation of your Windows qube. Microsoft frequently builds up-to-date ISOs for current versions of Windows, such as Windows 10. For these Windows versions, it's recommended to periodically visit the official Microsoft site `download-windows.sh` provides to get a fresh Windows image out of the box.

#### Advisories

Windows 7 and Windows Server 2008 R2 reached End of Life (EOL) on [January 14, 2020](https://support.microsoft.com/en-us/help/4057281/windows-7-support-will-end-on-january-14-2020). Updates for these OSs are still available with Extended Security Updates (ESUs) if paid for. Office 365 for these OSs will continue getting security updates at no additional cost until [January 2023](https://support.office.com/en-us/article/windows-7-end-of-support-and-office-78f20fab-b57b-44d7-8368-06a8493f3cb9).

If RDP is to be enabled on a Windows 7 qube (not default) then make sure it is fully up-to-date because the latest Windows 7 ISO Microsoft offers is unfortunately still vulnerable to [BlueKeep](https://en.wikipedia.org/wiki/BlueKeep) and related DejaBlue vulnerabilities.

A critical vulnerability in Windows 10 and Windows Server 2016/2019 cryptography was [recently disclosed](https://media.defense.gov/2020/Jan/14/2002234275/-1/-1/0/CSA-WINDOWS-10-CRYPT-LIB-20190114.PDF). This allows any and all cryptography in these OSs (including HTTPS; the little padlock in your browser) to be easily intercepted. When Microsoft releases an updated ISO, the direct links in `download-windows.sh` will be updated but until then please update your qubes if they run the aforementioned OSs.

## Privacy

qvm-create-windows-qube aims to be the most private way to use Windows. Many Qubes users switched from Windows (or another proprietary OS) in part to get away from Microsoft (or Big Tech in general) and so being able to use Windows from a safe distance is of utmost importance to this project. Or at least, as safe a distance as possible for what is a huge, proprietary binary blob.

### Windows Telemetry

Configures Windows telemetry settings to respect privacy.

- Opt-out of Customer Experience Improvement Program (CEIP)
- Disable Windows Error Reporting (WER)
- Disable DiagTrack service
- Switch off all telemetry in Windows 10 "Settings" application
- Enable "Security" level of telemetry on compatible editions of Windows 10
- See `spyless.bat` for more info

### Whonix Recommendations for Windows-Whonix-Workstation

Everything mentioned [here](https://www.whonix.org/wiki/Other_Operating_Systems) up to "Even more security" is implemented. "Most security" is to use an official Whonix-Workstation built yourself from source. This feature is not official or endorsed by Whonix.

It's recommended to read [this](https://www.whonix.org/wiki/Windows_Hosts) Whonix documentation to understand the implications of using Windows in this way.

### Easy to Reset Fingerprint

There are countless unique identifiers present in every Windows installation such as the MachineGUID, installation ID, NTFS drive Volume Serial Numbers (VSNs) and more. With qvm-create-windows-qube, these unique identifiers can easily be reset by automatically reinstalling Windows.

### Limitations

Fingerprinting is possible through the hypervisor in the event of VM compromise, here are some practical examples (not specific to Windows):

- [Xen clocksource](https://phabricator.whonix.org/T389)
    - Timezone leak can at least be mitigated by configuring UTC time in the BIOS/UEFI, the local timezone can still be configured for XFCE Dom0 clock
    - However, correlation between other VMs remains trivial
- [CPUID](https://github.com/QubesOS/qubes-issues/issues/1142)
- Generally some of the VM interfaces documented [here](https://www.qubes-os.org/doc/vm-interface/) (e.g. screen dimensions)

## Contributing

You can start by giving this project a star! PRs are also welcome! Take a look at the todo list below if you're looking for things that need improvement. Other improvements such as more elegant ways of completing a task, code cleanup and other fixes are also welcome. :)

Lots of Windows-related [GSoCs](https://www.qubes-os.org/gsoc/) for those interested.

This project is the product of an independent effort that is not officially endorsed by Qubes OS.

## QWT Known Issues

I may get around to patching some of these upstream issues later if nobody else does. Fixing these issues requires building QWT for which I would have to become the maintainer for, but, as of right now, I simply lack the time.

All OSs:
- [No Windows display when Qubes GUI driver is not installed](https://github.com/QubesOS/qubes-issues/issues/5739)
    - Any OS other than Windows 7/Windows Server 2008 R2 does not support Qubes GUI driver
    - Temporary fix: Run `qvm-features <windows_qube> gui 1` to make the display show up after Windows qube creation is complete

All OSs except Windows 7/Windows Server 2008 R2:
- [Prompt to install earlier version of .NET](https://github.com/QubesOS/qubes-issues/issues/5091)
    - This only appears to be a cosmetic issue because qrexec services still work
    - Has been merged but QWT needs to be rebuilt to include it and there's currently no maintainer

Windows 10/Windows Server 2019:
- [Private disk creation fails](https://github.com/QubesOS/qubes-issues/issues/5090)
    - Temporary fix: Close `prepare-volume.exe` window causing there to be no private disk (can't make a `TemplateVM`) but besides that Windows qube creation will continue as normal
    - Has been merged but QWT needs to be rebuilt to include it and there's currently no maintainer

See here:

- https://groups.google.com/forum/#!topic/qubes-users/AdQcjg7XOFo
- https://groups.google.com/forum/#!topic/qubes-devel/aCCGpYysZTQ
- https://github.com/QubesOS/qubes-issues/labels/C%3A%20windows-tools
- https://github.com/QubesOS/qubes-issues/labels/C%3A%20windows-vm

## Todo

- [x] Gain the ability to reliably unpack/insert answer file/repack for any given ISO 9660 (Windows ISO format)
    - ISO 9660 is write-once (i.e. read-only) filesystem; you cannot just add a file to it without creating a whole new ISO
    - Blocking issue for supporting other versions of Windows
    - This is the same way VMWare does it as can be seen by the "Creating Disk..." part in the video below (Further research indicates that they use `mkisofs`)
    - [ ] In the future, it would be best for Qubes to do this by [extending livirt XML templates](https://github.com/QubesOS/qubes-issues/issues/5085)
        - Much faster
        - Saves storage due to not having to create a new ISO
- [x] auto-qwt takes D:\\ making QWT put the user profile on E:\\; it would be nicer to have it on D:\\ so there is no awkward gap in the middle
- [x] Make Windows answer file automatically use trial key for Windows installation without hard-coding any product keys anywhere (Windows is finicky on this one)
- [x] Support Windows 8.1-10 (Note: QWT doesn't fully officially any OS other than Windows 7 yet, however, everything is functional except the GUI driver)
- [x] Support Windows Server 2008 R2 to Windows Server 2019
- [x] Support Windows 10 Enterprise LTSC (Long Term Support Channel)
    - Provides security updates for 10 years, very stable and less bloat than stock Windows 10
- [x] Provision Chocolatey
- [x] Add an option to slim down Windows as documented for Qubes [here](https://www.qubes-os.org/doc/windows-template-customization/)
- [x] Make `windows-mgmt` air gapped
- [ ] I recently discovered this is a Qubes [Google Summer of Code](https://www.qubes-os.org/gsoc/) project; which is cool
    - [x] Add automated tests
        - Using Travis CI for automated ShellCheck
    - [ ] ACPI tables for fetching Windows the license embedded there
        - It mentions use of C, however, in [this](https://www.qubes-os.org/doc/windows-vm/#simple-windows-install) Qubes documentation it looks to be accessible simply using shell
        - Found more info on this, should be very simple by just placing the following jinja libvirt template extension in `/etc/qubes/templates/libvirt/xen/by-name/<windows_qube>`:
            - https://github.com/QubesOS/qubes-issues/issues/5279#issuecomment-525947408
            - Thanks to @jevank for the patch
    - [ ] Port to Python
        - This seems like it would be unnecessary for scripts like `create-media.sh` where the Python script would essentially just be calling out to external programs
        - This would certainly be suitable for `qvm-create-windows-qube.sh` though
            - This would allow us to interchange data between Dom0 and the VM without worrying about another Shellshock
- [ ] Automatically select which answer file to use based on Windows ISO characteristics gathered from the `wiminfo` command (Currently a WIP; see branch)
    - `wiminfo` works just like DISM on Windows
- [x] Follow [this](https://www.whonix.org/wiki/Other_Operating_Systems) Whonix documentation to make Windows-Whonix-Workstation
- [ ] Add functionality for `create-media.sh` to add MSUs (Microsoft Update standalone packages) to be installed during the Windows PE pass ("Installing updates...") of Windows setup
    - We could fix currently not working QWT installation for old Windows 7 SP1 and Windows Server 2008 R2 ISOs using [KB4474419](https://github.com/QubesOS/qubes-issues/issues/3585#issuecomment-521280301) to add SHA-256 support
    - Allows us to get rid of `allow-drivers.vbs` hack by fixing SHA-256 automatic driver installation bug
        - The other option is to have Xen sign their drivers with SHA-1 as well, which other driver vendors seem to do, but is not ideal from a security standpoint
    - Patch a couple Windows security bugs?
        - Patch BlueKeep for Windows 7 out-of-the-box
        - Windows Server 2008 R2 base ISO is also vulnerable to ETERNALBLUE and BlueKeep out-of-the-box
        - Probably not worth getting into that, users should just update the VM upon making it
- [ ] Headless mode
- [ ] Package this project so its delivery can be made more streamlined and secure through `qubes-dom0-update`
- [ ] Consider adding ReactOS support as an open source alternative to Windows
    - This would be a good at least until a [ReactOS template is made](https://github.com/QubesOS/qubes-issues/issues/2809)
    - Perhaps ReactOS developers may want to use this to develop ReactOS
    - Or maybe just add ReactOS as a template (outside of this project)
        - However, someone would have to maintain this template
        - Also, there may not be much point if QWT/Xen PV drivers don't work
            - At least for basic features like copy/paste and file transfer
    - Interest from both sides
        - https://github.com/QubesOS/qubes-issues/issues/2809
        - https://reactos.org/forum/viewtopic.php?p=126279#p126279
            - "one of the most interesting offers for collaboration we got till today"
    - Seems different then Windows XML unattended installations
        - https://reactos.org/wiki/Create_an_unattended_Installation_CD
    - [ ] Only blocking issue I could find is the SCSI controller type
        - Qubes could extend libvirt to add an option for using that controller
            - This solution seems better because according to [this](https://github.com/QubesOS/qubes-issues/issues/3651#issuecomment-420914348) comment it would also fix a bunch of other OSs whose installer doesn't support our current controller
        - ReactOS could add support for our current controller type
        - https://reactos.org/forum/viewtopic.php?t=17529
        - https://github.com/QubesOS/qubes-issues/issues/3494
    - ReactOS is in alpha so for most users this probably won't be viable right now
    - Help wanted
        - No timeline for this currently

## End Goal

Have a feature similar (or superior) to [VMWare's Windows "Easy Install"](https://www.youtube.com/watch?v=1OpDXlttmE0) feature on Qubes. VMWare's solution is proprietary and only available in their paid products.

VirtualBox also has [something similar](https://blogs.oracle.com/scoter/oracle-vm-virtualbox-52:-unattended-guest-os-install) but is not as feature-rich.
