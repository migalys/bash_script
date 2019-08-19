#!/bin/bash

######### Migalys Pavon, 2018-08-13 AIDE-explain.sh ####################

#### Scrip to check changes reported by AIDE and return ####
#####        Date and time of AIDE execution          ######
#####        Name of files that have been added       ######
#####        Name of files that have been removed     ######
#####        Name of files that have changed          ######

#cheking for new files or directories
new_file() {
    new=$(echo "$aide_output" | grep "f+++++++++" | cut -d' ' -f2)
    new_count=$(echo "$new" | grep -cv ^\$)
    if [[ ${new_count} -gt 0 ]]; then
        echo -e "\n${new_count} Files have been added"
        echo "${new}"
    else
        echo -e "\nNo files were added"
    fi
}

new_dir() {
    new=$(echo "$aide_output" | grep "d+++++++++" | cut -d' ' -f2)
    new_count=$(echo "$new" | grep -cv ^\$)
    if [[ ${new_count} -gt 0 ]]; then
        echo -e "\n${new_count} Directories have been added"
        echo "${new}"
    else
        echo -e "\nNo Directories were added"
    fi
}

#checking for removed files or directory
removed_file() {
    removed=$(echo "$aide_output" | grep "f----------" | cut -d' ' -f2)
    remv_count=$(echo "$removed" | grep -cv ^\$)
    if [[ ${remv_count} -gt 0 ]]; then
        echo -e "\n${remv_count} Files have been removed"
        echo  "${removed}"
    else
        echo -e "\nNo files were removed"
    fi
}

removed_dir() {
    removed=$(echo "$aide_output" | grep "d----------" | cut -d' ' -f2)
    remv_count=$(echo "$removed" | grep -cv ^\$)
    if [[ ${remv_count} -gt 0 ]]; then
        echo -e "\n${remv_count} Directories have been removed"
        echo  "${removed}"
    else
        echo -e "\nNo Directories were removed"
    fi
}

#checking for changed files
#determine if change is in content, size or permissions
changed_file() {
    content=$(echo "$aide_output" | grep "f [=<>] " | cut -d' ' -f9)
    cont_count=$(echo "$content" | grep -cv ^\$)
    if [[ ${cont_count} -gt 0 ]]; then
        echo -e "\n${cont_count} Files have been changed."
        echo  "${content}"
    else
        echo -e "\nNo files have been changed"
    fi


    time=$(echo "$aide_output" | grep "^f\s[<>=]\s...\smc" | cut -d' ' -f9)
    cont_count=$(echo "$time" | grep -cv ^\$)
    if [[ ${cont_count} -gt 0 ]]; then
        echo -e "\n${cont_count} Files have the modification and change time changed."
        echo  "${time}"
    else
        echo -e "\nNo files modification and change time were changed"
    fi


    md=$(echo "$aide_output" | grep "^f\s[<>=]\s...\s..\s.C" | cut -d' ' -f9)
    cont_count=$(echo "$md" | grep -cv ^\$)
    if [[ ${cont_count} -gt 0 ]]; then
        echo -e "\n${cont_count} Files have the checksums changed."
        echo  "${md}"
    else
        echo -e "\nNo files checksums were changed"
    fi

    perm=$(echo "$aide_output" | grep "f [=<>] p" | cut -d' ' -f9)
    perm_count=$(echo "$perm" | grep -cv ^\$)
    if [[ ${perm_count} -gt 0 ]]; then
        echo -e "\n${perm_count} Files have permission changed"
        echo  "${perm}"
    else
        echo -e "\nNo files permissions were changed"
    fi

    size=$(echo "$aide_output" | grep "f [<>]" | cut -d' ' -f9)
    size_count=$(echo "$size" | grep -cv ^\$)
    if [[ ${size_count} -gt 0 ]]; then
        echo -e "\n${size_count} Files have the size changed"
        echo "${size}"
    else
        echo -e "\nNo files sizes were changed"
    fi
}

changed_dir() {
    content=$(echo "$aide_output" | grep "d [=<>] " | cut -d' ' -f10)
    cont_count=$(echo "$content" | grep -cv ^\$)
    if [[ ${cont_count} -gt 0 ]]; then
        echo -e "\n${cont_count} Directories have been changed."
        echo  "${content}"
    else
        echo -e "\nNo Directories have been changed"
    fi
}

#check if AIDE is installed
if ! aide -version 2>/dev/null; then
    echo "AIDE is not installed, please."
    exit
fi

#check if there are changes
if aide_output=$(aide --config=/etc/aide/aide.conf --check); then
	  echo "AIDE detected NO changes."
else
    EXIT_STATUS=$?
    if  [[ "${EXIT_STATUS}" -le 7 && "${EXIT_STATUS}" -ge 1 ]]; then
        echo -e "\nDate and time: $(echo "$aide_output" | grep "Start timestamp:" | cut -d' ' -f3-4)"
        echo -e "\nAIDE detected changes"

        new_file
        new_dir
        removed_file
        removed_dir
        changed_dir
        changed_file

    else
        echo "Something was wrong with AIDE check."
    fi
fi
