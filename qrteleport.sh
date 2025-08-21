set -e
VERBOSE=0
TXT=0

USAGE="Usage: $0 [-v] [-t] <filepath> [outdir] [chunksdir]\n
-v: verbose output
-t: using text output instead of PNG
"

if [[ "$1" == "-v" ]]; then
  VERBOSE=1
  shift
fi

if [[ "$1" == "-t" ]]; then
  TXT=1
  shift
fi

FILEPATH="$1"
OUTDIR="$2"
CHUNKS="$3"

if [ -z "$FILEPATH" ]; then
  echo "$USAGE"
  exit 1
fi

if [[ ! -e "$FILEPATH" ]]; then
  echo "Error: file or directory '$FILEPATH' does not exist."
  exit 1
fi

if [ -z "$OUTDIR" ]; then
  OUTDIR="codes"
fi

if [[ $VERBOSE -eq 1 ]]; then
  echo "using directory $OUTDIR"
fi

if [ -z "$CHUNKS" ]; then
  CHUNKS="_tmp_chunks"
fi

if [[ $VERBOSE -eq 1 ]]; then
  echo "using default temp chunk directory $CHUNKS"
fi

FILENAME=$(basename "$FILEPATH")
if [[ $VERBOSE -eq 1 ]]; then
  echo "processing $FILENAME ..."
fi

if [[ -d "$FILEPATH" ]]; then
  if [[ $VERBOSE -eq 1 ]]; then
    tar -cvhzf "$FILENAME".tgz "$FILEPATH"
  else
    tar -chzf "$FILENAME".tgz "$FILEPATH"
  fi
  base64 "$FILENAME.tgz" >"$FILENAME".tmp
else
  ln -s "$FILEPATH" "$FILENAME".tmp
fi

mkdir -p "$OUTDIR"
mkdir -p "$CHUNKS"

split -b 2700 "$FILENAME".tmp "$CHUNKS"/"$FILENAME"_

n=0
for f in "$CHUNKS"/"$FILENAME"*; do
  if [[ $TXT -eq 0 ]]; then
    OUTFILE="$OUTDIR/$FILENAME-$(printf '%04d' $n).png"
  else
    OUTFILE="$OUTDIR/$FILENAME-$(printf '%04d' $n).txt"
  fi
  if [[ $VERBOSE -eq 1 ]]; then
    echo "creating '$OUTFILE' ..."
  fi

  if [[ $TXT -eq 0 ]]; then
    cat "$f" | qrencode -8 -m 2 -o "$OUTFILE"
  else
    cat "$f" | qrencode -8 -t ASCII -m 2 -o "$OUTFILE"
  fi
  n=$((n + 1))
done

if [[ $VERBOSE -eq 1 ]]; then
  echo "removing temp files ..."
fi
if [[ -d "$FILEPATH" ]]; then
  rm "$FILENAME".tgz
fi
rm -r "$CHUNKS"
rm "$FILENAME".tmp

if [[ $VERBOSE -eq 1 ]]; then
  echo "processing $FILENAME Done"
fi
