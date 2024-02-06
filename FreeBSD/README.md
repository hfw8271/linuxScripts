This is a collection of security scripts for FreeBSD

These scripts have been created by Hal Williams for use in cybersecurity competitions. Use of these scripts in production systems is not reccomened and should not be run without fully understanding what each does and in depth knowledge of FreeBSD systems. I will attemt to doccument each script to provide the user with what each configuration change will do, but I reccomend that any user who wishes to secure a FreeBSD system seeks out CIS Benchmark Doccumentation, conducts thorough research, and tests each configuration in a backup system.

These Scripts have been designed based on CIS benchmark reccomendations and other research conducted

Some aspects of the script change TCP wrappers, ssh configs, and other critical configurations which may cause a lockout if the machine is accesed remotely

Refer to the following if the access is remote:

-A back up script is the first thing to run
-After changes have been made another backup script will save all changes to a directory with each configuration file modified
-Then a script will run to revert the system back to its old configurations after 5 minutes
-This is to prevent lockout to the system
-If the system does not lock out then the user should remove the scheduled task to revert the machine
-If the system is locked out then the user should access the machine after it is reverted and manually make changes and identify what has caused the system lockout
