#!/usr/bin/env bash
if [ "$#" -ne 2 ]; then
  printf "Usage: %s <file> <line_number>\n" "$0" >&2
  exit 1
fi

file="$1"
line="$2"

out="$(git blame -L "$line",+1 --porcelain -- "$file")" || exit 1

IFS=$'\n' read -r -d '' -a DATA < <(
  printf '%s\n' "$out" | awk '
        /^author /{ author_name=$0; sub(/author /, "", author_name); next }
        /^author-mail /{ author_mail=$0; sub(/author-mail /, "", author_mail); next }
        /^author-time /{ epoch=$2; next }
        /^author-tz /{ author_tz=$2; next }
        /^summary /{ summary=$0; sub(/summary /, "", summary); next }
        {
            if (NR==1) { sha=$1 }
        }
        END {
            printf "%s\n%s\n%s\n%s\n%s\n%s", sha, author_name, author_mail, epoch, author_tz, summary
        }
    '
)

if [ "${DATA[1]}" = "Not Committed Yet" ]; then
  printf "Not Committed Yet"
  exit
fi

sha="${DATA[0]}"
author_name="${DATA[1]}"
author_mail="${DATA[2]}"
epoch="${DATA[3]}"
author_tz="${DATA[4]}"
summary="${DATA[5]}"

author="${author_name} ${author_mail}"

formatted_date="$(date -d "@$epoch" +"%a %b %d %H:%M:%S %Y" 2>/dev/null || printf '%s' "$epoch")"
date="${formatted_date} ${author_tz}"

printf "Commit:  %s\nAuthor:  %s\nDate:    %s\nSummary: %s\n" "$sha" "$author" "$date" "$summary"
