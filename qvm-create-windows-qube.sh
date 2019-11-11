#!/bin/bash

RED='\033[0;31m'
BLUE='\033[0;34m'
GREEN='\033[0;32m'
NC='\033[0m'

wait_for_shutdown() {
    local is_boot="$1"

    # There is a small delay upon booting a qube before qvm-check will detect it as running
    if [ "$is_boot" == "true" ]; then
        sleep 5
    fi

    while qvm-check --running "$qube" &> /dev/null; do
        sleep 1
    done
}

usage() {
    echo "Usage: $0 [options] <name>"
    echo "  -h, --help"
    echo "  -c, --count <number> Number of Windows qubes with given basename desired"
    echo "  -t, --template Make this qube a TemplateVM instead of a StandaloneVM"
    echo "  -n, --netvm <qube> NetVM for Windows to use (default: sys-firewall)"
    echo "  -s, --seamless Enable seamless mode persistently across restarts"
    echo "  -p, --packages <packages> Comma-separated list of packages to pre-install (see available packages at: https://chocolatey.org/packages)"
    echo "  -i, --iso <file> Windows ISO to automatically install and setup (default: Win7_Pro_SP1_English_x64.iso)"
    echo "  -a, --answer-file <xml file> Settings for Windows installation (default: windows-7.xml)"
}

# Option strings
short="hc:tn:sp:i:a:"
long="help,count:,template,netvm:,seamless,packages:,iso:,answer-file:"

# Read options
if ! opts=$(getopt --options=$short --longoptions=$long --name "$0" -- "$@"); then
    exit 1
fi
eval set -- "$opts"

# Set defaults
count="1"
iso="7601.24214.180801-1700.win7sp1_ldr_escrow_CLIENT_ULTIMATE_x64FRE_en-us.iso"
answer_file="windows-7.xml"

# Put options into variables
while true; do
    case "$1" in
        -h | --help)
            usage
            exit
            ;;
        -c | --count)
            count="$2"
            shift 2
            ;;
        -t | --template)
            template="true"
            shift
            ;;
        -n | --netvm)
            netvm="$2"
            shift 2
            ;;
        -s | --seamless)
            seamless="true"
            shift
            ;;
        -p | --packages)
            packages="$2"
            shift 2
            ;;
        -i | --iso)
            iso="$2"
            shift 2
            ;;
        -a | --answer-file)
            answer_file="$2"
            shift 2
            ;;
        --)
            shift
            break
            ;;
    esac
done

