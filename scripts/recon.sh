#!/bin/bash

#############
# VARIABLES #
#############

TODAY=$(date)
DOMAIN=$1
DIRECTORY=${DOMAIN}_recon
HTML_REPORT="$DIRECTORY/report_$(date +'%Y%m%d_%H%M%S').html"


#############
# FUNCTIONS #
#############

cleanup_and_setup(){
	rm -Rf $DIRECTORY
	echo "Creating directory $DIRECTORY"
	mkdir $DIRECTORY
}

logo(){
echo "
    ---- --  ---       ---   ---- --- ----     
    |   |  | |   | |   |  |  |    |   |  | |\  |
    ---- --  --- ---   |--|  |--  |   |  | | \ |
    |   |  |   |  |    |  \  |    |   |  | |  \|
    --- |  | ---  |    |   | ---  --- ---- |   |

"
}

sublist3r_scan(){
        echo "Running sublist3r on $DOMAIN..."
	sublist3r -d $DOMAIN -o $DIRECTORY/sublist3r.txt
	echo "Checking responsive subdomains.."
	cat $DIRECTORY/sublist3r.txt | sort -u | httprobe -c 50 -t 3000 >> $DIRECTORY/sublist3r_responsive.txt
}

crt_scan(){
	echo "Running crt on $DOMAIN..."
	curl "https://crt.sh/?q=$DOMAIN&output=json" -o $DIRECTORY/crt
	jq -r ".[] | .name_value" $DIRECTORY/crt > $DIRECTORY/crt_results.txt
}

merge_subdomain_lists(){
	cat $DIRECTORY/sublist3r.txt >> $DIRECTORY/all_results.txt
	cat $DIRECTORY/crt_results.txt >> $DIRECTORY/all_results.txt
	sort -u $DIRECTORY/all_results.txt -o $DIRECTORY/all_results.txt
}

check_responsive(){
	echo "Checking responsive subdomains.."
	cat $DIRECTORY/all_results.txt | sort -u | httprobe -c 50 -t 3000 >> $DIRECTORY/all_responsive.txt
}


#!/bin/bash

generate_html_report() {
    echo "Creating HTML report"

    # Start the HTML file with dark mode styling
    cat <<EOF > "$HTML_REPORT"
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Subdomains report - $TODAY</title>
    <style>
        body {
            background-color: #1E1E1E;
            color: #FFFFFF;
            font-family: Arial, sans-serif;
        }
        h1 {
            color: #FFD700;
        }
        ul {
            list-style-type: none;
            padding: 0;
        }
        li {
            padding: 8px 0;
        }
        a {
            color: #64FFDA;
            text-decoration: none;
        }
        a:hover {
            text-decoration: underline;
        }
    </style>
</head>
<body>
    <h1>Responsive subdomains for $DOMAIN</h1>
    <ul>
EOF

    # Read the input file line by line
    while IFS= read -r url; do
        # Generate a list item for each URL
        echo "        <li><a href=\"$url\" target=\"_blank\">$url</a></li>" >> "$HTML_REPORT"
    done < "$DIRECTORY/all_responsive.txt"

    # End the HTML file
    cat <<EOF >> "$HTML_REPORT"
    </ul>
</body>
</html>
EOF

    echo "HTML report generated: $HTML_REPORT"
}


################
# EXECUTION    #
################
cleanup_and_setup
logo
echo "Scan date: $TODAY"
sublist3r_scan
crt_scan
merge_subdomain_lists
check_responsive
generate_html_report
