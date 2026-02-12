Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
iex "& {$(irm get.scoop.sh)} -RunAsAdmin"
scoop install restic
Write-Host "You're about to get prompted for a password, remember it or access to the backup repo is lost"
restic init --repo C:\Windows\bni
cd 'C:\Program Files'
restic -r C:\Windows\bni backup .\ C:\Users C:\AppData
Write-Host "Program Files, Users and C drive app data have been backed up, to resotre run restic -r C:\Windows\bni restore latest"
