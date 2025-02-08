#!/bin/bash

function getOptions() {
    opt_found=0

    while getopts "acdhilnot" opt; do
        opt_found=1
        case $opt in
            a) asn=1 ;;
            c) country=1 ;;
            d) connection=1 ;;
            h) display_help ;;
            i) isp=1 ;;
            l) threat_level=1 ;;
            n) hostname=1 ;;
            o) organisation=1 ;;
            t) type=1 ;;

        esac
    done

    if [[ $opt_found == 0 ]]; then
        asn=1 && country=1 && connection=1 && isp=1 && threat_level=1 && hostname=1 && organisation=1 && type=1
    fi

    shift $((OPTIND-1))
    echo $@
    ip_address=$@
}

function display_help() {
    echo "Usage"
    echo "  $0 <ip_address>" [OPTIONS]
    echo "Each of the following options can be used to display specific information about the IP address."
    echo "Options:"
    echo "  -a          ASN"
    echo "  -c          Country"
    echo "  -d          Connection"
    echo "  -h          Display this help"
    echo "  -i          ISP"
    echo "  -l          Estimated threat level, including Crawler, Proxy, and Attack Source"
    echo "  -n          Hostname"
    echo "  -o          Organisation"
    echo "  -t          Type"
    exit 1
}

function checkEmpty() {
    if [ -z "$1" ]; then
        return 0
    else
        return 1
    fi
}


# Vérifie si l'adresse est une adresse IPv4 ou IPv6 valide
function validate_ip {
    if [[ $ip_address =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]] || [[ $1 =~ ^[0-9a-fA-F:]+$ ]]; then
        return 0
    else
        return 1
    fi
}

function get_info
{
curl -s https://db-ip.com/"$ip_address" > $TEMPDIR/ipnf.tmp
}

function parse_data
{
    # Prepare the output
    output="## RESULT FOR IP ADDRESS: $ip_address ## \n"

    if [ "$country" == 1 ]; then
    COUNTRY=$(cat $TEMPDIR/ipnf.tmp | grep ">Country<" | cut -d ">" -f 6 | cut -d "<" -f 1)
    output+="\nCOUNTRY:             $COUNTRY"
    fi

    if [ "$type" == 1 ]; then
    TYPE=$(cat $TEMPDIR/ipnf.tmp | grep "Address type" | cut -d ">" -f 5 | cut -d "&" -f 1)
    output+="\nLINK TYPE:           $TYPE"
    fi

    if [ "$hostname" == 1 ]; then
    HOSTNAME=$(cat $TEMPDIR/ipnf.tmp | grep "Hostname" | cut -d ">" -f 5 | cut -d "<" -f 1)
    output+="\nHOSTNAME:            $HOSTNAME"
    fi

    if [ "$asn" == 1 ]; then
    ASN=$(cat $TEMPDIR/ipnf.tmp | grep "ASN" | cut -d ">" -f 6 | cut -d "<" -f 1)
    output+="\nASN:                 $ASN"
    fi

    if [ "$isp" == 1 ]; then
    ISP=$(cat $TEMPDIR/ipnf.tmp | grep "ISP" | head -1 | cut -d ">" -f 5 | cut -d "<" -f 1)
    output+="\nISP:                 $ISP"
    fi

    if [ "$connection" == 1 ]; then
    CONNECTION=$(cat $TEMPDIR/ipnf.tmp |  grep "Connection" | head -1 | cut -d ">" -f 5 | cut -d "<" -f 1)
    output+="\nCONNECTION:          $CONNECTION"
    fi

    if [ "$connection" == 1 ]; then
    ORGANISATION=$(cat $TEMPDIR/ipnf.tmp | grep "Organization" | head -1 | cut -d ">" -f 5 | cut -d "<" -f 1)
    output+="\nORGANISATION:        $ORGANISATION"
    fi

    if [ "$threat_level" == 1 ]; then
        output+="\n \nTHREAT LEVEL:"
        cat $TEMPDIR/ipnf.tmp | grep "is not used by a web crawler" > /dev/null
        CHCRAWLER=$?
        if [[ $CHCRAWLER == 0 ]]; then
                output+="\nThis IP address is not used by a web crawler."
        else
                output+="\nThis IP address is used by a web crawler."
        fi

        cat $TEMPDIR/ipnf.tmp | grep "is not used by an anonymous proxy" > /dev/null
        CHPROXY=$?
        if [[ $CHPROXY == 0 ]]; then
                output+="\nThis IP address is not used by an anonymous proxy."
        else
                output+="\nThis IP address is used by an anonymous proxy."
        fi

        cat $TEMPDIR/ipnf.tmp | grep "is not a known source of cyber attack" > /dev/null
        CHATTACK=$?
        if [[ $CHATTACK == 0 ]]; then
                output+="\nThis IP address is not a known source of cyber attack."
        else
                output+="\nThis IP address is known as source of cyber attack."
        fi
    fi

    rm "$TEMPDIR/ipnf.tmp"
}

# Fonction principale
function main {
    getOptions "$@"

    TEMPDIR="/tmp"

    if validate_ip "$ip_address"; then
        get_info
        parse_data
        echo -e "$output"
    else
        echo "Invalid IP address."
    fi
}

main "$@"