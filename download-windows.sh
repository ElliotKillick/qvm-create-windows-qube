#!/bin/bash

scurl() {
    curl --tlsv1.2 --proto =https "$@"
}

archive_org_keys="sha256//cr5zEW+kToY4s0gRfx81qV0hJAVY1exO58jGFDaqvoQ=;sha256//zLWoDiMQtiVFZSFsOe3BPlTJ2tnNOc403LS/r0atv2s="
download_microsoft_com_key="sha256//2e0F/Ardt/GQmXeDy1wheisQhjSImsJtf1rIekoQE7E="

echo "Download Windows ISO..." >&2
cd "media-creation/isos" || exit 1
scurl --pinnedpubkey "$archive_org_keys" --location https://archive.org/download/digital_river/x17-59186.iso -o Win7_Pro_SP1_English_x64.iso
#scurl --pinnedpubkey "$download_microsoft_com_key" https://download.microsoft.com/download/5/1/9/5195A765-3A41-4A72-87D8-200D897CBE21/7601.24214.180801-1700.win7sp1_ldr_escrow_CLIENT_ULTIMATE_x64FRE_en-us.iso -O # This ISO doesn't work yet (See: todo)
sha256sum -c SHA256SUMS

cd "$OLDPWD" || exit 1

echo "Downlading update packages..." >&2
cd "auto-tools/auto-tools/updates/updates" || exit 1
scurl --pinnedpubkey "$download_microsoft_com_key" https://download.microsoft.com/download/5/D/0/5D0821EB-A92D-4CA2-9020-EC41D56B074F/Windows6.1-KB3020369-x64.msu -O
curl "http://download.windowsupdate.com/d/msdownload/update/software/updt/2016/05/windows6.1-kb3125574-v4-x64_2dafb1d203c8964239af3048b5dd4b1264cd93b9.msu" -O # Microsoft doesn't have HTTPS setup correctly for this domain
sha256sums -c SHA256SUMS

echo "Finished downloading Windows files!"
