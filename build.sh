#!/bin/sh -e

if [ -z "$1" ] || [ ! -e "$1" ]; then
    echo "Ошибка! Файл не указан или не существует" >&2
    exit 1
fi

file="$1"
dir=$(cd "$(dirname "$file")" && pwd)
filename="${file##*/}"
out=$(grep -m 1 -E "(//|/\*|%).*Output:" "$file" | sed 's/.*Output:[[:space:]]*//' | tr -d '\r')

if [ -z "$out" ]; then
    echo "Ошибка! Не найден Output" >&2
    exit 2
fi

tmp=$(mktemp -d)

exit_handler() {
    local code=$?
    trap - EXIT
    rm -rf "$tmp"
    exit "$code"
}
trap exit_handler EXIT HUP INT QUIT PIPE TERM

cp "$file" "$tmp/"
cd "$tmp"
ext="${filename##*.}"

case "$ext" in
    c)
    gcc "$filename" -o "$out"
    ;;
    cpp|cc|cxx)
    g++ "$filename" -o "$out"
    ;;
    tex)
    pdflatex -interaction=nonstopmode -jobname="${out%.*}" "$filename"
    ;;
    *)
    echo "Ошибка! Неизвестный тип файла ($ext)" >&2
    exit 3
    ;;
esac

mv "$out" "$dir/"