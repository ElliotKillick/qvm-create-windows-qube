#!/bin/bash

# Test for 4-bit color (16 colors)
if [ "0$(tput colors 2> /dev/null)" -ge 16 ]; then
    RED='\033[0;31m'
    BLUE='\033[0;34m'
    GREEN='\033[0;32m'
    NC='\033[0m'
fi

usage() {
    echo "Usage: ${0} <windows_media>..."
    echo ""
    echo "Download specified list of Windows media."
    echo ""
    echo "Specify \"all\" or one or more of the following Windows media:"
    echo "  win7x64-ultimate"
    echo "  win81x64"
    echo "  win10x64"
    echo "  win81x64-enterprise-eval"
    echo "  win10x64-enterprise-eval"
    echo "  win10x64-ltsc-eval"
    echo "  win2008r2"
    echo "  win2012r2-eval"
    echo "  win2016-eval"
    echo "  win2019-eval"
    echo ""
    echo "Important: The direct ISO downloads listed here are not necessarily subject to being updated and it is therefore recommended that the source referenced above each curl command is checked to see if a newer version is available"
}

for arg in "$@"; do
    if [ "$arg" == "-h" ] ||  [ "$arg" == "--help" ]; then
        usage
        exit
    fi
done

if [ "$#" -lt "1" ]; then
    usage >&2
    exit 1
fi

for arg in "$@"; do
    case "$arg" in
        win7x64-ultimate)
            win7x64_ultimate="true"
            ;;
        win81x64)
            win81x64="true"
            ;;
        win10x64)
            win10x64="true"
            ;;
        win81x64-enterprise-eval)
            win81x64_enterprise_eval="true"
            ;;
        win10x64-enterprise-eval)
            win10x64_enterprise_eval="true"
            ;;
        win10x64-ltsc-eval)
            win10x64_ltsc_eval="true"
            ;;
        win2008r2)
            win2008r2="true"
            ;;
        win2012r2-eval)
            win2012r2_eval="true"
            ;;
        win2016-eval)
            win2016_eval="true"
            ;;
        win2019-eval)
            win2019_eval="true"
            ;;
        all)
            all="true"
            ;;
        *)
            echo -e "${RED}[!]${NC} Invalid Windows media specified: $arg" >&2
            exit 1
            ;;
    esac
done

trap 'exit' ERR

download_microsoft_com_key="sha256//2e0F/Ardt/GQmXeDy1wheisQhjSImsJtf1rIekoQE7E="
software_download_microsoft_com_key="sha256//PPjoAKk+kCVr9VNPXJkyHXEKnIyd5t5NqpPL3zCvJOE="

scurl_1() {
    curl --pinnedpubkey "$download_microsoft_com_key" --tlsv1.2 --proto =https "$@"
}

scurl_2() {
    curl --pinnedpubkey "$software_download_microsoft_com_key" --tlsv1.3 --proto =https "$@"
}

echo -e "${BLUE}[i]${NC} Downloading Windows media from Microsoft servers..." >&2

if [ "$win7x64_ultimate" ] || [ "$all" ]; then
    echo -e "${BLUE}[i]${NC} Downloading Windows 7..." >&2
    # Heidoc Windows ISO Downloader
    scurl_1 "https://download.microsoft.com/download/5/1/9/5195A765-3A41-4A72-87D8-200D897CBE21/7601.24214.180801-1700.win7sp1_ldr_escrow_CLIENT_ULTIMATE_x64FRE_en-us.iso" -o "win7x64-ultimate.iso"
fi

if [ "$win81x64" ] || [ "$all" ]; then
    echo -e "${BLUE}[i]${NC} Downloading Windows 8.1..." >&2
    # Doesn't work because Microsoft gives links that are only valid for 24 hours (https://serverfault.com/questions/952196/how-do-i-download-a-win10x64-enterprise-eval-iso-file-from-microsoft-via-the-command-line)
    # https://www.microsoft.com/en-us/software-download/windows8ISO
    # Returns 403 forbidden: scurl_2 "https://software-download.microsoft.com/pr/Win8.1_English_x64.iso" -o "win81x64.iso
    echo -e "${RED}[!]${NC} Microsoft does not allow automatic downloading of this Windows media; please download it manually here: https://www.microsoft.com/en-us/software-download/windows8ISO (Don't forget to verify it afterwards)" >&2
fi

if [ "$win10x64" ] || [ "$all" ]; then
    echo -e "${BLUE}[i]${NC} Downloading Windows 10..." >&2
    # Doesn't work for same reason as Windows 8
    # https://www.microsoft.com/en-us/software-download/windows10ISO
    # Returns 403 forbidden: scurl_2 "https://software-download.microsoft.com/sg/Win10_1909_English_x64.iso" -o "win10x64.iso"
    echo -e "${RED}[!]${NC} Microsoft does not allow automatic downloading of this Windows media; please download it manually here: https://www.microsoft.com/en-us/software-download/windows10ISO (Don't forget to verify it afterwards)" >&2
