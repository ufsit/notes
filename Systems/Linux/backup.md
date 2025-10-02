# Backups
## rsync
* rsync is able to recognize only the parts of a file that changed, and only send that data through
* `rsync [FLAGS] [SOURCE_FILES] [DESTINATION_FILES]`
  * `--archive, -a` - a collection of flags, creates an archive with expected behavior 
  * `--verbose, -v` - verbose 
  * `--delete` - if a file was deleted from source files, then it will also be deleted in destination path; ensures consistency between source and destination paths
  * `-e` - remote shell, can specify various remote shells
    * `rsync -av -e ssh [SOURCE_FILES] [REMOTE_USER]@[REMOTE_IP_ADDRESS]:[DESTINATION_FILES_ADDRESS]`
    * `rsync -av -e "ssh -i [PRIVATE_KET]" [SOURCE_FILES] [REMOTE_USER]@[REMOTE_IP_ADDRESS]:[DESTINATION_FILES]`
* NOTE: when specifying the source files to backup:
  * `/home/user/Desktop/stuff/` will copy all files inside `stuff` directory, but not the directory itself
  * `/home/user/Desktop/stuff` (without the `/`) will copy the folder and its files
### Example
* To backup 
  * `rsync -av [SOURCE_FILES] [DESTINATION_FILES]`
  * `rsync -ar [SRC] [DEST] --progress --delete --perms`
* To restore
  * `rsync -av <remote_user>@<remote_ip>:<remote_dir> <destination_dir>`