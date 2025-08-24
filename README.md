# dotfiles
Make sure `sudo` is installed, configure your user to a group to your liking, then add this line to your sudoers (manually or via `visudo`):
`%wheel ALL=(ALL:ALL) NOPASSWD: ALL`
Then just run `./install.sh`. (Do NOT call the script from outside this directory)

For any additional config, best practice is always creating a symlink to the config file in the include folder:
`ln -s <path_to_file> <path>/<to>/<destination>/<filename>`, optionally append custom file name as argument. 
Such folder is usually `conf.d/`.
