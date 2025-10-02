# Backups
## rsync
* for subsequent backups, rsync will copy only the files that have been changed. 
* `rsync [FLAGS] [SOURCE_FILES] [DESTINATION_FILES]`
  * `--archive, -a` - a collection of flags, creates an archive with expected behavior 
  * `--verbose, -v` - verbose 
  * `--delete` - if a file was deleted from source files, then it will delete them in destination path; ensures consistency between source and destination paths
  * `-e` - remote shell, can specify various remote shells
    * `rsync -av -e ssh [SOURCE_FILES] [REMOTE_USER]@[REMOTE_IP_ADDRESS]:[DESTINATION_FILES_ADDRESS]`
    * `rsync -av -e "ssh -i [PRIVATE_KET]" [SOURCE_FILES] [REMOTE_USER]@[REMOTE_IP_ADDRESS]:[DESTINATION_FILES]`
### Example
* To backup 
  * `rsync -av [SOURCE_FILES] [DESTINATION_FILES]`
  * `rsync -ar [SRC] [DEST] --progress --delete --perms`