task default -depends Build

Task Build {

    .\BuildMP.ps1
}

Task BuildMP -requiredVariables "File" {

    $MPBuildDir = $(Resolve-Path "$PSScriptRoot\Management Packs").Path

    # Walk the folder back up, until MP folder is found.
    $MPDir = $File
    $MPRootDirNotFound = $true
    while ($MPRootDirNotFound) {
        $prevDir = $MPDir

        $MPDir = Split-Path -Path $MPDir -Parent

        # Check if the MPBuildDir has been reached.
        if ($MPDir -eq $MPBuildDir) {

            # Restore the previous folder level, and quit the loop.
            $MPDir = $prevDir
            $MPRootDirNotFound = $false
        }
    }

    .\BuildMP.ps1 -MPDir $MPDir
}

Task Seal -requiredVariables "File" {
    .\MPSeal.ps1 -XMLFile $File
}