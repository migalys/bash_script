#!/usr/bin/env bash

######### Migalys Pavon, 2018-08-13 checkingIntegrity.sh ####################

####################### To install and configure AIDE ########################
##### Check whether AIDE is installed. If not, install and configure it ######
##############################################################################
error_exit()
{
    echo "${1}" 1>&2
    exit 1
}

install_aide()
{
apt update

apt install aide

# update configuration file
if cd /etc/aide; then
    rm aide.conf
    touch aide.conf
    echo -e '#Path for creating the databases\ndatabase=file:/var/lib/aide/aide.db\ndatabase_out=file:/var/lib/aide/aide.db.new\ndatabase_new=file:/var/lib/aideaide.db.new\n\n# Set your own AIDE rule\nMYRULE = p+n+u+g+s+m+c+xattrs+md5+sha512\n\n# Directories/files to be monitored and rule to apply\n/etc MYRULE\n/bin MYRULE\n/usr/bin MYRULE\n/root MYRULE\n\n# Directories to ignore\n!/home\n!/proc' > aide.conf
else
    error_exit 'Something was wrong with the installation.'
fi

#init aide to create databases
aide --config=/etc/aide/aide.conf --init

if cd /var/lib/aide; then
    cp aide.db.new  aide.db
else
    error_exit 'Something was wrong with the configuration.'
fi
}

#call function if aide is not installed
if ! aide -version 2>/dev/null; then
    install_aide
fi

################## end install and configure AIDE #####################
#######################################################################

################# creating new folder and file to check AIDE ##########
#######################################################################

to_check_aide() {
    if [[ -e "/etc/aide-test" ]]; then
        echo 'aide-test folder already exists'
    else
        mkdir /etc/aide-test
    fi

    if [[ -f "/etc/security-alert" ]]; then
        echo 'file security-alert already exists'
    else
        touch /etc/security-alert
    fi
}


## call function to_check_aide if necessary to generate a folder and file ##
####### Comment it out not to create a folder and file to test AIDE ########

to_check_aide

############## end creating new folder and file to check AIDE #########
#######################################################################


################# check for changes in the system ####################
######################################################################

if ! aide --config=/etc/aide/aide.conf --check; then
    # AIDE detected changes
    EXIT_STATUS=$?
    if  [[ "${EXIT_STATUS}" -gt 7 ]]; then
        case ${EXIT_STATUS} in
            14)
                message="Writing error."
                ;;
            15)
                message="Invalid argument error."
                ;;
            16)
                message="Unimplemented function erro.r"
                ;;
            17)
                message="Invalid configure line error."
                ;;
            18)
                message="IO error."
                ;;
            19)
                message="Version mismatch error."
                ;;
            *)
                message="Something was wrong with AIDE."
                ;;
        esac
    else
        message="AIDE detected changes in the system!"
    fi

    #Check if user exist and send mail with alert or error
    list=''
    date=$(date +'%d-%m-%Y %X')

    #admin users to send alert if no user
    adm="root $(getent group sudo | cut -d: -f4 | cut -d, -f1,2 --output-delimiter ' ')"

    for arg in "$@"
    do
        if getent passwd "$arg" >>/dev/null; then
            list+=" $arg"
        fi
    done

    if [[ -n "$list" ]]; then
        echo "${message} on ${date}." | mailx ${list} -s "AIDE alert on ${date}"
        if [[ $? -ne 0 ]]; then
            echo "Unable to send email to ${list} with alert: ${message}."
        else
            echo "AIDE alert was sent to ${list}: ${message}."
        fi
    else
        echo "There were no valid users to send AIDE alert on ${date}." | mailx ${adm} -s "AIDE alert error on ${date}"
        if [[ $? -ne 0 ]]; then
            echo "Unable to send email to admins with alert: ${message}."
        else
            echo "There were no valid users to send AIDE alert: ${message}."
        fi
    fi
else
    echo "AIDE did not report changes."
fi
#################             end                  ####################
#######################################################################