fi

if [ "$win81x64_enterprise_eval" ] || [ "$all" ]; then
    echo -e "${BLUE}[i]${NC} Downloading Windows 8.1 Enterprise Evaluation..." >&2
    # Use to be here but got taken down: https://www.microsoft.com/en-us/evalcenter/evaluate-windows-8-1-enterprise
    # https://gist.github.com/eyecatchup/11527136b23039a0066f
    scurl_1 "https://download.microsoft.com/download/B/9/9/B999286E-0A47-406D-8B3D-5B5AD7373A4A/9600.17050.WINBLUE_REFRESH.140317-1640_X64FRE_ENTERPRISE_EVAL_EN-US-IR3_CENA_X64FREE_EN-US_DV9.ISO" -o "win81x64-enterprise-eval.iso"
fi

if [ "$win10x64_enterprise_eval" ] || [ "$all" ]; then
    echo -e "${BLUE}[i]${NC} Downloading Windows 10 Enterprise Evaluation..." >&2
    # https://www.microsoft.com/en-us/evalcenter/evaluate-windows-10-enterprise
    scurl_2 "https://software-download.microsoft.com/download/pr/18363.418.191007-0143.19h2_release_svc_refresh_CLIENTENTERPRISEEVAL_OEMRET_x64FRE_en-us.iso" -o "win10x64-enterprise-eval.iso"
fi

if [ "$win10x64_ltsc_eval" ] || [ "$all" ]; then
    echo -e "${BLUE}[i]${NC} Downloading Windows 10 Enterprise LTSC Evaluation..." >&2
    # https://www.microsoft.com/en-us/evalcenter/evaluate-windows-10-enterprise
    scurl_2 "https://software-download.microsoft.com/download/sg/17763.107.101029-1455.rs5_release_svc_refresh_CLIENT_LTSC_EVAL_x64FRE_en-us.iso" -o "win10x64-ltsc-eval.iso"
fi

if [ "$win2008r2" ] || [ "$all" ]; then
    echo -e "${BLUE}[i]${NC} Downloading Windows Server 2008 R2..." >&2
    # https://www.microsoft.com/en-us/download/details.aspx?id=11093
    scurl_1 "https://download.microsoft.com/download/7/5/E/75EC4E54-5B02-42D6-8879-D8D3A25FBEF7/7601.17514.101119-1850_x64fre_server_eval_en-us-GRMSXEVAL_EN_DVD.iso" -o "win2008r2.iso"
fi

if [ "$win2012r2_eval" ] || [ "$all" ]; then
    echo -e "${BLUE}[i]${NC} Downloading Windows Server 2012 R2..." >&2
    # https://www.microsoft.com/en-us/evalcenter/evaluate-windows-server-2012-r2
    scurl_1 "https://download.microsoft.com/download/6/2/A/62A76ABB-9990-4EFC-A4FE-C7D698DAEB96/9600.17050.WINBLUE_REFRESH.140317-1640_X64FRE_SERVER_EVAL_EN-US-IR3_SSS_X64FREE_EN-US_DV9.ISO" -o "win2012r2-eval.iso"
fi

if [ "$win2016_eval" ] || [ "$all" ]; then
    echo -e "${BLUE}[i]${NC} Downloading Windows Server 2016..." >&2
    # https://www.microsoft.com/en-us/evalcenter/evaluate-windows-server-2016
    scurl_2 "https://software-download.microsoft.com/download/pr/win2016_eval_Datacenter_EVAL_en-us_14393_refresh.ISO" -o "win2016-eval.iso"
fi

if [ "$win2019_eval" ] || [ "$all" ]; then
    echo -e "${BLUE}[i]${NC} Downloading Windows Server 2019..." >&2
    # https://www.microsoft.com/en-us/evalcenter/evaluate-windows-server-2019
    scurl_2 "https://software-download.microsoft.com/download/pr/17763.737.190906-2324.rs5_release_svc_refresh_SERVER_EVAL_x64FRE_en-us_1.iso" -o "win2019-eval.iso"
fi

echo -e "${BLUE}[i]${NC} Verifying integrity..." >&2
if ! sha256sum -c SHA256SUMS --ignore-missing; then
    echo -e "${RED}[!]${NC} One or more of the downloaded Windows media did not match the expected hash! This means either the media was corrupted during download or that is has been (potentially maliciously) modified! Please re-attempt the download and do not use the bad media." >&2
    exit 1
fi

echo -e "${GREEN}[+]${NC} Successfully downloaded and verified integrity of Windows media!"
