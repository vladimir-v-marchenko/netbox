#!/bin/bash

set -eu

SELFDIR=$(dirname $(readlink -m $0))
BASE=$(readlink -m $SELFDIR/..)

. $BASE/conf.sh

cd $SELFDIR

for template in ^*; do
    TARGET=${template//^/\/}
    if [ -f $TARGET ]; then
        mv $TARGET /tmp/$(basename $TARGET).bak
    fi
    cp --attributes-only $template $TARGET
    if grep @@@-COPY-ONLY $template > /dev/null; then
        grep -v @@@-COPY-ONLY $template > $TARGET
    else
        cat $template | {
            linenum=1
            while read line; do
                while [[ $line =~ \$\{([a-zA-Z_][a-zA-Z_0-9]*)\} ]]; do
                    LHS=${BASH_REMATCH[1]}
                    RHS="$(eval echo "\"\${$LHS-}\"")"
                    if [ -z $RHS ]; then
                        echo "Warning: $TARGET line $linenum: Undefined variable \"$LHS\""
                        RHS="[UNDEFINED]"
                    fi
                    line=${line//\$\{$LHS\}/$RHS}
                done
                echo $line >> $TARGET
                let linenum+=1
            done
        }
    fi
    chmod --reference=$template $TARGET
    chown --reference=$template $TARGET
done