# Handle postitional arguments
if [ $# != 1 ]; then
    usage >&2
    exit 1
fi
name="$1"

# Validate name
if qvm-check "$name" &> /dev/null; then
    echo -e "${RED}[!]${NC} Qube already exists: $name" >&2
    exit 1
fi

# Validate count
if ! [[ "$count" =~ ^[0-9]+$ ]]; then
    echo -e "${RED}[!]${NC} Count is not a number" >&2
    exit 1
elif [ "$count" -lt 1 ]; then
    echo -e "${RED}[!]${NC} Count should be 1 or more" >&2
    exit 1
fi

# Parse template
if [ "$template" == "true" ]; then
    class="TemplateVM"
else
    class="StandaloneVM"
fi

# Validate netvm
if [ "$netvm" ]; then
    if ! qvm-check "$netvm" &> /dev/null; then
        echo -e "${RED}[!]${NC} NetVM does not exist: $netvm" >&2
        exit 1
    elif [ "$(qvm-prefs "$netvm" provides_network)" != "True" ]; then
        echo -e "${RED}[!]${NC} Not a NetVM: $netvm" >&2
        exit 1
    fi
fi

resources_qube="windows-mgmt"
resources_dir="/home/user/Documents/qvm-create-windows-qube"

# Validate packages
if [ "$packages" ]; then
    if [ "$netvm" ]; then
        if [ "$netvm" != "sys-whonix" ] && [ "$(qvm-prefs "$resources_qube" netvm)" != "sys-whonix" ]; then
            IFS="," read -ra package_arr <<< "$packages"
            for package in "${package_arr[@]}"; do
                if ! qvm-run -q "$resources_qube" "if [ \"\$(curl -so /dev/null -w '%{http_code}' 'https://chocolatey.org/api/v2/package/$package')\" == 404 ]; then exit 1; fi"; then
                    echo -e "${RED}[!]${NC} Package not found: $package" >&2
                    exit 1
                fi
            done
        else
            echo -e "${RED}[!]${NC} Cannot install Chocolatey packages because they use Cloudflare to indiscriminately block requests from curl/PowerShell over Tor. Websites may defend this practice by saying that the majority of Tor requests are malicious. However, this is a faulty comparision because just like with email or generally any other part of the internet these bad requests are made by a few bad apples that take more than their fair share of resources. To make a change, please visit https://chocolatey.org/contact and submit a blocked IP report refrencing Tor and this project." >&2
            exit 1
        fi
    else
        echo -e "${RED}[!]${NC} A NetVM must be configured to use packages" >&2
        exit 1
    fi
fi

# Validate iso
if ! qvm-run -q "$resources_qube" "cd '$resources_dir/windows-media/isos' && if ! [ -f '$iso' ]; then exit 1; fi"; then
    echo -e "${RED}[!]${NC} File not found in $resources_qube:$resources_dir/windows-media/isos: $iso" >&2
    exit 1
fi

# Validate answer-file
if ! qvm-run -q "$resources_qube" "cd '$resources_dir/windows-media/answer-files' && if ! [ -f '$answer_file' ]; then exit 1; fi"; then
    echo -e "${RED}[!]${NC} File not found in $resources_qube:$resources_dir/windows-media/answer-files: $answer_file" >&2
    exit 1
fi

# Install dependencies
echo -e "${BLUE}[i]${NC} Installing package dependencies on $resources_qube..." >&2
until qvm-run -q "$resources_qube" "cd '$resources_dir' && './install-dependencies.sh'"; do
    echo -e "${RED}[!]${NC} Failed to install dependencies! Retrying in 10 seconds..." >&2
    sleep 10
done

# Put answer file into Windows media
echo -e "${BLUE}[i]${NC} Preparing Windows media for automatic installation..." >&2
autounattend_iso="${iso%.*}-autounattend.iso"
if ! qvm-run -p "$resources_qube" "cd '$resources_dir/windows-media' && if ! [ -f $autounattend_iso ]; then './create-media.sh' 'isos/$iso' 'answer-files/$answer_file'; fi"; then
    echo -e "${RED}[!]${NC} Failed to create media! Possibly out of disk space? Exiting..." >&2
    exit 1
fi

# Create Windows qube the number of times specified using name as the basename if creating more than 1
for (( counter = 1; counter <= count; counter++ )); do
    if [ "$count" -gt 1 ]; then
        qube="$name-$counter"

        # If qube with that name already exists, keep incrementing the number until one that does not exist is found
        i=0
        while qvm-check "$qube" &> /dev/null; do
            ((i++))
            qube="$name-$i"
        done
    else
        qube="$name"
    fi

    echo -e "${BLUE}[i]${NC} Starting creation of $qube"
    qvm-create --class "$class" --label red "$qube"
    qvm-prefs "$qube" virt_mode hvm
    qvm-prefs "$qube" memory 400
    qvm-prefs "$qube" maxmem 0 # Disables currently unstable Qubes memory manager (Also grays the option out in qubes-vm-settings)
    qvm-prefs "$qube" kernel ""
    qvm-prefs "$qube" qrexec_timeout 300 # Windows startup can take longer, especially if a disk scan is performed
    qvm-features "$qube" video-model cirrus
    qvm-volume extend "$qube":root 30g
    qvm-prefs "$qube" netvm ""

    echo -e "${BLUE}[i]${NC} Commencing first part of Windows installation process..." >&2
    until qvm-start --cdrom "$resources_qube:$resources_dir/windows-media/$autounattend_iso" "$qube"; do
        echo -e "${RED}[!]${NC} Failed to start $qube! Retrying in 10 seconds..." >&2
        sleep 10
    done

    # Waiting for first part of Windows installation process to finish...
    wait_for_shutdown "true"

    echo -e "${BLUE}[i]${NC} Commencing second part of Windows installation process..." >&2
    qvm-features --unset "$qube" video-model
    until qvm-start "$qube"; do
        echo -e "${RED}[!]${NC} Failed to start $qube! Retrying in 10 seconds..." >&2
        sleep 10
    done

    # Waiting for second part of Windows installation process to finish...
    wait_for_shutdown "true"

    echo -e "${BLUE}[i]${NC} Preparing Qubes Windows Tools for automatic installation..." >&2
    # Pack latest QWT into auto-qwt
    qvm-run -p "$resources_qube" "cat > '$resources_dir/tools-media/qwt-installer.iso'" < "/usr/lib/qubes/qubes-windows-tools.iso"
    qvm-run -q "$resources_qube" "cd '$resources_dir/tools-media' && './unpack-qwt-installer-media.sh'"

    # Create auto-qwt media
    qvm-run -q "$resources_qube" "cd '$resources_dir/tools-media' && './pack-auto-qwt.sh'"

    echo -e "${BLUE}[i]${NC} Installing Qubes Windows Tools..." >&2
    qvm-prefs "$qube" netvm "$netvm"
    until qvm-start --cdrom "$resources_qube:$resources_dir/tools-media/auto-qwt.iso" "$qube"; do
        echo -e "${RED}[!]${NC} Failed to start $qube! Retrying in 10 seconds..." >&2
        sleep 10
    done

    # Waiting for automatic shutdown after Qubes Windows Tools install...
    wait_for_shutdown "true"

    echo -e "${BLUE}[i]${NC} Completing setup of Qubes Windows Tools..." >&2
    qvm-start "$qube"

    # Wait until QWT installation is advertised to Dom0
    until [ "$(qvm-features "$qube" os)" == "Windows" ]; do
        sleep 1
    done

    # At this point, qvm-run is working

    # Wait for app menu to synchronize (Automatically done once Qubes detects QWT)
    while pgrep -fx "/usr/bin/python3 /usr/bin/qvm-sync-appmenus $qube" &> /dev/null; do
        sleep 1
    done

    if [ "$seamless" == "true" ]; then
        qvm-run -q "$qube" 'reg add "HKLM\SOFTWARE\Invisible Things Lab\Qubes Tools\qga" /v SeamlessMode /t REG_DWORD /d 1 /f'
    fi

    # Nobody likes random reboots
    qvm-run -q "$qube" 'reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" /ve /f'
    qvm-run -q "$qube" 'reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" /ve /f'
    qvm-run -q "$qube" 'reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" /v NoAutoRebootWithLoggedOnUsers /t REG_DWORD /d 1 /f'

    if [ "$packages" ]; then
        echo -e "${BLUE}[i]${NC} Installing Chocolatey and packages..." >&2
        # Install Chocolatey (Command provided by: https://chocolatey.org/install)
        # Just added environment variable to use Windows compression so 7-Zip is not a mandatory install
        # shellcheck disable=SC2016
        qvm-run -q "$qube" '@"%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -InputFormat None -ExecutionPolicy Bypass -Command "$env:chocolateyUseWindowsCompression = '\''true'\''; iex ((New-Object System.Net.WebClient).DownloadString('\''https://chocolatey.org/install.ps1'\''))" && SET "PATH=%PATH%;%ALLUSERSPROFILE%\chocolatey\bin"'
        # Install packages
        qvm-run -p "$qube" "choco install -y ${packages//,/ }"

        # Add new apps to app menu
        qvm-sync-appmenus "$qube" &> /dev/null
    fi

    # Shutdown and wait until complete before finishing or starting next installation
    qvm-run -q "$qube" "shutdown /s /t 0"
    wait_for_shutdown "false"

    # Give reasonable amount of memory for actual use
    qvm-prefs "$qube" memory 1536

    if [ "$count" -gt 1 ]; then
       echo -e "${GREEN}[+]${NC} Finished creation of $qube successfully!"
    fi
done

echo -e "${GREEN}[+]${NC} Completed successfully!"
