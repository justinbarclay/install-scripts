
# .SYNOPSIS
#     Downloads Rust installers for Windows.
# .DESCRIPTION
#     Tries to download the latest available release for a given version of the Rust compiler.  It does this by checking the date the currently installed compiler was built against the timestamp of the remote installer.  These do not always match up, so do not be surprised if this script keeps trying to re-download the same archive.
#     Once downloaded, provided you specified either 'exe' or 'msi', the script will run the installer for you.
# .PARAMETER Release
#     'nightly', 'beta', or a full 3-part version number.
# .PARAMETER InstallerType
#     'exe', 'msi', or 'tar.gz'.  Note that 'tar.gz' archives will be downloaded, but not installed.
# .PARAMETER UseStaging
#     Acquire archive from staging.  This is used to access preview releases.
# .PARAMETER Triple
#     Override platform triple.  May be one of the follow: 'i686-pc-windows-gnu', 'x86_64-pc-windows-gnu', 'i686-pc-windows-msvc', or 'x86_64-pc-windows-msvc'.
# .PARAMETER ForceInstall
#     Force installer to be run.
# .PARAMETER DontInstall
#     Instruct rustup to not install what it downloads.
# .PARAMETER NoisyInstall
#     Don't run the installer silently.

[CmdletBinding()]
Param(
    [Parameter(Mandatory=$False, Position=0,
        HelpMessage="'nightly', 'beta', or a full 3-part version number.")]
    [Alias("Version")]
    [ValidatePattern("nightly|beta|[0-9]+\.[0-9]+\.[0-9]+")]
    [String]$Release = "nightly",

    [Parameter(Mandatory=$False, Position=1,
        HelpMessage="'exe', 'msi', or 'tar.gz'.")]
    [Alias("Archive", "Type")]
    [ValidateSet("exe", "msi", "tar.gz")]
    [String]$InstallerType = "exe",

    [Parameter(Mandatory=$False,
        HelpMessage="Acquire archive from staging.")]
    [Alias("Staging")]
    [Switch]$UseStaging = $False,

    [Parameter(Mandatory=$False,
        HelpMessage="Override platform triple.")]
    [Alias("Platform")]
    [ValidateSet("i686-pc-windows-gnu", "x86_64-pc-windows-gnu", "i686-pc-windows-msvc", "x86_64-pc-windows-msvc")]
    [String]$Triple = "i686-pc-windows-gnu",

    [Parameter(Mandatory=$False,
        HelpMessage="Force installer to be downloaded and run.")]
    [Alias("Force")]
    [Switch]$ForceInstall = $False,

    [Parameter(Mandatory=$False,
        HelpMessage="Instruct rustup to not install what it downloads.")]
    [Switch]$DontInstall = $False,

    [Parameter(Mandatory=$False,
        HelpMessage="Don't run the installer silently.")]
    [Switch]$NoisyInstall = $False
)

$DIST_URL = "https://static.rust-lang.org/dist{3}/rust-{0}-{1}.{2}"

$STAGING_URL = @{
    $true = "/staging";
    $false = "";
}

$ErrorActionPreference = [System.Management.Automation.ActionPreference]::Stop

$release = $Release
$installer_type = $InstallerType
$use_staging = $UseStaging
$triple = $Triple

$nightly_url = $DIST_URL
$nightly_url = [String]::Format($nightly_url,
    $release, $triple, $installer_type, $STAGING_URL[$use_staging])

echo "Checking $nightly_url..."
$nightly_resp = Invoke-WebRequest -Method HEAD $nightly_url -usebasicparsing
$nightly_size = $nightly_resp.Headers['Content-Length']
$nightly_date = [DateTime]$nightly_resp.Headers["Last-Modified"]

# Subtract 24 hours because the last-modified date the server returns doesn't
# actually match the date the compiler itself reports.
$nightly_date = $nightly_date.AddDays(-1)

$nightly_ts = $NIGHTLY_DATE.ToString("yyyyMMdd")

$m = [regex]::match($(rustc -V), '(\d{4})-(\d\d)-(\d\d)')
$rustc_ts = "$($m.Groups[1].Value)$($m.Groups[2].Value)$($m.Groups[3].Value)"

$dest = "rust-nightly-$triple-$nightly_ts.$installer_type"

if ($rustc_ts -ge $nightly_ts -and -not $ForceInstall) {
    # No need to do anything.
    echo "Installed compiler is up-to-date ($nightly_ts)."
    exit
}

# We need to download if the nightly file doesn't exist.
echo "Build timestamp: $nightly_ts"

if (Test-Path $dest) {
    # Do nothing.
    echo "Skipping download."
} else {
    $nightly_mib = $nightly_size / (1024 * 1024)
    $nightly_mib = [String]::Format("{0:F2} MiB", $nightly_mib)
    echo "Downloading $nightly_url ($nightly_mib) to $dest..."
    Invoke-WebRequest $nightly_url -OutFile $dest
    orElse {
        echo "Aborting: download failed."
        exit
    }
}

# Install if `rustc` reports an older version and we didn't get .tar.gz.

if ([regex]::Match($dest, '\.tar\.gz$').Success) {
    $dontInstall = $true
}

if (-not $DontInstall) {
    if ($ForceInstall -or $rustc_ts -lt $nightly_ts) {
        echo "Installing $release..."
        $installer_args = @()
        if ($installer_type -eq "exe" -and -not $NoisyInstall) {
            $installer_args = @("/SILENT")
        } elseif ($install_type -eq "msi" -and -not $NoisyInstall) {
            echo "(Silent install of MSI not yet implemented.)"
        }
        Start-Process ".\$dest" -ArgumentList $installer_args -NoNewWindow -Wait
    } else {
        echo "Installed rustc is up-to-date."
    }
}
