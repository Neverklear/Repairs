# Boot Repair Tool
## Purpose

The Boot Repair Tool is a batch script designed to fix common Windows boot problems on UEFI/GPT systems. It automates the repair of the bootloader by checking the EFI System Partition (ESP) and rebuilding the boot configuration. This tool is intended to be run from a bootable recovery environment—such as the Windows Recovery Environment or Hiren’s Boot CD—to restore the Master Boot Record (MBR) and Boot Configuration Data (BCD) without needing to reinstall Windows.

### What this script does:

1. Identifies the EFI System Partition (or the active boot partition on BIOS/MBR systems) and assigns it a drive letter if necessary.

3. Checks the EFI partition’s file system for errors using chkdsk /f /r to ensure the partition is readable and not corrupted.

5. Runs boot repair commands: bootrec /fixmbr, bootrec /fixboot, bootrec /scanos, and bootrec /rebuildbcd to repair boot records.

7. If those commands fail, it uses bcdboot to manually rebuild the BCD.

**Verifies the results by listing the boot entries with bcdedit so you can confirm the boot configuration.**

This script offers a streamlined solution to repair boot issues caused by missing or corrupt boot files, an incorrect BCD configuration, or an unmounted EFI partition.

### Prerequisites
1. Windows Recovery Environment: You need to run the script from a recovery environment. Options include:

3. A Windows installation USB/DVD booted into Repair Mode (select “Repair your computer” > “Troubleshoot” > “Advanced options” > Command Prompt).

5. A bootable rescue disk like Hiren’s Boot CD PE or another Windows PE environment.

7. Administrator Access: The command prompt must be run with administrator privileges.

9. Script File: Ensure the batch script is accessible from the recovery environment (e.g., on a USB drive). Note that drive letters in recovery mode may differ from your usual Windows setup.

11. Unlocked Windows Partition: If your Windows partition is encrypted (e.g., BitLocker), unlock it before running the script.

### Usage Instructions
1. Boot from Recovery Media:
Insert your Windows installation media or Hiren’s Boot CD and boot the PC from it. Access the advanced recovery options:

2. For a Windows installation USB/DVD: select your language, click “Repair your computer,” then navigate to Troubleshoot > Advanced Options > Command Prompt.

3. For Hiren’s Boot CD PE: boot into the PE environment and open the Command Prompt.

### Locate the Script:

4. Determine the drive letter where the script is stored. In the recovery environment, drive letters may vary—use the dir command to locate your script file (e.g., BootRepair.bat).

5. Run the Script:
Navigate to the directory containing the script using the cd command and run the script by typing its name, such as:

**shell
Copy
BootRepair.bat**

*The script will start automatically and display messages as it performs each repair step.
*
Wait for Completion:
### The script will:

1. Locate and mount the EFI System Partition (assigning it a drive letter, typically S:, if necessary).

3. Perform a file system check on the EFI partition using chkdsk /f /r.

5. Execute the bootrec commands to repair the MBR, boot sector, scan for Windows installations, and rebuild the BCD.

7. Use bcdboot to recreate boot files and the BCD if needed.

9. Display the final boot configuration via bcdedit for verification.

*Allow the script to complete without interruption.
*
### Review the Output:
*Review the command prompt output for any error messages:

If errors occur during the bootrec commands (for example, “Access Denied”), the script will attempt to correct them using bcdboot.

Verify that the bcdedit output shows the correct boot entries for the Windows Boot Manager and Windows Boot Loader.

Exit and Reboot:
After the script completes:

Close the Command Prompt.

Remove the recovery media.

Reboot the system. The computer should now boot into Windows normally.
*
Post-Reboot Check:
Once Windows starts, confirm that the boot configuration remains intact. If you experience further boot issues, consider re-running the script or using additional troubleshooting steps.

Notes
The script removes any temporary drive letter assignment for the EFI partition once the repair is complete.

Ensure the disk is not being used by any other process during the repair.

It is recommended to back up important data before performing any boot repairs.

Follow these instructions carefully to restore your system's boot functionality.
