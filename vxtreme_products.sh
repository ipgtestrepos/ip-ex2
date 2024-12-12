#!/bin/bash
echo ===========================================================================
echo BEGIN FILE: vxtreme_products.sh
echo -e "===========================================================================\n"

ipgrid_server=localhost
ipgrid_port=4000

admin_user=ipgrid_admin
admin_pwd=ipgrid_pwd

integ_user=alex.rosso@ipgrid.com
integ_pwd=alex1234


# login as admin to create the company
ipg auth login --host ${ipgrid_server} --port ${ipgrid_port} --login ${admin_user} --password ${admin_pwd}

# setup vxtreme company
ipg auth company create --company vxtreme --legal-name "Verilog eXtreme" --email info@vxtreme --url "http://www.vxtreme.com"

# login owner for vxtreme products
ipg auth login --host ${ipgrid_server} --port ${ipgrid_port} --login ${integ_user} --password ${integ_pwd}

# define the products to be initialized: (name, release, company)
vxtremedirs=(
    'ip-vx-cache|vx-cache|VX High-speed Cache'
    'ip-vx-cvfpu|vx-cvfpu|VX CV Floating Point Unit'
    'ip-vx-fpu|vx-fpu|VX Floating Point Unit'
    'ip-vx-mem|vx-mem|VX SRAM Block'
)

# copy the products to the testbench
TOP=$(pwd)

saveIFS="$IFS"
for entry in "${vxtremedirs[@]}"; do
    IFS='|' read -r repo name descr <<< "$entry"
    cd ${TOP}

    git clone https://github.com/ipgtestrepos/${repo}.git
    cd $repo

    echo "Initializing product: $name"

    ipg prod init --company vxtreme --product $name --description "$descr" --type soft_ip --package-sources

    tags=( $( git tag --list ) )

    # following assumes tag in git is form:  v1.0.0 -> revision becomes 1.0.0
    for tag in ${tags[@]} ; do
        echo "processing git tag:  ${tag}"
        rev=${tag:1}
        git checkout ${tag}

        echo -e ".git\n.gitignore\n.ipg\n.ipgignore\n" > .ipgignore

        ipg prod add --delta
        ipg prod commit --release ${rev} --quiet
    done
done
IFS="$saveIFS"

