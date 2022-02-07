for f in $1*.png; do
    ff="$(basename -- $f .png).tres"
    if test -f "$ff"; then
        echo "$ff - already exist"
        continue
    fi
    if [[ "$ff" != *"INFO"* ]]; then
        echo "$ff - is not an INFO card"
        continue
    fi
    cp -p template.tres "$(basename -- $f .png).tres"
    echo "$ff - was added"
done
