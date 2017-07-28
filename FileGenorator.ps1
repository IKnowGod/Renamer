$files = get-content ".\newFile.txt"

foreach ($file in $files) {
    New-Item -Path ".\GoT\" -Name "$file"
}